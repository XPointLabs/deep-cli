using Deep.Cli.Engineering;

namespace Deep.Cli.Tests;

public sealed class SecureStorageBenchmarkScopeTests
{
    [Fact]
    public async Task AggregateLabelCannotBenchmarkTheNewEngineOrCreateAnyFixture()
    {
        var root = Path.Combine(Path.GetTempPath(), "deep-storage-scope-" + Guid.NewGuid().ToString("N"));
        await Assert.ThrowsAsync<InvalidOperationException>(() => SecureStorageProviderBenchmark.RunAsync("aggregate", "unused", root));
        Assert.False(Directory.Exists(root));
    }
}
