using System.Diagnostics;
using System.Diagnostics.Tracing;

namespace Deep.Cli;

// Emits only fixed public endpoint groups/status/count/duration. Never exports
// a host, URI, query, headers, body, exception text or activity identifier.
internal sealed class NetworkWork : EventListener
{
    private readonly object gate = new();
    private readonly Dictionary<Guid, Request> active = [];
    private readonly Dictionary<string, Totals> totals = new(StringComparer.Ordinal);
    protected override void OnEventSourceCreated(EventSource source)
    {
        if (source.Name == "System.Net.Http") EnableEvents(source, EventLevel.Informational);
        // Http's Start/Stop identifiers require the runtime's activity flow.
        // Enable only that TPL keyword; no task payload is consumed.
        if (source.Name == "System.Threading.Tasks.TplEventSource")
            EnableEvents(source, EventLevel.Informational, (EventKeywords)0x80);
    }
    protected override void OnEventWritten(EventWrittenEventArgs e)
    {
        if (e.EventSource.Name != "System.Net.Http") return;
        try
        {
            lock (gate)
            {
                if (e.EventName == "RequestStart")
                {
                    var path = Field(e, "pathAndQuery") as string;
                    var group = path switch
                    {
                        "/api/v2/network/closure" => "NetworkClosure",
                        "/api/v2/account-directory/proofs" => "DirectoryProof",
                        "/api/v2/account-directory/history" => "DirectoryHistory",
                        "/api/v2/account-directory/genesis-admissions" => "GenesisAdmission",
                        "/api/ingress/v1/frame" => "OnionFrame",
                        _ => "Other"
                    };
                    if (!totals.TryGetValue(group, out var row)) totals.Add(group, row = new());
                    row.Starts++;
                    if (active.Count < 128 && e.ActivityId != Guid.Empty)
                        active[e.ActivityId] = new(group, Stopwatch.GetTimestamp());
                }
                else if (e.EventName == "RequestFailed" && active.TryGetValue(e.ActivityId, out var failed))
                    failed.Failed = true;
                else if (e.EventName == "RequestStop" && active.Remove(e.ActivityId, out var request))
                {
                    var row = totals[request.Group];
                    var ms = Math.Clamp((long)Stopwatch.GetElapsedTime(request.Started).TotalMilliseconds, 0, 3600000);
                    row.Completed++; row.Milliseconds += ms; row.Maximum = Math.Max(row.Maximum, ms);
                    if (request.Failed) row.Failed++;
                    if (Field(e, "statusCode") is int status && status != 200) row.NonSuccess++;
                }
            }
        }
        catch { /* Metrics cannot replace the transport outcome. */ }
    }
    private static object? Field(EventWrittenEventArgs e, string name)
    {
        for (var i = 0; i < (e.PayloadNames?.Count ?? 0); i++)
            if (e.PayloadNames![i] == name) return e.Payload?[i];
        return null;
    }
    internal object Snapshot()
    {
        lock (gate) return totals.OrderBy(x => x.Key, StringComparer.Ordinal).Select(x => new
        {
            group = x.Key, started = x.Value.Starts, completed = x.Value.Completed,
            failed = x.Value.Failed, nonSuccess = x.Value.NonSuccess,
            totalMilliseconds = x.Value.Milliseconds, maximumMilliseconds = x.Value.Maximum
        }).ToArray();
    }
    private sealed class Request(string group, long started)
    { internal readonly string Group = group; internal readonly long Started = started; internal bool Failed; }
    private sealed class Totals
    { internal long Starts, Completed, Failed, NonSuccess, Milliseconds, Maximum; }
}
