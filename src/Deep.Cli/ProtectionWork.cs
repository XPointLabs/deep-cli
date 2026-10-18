using System.Diagnostics;

namespace Deep.Cli;

// Numeric resource diagnostics only, not authority or retry decisions.
internal sealed class ProtectionWork : IDisposable
{
    private static readonly AsyncLocal<ProtectionWork?> Current = new();
    private readonly ProtectionWork? parent;
    private long protects, unprotects, ticks;
    private readonly object sitesGate = new();
    private readonly Dictionary<string, (long Samples, long Ticks)> sites = new(StringComparer.Ordinal);
    private ProtectionWork() { parent = Current.Value; Current.Value = this; }
    internal static ProtectionWork Begin() => new();
    internal static void Record(bool protect, long started)
    {
        var scope = Current.Value; if (scope is null) return;
        var elapsed = Stopwatch.GetTimestamp() - started;
        var index = protect ? Interlocked.Increment(ref scope.protects) : Interlocked.Increment(ref scope.unprotects);
        Interlocked.Add(ref scope.ticks, elapsed);
        // Sparse, bounded metadata sampling; never inspect arguments, slot
        // names, paths, exception text or protected/plaintext values.
        if (!protect && (index <= 16 || index % 16 == 0))
        {
            var site = "AsyncBoundary";
            foreach (var frame in new StackTrace(false).GetFrames().Take(32))
            {
                var method = frame.GetMethod(); var type = method?.DeclaringType;
                if (type?.Assembly != typeof(Deep.Client.Shared.Persistence.JournaledDeepSecureStorage).Assembly ||
                    type.FullName is not { } name || name.StartsWith("Deep.Client.Shared.Persistence.JournaledDeepSecureStorage", StringComparison.Ordinal)) continue;
                var candidate = name + "." + method!.Name;
                if (candidate.Length <= 240) site = candidate;
                break;
            }
            lock (scope.sitesGate)
                if (scope.sites.Count < 64 || scope.sites.ContainsKey(site))
                {
                    scope.sites.TryGetValue(site, out var prior);
                    scope.sites[site] = (prior.Samples + 1, prior.Ticks + elapsed);
                }
        }
    }
    private object[] ReadSites()
    {
        lock (sitesGate) return sites.OrderByDescending(row => row.Value.Samples).Take(10).Select(row => (object)new
        { method = row.Key, samples = row.Value.Samples, nativeMilliseconds = (long)(row.Value.Ticks * 1000d / Stopwatch.Frequency) }).ToArray();
    }
    internal object Snapshot() => new
    {
        nativeProtects = Interlocked.Read(ref protects), nativeUnprotects = Interlocked.Read(ref unprotects),
        nativeProtectionMilliseconds = (long)(Interlocked.Read(ref ticks) * 1000d / Stopwatch.Frequency),
        sampledReadSites = ReadSites()
    };
    public void Dispose() { if (ReferenceEquals(Current.Value, this)) Current.Value = parent; }
}
