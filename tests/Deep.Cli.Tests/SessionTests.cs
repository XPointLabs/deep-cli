using System.Security.Cryptography;
using System.Text.Json;

namespace Deep.Cli.Tests;

public sealed class SessionTests
{
    private static CommandLine Binding() => CommandLine.Parse(["session", "run", "--profile",
        "session-" + Guid.NewGuid().ToString("N")[..20], "--network",
        Convert.ToHexStringLower(RandomNumberGenerator.GetBytes(16)), "--bootstrap", "public-bundle",
        "--registry", "https://localhost:28543/"]);

    [Fact]
    public void SessionRejectsConfigurationSwitchesAndNestedHostsBeforeOpeningStorage()
    {
        var binding = Binding(); using var session = new CliSession(binding);
        var command = binding with { Area = "network", Operation = "verify" };
        session.RequireBinding(command);
        foreach (var changed in new[] { command with { Profile = "other" },
            command with { Network = RandomNumberGenerator.GetBytes(16) },
            command with { Bootstrap = "another-bundle" }, command with { Registry = "https://other/" }, binding })
            Assert.Throws<ArgumentException>(() => session.RequireBinding(changed));
        session.Dispose();
        Assert.Throws<ObjectDisposedException>(() => session.RequireBinding(command));
    }

    [Fact]
    public async Task FramesAreSerialBoundedAndNeverRetryFailedCommands()
    {
        var calls = 0;
        using var output = new StringWriter();
        var input = new StringReader("[\"account\",\"status\"]\nnot-json\n[null,null]\n[\"group\",\"list\"]\r\n");
        Assert.Equal(0, await CliSession.RunFramesAsync(input, output, args =>
        {
            Assert.Equal(++calls == 1 ? "account" : "group", args[0]);
            return Task.FromResult("{\"exitCode\":6}");
        }, default));
        Assert.Equal(2, calls);
        Assert.Equal(4, output.ToString().Split('\n', StringSplitOptions.RemoveEmptyEntries).Length);
        foreach (var frame in output.ToString().Split('\n', StringSplitOptions.RemoveEmptyEntries))
            using (JsonDocument.Parse(frame)) { }
    }

    [Theory]
    [InlineData(false)]
    [InlineData(true)]
    public async Task OversizedOrTruncatedFrameDoesNotExecute(bool oversize)
    {
        using var output = new StringWriter();
        var value = oversize ? new string(' ', CliSession.MaximumFrameCharacters + 1) + "\n" : "[\"group\",\"list\"]";
        var calls = 0;
        Assert.Equal(2, await CliSession.RunFramesAsync(new StringReader(value), output,
            _ => { calls++; return Task.FromResult("{}"); }, default));
        Assert.Equal(0, calls);
        Assert.Equal("", output.ToString());
    }

    [Fact]
    public async Task CancelledFrameNeverExecutes()
    {
        using var output = new StringWriter();
        await Assert.ThrowsAnyAsync<OperationCanceledException>(() => CliSession.RunFramesAsync(
            new StringReader("[\"group\",\"list\"]\n"), output, _ => throw new InvalidOperationException(),
            new CancellationToken(true)));
    }

    [Fact]
    public async Task SerialCommandsShareTheActualProfileLeaseAndReleaseItOnClose()
    {
        var binding = Binding();
        var args = new[] { "account", "status", "--profile", binding.Profile, "--network", Convert.ToHexStringLower(binding.Network) };
        using var output = new StringWriter(); using var error = new StringWriter();
        using (var session = new CliSession(binding))
        {
            var command = CommandLine.Parse(args);
            Assert.Same(session.GetProfile(command), session.GetProfile(command));
            Assert.Throws<IOException>(() => WindowsProfile.Open(command));
            Assert.Equal(0, await Program.RunAsync(args, output, error, default, session));
            Assert.Equal(0, await Program.RunAsync(args, output, error, default, session));
            Assert.Equal("", error.ToString());
        }
        using var reopened = WindowsProfile.Open(CommandLine.Parse(args));
    }

    [Fact]
    public async Task ActualSessionHostReturnsOneClosedResultPerFrameAndClosesAtEof()
    {
        var binding = Binding();
        string[] Args(string area, string operation) => [area, operation, "--profile", binding.Profile,
            "--network", Convert.ToHexStringLower(binding.Network)];
        var frames = JsonSerializer.Serialize(Args("account", "status")) + "\n" +
            JsonSerializer.Serialize(Args("group", "list")) + "\n";
        using var output = new StringWriter();
        Assert.Equal(0, await CliSession.RunAsync(binding, new StringReader(frames), output, default));
        var results = output.ToString().Split('\n', StringSplitOptions.RemoveEmptyEntries);
        Assert.Equal(2, results.Length);
        using var first = JsonDocument.Parse(results[0]); using var second = JsonDocument.Parse(results[1]);
        Assert.Equal(0, first.RootElement.GetProperty("exitCode").GetInt32());
        Assert.False(first.RootElement.GetProperty("result").GetProperty("accountPresent").GetBoolean());
        Assert.Equal(4, second.RootElement.GetProperty("exitCode").GetInt32());
        Assert.Equal("account-missing", second.RootElement.GetProperty("result").GetProperty("code").GetString());
        using var reopened = WindowsProfile.Open(CommandLine.Parse(Args("account", "status")));
    }
}
