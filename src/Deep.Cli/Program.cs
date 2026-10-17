using System.Security.Cryptography;
using System.Text.Json;

namespace Deep.Cli;

internal static class Program
{
    private static async Task<int> Main(string[] args)
    {
        using var cancellation = new CancellationTokenSource();
        Console.CancelKeyPress += (_, e) => { e.Cancel = true; cancellation.Cancel(); };
        return await RunAsync(args, Console.Out, Console.Error, cancellation.Token);
    }

    internal static async Task<int> RunAsync(string[] args, TextWriter output, TextWriter error,
        CancellationToken ct = default)
    {
        try
        {
            if (args is ["--help"] or [])
            {
                await output.WriteLineAsync("deep account <create|status|address> --profile <alias> --network <32 lowercase hex> [--name <display name>]\n" +
                    "Windows host; isolated persistent DID2 profiles. Network commands are not implemented yet.");
                return 0;
            }
            var command = CommandLine.Parse(args);
            ct.ThrowIfCancellationRequested();
            using var profile = WindowsProfile.Open(command);
            var account = command.Operation == "create"
                ? await profile.Accounts.CreateAsync(command.Name!, ct)
                : await profile.Accounts.GetCurrentAsync(ct);
            if (command.Operation == "address" && account is null)
                return await FailAsync(error, "account-missing", 4);
            // Only explicit public-address commands return the resolver address.
            // No account ID, credential, recovery phrase or private storage path.
            await output.WriteLineAsync(JsonSerializer.Serialize(new
            {
                status = command.Operation == "create" ? "created" : "ok",
                accountPresent = account is not null,
                address = command.Operation == "status" ? null : account?.PermanentId.CanonicalText
            }));
            return 0;
        }
        catch (OperationCanceledException) { return await FailAsync(error, "cancelled", 130); }
        catch (ArgumentException) { return await FailAsync(error, "invalid-arguments", 2); }
        catch (PlatformNotSupportedException) { return await FailAsync(error, "platform-unavailable", 3); }
        catch (CryptographicException) { return await FailAsync(error, "protected-state-rejected", 4); }
        catch (InvalidDataException) { return await FailAsync(error, "protected-state-rejected", 4); }
        catch (IOException) { return await FailAsync(error, "storage-unavailable-or-busy", 5); }
        catch (UnauthorizedAccessException) { return await FailAsync(error, "storage-access-denied", 5); }
        catch (Exception) { return await FailAsync(error, "operation-failed", 1); }
    }

    private static async Task<int> FailAsync(TextWriter error, string code, int exit)
    {
        await error.WriteLineAsync(JsonSerializer.Serialize(new { status = "error", code }));
        return exit;
    }
}
