using System.Text;
using System.Text.Json;
using Deep.Client.Shared.Services;

namespace Deep.Cli;

// One serial host, one exclusive profile lease, one public network composition.
// Account/transport loans still belong to each existing Shared operation.
internal sealed class CliSession(CommandLine binding) : IDisposable, IAsyncDisposable
{
    internal const int MaximumFrameCharacters = 65536;
    private WindowsProfile? profile;
    private DeepIdV2ClientNetworkSession? network;
    private readonly SemaphoreSlim operations = new(1, 1);
    private readonly CancellationTokenSource stopping = new();
    private Task? maintenance;
    private long maintenanceChecks, maintenanceFailures, maintenanceMilliseconds;
    private bool disposed;

    internal void RequireBinding(CommandLine command)
    {
        ObjectDisposedException.ThrowIf(disposed, this);
        if (command.Area == "session" || command.Profile != binding.Profile ||
            !command.Network.AsSpan().SequenceEqual(binding.Network) ||
            command.Bootstrap is not null && !StringComparer.Ordinal.Equals(command.Bootstrap, binding.Bootstrap) ||
            command.Registry is not null && !StringComparer.Ordinal.Equals(command.Registry, binding.Registry))
            throw new ArgumentException("Session configuration cannot change.");
    }

    internal WindowsProfile GetProfile(CommandLine command)
    {
        RequireBinding(command);
        return profile ??= WindowsProfile.Open(binding);
    }

    internal async Task<DeepIdV2ClientNetworkSession> GetNetworkAsync(CommandLine command, CancellationToken ct)
    {
        RequireBinding(command);
        ct.ThrowIfCancellationRequested();
        return network ??= await NetworkBootstrap.OpenAsync(binding, GetProfile(command).Accounts, ct).ConfigureAwait(false);
    }

    internal void InvalidateNetwork() { network?.Dispose(); network = null; }
    internal object Snapshot() => new { maintenanceChecks, maintenanceFailures, maintenanceMilliseconds };

    private async Task MaintainAsync()
    {
        using var timer = new PeriodicTimer(TimeSpan.FromSeconds(10));
        try
        {
            while (await timer.WaitForNextTickAsync(stopping.Token).ConfigureAwait(false))
            {
                // Never queue behind delivery or refresh concurrently with an
                // account operation. No private loan survives a command.
                if (!await operations.WaitAsync(0, stopping.Token).ConfigureAwait(false)) continue;
                var started = System.Diagnostics.Stopwatch.GetTimestamp();
                try
                {
                    if (network is not null)
                    {
                        using var budget = CancellationTokenSource.CreateLinkedTokenSource(stopping.Token);
                        budget.CancelAfter(TimeSpan.FromSeconds(30));
                        maintenanceChecks++;
                        await network.MaintainGroupAuthorityAsync(budget.Token).ConfigureAwait(false);
                    }
                }
                catch (OperationCanceledException) when (stopping.IsCancellationRequested) { throw; }
                catch { maintenanceFailures++; InvalidateNetwork(); } // no stale fallback, retry or payload logging
                finally
                {
                    maintenanceMilliseconds += (long)System.Diagnostics.Stopwatch.GetElapsedTime(started).TotalMilliseconds;
                    operations.Release();
                }
            }
        }
        catch (OperationCanceledException) when (stopping.IsCancellationRequested) { }
    }

    public void Dispose()
    {
        if (disposed) return;
        stopping.Cancel();
        maintenance?.GetAwaiter().GetResult();
        disposed = true;
        try { InvalidateNetwork(); } finally { profile?.Dispose(); stopping.Dispose(); operations.Dispose(); }
    }

    public async ValueTask DisposeAsync()
    {
        if (disposed) return;
        stopping.Cancel();
        if (maintenance is not null) await maintenance.ConfigureAwait(false);
        Dispose();
    }

    internal static async Task<int> RunAsync(CommandLine binding, TextReader input, TextWriter output, CancellationToken ct)
    {
        await using var session = new CliSession(binding);
        session.maintenance = session.MaintainAsync();
        return await RunFramesAsync(input, output, async args =>
        {
            using var budget = CancellationTokenSource.CreateLinkedTokenSource(ct);
            budget.CancelAfter(Program.TimeoutFor(args));
            using var stdout = new StringWriter(); using var stderr = new StringWriter();
            try { await session.operations.WaitAsync(budget.Token).ConfigureAwait(false); }
            catch (OperationCanceledException)
            { return "{\"exitCode\":130,\"result\":{\"status\":\"error\",\"code\":\"cancelled\"}}"; }
            int exit;
            try
            {
                exit = await Program.RunAsync(args, stdout, stderr, budget.Token, session).ConfigureAwait(false);
                // Failed commands retain durable work, but never retain a possibly
                // invalid public composition for the next independent command.
                if (exit != 0) session.InvalidateNetwork();
            }
            finally { session.operations.Release(); }
            var encoded = exit == 0 ? stdout.ToString() : stderr.ToString();
            using var json = JsonDocument.Parse(encoded);
            return JsonSerializer.Serialize(new { exitCode = exit, result = json.RootElement });
        }, ct).ConfigureAwait(false);
    }

    // JSON argument arrays over private stdio, not a listening service. No
    // automatic business retries, concurrent commands or unbounded line reads.
    internal static async Task<int> RunFramesAsync(TextReader input, TextWriter output,
        Func<string[], Task<string>> execute, CancellationToken ct)
    {
        var frame = new StringBuilder(); var buffer = new char[1024];
        while (true)
        {
            var count = await input.ReadAsync(buffer.AsMemory(), ct).ConfigureAwait(false);
            if (count == 0) return frame.Length == 0 ? 0 : 2; // truncated command is never executed
            for (var i = 0; i < count; i++)
            {
                ct.ThrowIfCancellationRequested();
                if (buffer[i] != '\n')
                {
                    if (frame.Length >= MaximumFrameCharacters) return 2;
                    frame.Append(buffer[i]); continue;
                }
                string[]? args;
                try
                {
                    args = JsonSerializer.Deserialize<string[]>(frame.ToString());
                    if (args is null || args.Length is < 2 or > 40 || args.Any(x => x is null))
                        throw new JsonException();
                }
                catch (JsonException)
                {
                    await output.WriteLineAsync("{\"exitCode\":2,\"result\":{\"status\":\"error\",\"code\":\"invalid-frame\"}}").ConfigureAwait(false);
                    await output.FlushAsync(ct).ConfigureAwait(false);
                    frame.Clear(); continue;
                }
                frame.Clear();
                await output.WriteLineAsync(await execute(args).ConfigureAwait(false)).ConfigureAwait(false);
                await output.FlushAsync(ct).ConfigureAwait(false);
            }
        }
    }
}
