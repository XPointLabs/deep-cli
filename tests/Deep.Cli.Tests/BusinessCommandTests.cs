using System.Text.Json;

namespace Deep.Cli.Tests;

public sealed class BusinessCommandTests
{
    [Theory]
    [InlineData(429, "DirectoryRateLimited")]
    [InlineData(503, "DirectoryUnavailable")]
    public void DirectoryDiagnosticsDistinguishOnlyClosedHttpStates(int status, string expected)
    {
        var error = new Deep.Client.Shared.Services.AccountDirectoryV2.DeepIdV2DirectoryProofUnavailableException(
            (System.Net.HttpStatusCode)status, TimeSpan.FromSeconds(1));
        using var json = JsonDocument.Parse(JsonSerializer.Serialize(new CliBusinessException("MailboxSync", error).ClosedDiagnostic()));
        Assert.Equal(expected, json.RootElement.GetProperty("causes")[0].GetProperty("category").GetString());
        Assert.DoesNotContain("RetryAfter", json.RootElement.GetRawText());
    }
    [Theory]
    [InlineData("RouteExpiry", "GrantRouteExpiry")]
    [InlineData("Issuer", "GrantIssuer")]
    [InlineData("DO-NOT-EXPORT", "Unclassified")]
    public void GrantDiagnosticsExportOnlyClosedReasons(string input, string expected)
    {
        var error = new System.Security.Cryptography.CryptographicException("DO-NOT-EXPORT");
        error.Data["Deep.MailboxGrant.Check"] = input;
        using var json = JsonDocument.Parse(JsonSerializer.Serialize(new CliBusinessException("GroupWork", error).ClosedDiagnostic()));
        Assert.Equal(expected, json.RootElement.GetProperty("causes")[0].GetProperty("check").GetString());
        Assert.DoesNotContain("DO-NOT-EXPORT", json.RootElement.GetRawText());
    }
    [Fact]
    public void CompositeHostBudgetCoversPreparationWithoutChangingProtocolDeadlines() =>
        Assert.Equal(TimeSpan.FromMinutes(5), Program.CommandTimeout);

    [Theory]
    [InlineData("maintain")]
    [InlineData("verify")]
    [InlineData("publish")]
    public void ConnectionMaintenanceUsesTheBoundedCompositeBudgetWithoutChangingAnyHop(string verb) =>
        Assert.Equal(Program.GroupBatchTimeout, Program.TimeoutFor(["network", verb]));
    private const string Network = "11111111111111111111111111111111";
    private const string Conversation = "2222222222222222222222222222222222222222222222222222222222222222";
    private const string Operation = "3333333333333333333333333333333333333333333333333333333333333333";

    [Fact]
    public void RouteReintroductionRequiresAddressAndExistingConversationButNoRawRouteOrOperation()
    {
        string[] common = ["contact", "reintroduce-route", "--profile", "alice", "--network", Network,
            "--bootstrap", "public-bundle", "--registry", "https://localhost:28543/", "--conversation", Conversation];
        Assert.Throws<ArgumentException>(() => CommandLine.Parse(common));
        var parsed = CommandLine.Parse([.. common, "--address", "untrusted-address-for-owned-verification"]);
        Assert.Equal("reintroduce-route", parsed.Operation); Assert.Null(parsed.OperationId);
        Assert.Throws<ArgumentException>(() => CommandLine.Parse([.. common, "--address", "candidate", "--operation", Operation]));
        Assert.Throws<ArgumentException>(() => CommandLine.Parse([.. common, "--address", "candidate", "--route", "raw"]));
    }

    [Theory]
    [InlineData("route-health")]
    [InlineData("refresh-route")]
    public void RouteCommandsRequireExistingConversationAndHaveNoCallerAuthoredInputs(string verb)
    {
        string[] common = ["--profile", "alice", "--network", Network, "--bootstrap", "public-bundle",
            "--registry", "https://localhost:28543/"];
        Assert.Throws<ArgumentException>(() => CommandLine.Parse(["contact", verb, .. common]));
        var parsed = CommandLine.Parse(["contact", verb, .. common, "--conversation", Conversation]);
        Assert.Equal(verb, parsed.Operation);
        Assert.Throws<ArgumentException>(() => CommandLine.Parse(["contact", verb, .. common,
            "--conversation", Conversation, "--operation", Operation]));
        var health = new Deep.Client.Shared.Services.DeepIdV2ContactRouteHealth(false, false, true);
        using var json = JsonDocument.Parse(JsonSerializer.Serialize(health));
        Assert.Equal(3, json.RootElement.EnumerateObject().Count());
        Assert.All(json.RootElement.EnumerateObject(), property => Assert.True(property.Value.ValueKind is JsonValueKind.False or JsonValueKind.True));
    }

    [Theory]
    [InlineData("network", "verify")]
    [InlineData("network", "maintain")]
    [InlineData("network", "publish")]
    [InlineData("mailbox", "sync")]
    public void NetworkCommandsRequireExplicitBootstrapAndHttpsOrigin(string area, string verb)
    {
        Assert.Throws<ArgumentException>(() => CommandLine.Parse([area, verb, "--profile", "alice", "--network", Network]));
        var command = CommandLine.Parse([area, verb, "--profile", "alice", "--network", Network,
            "--bootstrap", "public-bundle", "--registry", "https://localhost:28543/"]);
        Assert.Equal(area, command.Area); Assert.Equal(verb, command.Operation);
    }

    [Theory]
    [InlineData("contact", "list")]
    [InlineData("contact", "operations")]
    [InlineData("message", "pending")]
    public void LocalQueriesHaveNoTransportOptions(string area, string verb)
    {
        var command = CommandLine.Parse([area, verb, "--profile", "alice", "--network", Network]);
        Assert.Null(command.Bootstrap); Assert.Null(command.Registry);
        Assert.Throws<ArgumentException>(() => CommandLine.Parse([area, verb, "--profile", "alice", "--network", Network,
            "--registry", "https://localhost:28543/"]));
    }

    [Fact]
    public void TextQueueAndExactSendAreSeparateCommands()
    {
        string[] common = ["--profile", "alice", "--network", Network, "--bootstrap", "public-bundle",
            "--registry", "https://localhost:28543/", "--conversation", Conversation, "--text", "QA test text"];
        var queued = CommandLine.Parse(["message", "queue", .. common]);
        Assert.Null(queued.OperationId);
        Assert.Throws<ArgumentException>(() => CommandLine.Parse(["message", "queue", .. common, "--operation", Operation]));
        Assert.Throws<ArgumentException>(() => CommandLine.Parse(["message", "send", .. common]));
        Assert.Equal(Operation, CommandLine.Parse(["message", "send", .. common, "--operation", Operation]).OperationId);
    }

    [Theory]
    [InlineData("")]
    [InlineData("00000000000000000000000000000000")]
    [InlineData("0000000000000000000000000000000000000000000000000000000000000000")]
    [InlineData("33333333333333333333333333333333")]
    [InlineData("ABCDEF00000000000000000000000000")]
    [InlineData("../other")]
    public void RequestRejectsMissingNoncanonicalOrZeroOperation(string operation) => Assert.Throws<ArgumentException>(() =>
        CommandLine.Parse(["contact", "request", "--profile", "alice", "--network", Network,
            "--bootstrap", "public-bundle", "--registry", "https://localhost:28543/", "--address", "unparsed", "--operation", operation]));

    [Fact]
    public void ClosedDiagnosticsNeverExportExceptionTextAndBoundTheChain()
    {
        Exception cause = new IOException("DO-NOT-EXPORT-PATH-OR-PAYLOAD");
        for (var i = 0; i < 12; i++) cause = new InvalidOperationException("DO-NOT-EXPORT-PATH-OR-PAYLOAD", cause);
        var json = JsonSerializer.Serialize(new CliBusinessException("ContactRequest", cause).ClosedDiagnostic());
        Assert.DoesNotContain("DO-NOT-EXPORT", json);
        using var parsed = JsonDocument.Parse(json);
        Assert.Equal("ContactRequest", parsed.RootElement.GetProperty("phase").GetString());
        Assert.Equal(8, parsed.RootElement.GetProperty("causes").GetArrayLength());
    }

    [Theory]
    [InlineData("GrantStart", "RetainedReadGrantStart")]
    [InlineData("IssuedAfterCurrentUpper", "RetainedReadIssuedAfterCurrentUpper")]
    [InlineData("DO-NOT-EXPORT", "Unclassified")]
    public void RetainedReadDiagnosticsExposeOnlyClosedReasons(string input, string expected)
    {
        var error = new System.Security.Cryptography.CryptographicException("DO-NOT-EXPORT");
        error.Data["Deep.MailboxRetainedRead.Check"] = input;
        using var json = JsonDocument.Parse(JsonSerializer.Serialize(new CliBusinessException("MailboxSync", error).ClosedDiagnostic()));
        Assert.Equal(expected, json.RootElement.GetProperty("causes")[0].GetProperty("check").GetString());
        Assert.DoesNotContain("DO-NOT-EXPORT", json.RootElement.GetRawText());
    }

    [Theory]
    [InlineData("Held pre-key authoring no longer binds protected network custody.", "EndpointPairNetworkChanged")]
    [InlineData("Refreshed messaging endpoints no longer bind owned network custody.", "EndpointPairNetworkChanged")]
    [InlineData("Held authoring directory freshness expired.", "EndpointPairDirectoryExpired")]
    [InlineData("DO-NOT-EXPORT", "Unclassified")]
    public void EndpointPairDiagnosticsAreClosedAndGrantNoAuthority(string message, string expected)
    {
        var error = new System.Security.Cryptography.CryptographicException(message);
        using var json = JsonDocument.Parse(JsonSerializer.Serialize(new CliBusinessException("MailboxSync", error).ClosedDiagnostic()));
        Assert.Equal(expected, json.RootElement.GetProperty("causes")[0].GetProperty("check").GetString());
        Assert.Equal("ProtectedState", json.RootElement.GetProperty("causes")[0].GetProperty("category").GetString());
        Assert.DoesNotContain("DO-NOT-EXPORT", json.RootElement.GetRawText());
    }

    [Fact]
    public void CancellationKeepsBusinessPhaseWithoutInventingForwardingCertainty()
    {
        var json = JsonSerializer.Serialize(new CliBusinessException("MailboxSync",
            new OperationCanceledException("DO-NOT-EXPORT")).ClosedDiagnostic());
        using var parsed = JsonDocument.Parse(json);
        Assert.Equal("MailboxSync", parsed.RootElement.GetProperty("phase").GetString());
        Assert.Equal("Cancelled", parsed.RootElement.GetProperty("causes")[0].GetProperty("category").GetString());
        Assert.DoesNotContain("DO-NOT-EXPORT", json);
        Assert.DoesNotContain("BeforeForward", json);
    }

    [Theory]
    [InlineData(true, "IngressRetryableBeforeForward")]
    [InlineData(false, "IngressRejectedBeforeForward")]
    public void BeforeForwardClassificationUsesTheTypedTransportOutcome(bool retryable, string category)
    {
        var type = typeof(Deep.Client.Shared.Services.DeepIdV2AccountService).Assembly.GetType(
            "Deep.Client.Shared.Services.PrivacyIngressRejectedBeforeForwardException", throwOnError: true)!;
        Assert.True(type.IsSealed);
        var error = (Exception)Activator.CreateInstance(type, System.Reflection.BindingFlags.Instance |
            System.Reflection.BindingFlags.NonPublic, binder: null, args: [retryable, "DO-NOT-EXPORT", null], culture: null)!;
        using var json = JsonDocument.Parse(JsonSerializer.Serialize(new CliBusinessException("ContactRequest", error).ClosedDiagnostic()));
        Assert.Equal(category, json.RootElement.GetProperty("causes")[0].GetProperty("category").GetString());
        Assert.DoesNotContain("DO-NOT-EXPORT", json.RootElement.GetRawText());
    }

    [Theory]
    [InlineData("MalformedFrame")]
    [InlineData("WrongOrigin")]
    [InlineData("Saturated")]
    [InlineData("Unavailable")]
    public void BeforeForwardControlClassIsClosedAndDoesNotExportArbitraryText(string errorClass)
    {
        var type = typeof(Deep.Client.Shared.Services.DeepIdV2AccountService).Assembly.GetType(
            "Deep.Client.Shared.Services.PrivacyIngressRejectedBeforeForwardException", throwOnError: true)!;
        var error = (Exception)Activator.CreateInstance(type, System.Reflection.BindingFlags.Instance |
            System.Reflection.BindingFlags.NonPublic, binder: null,
            args: [true, $"Privacy ingress rejected the request before forwarding ({errorClass}).", null], culture: null)!;
        using var json = JsonDocument.Parse(JsonSerializer.Serialize(new CliBusinessException("ContactRequest", error).ClosedDiagnostic()));
        Assert.Equal("Ingress" + errorClass, json.RootElement.GetProperty("causes")[0].GetProperty("check").GetString());
    }
}
