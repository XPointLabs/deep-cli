using System.Diagnostics;

namespace Deep.Cli;

// Numeric resource diagnostics only, not authority or retry decisions.
internal sealed class ProtectionWork : IDisposable
{
    private static readonly AsyncLocal<ProtectionWork?> Current = new();
    private readonly ProtectionWork? parent;
    private long protects, unprotects, ticks;
    private ProtectionWork() { parent = Current.Value; Current.Value = this; }
    internal static ProtectionWork Begin() => new();
    internal static void Record(bool protect, long started)
    {
        var scope = Current.Value; if (scope is null) return;
        if (protect) Interlocked.Increment(ref scope.protects); else Interlocked.Increment(ref scope.unprotects);
        Interlocked.Add(ref scope.ticks, Stopwatch.GetTimestamp() - started);
    }
    internal object Snapshot() => new
    {
        nativeProtects = Interlocked.Read(ref protects), nativeUnprotects = Interlocked.Read(ref unprotects),
        nativeProtectionMilliseconds = (long)(Interlocked.Read(ref ticks) * 1000d / Stopwatch.Frequency)
    };
    public void Dispose() { if (ReferenceEquals(Current.Value, this)) Current.Value = parent; }
}
