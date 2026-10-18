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
    private readonly CurrentUserProtector protector = new();
    internal DeepIdV2AccountService Accounts { get; }

    private WindowsProfile(string root, byte[] network)
    {
        commandLease = new FileStream(Path.Combine(root, "command.lock"), FileMode.OpenOrCreate,
            FileAccess.ReadWrite, FileShare.None);
        try
        {
            storage = new JournaledDeepSecureStorage(Path.Combine(root, "deep-store-v2", "secure-storage.dss"),
                protector);
            Accounts = new DeepIdV2AccountService(storage, Path.Combine(root, "deep-store-v2"), network,
                1, new SystemClock(), DeepMlDsa65CandidateVerifierFactory.OpenForCurrentProcess);
        }
        catch { storage?.Dispose(); protector.Dispose(); commandLease.Dispose(); throw; }
    }

    internal static WindowsProfile Open(CommandLine command)
    {
        if (!OperatingSystem.IsWindows()) throw new PlatformNotSupportedException();
        var root = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "XPointLabs", "DeepCli", Convert.ToHexStringLower(command.Network), command.Profile);
        RequireNoReparseAncestors(root);
        var security = new DirectorySecurity();
        var user = WindowsIdentity.GetCurrent().User ?? throw new UnauthorizedAccessException();
        security.SetOwner(user);
        security.SetAccessRuleProtection(isProtected: true, preserveInheritance: false);
        security.AddAccessRule(new FileSystemAccessRule(user, FileSystemRights.FullControl,
            InheritanceFlags.ContainerInherit | InheritanceFlags.ObjectInherit, PropagationFlags.None,
            AccessControlType.Allow));
        // The profile is private from creation, before any account/SQL/key write.
        var profile = new DirectoryInfo(root);
        profile.Create(security);
        profile.SetAccessControl(security);
        RequireNoReparseAncestors(root);
        foreach (var child in profile.EnumerateFileSystemInfos("*", SearchOption.AllDirectories))
            if ((child.Attributes & FileAttributes.ReparsePoint) != 0)
                throw new IOException("Profile reparse point rejected.");
        return new WindowsProfile(root, command.Network);
    }

    private static void RequireNoReparseAncestors(string root)
    {
        for (DirectoryInfo? current = new(root); current is not null; current = current.Parent)
            if (current.Exists && (current.Attributes & FileAttributes.ReparsePoint) != 0)
                throw new IOException("Profile reparse point rejected.");
    }

    public void Dispose() { try { storage.Dispose(); } finally { protector.Dispose(); commandLease.Dispose(); } }

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
