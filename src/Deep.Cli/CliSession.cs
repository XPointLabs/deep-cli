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
    private readonly object maintenanceSync = new();
    private CancellationTokenSource? activeMaintenance;
    private int foregroundCommands;
    private long nextContactMaintenance;
    private bool connectionActivated;
    private bool contactMaintenanceActivated;
    private bool knownContactsSeeded;
    private DeliveryDiagnostics? delivery;
    private long maintenanceChecks, maintenanceFailures, maintenanceMilliseconds;
    private long maintenanceCycles;
    private bool disposed;

    internal void RequireBinding(CommandLine command)
    {
        ObjectDisposedException.ThrowIf(disposed, this);
        if (command.Area is "session" or "storage" or "publication" || command.Profile != binding.Profile ||
            !command.Network.AsSpan().SequenceEqual(binding.Network) ||
            command.Bootstrap is not null && !StringComparer.Ordinal.Equals(command.Bootstrap, binding.Bootstrap) ||
            command.Registry is not null && !StringComparer.Ordinal.Equals(command.Registry, binding.Registry))
            throw new ArgumentException("Session configuration cannot change.");
    }

    internal async Task<WindowsProfile> GetProfileAsync(CommandLine command, CancellationToken ct = default)
    {
        RequireBinding(command);
        return profile ??= await WindowsProfile.OpenAsync(command, ct).ConfigureAwait(false);
    }

    internal Deep.Client.Shared.Persistence.DeepSecureStorageWorkSnapshot StorageWork => profile?.StorageWork ?? default;

    internal async Task<DeepIdV2ClientNetworkSession> GetNetworkAsync(CommandLine command, CancellationToken ct)
    {
        RequireBinding(command);
        ct.ThrowIfCancellationRequested();
        var result = network ??= await NetworkBootstrap.OpenAsync(binding,
            (await GetProfileAsync(command, ct).ConfigureAwait(false)).Accounts, ct).ConfigureAwait(false);
        connectionActivated = true;
        return result;
    }

    internal void InvalidateNetwork() { network?.Dispose(); network = null; }
    internal void EnableContactMaintenance() => contactMaintenanceActivated = true;
    internal object Snapshot() => new { maintenanceChecks, maintenanceFailures, maintenanceMilliseconds };

    internal bool TryStartMaintenance(out CancellationTokenSource? budget)
    {
        lock (maintenanceSync)
        {
            budget = null;
            if (foregroundCommands != 0 || !operations.Wait(0)) return false;
            budget = CancellationTokenSource.CreateLinkedTokenSource(stopping.Token);
            activeMaintenance = budget; return true;
        }
    }

    internal void EndMaintenance(CancellationTokenSource budget)
    {
        lock (maintenanceSync) { activeMaintenance = null; budget.Dispose(); }
        operations.Release();
    }

    internal async Task EnterCommandAsync(CancellationToken ct)
    {
        lock (maintenanceSync) { foregroundCommands++; activeMaintenance?.Cancel(); }
        try { await operations.WaitAsync(ct).ConfigureAwait(false); }
        catch { lock (maintenanceSync) foregroundCommands--; throw; }
    }

    internal void LeaveCommand()
    {
        operations.Release();
        lock (maintenanceSync) foregroundCommands--;
    }

    internal static TimeSpan ContactMaintenancePause(DeepIdV2ContactMaintenanceResult? completed) =>
        completed is { ControlsStored: > 0 } or { ProcessedEnvelopes: > 0 } or { Reintroductions: > 0 }
            ? TimeSpan.FromSeconds(10) : TimeSpan.FromSeconds(60);

    private async Task MaintainAsync()
    {
        using var timer = new PeriodicTimer(TimeSpan.FromSeconds(10));
        try
        {
            while (await timer.WaitForNextTickAsync(stopping.Token).ConfigureAwait(false))
            {
                // Never queue behind delivery or refresh concurrently with an
                // account operation. No private loan survives a command.
                if (!TryStartMaintenance(out var selectedBudget)) continue;
                var budget = selectedBudget!;
                var started = System.Diagnostics.Stopwatch.GetTimestamp();
                var contactCycle = connectionActivated && contactMaintenanceActivated && started >= nextContactMaintenance;
                var cycle = contactCycle ? ++maintenanceCycles : 0;
                DeepIdV2ContactMaintenanceResult? completedCycle = null;
                if (contactCycle)
                {
                    nextContactMaintenance = started + 60 * System.Diagnostics.Stopwatch.Frequency;
                    delivery?.ObserveMaintenance(cycle, "Started");
                }
                try
                {
                    if (connectionActivated)
                    {
                        budget.CancelAfter(TimeSpan.FromMinutes(6));
                        maintenanceChecks++;
                        var connected = await GetNetworkAsync(binding with { Area = "network", Operation = "maintain" },
                            budget.Token).ConfigureAwait(false);
                        if (!contactCycle) await connected.MaintainGroupAuthorityAsync(budget.Token).ConfigureAwait(false);
                        if (contactCycle)
                        {
                            // One bounded ordinary cycle, including exact pending
                            // controls and a receive page. A foreground command
                            // cancels this phase before waiting on the serial loan.
                            var completed = await connected.MaintainContactsInBackgroundAsync(knownContactsSeeded ? null : binding.KnownContacts,
                                budget.Token).ConfigureAwait(false);
                            knownContactsSeeded = true;
                            completedCycle = completed;
                            delivery?.ObserveMaintenance(cycle, "Completed", completed);
                        }
                    }
                }
                catch (OperationCanceledException) when (stopping.IsCancellationRequested)
                { if (contactCycle) delivery?.ObserveMaintenance(cycle, "Cancelled"); throw; }
                catch (OperationCanceledException) when (budget.IsCancellationRequested)
                { if (contactCycle) delivery?.ObserveMaintenance(cycle, "Cancelled"); InvalidateNetwork(); } // Exact durable controls resume on a later opportunity.
                catch (Exception error)
                { if (contactCycle) delivery?.ObserveMaintenance(cycle, "Failed", failure: error); maintenanceFailures++; InvalidateNetwork(); } // no stale fallback or business retry
                finally
                {
                    if (contactCycle) nextContactMaintenance = System.Diagnostics.Stopwatch.GetTimestamp() +
                        (long)(ContactMaintenancePause(completedCycle).TotalSeconds * System.Diagnostics.Stopwatch.Frequency);
                    maintenanceMilliseconds += (long)System.Diagnostics.Stopwatch.GetElapsedTime(started).TotalMilliseconds;
                    EndMaintenance(budget);
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

    internal static async Task<int> RunAsync(CommandLine binding, TextReader input, TextWriter output, CancellationToken ct,
        TextWriter? diagnostics = null)
    {
        await using var session = new CliSession(binding);
        await using var delivery = binding.DeliveryEvents ? new DeliveryDiagnostics(diagnostics ?? TextWriter.Null) : null;
        session.delivery = delivery;
        session.maintenance = session.MaintainAsync();
        try { return await RunFramesAsync(input, output, async args =>
        {
            using var budget = CancellationTokenSource.CreateLinkedTokenSource(ct);
            budget.CancelAfter(Program.TimeoutFor(args));
            using var stdout = new StringWriter(); using var stderr = new StringWriter();
            CommandLine? admitted = null;
            if (delivery is not null)
            {
                try { admitted = CommandLine.Parse(args); session.RequireBinding(admitted); }
                catch (ArgumentException) { admitted = null; } // Ordinary Program error framing remains authoritative.
            }
            // Admit the valid bound command before its serial queue wait. The
            // same parsed value is used by Program; no alternate command grammar.
            using var observation = admitted is null ? null : delivery?.AcceptCommand();
            try { await session.EnterCommandAsync(budget.Token).ConfigureAwait(false); }
            catch (OperationCanceledException)
            {
                return "{\"exitCode\":130,\"result\":{\"status\":\"error\",\"code\":\"cancelled\"}}";
            }
            int exit;
            try
            {
                exit = await Program.RunAsync(args, stdout, stderr, budget.Token, session, admitted).ConfigureAwait(false);
                // Failed commands retain durable work, but never retain a possibly
                // invalid public composition for the next independent command.
                if (exit != 0) session.InvalidateNetwork();
            }
            finally
            {
                session.LeaveCommand();
            }
            var encoded = exit == 0 ? stdout.ToString() : stderr.ToString();
            using var json = JsonDocument.Parse(encoded);
            return JsonSerializer.Serialize(new { exitCode = exit, result = json.RootElement });
        }, ct).ConfigureAwait(false); }
        finally { await session.DisposeAsync().ConfigureAwait(false); } // Close background observation before delivery stream terminal.
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
