namespace Deep.Cli.Tests;

public sealed class AttachmentCommandTests
{
    [Fact]
    public void MultiChunkTransfersHaveABoundedCompositeBudgetWithoutExtendingOtherCommands()
    {
        Assert.Equal(TimeSpan.FromHours(3), Program.TimeoutFor(["attachment", "send"]));
        Assert.Equal(TimeSpan.FromHours(3), Program.TimeoutFor(["attachment", "download"]));
        Assert.Equal(TimeSpan.FromMinutes(5), Program.TimeoutFor(["attachment", "queue"]));
        Assert.Equal(TimeSpan.FromMinutes(5), Program.TimeoutFor(["message", "send"]));
    }

    private static readonly string[] Local = ["--profile", "alice", "--network", new('1', 32)];
    private static readonly string[] Online = [.. Local, "--bootstrap", "public-bundle", "--registry", "https://localhost:28543/"];
    private static readonly string Id = new('2', 64);

    [Fact]
    public void AttachmentCommandsAreClosedAndRequireOwnedSelectors()
    {
        Assert.Equal("list", CommandLine.Parse(["attachment", "list", .. Local, "--conversation", Id]).Operation);
        Assert.Throws<ArgumentException>(() => CommandLine.Parse(["attachment", "list", .. Online, "--conversation", Id]));
        Assert.Equal(Id, CommandLine.Parse(["attachment", "send", .. Online, "--conversation", Id, "--asset", Id, "--operation", Id]).Asset);
        Assert.Null(CommandLine.Parse(["attachment", "queue", .. Online, "--conversation", Id, "--asset", Id]).OperationId);
        Assert.Throws<ArgumentException>(() => CommandLine.Parse(["attachment", "queue", .. Online, "--conversation", Id, "--asset", Id, "--operation", Id]));
        Assert.Null(CommandLine.Parse(["attachment", "pending", .. Local]).Registry);
        Assert.Null(CommandLine.Parse(["attachment", "operations", .. Local]).Registry);
        Assert.Throws<ArgumentException>(() => CommandLine.Parse(["attachment", "send", .. Online, "--conversation", Id, "--operation", Id]));
        Assert.Throws<ArgumentException>(() => CommandLine.Parse(["attachment", "download", .. Online, "--conversation", Id, "--logical", Id, "--device", Id, "--output", "relative.bin"]));
        Assert.Throws<ArgumentException>(() => CommandLine.Parse(["attachment", "prepare", .. Online, "--file", "relative.bin", "--media", "application/octet-stream", "--operation", Id]));
        Assert.Throws<ArgumentException>(() => CommandLine.Parse(["attachment", "send", .. Online, "--conversation", Id, "--asset", new('0',64), "--operation", Id]));
        Assert.Throws<ArgumentException>(() => CommandLine.Parse(["attachment", "download", .. Online, "--conversation", Id, "--logical", Id, "--device", Id, "--output", Path.GetFullPath("qa.bin"), "--key", Id]));
    }
}
