using System.Text.RegularExpressions;

namespace Deep.Cli;

internal sealed record CommandLine(string Operation, string Profile, byte[] Network, string? Name)
{
    internal static CommandLine Parse(string[] args)
    {
        if (args.Length < 2 || args[0] != "account" ||
            args[1] is not ("create" or "status" or "address"))
            throw new ArgumentException("Unsupported command.");
        var options = new Dictionary<string, string>(StringComparer.Ordinal);
        for (var i = 2; i < args.Length; i += 2)
        {
            if (i + 1 >= args.Length || args[i] is not ("--profile" or "--network" or "--name") ||
                !options.TryAdd(args[i], args[i + 1]))
                throw new ArgumentException("Invalid options.");
        }
        if (!options.TryGetValue("--profile", out var profile) ||
            !Regex.IsMatch(profile, "\\A[a-z][a-z0-9-]{0,31}\\z", RegexOptions.CultureInvariant) ||
            !options.TryGetValue("--network", out var network) ||
            !Regex.IsMatch(network, "\\A[0-9a-f]{32}\\z", RegexOptions.CultureInvariant) ||
            network.All(c => c == '0'))
            throw new ArgumentException("Explicit profile and network are required.");
        options.TryGetValue("--name", out var name);
        if (args[1] == "create" ? string.IsNullOrWhiteSpace(name) || name.Length > 80 || name.Any(char.IsControl)
            : name is not null)
            throw new ArgumentException("Invalid display name option.");
        return new(args[1], profile, Convert.FromHexString(network), name);
    }
}
