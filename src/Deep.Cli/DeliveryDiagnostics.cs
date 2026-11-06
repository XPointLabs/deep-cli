using System.Diagnostics.Tracing;
using System.Text.Json;
using System.Threading.Channels;

namespace Deep.Cli;

// Opt-in stderr stream. Stdout command responses keep their existing framing.
// Bounded, nonblocking observation: dropped frames leave sequence gaps and can
// never qualify a latency sample. There are no client-side clock timestamps.
internal sealed class DeliveryDiagnostics : EventListener, IAsyncDisposable
{
    private static readonly AsyncLocal<(DeliveryDiagnostics Owner, long Command)?> Current = new();
    private readonly object gate = new();
    private readonly Channel<string> frames = Channel.CreateBounded<string>(new BoundedChannelOptions(256)
        { SingleReader = true, FullMode = BoundedChannelFullMode.Wait });
    private readonly Task pump;
    private readonly TextWriter output;
    private long sequence, command, dropped;
    private long maintenanceSequence;

    internal DeliveryDiagnostics(TextWriter output) { this.output = output; pump = PumpAsync(output); }

    internal IDisposable AcceptCommand()
    {
        var parent = Current.Value;
        lock (gate)
        {
            Current.Value = (this, ++command);
            Emit(command, "CommandAccepted", "", "");
        }
        return new Scope(() => Current.Value = parent);
    }

    internal void ObserveMaintenance(long cycle, string phase, Deep.Client.Shared.Services.DeepIdV2ContactMaintenanceResult? result = null)
    {
        if (cycle <= 0 || phase is not ("Started" or "Completed" or "Cancelled" or "Failed") ||
            (phase == "Completed") != (result is not null)) throw new ArgumentException("Invalid maintenance observation.");
        lock (gate)
            if (!frames.Writer.TryWrite(JsonSerializer.Serialize(new { schema = "deep.maintenance.v1", sequence = ++maintenanceSequence,
                cycle, phase, acceptedContacts = result?.AcceptedContacts ?? 0, controlsStored = result?.ControlsStored ?? 0,
                deferredContacts = result?.DeferredContacts ?? 0, reintroductions = result?.Reintroductions ?? 0 }))) dropped++;
    }

    protected override void OnEventSourceCreated(EventSource source)
    { if (source.Name == "Deep-Client-Delivery") EnableEvents(source, EventLevel.Informational); }

    protected override void OnEventWritten(EventWrittenEventArgs e)
    {
        if (Current.Value is not { } current || !ReferenceEquals(current.Owner, this) ||
            e.EventSource.Name != "Deep-Client-Delivery" || e.EventId != 1 || e.Payload is not { Count: 3 } ||
            e.Payload[0] is not int phase || phase is < 1 or > 3 ||
            e.Payload[1] is not string messageHash || !IsHash(messageHash) ||
            e.Payload[2] is not string deliveryHash || !IsHash(deliveryHash)) return;
        lock (gate) Emit(current.Command, phase switch
        { 1 => "NativeOutboxDurable", 2 => "StoreQuorum", _ => "RecipientDurableReadable" }, messageHash, deliveryHash);
    }

    internal static bool IsHash(string value) => value.Length == 64 && value.All(c => c is >= '0' and <= '9' or >= 'a' and <= 'f');

    private void Emit(long acceptedCommand, string phase, string messageHash, string deliveryHash)
    {
        if (!frames.Writer.TryWrite(JsonSerializer.Serialize(new { schema = "deep.delivery.v1", sequence = ++sequence,
            command = acceptedCommand, phase, messageHash, deliveryHash }))) dropped++;
    }

    private async Task PumpAsync(TextWriter output)
    {
        try
        {
            await foreach (var frame in frames.Reader.ReadAllAsync().ConfigureAwait(false))
            {
                await output.WriteLineAsync(frame).ConfigureAwait(false);
                await output.FlushAsync().ConfigureAwait(false);
            }
        }
        catch (IOException) { } // Product outcomes remain authoritative; incomplete evidence cannot pass.
        catch (ObjectDisposedException) { }
    }

    public async ValueTask DisposeAsync()
    {
        Dispose(); frames.Writer.TryComplete(); await pump.ConfigureAwait(false);
        // This mandatory terminal bypasses the bounded queue. Even a dropped
        // LAST event is detectable; EOF without this terminal cannot qualify.
        string terminal;
        lock (gate) terminal = JsonSerializer.Serialize(new { schema = "deep.delivery.v1", sequence = ++sequence,
            command = 0, phase = "StreamClosed", messageHash = "", deliveryHash = "", dropped });
        try { await output.WriteLineAsync(terminal).ConfigureAwait(false); await output.FlushAsync().ConfigureAwait(false); }
        catch (IOException) { }
        catch (ObjectDisposedException) { }
    }

    private sealed class Scope(Action close) : IDisposable { public void Dispose() => close(); }
}
