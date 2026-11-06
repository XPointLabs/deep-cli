using System.Security.Cryptography;
using System.Text.Json;
using Deep.Client.Shared.Services;

namespace Deep.Cli.Tests;

public sealed class MaintenanceDiagnosticsTests
{
    [Fact]
    public async Task CompletedMaintenanceReportsBoundedPageProgressWithoutFailureOrPrivateData()
    {
        using var output = new StringWriter();
        await using (var diagnostics = new DeliveryDiagnostics(output))
        {
            diagnostics.ObserveMaintenance(1, "Started");
            diagnostics.ObserveMaintenance(1, "Completed", new DeepIdV2ContactMaintenanceResult(1, 1, 0, 3, 0, true));
        }
        var frames = output.ToString().Split('\n', StringSplitOptions.RemoveEmptyEntries);
        using var started = JsonDocument.Parse(frames[0]); using var completed = JsonDocument.Parse(frames[1]);
        Assert.Equal(11, started.RootElement.EnumerateObject().Count());
        Assert.Equal(11, completed.RootElement.EnumerateObject().Count());
        Assert.Equal(0, started.RootElement.GetProperty("processedEnvelopes").GetInt32());
        Assert.False(started.RootElement.GetProperty("hasMore").GetBoolean());
        Assert.Equal(3, completed.RootElement.GetProperty("processedEnvelopes").GetInt32());
        Assert.True(completed.RootElement.GetProperty("hasMore").GetBoolean());
        Assert.Equal(JsonValueKind.Null, completed.RootElement.GetProperty("failure").ValueKind);
    }

    [Fact]
    public async Task FailedMaintenanceReusesClosedTypedCauseAndGuardWithoutExceptionText()
    {
        const string secret = "DO-NOT-EXPORT-private-message-address-path";
        var inner = new CryptographicException(secret); inner.Data["Deep.MailboxGrant.Check"] = "RouteExpiry";
        var failure = new IOException(secret, inner);
        using var output = new StringWriter();
        await using (var diagnostics = new DeliveryDiagnostics(output))
        {
            diagnostics.ObserveMaintenance(1, "Started");
            diagnostics.ObserveMaintenance(1, "Failed", failure: failure);
        }
        Assert.DoesNotContain(secret, output.ToString());
        var frames = output.ToString().Split('\n', StringSplitOptions.RemoveEmptyEntries);
        using var json = JsonDocument.Parse(frames[1]); var root = json.RootElement;
        Assert.Equal(11, root.EnumerateObject().Count());
        Assert.Equal(0, root.GetProperty("processedEnvelopes").GetInt32());
        Assert.False(root.GetProperty("hasMore").GetBoolean());
        var diagnostic = root.GetProperty("failure"); Assert.Equal("ContactMaintenance", diagnostic.GetProperty("phase").GetString());
        var causes = diagnostic.GetProperty("causes"); Assert.Equal(2, causes.GetArrayLength());
        Assert.Equal("IoFailure", causes[0].GetProperty("category").GetString());
        Assert.Equal("ProtectedState", causes[1].GetProperty("category").GetString());
        Assert.Equal("GrantRouteExpiry", causes[1].GetProperty("check").GetString());
        Assert.Equal("Unavailable", causes[1].GetProperty("method").GetString());
    }
}
