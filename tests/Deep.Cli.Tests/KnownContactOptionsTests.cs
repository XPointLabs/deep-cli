using System.Text.Json;
using Deep.Protocol.Identity;
using Deep.Protocol.ApplicationCore;

namespace Deep.Cli.Tests;

public sealed class KnownContactOptionsTests
{
    // Parsing metadata only, never a native credential/authentication fixture.
    private static string Address
    {
        get
        {
            var capability = Enumerable.Repeat((byte)2, 16).ToArray();
            return DeepPermanentIdV2.FromCredential(DeepIdV2Codec.AuthorDid2(
                Enumerable.Repeat((byte)1, 32).ToArray(), Enumerable.Repeat((byte)3, 1952).ToArray(), capability), capability).CanonicalText;
        }
    }
    private static string[] Args(string text, string verb = "maintain") => ["network", verb, "--profile", "unit-book", "--network", new string('1', 32),
        "--bootstrap", "public-bundle", "--registry", "https://localhost:28543/", "--known-contacts", text];

    [Fact]
    public void KnownDescriptorsAreMetadataAndNotEmittedByCommandDiagnostics()
    {
        var command = CommandLine.Parse(Args(JsonSerializer.Serialize(new[] { new { conversation = new string('a', 64), address = Address } })));
        var entry = Assert.Single(command.KnownContacts!);
        Assert.Equal(new string('A', 64), entry.Key); Assert.Equal(Address, entry.Value.CanonicalText);
        Assert.DoesNotContain(Address, command.ToString());
        Assert.Empty(CommandLine.Parse(Args("[]")).KnownContacts!);
    }

    [Theory]
    [InlineData(0)]
    [InlineData(1)]
    [InlineData(2)]
    [InlineData(3)]
    [InlineData(4)]
    [InlineData(5)]
    [InlineData(6)]
    [InlineData(7)]
    [InlineData(8)]
    public void MalformedAmbiguousOrOversizedBooksRejectBeforeOpeningAProfile(int fault)
    {
        var item = new { conversation = new string('a', 64), address = Address };
        var text = fault switch
        {
            0 => "invalid-json", 1 => "{}", 2 => "[{}]",
            3 => JsonSerializer.Serialize(new[] { new { item.conversation, item.address, unexpected = true } }),
            4 => JsonSerializer.Serialize(new[] { item, item }),
            5 => JsonSerializer.Serialize(new[] { item, new { conversation = item.conversation.ToUpperInvariant(), item.address } }),
            6 => JsonSerializer.Serialize(new[] { new { conversation = "invalid", item.address } }),
            7 => JsonSerializer.Serialize(Enumerable.Range(0, Deep.Client.Shared.Services.DeepIdV2AccountService.MaximumKnownContactAddresses + 1)
                .Select(index => new { conversation = index.ToString("x64"), address = Address })),
            _ => JsonSerializer.Serialize(new[] { new { item.conversation, address = "invalid" } })
        };
        Assert.Throws<ArgumentException>(() => CommandLine.Parse(Args(text)));
    }

    [Theory]
    [InlineData("publish")]
    [InlineData("refresh")]
    public void BootstrapAndAuthorityRefreshDoNotAcceptAddressBookSideEffects(string verb) =>
        Assert.Throws<ArgumentException>(() => CommandLine.Parse(Args("[]", verb)));
}
