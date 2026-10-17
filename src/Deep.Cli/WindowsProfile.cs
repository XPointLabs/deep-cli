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
    internal DeepIdV2AccountService Accounts { get; }

    private WindowsProfile(string root, byte[] network)
    {
        commandLease = new FileStream(Path.Combine(root, "command.lock"), FileMode.OpenOrCreate,
            FileAccess.ReadWrite, FileShare.None);
        try
        {
            storage = new JournaledDeepSecureStorage(Path.Combine(root, "deep-store-v2", "secure-storage.dss"),
                new CurrentUserProtector());
            Accounts = new DeepIdV2AccountService(storage, Path.Combine(root, "deep-store-v2"), network,
                1, new SystemClock(), DeepMlDsa65CandidateVerifierFactory.OpenForCurrentProcess);
        }
        catch { storage?.Dispose(); commandLease.Dispose(); throw; }
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

    public void Dispose() { storage.Dispose(); commandLease.Dispose(); }

    // Platform envelope only: raw DPAPI output, no new Deep wire/record grammar,
    // no application-owned key file and no device namespace compatibility reader.
    internal sealed class CurrentUserProtector : IDeepSecretProtector
    {
        private static readonly byte[] Entropy = "Deep/Cli/Store/V2/Windows-DPAPI"u8.ToArray();
        public byte[] Protect(ReadOnlySpan<byte> plaintext)
        {
            if (plaintext.IsEmpty) throw new ArgumentException("Empty secret rejected.");
            var copy = plaintext.ToArray();
            try { return ProtectedData.Protect(copy, Entropy, DataProtectionScope.CurrentUser); }
            finally { CryptographicOperations.ZeroMemory(copy); }
        }
        public byte[] Unprotect(ReadOnlySpan<byte> protectedBytes)
        {
            var copy = protectedBytes.ToArray();
            try { return ProtectedData.Unprotect(copy, Entropy, DataProtectionScope.CurrentUser); }
            finally { CryptographicOperations.ZeroMemory(copy); }
        }
    }
}
