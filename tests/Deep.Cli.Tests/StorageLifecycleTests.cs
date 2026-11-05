using System.Buffers.Binary;
using System.Security.AccessControl;
using System.Security.Cryptography;
using System.Security.Principal;
using System.Text;
using System.Text.Json;
using Deep.Client.Shared.Persistence;

namespace Deep.Cli.Tests;

public sealed class StorageLifecycleTests
{
    [Fact]
    public async Task PublicationArchiveEnrollmentIsExplicitAndRejectsSessionBeforeProfileAccess()
    {
        using var f = new Fixture();
        var args = f.Args("publication", "enroll-archive");
        var command = CommandLine.Parse(args);
        Assert.Equal("publication", command.Area);
        foreach (var option in new[] { "--reset", "--force", "--name", "--bootstrap", "--registry", "--operation" })
            Assert.Throws<ArgumentException>(() => CommandLine.Parse([.. args, option, "rejected"]));
        using var session = new CliSession(command with { Area = "session", Operation = "run" });
        using var output = new StringWriter(); using var error = new StringWriter();
        Assert.Equal(2, await Program.RunAsync(args, output, error, default, session));
        Assert.Equal("", output.ToString());
        Assert.False(Directory.Exists(f.Root));
    }

    [Fact]
    public async Task EnrollmentIsExplicitScopedAndRejectedInsideSessionBeforeProfileAccess()
    {
        using var f = new Fixture();
        var command = CommandLine.Parse(f.Args("storage", "enroll"));
        Assert.Equal("storage", command.Area);
        foreach (var option in new[] { "--reset", "--force", "--name", "--bootstrap", "--operation" })
            Assert.Throws<ArgumentException>(() => CommandLine.Parse([.. f.Args("storage", "enroll"), option, "rejected"]));
        using var session = new CliSession(command with { Area = "session", Operation = "run" });
        using var output = new StringWriter(); using var error = new StringWriter();
        Assert.Equal(2, await Program.RunAsync(f.Args("storage", "enroll"), output, error, default, session));
        Assert.Equal("", output.ToString());
        Assert.False(Directory.Exists(f.Root));
    }

    [Fact]
    public async Task MissingOrdinaryOrEnrollmentProfileDoesNotCreateStateAndCreationCannotReplacePriorNativeFiles()
    {
        using var f = new Fixture();
        foreach (var args in new[] { f.Args("account", "status"), f.Args("storage", "enroll"), f.Args("publication", "enroll-archive") })
        {
            using var output = new StringWriter(); using var error = new StringWriter();
            Assert.Equal(5, await Program.RunAsync(args, output, error));
            Assert.False(Directory.Exists(f.Root)); Assert.Equal("", output.ToString());
        }
        f.CreatePrivateDirectory();
        Directory.CreateDirectory(Path.GetDirectoryName(f.State)!);
        var sentinel = Path.Combine(Path.GetDirectoryName(f.State)!, "retained-native.dsv2");
        await File.WriteAllBytesAsync(sentinel, [1, 2, 3]);
        using var created = new StringWriter(); using var rejected = new StringWriter();
        Assert.Equal(5, await Program.RunAsync([.. f.Args("account", "create"), "--name", "No replacement"], created, rejected));
        Assert.False(File.Exists(f.State)); Assert.Equal(new byte[] { 1, 2, 3 }, await File.ReadAllBytesAsync(sentinel));
    }

    [Fact]
    public async Task FreshCreationInitializesEmptyStorageAndMissingCommittedStateCannotReinitializeIt()
    {
        using var f = new Fixture();
        var create = CommandLine.Parse([.. f.Args("account", "create"), "--name", "Empty lifecycle fixture"]);
        using (var profile = await WindowsProfile.OpenAsync(create))
            Assert.True(profile.StorageWork.ManifestWrites > 0);
        using var output = new StringWriter(); using var error = new StringWriter();
        Assert.Equal(0, await Program.RunAsync(f.Args("account", "status"), output, error));
        using (var result = JsonDocument.Parse(output.ToString()))
        {
            Assert.False(result.RootElement.GetProperty("accountPresent").GetBoolean());
            Assert.True(result.RootElement.GetProperty("storageWork").GetProperty("manifestReads").GetInt64() > 0);
        }
        File.Delete(f.State); // Disposable empty fixture only; never a repair action.
        using var missing = new StringWriter(); using var missingError = new StringWriter();
        Assert.NotEqual(0, await Program.RunAsync(f.Args("account", "status"), missing, missingError));
        Assert.False(File.Exists(f.State));
        using var denied = new StringWriter(); using var deniedError = new StringWriter();
        Assert.Equal(5, await Program.RunAsync([.. f.Args("account", "create"), "--name", "Must refuse"], denied, deniedError));
        Assert.False(File.Exists(f.State));
    }

    [Fact]
    public async Task StandaloneEnrollmentPreservesSlotsAndNativeFilesUnderTheSameExclusiveCommandLease()
    {
        using var f = new Fixture(); f.CreatePrivateDirectory();
        Directory.CreateDirectory(Path.GetDirectoryName(f.State)!);
        var clear = LegacyInventory();
        byte[] original;
        using (var protector = new WindowsProfile.CurrentUserProtector()) original = protector.Protect(clear);
        CryptographicOperations.ZeroMemory(clear);
        await File.WriteAllBytesAsync(f.State, original);
        var sentinel = Path.Combine(Path.GetDirectoryName(f.State)!, "retained-native.dsv2");
        await File.WriteAllBytesAsync(sentinel, [4, 5, 6]);
        using (var held = new FileStream(Path.Combine(f.Root, "command.lock"), FileMode.OpenOrCreate,
            FileAccess.ReadWrite, FileShare.None))
        {
            using var denied = new StringWriter(); using var deniedError = new StringWriter();
            Assert.Equal(5, await Program.RunAsync(f.Args("storage", "enroll"), denied, deniedError));
            Assert.Equal(original, await File.ReadAllBytesAsync(f.State));
        }
        using var output = new StringWriter(); using var error = new StringWriter();
        Assert.Equal(0, await Program.RunAsync(f.Args("storage", "enroll"), output, error));
        using (var result = JsonDocument.Parse(output.ToString()))
        {
            Assert.Equal("enrolled", result.RootElement.GetProperty("status").GetString());
            Assert.True(result.RootElement.GetProperty("storageWork").GetProperty("unprotectCalls").GetInt64() > 0);
            Assert.DoesNotContain("retained-a", result.RootElement.GetRawText(), StringComparison.Ordinal);
        }
        Assert.Equal(new byte[] { 4, 5, 6 }, await File.ReadAllBytesAsync(sentinel));
        using var currentProtector = new WindowsProfile.CurrentUserProtector();
        using var current = new JournaledDeepSecureStorage(f.State, currentProtector);
        using var values = await current.ReadOwnedBatchAsync(["retained-b", "absent", "retained-a"]);
        Assert.Equal(new byte[] { 3, 4 }, values[0]!.Use(bytes => bytes.ToArray())); Assert.Null(values[1]);
        Assert.Equal(new byte[] { 1, 2 }, values[2]!.Use(bytes => bytes.ToArray()));
        CryptographicOperations.ZeroMemory(original);
    }

    [Fact]
    public async Task GenuineDisposableDid2StateSurvivesExplicitAggregateEnrollmentWithExactSlotsAndNativeBytes()
    {
        using var f = new Fixture();
        using var created = new StringWriter(); using var createError = new StringWriter();
        Assert.Equal(0, await Program.RunAsync([.. f.Args("account", "create"), "--name", "Disposable conversion fixture"], created, createError));
        using var creation = JsonDocument.Parse(created.ToString());
        var address = creation.RootElement.GetProperty("address").GetString();
        Assert.False(string.IsNullOrWhiteSpace(address));
        var slots = ManifestSlotNames(f.State);
        var values = new List<(byte[] Slot, byte[] Value)>();
        var native = NativeSnapshot(f.State);
        try
        {
            using (var storage = new JournaledDeepSecureStorage(f.State, new WindowsProfile.CurrentUserProtector()))
                foreach (var group in slots.Chunk(32))
                {
                    using var batch = await storage.ReadOwnedBatchAsync(group);
                    for (var index = 0; index < group.Length; index++)
                        values.Add((Encoding.UTF8.GetBytes(group[index]), batch[index]!.Use(bytes => bytes.ToArray())));
                }
            // This is an explicit test fixture encoding of ALL genuine account
            // state into DSS1, not historical old-binary or retained-profile E2E.
            var aggregate = LegacyInventory(values);
            byte[] protectedAggregate;
            using (var protector = new WindowsProfile.CurrentUserProtector()) protectedAggregate = protector.Protect(aggregate);
            CryptographicOperations.ZeroMemory(aggregate);
            f.RemoveSyntheticObjects();
            await File.WriteAllBytesAsync(f.State, protectedAggregate);
            CryptographicOperations.ZeroMemory(protectedAggregate);
            using (var ordinary = new JournaledDeepSecureStorage(f.State, new WindowsProfile.CurrentUserProtector()))
                await Assert.ThrowsAnyAsync<CryptographicException>(() => ordinary.ReadOwnedAsync(slots[0]));
            using var enrollment = new StringWriter(); using var enrollmentError = new StringWriter();
            Assert.Equal(0, await Program.RunAsync(f.Args("storage", "enroll"), enrollment, enrollmentError));
            AssertNativeSnapshot(f.State, native);
            Assert.True(slots.SequenceEqual(ManifestSlotNames(f.State), StringComparer.Ordinal), "Complete slot inventory changed.");
            using (var storage = new JournaledDeepSecureStorage(f.State, new WindowsProfile.CurrentUserProtector()))
                foreach (var group in values.Chunk(32))
                {
                    using var batch = await storage.ReadOwnedBatchAsync(group.Select(value => Encoding.UTF8.GetString(value.Slot)).ToArray());
                    for (var index = 0; index < group.Length; index++)
                        Assert.True(batch[index] is not null && batch[index]!.Use(bytes => bytes.SequenceEqual(group[index].Value)),
                            "A logical account slot changed during enrollment.");
                }
            using var reopened = new StringWriter(); using var reopenError = new StringWriter();
            Assert.Equal(0, await Program.RunAsync(f.Args("account", "address"), reopened, reopenError));
            using var current = JsonDocument.Parse(reopened.ToString());
            Assert.True(StringComparer.Ordinal.Equals(address, current.RootElement.GetProperty("address").GetString()),
                "The genuine DID2 address changed during conversion.");
            using var status = new StringWriter(); using var statusError = new StringWriter();
            Assert.Equal(0, await Program.RunAsync(f.Args("account", "status"), status, statusError));
            using var statusResult = JsonDocument.Parse(status.ToString());
            Assert.True(statusResult.RootElement.GetProperty("accountPresent").GetBoolean());
            AssertNativeSnapshot(f.State, native);
        }
        finally
        {
            foreach (var entry in values) { CryptographicOperations.ZeroMemory(entry.Slot); CryptographicOperations.ZeroMemory(entry.Value); }
            foreach (var bytes in native.Values) CryptographicOperations.ZeroMemory(bytes);
        }
    }

    private static string[] ManifestSlotNames(string path)
    {
        using var protector = new WindowsProfile.CurrentUserProtector();
        var file = File.ReadAllBytes(path); var clear = protector.Unprotect(file);
        try
        {
            Assert.True(clear.AsSpan(0, 4).SequenceEqual("DSS2"u8));
            var count = checked((int)BinaryPrimitives.ReadUInt32BigEndian(clear.AsSpan(80)));
            Assert.InRange(count, 1, 1024); Assert.Equal(0U, BinaryPrimitives.ReadUInt32BigEndian(clear.AsSpan(84)));
            var slots = new string[count]; var offset = 96;
            for (var index = 0; index < count; index++)
            {
                var length = BinaryPrimitives.ReadUInt16BigEndian(clear.AsSpan(offset)); offset += 2;
                slots[index] = Encoding.UTF8.GetString(clear, offset, length);
                offset = checked(offset + length + 112);
                Assert.True(offset <= clear.Length);
            }
            Assert.Equal(clear.Length, offset); return slots;
        }
        finally { CryptographicOperations.ZeroMemory(file); CryptographicOperations.ZeroMemory(clear); }
    }

    private static Dictionary<string, byte[]> NativeSnapshot(string path)
    {
        var directory = Path.GetDirectoryName(path)!;
        var prefix = Path.Combine(directory, "deep-store-v2-account.dsv2");
        var files = Directory.EnumerateFiles(directory, "*", SearchOption.AllDirectories)
            .Where(file => file.StartsWith(prefix, StringComparison.Ordinal)).ToArray();
        Assert.True(files.Contains(prefix, StringComparer.Ordinal), "Actual account SQLCipher file is absent.");
        return files.ToDictionary(file => file, File.ReadAllBytes, StringComparer.Ordinal);
    }

    private static void AssertNativeSnapshot(string path, Dictionary<string, byte[]> expected)
    {
        var actual = NativeSnapshot(path);
        try
        {
            Assert.True(expected.Count == actual.Count && expected.Keys.All(actual.ContainsKey), "Native file family changed.");
            foreach (var entry in expected)
                Assert.True(actual[entry.Key].AsSpan().SequenceEqual(entry.Value), "Native SQLCipher bytes changed.");
        }
        finally { foreach (var bytes in actual.Values) CryptographicOperations.ZeroMemory(bytes); }
    }

    private static byte[] LegacyInventory() => LegacyInventory(
        [("retained-a"u8.ToArray(), [1, 2]), ("retained-b"u8.ToArray(), [3, 4])]);

    private static byte[] LegacyInventory(IReadOnlyList<(byte[] Slot, byte[] Value)> entries)
    {
        using var stream = new MemoryStream(); stream.Write("DSS1"u8);
        Span<byte> number = stackalloc byte[4];
        BinaryPrimitives.WriteUInt16BigEndian(number, 1); BinaryPrimitives.WriteUInt16BigEndian(number[2..], checked((ushort)entries.Count)); stream.Write(number);
        foreach (var entry in entries)
        {
            var name = entry.Slot;
            BinaryPrimitives.WriteUInt16BigEndian(number, checked((ushort)name.Length)); stream.Write(number[..2]);
            BinaryPrimitives.WriteUInt32BigEndian(number, checked((uint)entry.Value.Length)); stream.Write(number);
            stream.Write(name); stream.Write(entry.Value);
        }
        return stream.ToArray();
    }

    private sealed class Fixture : IDisposable
    {
        private readonly string profile = "storage-" + Guid.NewGuid().ToString("N")[..20];
        private readonly string network = Convert.ToHexStringLower(RandomNumberGenerator.GetBytes(16));
        internal string Root => Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "XPointLabs", "DeepCli", network, profile);
        internal string State => Path.Combine(Root, "deep-store-v2", "secure-storage.dss");
        internal string[] Args(string area, string operation) => [area, operation, "--profile", profile, "--network", network];
        internal void CreatePrivateDirectory()
        {
            var security = new DirectorySecurity(); var user = WindowsIdentity.GetCurrent().User!;
            security.SetOwner(user); security.SetAccessRuleProtection(true, false);
            security.AddAccessRule(new FileSystemAccessRule(user, FileSystemRights.FullControl,
                InheritanceFlags.ContainerInherit | InheritanceFlags.ObjectInherit, PropagationFlags.None, AccessControlType.Allow));
            new DirectoryInfo(Root).Create(security);
        }
        internal void RemoveSyntheticObjects()
        {
            var path = Path.GetFullPath(State + ".objects");
            if (!path.StartsWith(Path.GetFullPath(Root) + Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase) ||
                new DirectoryInfo(path).Attributes.HasFlag(FileAttributes.ReparsePoint))
                throw new InvalidOperationException("Disposable object directory scope differs.");
            Directory.Delete(path, recursive: true);
        }
        public void Dispose()
        {
            var expected = Path.GetFullPath(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "XPointLabs", "DeepCli", network)) + Path.DirectorySeparatorChar;
            var root = Path.GetFullPath(Root);
            if (!root.StartsWith(expected, StringComparison.OrdinalIgnoreCase) || Path.GetFileName(root) != profile)
                throw new InvalidOperationException("Disposable profile scope differs.");
            if (Directory.Exists(root)) Directory.Delete(root, recursive: true);
        }
    }
}
