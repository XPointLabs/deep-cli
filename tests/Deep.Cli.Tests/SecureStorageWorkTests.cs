using System.Text.Json;
using Deep.Client.Shared.Persistence;

namespace Deep.Cli.Tests;

public sealed class SecureStorageWorkTests
{
    [Fact]
    public void StorageWorkExportsOnlyThirteenNumericCommandDeltas()
    {
        var before = new DeepSecureStorageWorkSnapshot(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13);
        var after = new DeepSecureStorageWorkSnapshot(2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26);
        using var json = JsonDocument.Parse(JsonSerializer.Serialize(SecureStorageWork.Delta(after, before)));
        var fields = json.RootElement.EnumerateObject().ToArray();
        Assert.Equal(13, fields.Length);
        Assert.Equal(Enumerable.Range(1, 13).Select(value => (long)value), fields.Select(field => field.Value.GetInt64()));
    }
}
