using System.Security.Cryptography;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace Deep.Cli;

internal static class Program
{
    internal static readonly TimeSpan CommandTimeout = TimeSpan.FromMinutes(5);
    internal static readonly TimeSpan AttachmentTransferTimeout = TimeSpan.FromHours(3);
    internal static TimeSpan TimeoutFor(string[] args) => args is ["attachment", "send" or "download", ..]
        ? AttachmentTransferTimeout : CommandTimeout;
    private static async Task<int> Main(string[] args)
    {
        using var cancellation = new CancellationTokenSource();
        // A business command composes several independently bounded proof,
        // claim, grant and Store hops. Its outer host budget must not cancel a
        // healthy final Store merely because preparation took two minutes.
        // Signed windows and each transport's shorter deadlines still apply.
        // A maximum-sized attachment composes up to 200 separately bounded
        // chunk requests. No signed window or individual hop is extended.
        cancellation.CancelAfter(TimeoutFor(args));
        Console.CancelKeyPress += (_, e) => { e.Cancel = true; cancellation.Cancel(); };
        return await RunAsync(args, Console.Out, Console.Error, cancellation.Token);
    }

    internal static async Task<int> RunAsync(string[] args, TextWriter output, TextWriter error,
        CancellationToken ct = default)
    {
        using var work = ProtectionWork.Begin();
        using var networkWork = new NetworkWork();
        try
        {
            if (args is ["--help"] or [])
            {
                await output.WriteLineAsync("deep <area> <command> --profile <alias> --network <32 lowercase hex> [options]\n" +
                    "account create/status/address; network verify; contact request/accept/stop/list/operations; mailbox sync; message queue/send/list/pending; attachment prepare/queue/send/pending/operations/list/download\n" +
                    "Network operations require --bootstrap <public dev bundle> --registry <canonical HTTPS origin>.\n" +
                    "request: --address --operation; accept: --conversation --operation; queue: --conversation --text; send: --conversation --operation --text.\n" +
                    "Windows host; isolated persistent DID2 profiles. Stored is not remote delivery.");
                return 0;
            }
            var command = CommandLine.Parse(args);
            ct.ThrowIfCancellationRequested();
            using var profile = WindowsProfile.Open(command);
            if (command.Area != "account")
            {
                if (await profile.Accounts.GetCurrentAsync(ct) is null) return await FailAsync(error, "account-missing", 4);
                var result = await BusinessCommands.RunAsync(command, profile.Accounts, ct);
                var encoded = JsonSerializer.SerializeToNode(result)!.AsObject();
                encoded["protectionWork"] = JsonSerializer.SerializeToNode(work.Snapshot());
                encoded["networkWork"] = JsonSerializer.SerializeToNode(networkWork.Snapshot());
                await output.WriteLineAsync(encoded.ToJsonString());
                return 0;
            }
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
                address = command.Operation == "status" ? null : account?.PermanentId.CanonicalText,
                protectionWork = work.Snapshot()
            }));
            return 0;
        }
        catch (OperationCanceledException) { return await FailAsync(error, "cancelled", 130); }
        catch (CliBusinessException failure)
        {
            await error.WriteLineAsync(JsonSerializer.Serialize(new { status = "error", code = "business-operation-failed", diagnostic = failure.ClosedDiagnostic(), protectionWork = work.Snapshot(), networkWork = networkWork.Snapshot() }));
            return ct.IsCancellationRequested ? 130 : 6;
        }
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
