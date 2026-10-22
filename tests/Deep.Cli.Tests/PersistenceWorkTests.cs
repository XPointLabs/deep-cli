using System.Text.Json;
using Deep.Client.Shared.Persistence;

namespace Deep.Cli.Tests;

public sealed class PersistenceWorkTests
{
    [Fact]
    public async Task ActualStorageReadEmitsOnlyClosedNumericWork()
    {
        var root = Path.Combine(Path.GetTempPath(), "cli-private-timing-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(root);
        try
        {
            using var work = new PersistenceWork();
            using var storage = new JournaledDeepSecureStorage(Path.Combine(root, "PRIVATE.dss"), new RejectProtector());
            using var absent = await storage.ReadOwnedAsync("deep.store.v2.current-account");
            Assert.Null(absent);
            var json = JsonSerializer.Serialize(work.Snapshot());
            Assert.DoesNotContain(root, json);
            Assert.DoesNotContain("PRIVATE", json);
            Assert.DoesNotContain("deep.store.v2", json);
            using var parsed = JsonDocument.Parse(json);
            var row = Assert.Single(parsed.RootElement.EnumerateArray());
            Assert.Equal("StorageLoad", row.GetProperty("phase").GetString());
            Assert.Equal(1, row.GetProperty("count").GetInt64());
            Assert.True(row.GetProperty("totalMilliseconds").GetInt64() >= 0);
            Assert.Equal(4, row.EnumerateObject().Count());
        }
        finally { Directory.Delete(root, recursive: true); }
    }

    private sealed class RejectProtector : IDeepSecretProtector
    {
        public byte[] Protect(ReadOnlySpan<byte> plaintext) => throw new InvalidOperationException("No encryption for absent state.");
        public byte[] Unprotect(ReadOnlySpan<byte> protectedBytes) => throw new InvalidOperationException("No decryption for absent state.");
    }
}
