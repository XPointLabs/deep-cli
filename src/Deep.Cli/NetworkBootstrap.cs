using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using Deep.Client.Shared.Services;
using Deep.Protocol.XPointNetworkV1;

namespace Deep.Cli;

// Initial CLI host accepts the existing public local-development bundle only.
// No private operator, signer, node or account files are needed or accepted.
internal static class NetworkBootstrap
{
    internal static async Task<DeepIdV2ClientNetworkSession> OpenAsync(CommandLine command,
        DeepIdV2AccountService accounts, CancellationToken ct)
    {
        var root = Path.GetFullPath(command.Bootstrap!);
        using var manifest = JsonDocument.Parse(Read(root, "deep-dev.json", 16384));
        var m = manifest.RootElement;
        if (m.GetProperty("schema").GetString() != "deep-dev.v1" ||
            m.GetProperty("projectName").GetString() != "deep-dev-current" ||
            m.GetProperty("nodeCount").GetInt32() != 3 || m.GetProperty("deviceEvidence").GetBoolean() ||
            !Convert.FromHexString(m.GetProperty("networkIdHex").GetString()!).AsSpan().SequenceEqual(command.Network))
            throw new CryptographicException("Development bootstrap network binding rejected.");
        var pin = new XPointNetworkGenesisPin(command.Network,
            Convert.FromHexString(m.GetProperty("genesisAuthorityCoreHashHex").GetString()!));
        var headPin = Convert.FromHexString(m.GetProperty("genesisHeadCoreHashHex").GetString()!);
        if (!Uri.TryCreate(command.Registry, UriKind.Absolute, out var origin) ||
            origin.Scheme != "https" || origin.AbsoluteUri != command.Registry || origin.AbsolutePath != "/" ||
            origin.Query.Length != 0 || origin.Fragment.Length != 0 || origin.UserInfo.Length != 0)
            throw new ArgumentException("Canonical HTTPS Registry origin required.");
        var caBytes = Read(root, "dev-ca.crt", 16384);
        var caText = new UTF8Encoding(false, true).GetString(caBytes);
        if (!Regex.IsMatch(caText, "\\A\\s*-----BEGIN CERTIFICATE-----\\s*([A-Za-z0-9+/=\\r\\n]+)\\s*-----END CERTIFICATE-----\\s*\\z"))
            throw new CryptographicException("Exactly one public CA certificate required.");
        using var ca = X509Certificate2.CreateFromPem(caText);
        if (ca.HasPrivateKey) throw new CryptographicException("Private certificate material is not a bootstrap input.");
        var factory = new HttpServiceTransportFactory(HttpServiceEndpointPolicy.Production)
            .WithAppScopedPrivateCertificateAuthority(ca.RawData);
        return await DeepIdV2ClientNetworkSession.OpenAsync(accounts, factory, command.Registry!, pin,
            Read(root, "genesis.xna1", 65535), Read(root, "genesis.dts1", 65535),
            Read(root, "genesis.adh1", 4096), headPin, ct);
    }

    private static byte[] Read(string root, string name, int maximum)
    {
        var full = Path.Combine(root, name);
        for (var cursor = full; !string.IsNullOrEmpty(cursor); cursor = Path.GetDirectoryName(cursor))
            if (Path.Exists(cursor) && (File.GetAttributes(cursor) & FileAttributes.ReparsePoint) != 0)
                throw new IOException("Bootstrap reparse point rejected.");
        using var stream = new FileStream(full, FileMode.Open, FileAccess.Read, FileShare.Read);
        if (stream.Length < 1 || stream.Length > maximum) throw new InvalidDataException("Bootstrap size rejected.");
        var bytes = new byte[checked((int)stream.Length)]; stream.ReadExactly(bytes);
        if (stream.ReadByte() != -1) throw new InvalidDataException("Bootstrap changed during read.");
        return bytes;
    }
}
