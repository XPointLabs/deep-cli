namespace Deep.Cli.Tests;

public sealed class RecentReceiveCommandTests
{
    private static readonly string[] Local = ["--profile", "alice", "--network", new('1', 32)];
    private static readonly string[] Online = [.. Local, "--bootstrap", "public-bundle", "--registry", "https://localhost:28543/"];
    private static readonly string Id = new('2', 64);

    [Theory]
    [InlineData("message", "--conversation")]
    [InlineData("group", "--group")]
    public void RecentReadsRequireAnExactSelectorAndClosedPageSize(string area, string selector)
    {
        Assert.Equal(1, CommandLine.Parse([area, "recent", .. Local, selector, Id, "--limit", "1"]).Limit);
        Assert.Equal(100, CommandLine.Parse([area, "recent", .. Local, selector, Id, "--limit", "100"]).Limit);
        foreach (var invalid in new[] { "0", "101", "-1", "01", "+1", "1.0", " 1", "2147483647" })
            Assert.Throws<ArgumentException>(() => CommandLine.Parse([area, "recent", .. Local, selector, Id, "--limit", invalid]));
        Assert.Throws<ArgumentException>(() => CommandLine.Parse([area, "recent", .. Local, "--limit", "1"]));
        Assert.Throws<ArgumentException>(() => CommandLine.Parse([area, "recent", .. Online, selector, Id, "--limit", "1"]));
        Assert.Throws<ArgumentException>(() => CommandLine.Parse([area, "recent", .. Local, selector, Id, "--limit", "1", "--proof", Id]));
    }

    [Fact]
    public void ReceiveUsesTheOwnedOnlineMailboxWithoutCallerPageOrAcknowledgementAuthority()
    {
        Assert.Equal("receive", CommandLine.Parse(["mailbox", "receive", .. Online]).Operation);
        Assert.Throws<ArgumentException>(() => CommandLine.Parse(["mailbox", "receive", .. Local]));
        foreach (var option in new[] { "--page", "--ack", "--operation", "--skip-verification", "--limit" })
            Assert.Throws<ArgumentException>(() => CommandLine.Parse(["mailbox", "receive", .. Online, option, Id]));
        Assert.Equal(TimeSpan.FromMinutes(5), Program.TimeoutFor(["mailbox", "receive"]));
    }
}
