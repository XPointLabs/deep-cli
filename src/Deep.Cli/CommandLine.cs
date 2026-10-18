using System.Text.RegularExpressions;

namespace Deep.Cli;

internal sealed record CommandLine(string Operation, string Profile, byte[] Network, string? Name)
{
    internal string Area { get; init; } = "account";
    internal string? Bootstrap { get; init; }
    internal string? Registry { get; init; }
    internal string? Address { get; init; }
    internal string? Conversation { get; init; }
    internal string? OperationId { get; init; }
    internal string? Text { get; init; }
    internal string? File { get; init; }
    internal string? MediaType { get; init; }
    internal string? Asset { get; init; }
    internal string? Logical { get; init; }
    internal string? Device { get; init; }
    internal string? Output { get; init; }
    internal string? Group { get; init; }
    internal static CommandLine Parse(string[] args)
    {
        if (args.Length < 2) throw new ArgumentException("Unsupported command.");
        var extra = (args[0], args[1]) switch
        {
            ("account", "create") => new[] { "--name" },
            ("account", "status" or "address") or ("contact", "list" or "operations") or ("message", "pending") or ("attachment", "pending" or "operations") => [],
            ("network", "verify") or ("mailbox", "sync") => ["--bootstrap", "--registry"],
            ("contact", "request") => ["--bootstrap", "--registry", "--address", "--operation"],
            ("contact", "stop") => ["--bootstrap", "--registry", "--operation"],
            ("contact", "accept") => ["--bootstrap", "--registry", "--conversation", "--operation"],
            ("message", "queue") => ["--bootstrap", "--registry", "--conversation", "--text"],
            ("message", "send") => ["--bootstrap", "--registry", "--conversation", "--operation", "--text"],
            ("message", "list") => ["--conversation"],
            ("attachment", "prepare") => ["--bootstrap", "--registry", "--file", "--media", "--operation"],
            ("attachment", "send") => ["--bootstrap", "--registry", "--conversation", "--asset", "--operation"],
            ("attachment", "queue") => ["--bootstrap", "--registry", "--conversation", "--asset"],
            ("attachment", "list") => ["--conversation"],
            ("attachment", "download") => ["--bootstrap", "--registry", "--conversation", "--logical", "--device", "--output"],
            ("group", "create") => ["--bootstrap", "--registry", "--name"],
            ("group", "list") => [],
            ("group", "messages") => ["--group"],
            ("group", "invite" or "accept" or "advance" or "flush" or "sync") => ["--bootstrap", "--registry", "--conversation", "--group"],
            ("group", "publish") => ["--bootstrap", "--registry", "--group"],
            ("group", "send") => ["--bootstrap", "--registry", "--conversation", "--group", "--text"],
            _ => throw new ArgumentException("Unsupported command.")
        };
        var allowed = new HashSet<string>(["--profile", "--network", .. extra], StringComparer.Ordinal);
        var options = new Dictionary<string, string>(StringComparer.Ordinal);
        for (var i = 2; i < args.Length; i += 2)
        {
            if (i + 1 >= args.Length || !allowed.Contains(args[i]) ||
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
        if (extra.Any(key => !options.TryGetValue(key, out var value) || string.IsNullOrWhiteSpace(value)) ||
            name is not null && (name.Length > 80 || name.Any(char.IsControl)))
            throw new ArgumentException("Invalid display name option.");
        if (options.TryGetValue("--operation", out var operation) &&
            (!Regex.IsMatch(operation, "\\A[0-9a-f]{64}\\z") || operation.All(c => c == '0')) ||
            options.TryGetValue("--conversation", out var conversation) && !Regex.IsMatch(conversation, "\\A[0-9A-Fa-f]{64}\\z"))
            throw new ArgumentException("Invalid operation or conversation identifier.");
        foreach (var selector in new[] { "--asset", "--logical", "--device", "--group" })
            if (options.TryGetValue(selector, out var id) && (!Regex.IsMatch(id, "\\A[0-9a-f]{64}\\z") || id.All(c => c == '0')))
                throw new ArgumentException("Exact attachment selector required.");
        foreach (var path in new[] { "--file", "--output" })
            if (options.TryGetValue(path, out var value) && (!Path.IsPathFullyQualified(value) || value.Any(char.IsControl)))
                throw new ArgumentException("Attachment paths must be absolute.");
        return new(args[1], profile, Convert.FromHexString(network), name)
        {
            Area = args[0], Bootstrap = options.GetValueOrDefault("--bootstrap"), Registry = options.GetValueOrDefault("--registry"),
            Address = options.GetValueOrDefault("--address"), Conversation = options.GetValueOrDefault("--conversation")?.ToUpperInvariant(),
            OperationId = options.GetValueOrDefault("--operation"), Text = options.GetValueOrDefault("--text"),
            File = options.GetValueOrDefault("--file"), MediaType = options.GetValueOrDefault("--media"), Asset = options.GetValueOrDefault("--asset"),
            Logical = options.GetValueOrDefault("--logical"), Device = options.GetValueOrDefault("--device"), Output = options.GetValueOrDefault("--output"),
            Group = options.GetValueOrDefault("--group")
        };
    }
}
