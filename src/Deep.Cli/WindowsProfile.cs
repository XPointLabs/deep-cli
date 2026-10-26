using System.Buffers.Binary;
using System.Security.AccessControl;
using System.Security.Cryptography;
using System.Security.Principal;
using Deep.Client.Shared.Persistence;
using Deep.Client.Shared.Services;
using Deep.Protocol.ApplicationCore;

namespace Deep.Cli;

internal sealed class WindowsProfile : IDisposable
{
    private readonly FileStream commandLease;
    private readonly JournaledDeepSecureStorage storage;
    private readonly CurrentUserProtector protector;
    internal DeepIdV2AccountService Accounts { get; }
    internal DeepSecureStorageWorkSnapshot StorageWork => storage.ReadWorkSnapshot();

    private WindowsProfile(string root, byte[] network, FileStream commandLease,
        JournaledDeepSecureStorage storage, CurrentUserProtector protector)
    {
        this.commandLease = commandLease; this.storage = storage; this.protector = protector;
        Accounts = new DeepIdV2AccountService(storage, Path.Combine(root, "deep-store-v2"), network,
            1, new SystemClock(), DeepMlDsa65CandidateVerifierFactory.OpenForCurrentProcess);
    }

    internal static async Task<WindowsProfile> OpenAsync(CommandLine command, CancellationToken ct = default)
    {
        ct.ThrowIfCancellationRequested();
        if (command.Area == "storage") throw new ArgumentException("Storage enrollment is standalone.");
        var creating = command.Area == "account" && command.Operation == "create";
        var root = PrepareRoot(command, creating);
        var commandLease = AcquireCommandLease(root);
        var protector = new CurrentUserProtector();
        JournaledDeepSecureStorage? storage = null;
        try
        {
            ct.ThrowIfCancellationRequested();
            var directory = Path.Combine(root, "deep-store-v2");
            var path = Path.Combine(directory, "secure-storage.dss");
            if (creating && !File.Exists(path))
            {
                // Account creation can initialize only a genuinely empty owned
                // profile. Missing committed state beside any prior state is
                // refusal, never permission to replace its keys or instance.
                RequireEmptyProfile(root, directory);
                Directory.CreateDirectory(directory);
                RequireNoReparseTree(root);
                storage = await JournaledDeepSecureStorage.CreateNewAsync(path, protector, ct).ConfigureAwait(false);
            }
            else storage = new JournaledDeepSecureStorage(path, protector);
            ct.ThrowIfCancellationRequested();
            return new WindowsProfile(root, command.Network, commandLease, storage, protector);
        }
        catch { storage?.Dispose(); protector.Dispose(); commandLease.Dispose(); throw; }
    }

    internal static async Task<DeepSecureStorageWorkSnapshot> EnrollStorageAsync(CommandLine command, CancellationToken ct)
    {
        ct.ThrowIfCancellationRequested();
        if (command.Area != "storage" || command.Operation != "enroll")
            throw new ArgumentException("Explicit storage enrollment required.");
        var root = PrepareRoot(command, create: false);
        using var commandLease = AcquireCommandLease(root);
        using var protector = new CurrentUserProtector();
        using var storage = await JournaledDeepSecureStorage.EnrollAggregateAsync(
            Path.Combine(root, "deep-store-v2", "secure-storage.dss"), protector, ct).ConfigureAwait(false);
        return storage.ReadWorkSnapshot();
    }

    private static FileStream AcquireCommandLease(string root) =>
        new(Path.Combine(root, "command.lock"), FileMode.OpenOrCreate, FileAccess.ReadWrite, FileShare.None);

    private static string PrepareRoot(CommandLine command, bool create)
    {
        if (!OperatingSystem.IsWindows()) throw new PlatformNotSupportedException();
        var root = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "XPointLabs", "DeepCli", Convert.ToHexStringLower(command.Network), command.Profile);
        RequireNoReparseAncestors(root);
        if (!create && !Directory.Exists(root))
            throw new DirectoryNotFoundException("An existing private profile is required.");
        var security = new DirectorySecurity();
        var user = WindowsIdentity.GetCurrent().User ?? throw new UnauthorizedAccessException();
        security.SetOwner(user);
        security.SetAccessRuleProtection(isProtected: true, preserveInheritance: false);
        security.AddAccessRule(new FileSystemAccessRule(user, FileSystemRights.FullControl,
            InheritanceFlags.ContainerInherit | InheritanceFlags.ObjectInherit, PropagationFlags.None,
            AccessControlType.Allow));
        // The profile is private from creation, before any account/SQL/key write.
        var profile = new DirectoryInfo(root);
        if (create) profile.Create(security);
        profile.SetAccessControl(security);
        RequireNoReparseAncestors(root);
        RequireNoReparseTree(root);
        return root;
    }

    private static void RequireEmptyProfile(string root, string storageDirectory)
    {
        foreach (var entry in Directory.EnumerateFileSystemEntries(root))
            if (!StringComparer.OrdinalIgnoreCase.Equals(entry, Path.Combine(root, "command.lock")) &&
                !StringComparer.OrdinalIgnoreCase.Equals(entry, storageDirectory))
                throw new IOException("Missing committed storage cannot initialize a populated profile.");
        if (Directory.Exists(storageDirectory) && Directory.EnumerateFileSystemEntries(storageDirectory).Any())
            throw new IOException("Missing committed storage cannot initialize a populated profile.");
    }

    private static void RequireNoReparseTree(string root)
    {
        var pending = new Stack<DirectoryInfo>(); pending.Push(new(root));
        while (pending.TryPop(out var directory))
            foreach (var child in directory.EnumerateFileSystemInfos())
            {
                if ((child.Attributes & FileAttributes.ReparsePoint) != 0)
                    throw new IOException("Profile reparse point rejected.");
                if (child is DirectoryInfo nested) pending.Push(nested);
            }
    }

    private static void RequireNoReparseAncestors(string root)
    {
        for (DirectoryInfo? current = new(root); current is not null; current = current.Parent)
            if (current.Exists && (current.Attributes & FileAttributes.ReparsePoint) != 0)
                throw new IOException("Profile reparse point rejected.");
    }

    public void Dispose()
    {
        try { Accounts.Dispose(); }
        finally { try { storage.Dispose(); } finally { protector.Dispose(); commandLease.Dispose(); } }
    }

    // Platform envelope only, not a Deep wire record. DPAPI protects a fresh
    // per-write key, AES-GCM authenticates the entire aggregate on EVERY read.
    // No retained plaintext/key, separate key file or retired raw-DPAPI reader.
    internal sealed class CurrentUserProtector : IDeepSecretProtector, IDisposable
    {
        private static readonly byte[] Entropy = "Deep/Cli/Store/V2/Windows-DPAPI"u8.ToArray();
        private static ReadOnlySpan<byte> Marker => "DeepCli/DPAPI-AESGCM/v1\0"u8;
        private const int MaximumPlaintextBytes = 8 * 1024 * 1024, MaximumWrappedKeyBytes = 2048;
        private const int NonceBytes = 12, TagBytes = 16, KeyBytes = 32;
        private readonly object gate = new();
        private bool disposed;
        internal long NativeUnprotects { get; private set; }
        public byte[] Protect(ReadOnlySpan<byte> plaintext)
        {
            lock (gate)
            {
                ObjectDisposedException.ThrowIf(disposed, this);
                if (plaintext.IsEmpty || plaintext.Length > MaximumPlaintextBytes) throw new ArgumentException("Secret size rejected.");
                var key = RandomNumberGenerator.GetBytes(KeyBytes);
                byte[] wrapped = [];
                var started = System.Diagnostics.Stopwatch.GetTimestamp();
                try
                {
                    wrapped = ProtectedData.Protect(key, Entropy, DataProtectionScope.CurrentUser);
                    if (wrapped.Length is < 1 or > MaximumWrappedKeyBytes) throw new CryptographicException("Wrapped key size rejected.");
                    var prefix = checked(Marker.Length + 4 + wrapped.Length + NonceBytes);
                    var result = new byte[checked(prefix + TagBytes + plaintext.Length)];
                    Marker.CopyTo(result);
                    BinaryPrimitives.WriteUInt32BigEndian(result.AsSpan(Marker.Length), checked((uint)wrapped.Length));
                    wrapped.CopyTo(result, Marker.Length + 4);
                    var nonce = result.AsSpan(prefix - NonceBytes, NonceBytes);
                    RandomNumberGenerator.Fill(nonce);
                    using var aes = new AesGcm(key, TagBytes);
                    aes.Encrypt(nonce, plaintext, result.AsSpan(prefix + TagBytes), result.AsSpan(prefix, TagBytes), result.AsSpan(0, prefix));
                    return result;
                }
                finally { CryptographicOperations.ZeroMemory(key); CryptographicOperations.ZeroMemory(wrapped); ProtectionWork.Record(true, started); }
            }
        }
        public byte[] Unprotect(ReadOnlySpan<byte> protectedBytes)
        {
            lock (gate)
            {
                ObjectDisposedException.ThrowIf(disposed, this);
                if (protectedBytes.Length < Marker.Length + 4 + 1 + NonceBytes + TagBytes + 1 ||
                    protectedBytes.Length > MaximumPlaintextBytes + MaximumWrappedKeyBytes + Marker.Length + 4 + NonceBytes + TagBytes ||
                    !protectedBytes.StartsWith(Marker))
                    throw new CryptographicException("Unsupported CLI protection envelope; use a new isolated profile.");
                var length = BinaryPrimitives.ReadUInt32BigEndian(protectedBytes[Marker.Length..]);
                if (length is < 1 or > MaximumWrappedKeyBytes) throw new CryptographicException("Wrapped key size rejected.");
                var prefix = checked(Marker.Length + 4 + (int)length + NonceBytes);
                var clearLength = protectedBytes.Length - prefix - TagBytes;
                if (clearLength is < 1 or > MaximumPlaintextBytes) throw new CryptographicException("Protected aggregate size rejected.");
                var wrapped = protectedBytes.Slice(Marker.Length + 4, (int)length).ToArray();
                byte[] key = [], plaintext = [];
                var started = System.Diagnostics.Stopwatch.GetTimestamp();
                try
                {
                    NativeUnprotects++;
                    key = ProtectedData.Unprotect(wrapped, Entropy, DataProtectionScope.CurrentUser);
                    if (key.Length != KeyBytes) throw new CryptographicException("Unwrapped key size rejected.");
                    plaintext = new byte[clearLength];
                    using var aes = new AesGcm(key, TagBytes);
                    aes.Decrypt(protectedBytes.Slice(prefix - NonceBytes, NonceBytes), protectedBytes[(prefix + TagBytes)..],
                        protectedBytes.Slice(prefix, TagBytes), plaintext, protectedBytes[..prefix]);
                    var owned = plaintext; plaintext = []; return owned;
                }
                finally
                {
                    CryptographicOperations.ZeroMemory(key); CryptographicOperations.ZeroMemory(wrapped);
                    CryptographicOperations.ZeroMemory(plaintext); ProtectionWork.Record(false, started);
                }
            }
        }
        public void Dispose()
        {
            lock (gate)
            {
                if (disposed) return;
                disposed = true;
            }
        }
    }
}
