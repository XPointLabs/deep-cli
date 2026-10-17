using System.Security.Cryptography;
using System.Text.Json;
using Deep.Protocol.Identity;

namespace Deep.Cli.Tests;

public sealed class AccountTests
{
    private static string Network => Convert.ToHexStringLower(RandomNumberGenerator.GetBytes(16));

    [Theory]
    [InlineData("../device")]
    [InlineData("a/b")]
    [InlineData("Alice")]
    [InlineData("")]
    [InlineData("a.")]
    public void RejectsUnsafeProfileAliases(string profile) => Assert.Throws<ArgumentException>(() =>
        CommandLine.Parse(["account", "status", "--profile", profile, "--network", Network]));

    [Theory]
    [InlineData("--name", "name")]
    [InlineData("--unknown", "value")]
    [InlineData("--profile", "other")]
    public void RejectsUnknownIrrelevantOrDuplicateOptions(string option, string value) =>
        Assert.Throws<ArgumentException>(() => CommandLine.Parse(
            ["account", "status", "--profile", "alice", "--network", Network, option, value]));

    [Fact]
    public void RequiresNonzeroExplicitNetworkAndCreationName()
    {
        Assert.Throws<ArgumentException>(() => CommandLine.Parse(["account", "status", "--profile", "alice"]));
        Assert.Throws<ArgumentException>(() => CommandLine.Parse(["account", "status", "--profile", "alice", "--network", new('0', 32)]));
        Assert.Throws<ArgumentException>(() => CommandLine.Parse(["account", "status", "--profile", "alice", "--network", new('1', 64)]));
        Assert.Throws<ArgumentException>(() => CommandLine.Parse(["account", "create", "--profile", "alice", "--network", Network]));
    }

    [Fact]
    public void NativeDpapiRoundtripRejectsTamperingAndEmptySecrets()
    {
        var protector = new WindowsProfile.CurrentUserProtector();
        var clear = RandomNumberGenerator.GetBytes(32);
        var encrypted = protector.Protect(clear);
        Assert.Equal(clear, protector.Unprotect(encrypted));
        encrypted[^1] ^= 1;
        Assert.Throws<CryptographicException>(() => protector.Unprotect(encrypted));
        Assert.Throws<ArgumentException>(() => protector.Protect([]));
    }

    [Fact]
    public async Task TwoRealAccountsSurviveReopenWithoutSharingIdentityOrOverwriting()
    {
        var network = Network;
        var profileA = "qa-" + Guid.NewGuid().ToString("N")[..24];
        var profileB = "qa-" + Guid.NewGuid().ToString("N")[..24];
        var a = await Invoke("create", profileA, "--name", "CLI QA A");
        var b = await Invoke("create", profileB, "--name", "CLI QA B");
        var addressA = a.GetProperty("address").GetString()!;
        var addressB = b.GetProperty("address").GetString()!;
        Assert.True(DeepPermanentIdV2.ParseCanonical(addressA).Equals(DeepPermanentIdV2.ParseCanonical(addressA)));
        Assert.False(StringComparer.Ordinal.Equals(addressA, addressB));
        var reopened = await Invoke("address", profileA);
        Assert.True(StringComparer.Ordinal.Equals(addressA, reopened.GetProperty("address").GetString()));
        var status = await Invoke("status", profileB);
        Assert.True(status.GetProperty("accountPresent").GetBoolean());
        Assert.Equal(JsonValueKind.Null, status.GetProperty("address").ValueKind);
        using var output = new StringWriter(); using var error = new StringWriter();
        var exit = await Program.RunAsync(["account", "create", "--profile", profileA, "--network", network,
            "--name", "must not overwrite"], output, error);
        Assert.NotEqual(0, exit); Assert.Equal(string.Empty, output.ToString());
        reopened = await Invoke("address", profileA);
        Assert.True(StringComparer.Ordinal.Equals(addressA, reopened.GetProperty("address").GetString()));
        // Keep these isolated encrypted QA profiles for retained/restart follow-up;
        // neither the test runner nor a failed assertion dumps their addresses/keys.
        async Task<JsonElement> Invoke(string operation, string profile, params string[] extra)
        {
            using var stdout = new StringWriter(); using var stderr = new StringWriter();
            var code = await Program.RunAsync(["account", operation, "--profile", profile, "--network", network, .. extra], stdout, stderr);
            Assert.True(code == 0, $"CLI operation {operation} failed with exit {code}; raw output retained only in memory.");
            using var json = JsonDocument.Parse(stdout.ToString());
            return json.RootElement.Clone();
        }
    }

    [Fact]
    public async Task CancellationAndInvalidArgumentsHaveClosedErrors()
    {
        using var stdout = new StringWriter(); using var stderr = new StringWriter();
        Assert.Equal(2, await Program.RunAsync(["unsafe-command"], stdout, stderr));
        Assert.DoesNotContain("Exception", stderr.ToString());
        stderr.GetStringBuilder().Clear();
        Assert.Equal(130, await Program.RunAsync(["account", "status", "--profile", "cancelled", "--network", Network],
            stdout, stderr, new CancellationToken(canceled: true)));
        Assert.Equal(string.Empty, stdout.ToString());
    }
}
