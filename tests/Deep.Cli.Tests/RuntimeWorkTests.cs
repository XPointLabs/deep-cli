using System.Text.Json;

namespace Deep.Cli.Tests;

public sealed class RuntimeWorkTests
{
    [Fact]
    public void CompilerDiagnosticsContainOnlyClosedNonnegativeResourceCounters()
    {
        var work = new RuntimeWork();
        using var json = JsonDocument.Parse(JsonSerializer.Serialize(work.Snapshot()));
        Assert.Equal(new[] { "available", "jitCompilationMilliseconds", "jitCompiledMethods", "jitCompiledIlBytes" },
            json.RootElement.EnumerateObject().Select(property => property.Name));
        foreach (var property in json.RootElement.EnumerateObject().Where(property => property.Name != "available"))
            Assert.True(property.Value.GetDouble() >= 0);
    }
}
