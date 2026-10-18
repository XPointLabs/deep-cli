using System.Buffers.Binary;
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
        using var protector = new WindowsProfile.CurrentUserProtector();
        var clear = RandomNumberGenerator.GetBytes(32);
        var encrypted = protector.Protect(clear);
        Assert.Equal(clear, protector.Unprotect(encrypted));
        encrypted[^1] ^= 1;
        Assert.Throws<AuthenticationTagMismatchException>(() => protector.Unprotect(encrypted));
        Assert.Throws<ArgumentException>(() => protector.Protect([]));
    }

    [Fact]
    public void EveryDecryptionAuthenticatesNativelyAndReturnsDetachedCopies()
    {
        var clear = RandomNumberGenerator.GetBytes(32);
        byte[] encrypted;
        using (var writer = new WindowsProfile.CurrentUserProtector()) encrypted = writer.Protect(clear);
        var reader = new WindowsProfile.CurrentUserProtector();
        Assert.Equal(clear, reader.Unprotect(encrypted));
        Assert.Equal(1, reader.NativeUnprotects);
        var first = reader.Unprotect(encrypted); first[0] ^= 1;
        Assert.Equal(clear, reader.Unprotect(encrypted));
        Assert.Equal(3, reader.NativeUnprotects);
        var tampered = encrypted.ToArray(); tampered[^1] ^= 1;
        Assert.Throws<AuthenticationTagMismatchException>(() => reader.Unprotect(tampered));
        Assert.Equal(4, reader.NativeUnprotects);
        Assert.Equal(clear, reader.Unprotect(encrypted));
        reader.Dispose();
        Assert.Throws<ObjectDisposedException>(() => reader.Unprotect(encrypted));
    }

    [Fact]
    public void WrappedEnvelopeRejectsEveryTamperedRegionMalformedBoundsAndRetiredRawDpapi()
    {
        using var protector = new WindowsProfile.CurrentUserProtector();
        var clear = RandomNumberGenerator.GetBytes(801_334);
        var encrypted = protector.Protect(clear);
        Assert.Equal(clear, protector.Unprotect(encrypted));
        var markerBytes = "DeepCli/DPAPI-AESGCM/v1\0"u8.Length;
        var wrappedBytes = checked((int)BinaryPrimitives.ReadUInt32BigEndian(encrypted.AsSpan(markerBytes)));
        var prefix = markerBytes + 4 + wrappedBytes + 12;
        foreach (var position in new[] { 0, markerBytes, markerBytes + 4, prefix - 1, prefix, prefix + 16, encrypted.Length - 1 })
        {
            var changed = encrypted.ToArray(); changed[position] ^= 1;
            Assert.ThrowsAny<CryptographicException>(() => protector.Unprotect(changed));
        }
        Assert.Throws<CryptographicException>(() => protector.Unprotect(encrypted[..(prefix + 16)]));
        Assert.Throws<CryptographicException>(() => protector.Unprotect([]));
        var overflow = encrypted.ToArray(); BinaryPrimitives.WriteUInt32BigEndian(overflow.AsSpan(markerBytes), uint.MaxValue);
        Assert.Throws<CryptographicException>(() => protector.Unprotect(overflow));
        var raw = ProtectedData.Protect(clear, "Deep/Cli/Store/V2/Windows-DPAPI"u8.ToArray(), DataProtectionScope.CurrentUser);
        Assert.Throws<CryptographicException>(() => protector.Unprotect(raw));
        var independent = protector.Protect(clear);
        Assert.NotEqual(encrypted, independent);
        Assert.Equal(clear, protector.Unprotect(independent));
        var entropy = "Deep/Cli/Store/V2/Windows-DPAPI"u8.ToArray();
        var firstKey = ProtectedData.Unprotect(encrypted.AsSpan(markerBytes + 4, wrappedBytes).ToArray(), entropy, DataProtectionScope.CurrentUser);
        var nextLength = checked((int)BinaryPrimitives.ReadUInt32BigEndian(independent.AsSpan(markerBytes)));
        var nextKey = ProtectedData.Unprotect(independent.AsSpan(markerBytes + 4, nextLength).ToArray(), entropy, DataProtectionScope.CurrentUser);
        try { Assert.Equal(32, firstKey.Length); Assert.Equal(32, nextKey.Length); Assert.NotEqual(firstKey, nextKey); }
        finally { CryptographicOperations.ZeroMemory(firstKey); CryptographicOperations.ZeroMemory(nextKey); }
        var spliced = encrypted.ToArray(); independent.AsSpan(markerBytes + 4, wrappedBytes).CopyTo(spliced.AsSpan(markerBytes + 4));
        Assert.ThrowsAny<CryptographicException>(() => protector.Unprotect(spliced));
        CryptographicOperations.ZeroMemory(clear);
    }

    [Fact]
    public void LargeEnvelopeStillUnwrapsTheNativeKeyOnEveryReadWithoutCaching()
    {
        using var protector = new WindowsProfile.CurrentUserProtector();
        var clear = RandomNumberGenerator.GetBytes(801_334);
        try
        {
            var encrypted = protector.Protect(clear);
            for (var i = 0; i < 32; i++)
            {
                var opened = protector.Unprotect(encrypted);
                try { Assert.True(CryptographicOperations.FixedTimeEquals(clear, opened)); }
                finally { CryptographicOperations.ZeroMemory(opened); }
            }
            Assert.Equal(32, protector.NativeUnprotects);
        }
        finally { CryptographicOperations.ZeroMemory(clear); }
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
