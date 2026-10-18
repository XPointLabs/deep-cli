namespace Deep.Cli.Tests;

public sealed class GroupCommandTests
{
    private static readonly string[] Local = ["--profile", "alice", "--network", new('1', 32)];
    private static readonly string[] Online = [.. Local, "--bootstrap", "public-bundle", "--registry", "https://localhost:28543/"];
    private static readonly string Id = new('2', 64);

    [Fact]
    public void CompositeGroupBatchHasABoundedHostBudgetWithoutExtendingSingleHopAuthority()
    {
        foreach (var action in new[] { "invite", "accept", "advance", "send", "flush" })
            Assert.Equal(TimeSpan.FromMinutes(30), Program.TimeoutFor(["group", action]));
        Assert.Equal(TimeSpan.FromMinutes(5), Program.TimeoutFor(["group", "create"]));
        Assert.Equal(TimeSpan.FromMinutes(5), Program.TimeoutFor(["mailbox", "sync"]));
    }

    [Fact]
    public void ClosedCommandsRequireExactGroupAndConversationButNeverRawRecordsOrKeys()
    {
        Assert.Equal("list", CommandLine.Parse(["group", "list", .. Local]).Operation);
        Assert.Equal(Id, CommandLine.Parse(["group", "messages", .. Local, "--group", Id]).Group);
        Assert.Equal("Group QA", CommandLine.Parse(["group", "create", .. Online, "--name", "Group QA"]).Name);
        foreach (var action in new[] { "invite", "accept", "advance", "flush" })
        {
            Assert.Equal(Id, CommandLine.Parse(["group", action, .. Online, "--group", Id, "--conversation", Id]).Group);
            Assert.Throws<ArgumentException>(() => CommandLine.Parse(["group", action, .. Online, "--group", Id]));
            Assert.Throws<ArgumentException>(() => CommandLine.Parse(["group", action, .. Online, "--group", Id, "--conversation", Id, "--record", Id]));
        }
        Assert.Equal("hello", CommandLine.Parse(["group", "send", .. Online, "--group", Id, "--conversation", Id, "--text", "hello"]).Text);
        Assert.Throws<ArgumentException>(() => CommandLine.Parse(["group", "send", .. Online, "--group", new('0',64), "--conversation", Id, "--text", "hello"]));
        Assert.Throws<ArgumentException>(() => CommandLine.Parse(["group", "messages", .. Online, "--group", Id]));
        Assert.Throws<ArgumentException>(() => CommandLine.Parse(["group", "import", .. Local]));
    }
}
