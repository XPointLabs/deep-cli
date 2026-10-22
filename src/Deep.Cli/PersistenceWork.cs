using System.Diagnostics.Tracing;

namespace Deep.Cli;

// Closed numeric timings, never trust, retry or storage decisions. Nested
// phase totals overlap and must not be added into a synthetic critical path.
internal sealed class PersistenceWork : EventListener
{
    private static readonly AsyncLocal<PersistenceWork?> Current = new();
    private readonly PersistenceWork? parent;
    private readonly object gate = new();
    private readonly Dictionary<int, (long Count, double Total, double Maximum)> totals = [];
    internal PersistenceWork() { parent = Current.Value; Current.Value = this; }
    protected override void OnEventSourceCreated(EventSource source)
    {
        if (source.Name == "Deep-Client-Persistence") EnableEvents(source, EventLevel.Informational);
    }
    protected override void OnEventWritten(EventWrittenEventArgs e)
    {
        if (!ReferenceEquals(Current.Value, this) || e.EventSource.Name != "Deep-Client-Persistence" || e.EventId != 1 ||
            e.Payload is not { Count: 2 } || e.Payload[0] is not int phase || phase is < 1 or > 7 ||
            e.Payload[1] is not double ms || !double.IsFinite(ms) || ms is < 0 or > 3600000) return;
        try
        {
            lock (gate)
            {
                totals.TryGetValue(phase, out var row);
                totals[phase] = (row.Count + 1, row.Total + ms, Math.Max(row.Maximum, ms));
            }
        }
        catch { /* Observation cannot change storage outcomes. */ }
    }
    internal object Snapshot()
    {
        lock (gate) return totals.OrderBy(row => row.Key).Select(row => new
        {
            phase = row.Key switch { 1 => "StorageLoad", 2 => "GroupDecode", 3 => "ApplicationOpen", 4 => "ApplicationIntegrity", 5 => "DeviceValidate", 6 => "NativeReconcile", 7 => "NativeVerify", _ => "Unknown" },
            count = row.Value.Count, totalMilliseconds = (long)row.Value.Total, maximumMilliseconds = (long)row.Value.Maximum
        }).ToArray();
    }
    public override void Dispose()
    {
        base.Dispose();
        if (ReferenceEquals(Current.Value, this)) Current.Value = parent;
    }
}
