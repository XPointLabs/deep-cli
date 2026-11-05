using System.Text.Json;
using System.Reflection;
using Deep.Client.Shared.Persistence;

namespace Deep.Cli.Tests;

public sealed class PersistenceWorkTests
{
    [Fact]
    public async Task ActualNativeCounterSourceSumsCostsAndReportsMaximumInventoryWithoutSemanticFrames()
    {
        using var work = new PersistenceWork();
        var type = typeof(Deep.Client.Shared.Services.DeepIdV2AccountService).Assembly
            .GetType("Deep.Client.Shared.Persistence.ClientPersistenceTiming", throwOnError: true)!;
        var lazy = type.GetField("Log", BindingFlags.Static | BindingFlags.NonPublic)!.GetValue(null)!;
        var source = lazy.GetType().GetProperty("Value")!.GetValue(lazy);
        var emit = type.GetMethod("NativeCounts")!;
        using var output = new StringWriter();
        await using (var semantic = new DeliveryDiagnostics(output))
        {
            using var command = semantic.AcceptCommand();
            emit.Invoke(source, [2L, 2L, 4L, 5L, 6L, 1L, 0L, 8L, 12L]);
            emit.Invoke(source, [1L, 1L, 1L, 2L, 3L, 0L, 1L, 7L, 20L]);
        }
        Assert.Equal(2, output.ToString().Split('\n', StringSplitOptions.RemoveEmptyEntries).Length);
        Assert.DoesNotContain("NativeCounts", output.ToString());
        using var json = JsonDocument.Parse(JsonSerializer.Serialize(work.NativeSnapshot()));
        var counters = json.RootElement;
        Assert.Equal(2, counters.GetProperty("operations").GetInt64());
        Assert.Equal(3, counters.GetProperty("opens").GetInt64());
        Assert.Equal(9, counters.GetProperty("payloads").GetInt64());
        Assert.Equal(8, counters.GetProperty("maximumWorkingCount").GetInt64());
        Assert.Equal(20, counters.GetProperty("maximumArchiveCount").GetInt64());
        Assert.False(counters.GetProperty("rejected").GetBoolean());
        Assert.Equal(11, counters.EnumerateObject().Count());
        Assert.Equal("[]", JsonSerializer.Serialize(work.Snapshot()));
    }

    [Theory]
    [InlineData("missing")]
    [InlineData("int32")]
    [InlineData("negative")]
    [InlineData("overflow")]
    public void HostileNativeCountersRejectWithoutPartialAggregation(string defect)
    {
        using var work = new PersistenceWork();
        object?[] payload = [1L, 1L, 1L, 1L, 1L, 1L, 1L, 1L, 1L];
        if (defect == "missing") payload = payload[..8];
        else if (defect == "int32") payload[2] = 1;
        else if (defect == "negative") payload[2] = -1L;
        else { work.ObserveNativeCounts([long.MaxValue, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L]); }
        work.ObserveNativeCounts(payload);
        using var json = JsonDocument.Parse(JsonSerializer.Serialize(work.NativeSnapshot()));
        Assert.True(json.RootElement.GetProperty("rejected").GetBoolean());
        Assert.Equal(defect == "overflow" ? 1 : 0, json.RootElement.GetProperty("operations").GetInt64());
        Assert.Equal(0, json.RootElement.GetProperty("payloads").GetInt64());
    }
    [Fact]
    public async Task ActualStorageReadEmitsOnlyClosedNumericWork()
    {
        var root = Path.Combine(Path.GetTempPath(), "cli-private-timing-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(root);
        try
        {
            using var protector = new WindowsProfile.CurrentUserProtector();
            using var storage = await JournaledDeepSecureStorage.CreateNewAsync(Path.Combine(root, "PRIVATE.dss"), protector);
            var before = storage.ReadWorkSnapshot();
            using var work = new PersistenceWork();
            using var absent = await storage.ReadOwnedAsync("deep.store.v2.current-account");
            Assert.Null(absent);
            // DSS2 returns closed scalar work after the owner read; standalone
            // storage does not dispatch persistence EventSource callbacks.
            Assert.Equal("[]", JsonSerializer.Serialize(work.Snapshot()));
            var json = JsonSerializer.Serialize(SecureStorageWork.Delta(storage.ReadWorkSnapshot(), before));
            Assert.DoesNotContain(root, json);
            Assert.DoesNotContain("PRIVATE", json);
            Assert.DoesNotContain("deep.store.v2", json);
            using var parsed = JsonDocument.Parse(json);
            Assert.Equal(13, parsed.RootElement.EnumerateObject().Count());
            Assert.Equal(2, parsed.RootElement.GetProperty("manifestReads").GetInt64());
            Assert.True(parsed.RootElement.GetProperty("manifestProtectedBytesRead").GetInt64() > 0);
            Assert.True(parsed.RootElement.GetProperty("manifestPlaintextBytesDecoded").GetInt64() > 0);
            Assert.Equal(1, parsed.RootElement.GetProperty("unprotectCalls").GetInt64());
            Assert.Equal(0, parsed.RootElement.GetProperty("objectReads").GetInt64());
            Assert.Equal(0, parsed.RootElement.GetProperty("manifestWrites").GetInt64());
            Assert.All(parsed.RootElement.EnumerateObject(), property => Assert.True(property.Value.GetInt64() >= 0));
        }
        finally { Directory.Delete(root, recursive: true); }
    }

}
