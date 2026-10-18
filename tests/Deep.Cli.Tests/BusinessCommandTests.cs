using System.Text.Json;

namespace Deep.Cli.Tests;

public sealed class BusinessCommandTests
{
    [Fact]
    public void CompositeHostBudgetCoversPreparationWithoutChangingProtocolDeadlines() =>
        Assert.Equal(TimeSpan.FromMinutes(5), Program.CommandTimeout);
    private const string Network = "11111111111111111111111111111111";
    private const string Conversation = "2222222222222222222222222222222222222222222222222222222222222222";
    private const string Operation = "3333333333333333333333333333333333333333333333333333333333333333";

    [Theory]
    [InlineData("network", "verify")]
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
