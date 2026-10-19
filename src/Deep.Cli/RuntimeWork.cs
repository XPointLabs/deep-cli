using System.Runtime;

namespace Deep.Cli;

// Closed numeric compiler diagnostics only. They cannot select authority,
// delivery/retry behavior, runtime configuration or a trusted clock.
internal sealed class RuntimeWork
{
    private readonly Reading before = Read();
    private readonly record struct Reading(bool Available, double Milliseconds, long Methods, long IlBytes);
    private static Reading Read()
    {
        try { return new(true, JitInfo.GetCompilationTime(false).TotalMilliseconds,
            JitInfo.GetCompiledMethodCount(false), JitInfo.GetCompiledILBytes(false)); }
        catch { return default; } // Diagnostic failure never changes a business outcome.
    }
    internal object Snapshot()
    {
        var after = Read(); var available = before.Available && after.Available;
        return new
        {
            available,
            jitCompilationMilliseconds = available ? Math.Max(0, after.Milliseconds - before.Milliseconds) : 0,
            jitCompiledMethods = available ? Math.Max(0, after.Methods - before.Methods) : 0,
            jitCompiledIlBytes = available ? Math.Max(0, after.IlBytes - before.IlBytes) : 0
        };
    }
}
