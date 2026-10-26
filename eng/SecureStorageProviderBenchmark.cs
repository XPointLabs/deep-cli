using System;
using System.Buffers.Binary;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Deep.Client.Shared.Persistence;

namespace Deep.Cli.Engineering;

// The same source is compiled in separate fresh processes against each actual
// archived/current assembly. No aggregate implementation lives in this tool.
public static class SecureStorageProviderBenchmark
{
    public const int Warmups = 3, Measurements = 16, AtomicCycles = 4;
    public static int[] InventoryCapacities => new[] { 16, 256, 1024 };
    public static int PlannedRows => InventoryCapacities.Length * (1 + 2 * Warmups + 2 * Measurements + 2 * AtomicCycles);
    private static readonly string[] WorkFields =
    {
        "ManifestReads", "ManifestProtectedBytesRead", "ManifestPlaintextBytesDecoded", "ObjectReads",
        "ObjectCiphertextBytesRead", "ObjectPlaintextBytesDecrypted", "ManifestWrites", "ManifestProtectedBytesWritten",
        "ObjectWrites", "ObjectCiphertextBytesWritten", "CleanupTombstones", "UnprotectCalls", "ProtectCalls"
    };

    public static async Task<string> RunAsync(string provider, string runtimeDirectory, string temporaryRoot)
    {
        if (!OperatingSystem.IsWindows() || provider is not ("aggregate" or "manifest"))
            throw new ArgumentException("A closed Windows provider selection is required.");
        var factory = typeof(JournaledDeepSecureStorage).GetMethod("CreateNewAsync", BindingFlags.Static | BindingFlags.Public);
        var work = typeof(JournaledDeepSecureStorage).GetMethod("ReadWorkSnapshot", BindingFlags.Instance | BindingFlags.Public);
        if (provider == "manifest" ? factory is null || work is null : factory is not null || work is not null)
            throw new InvalidOperationException("Runtime does not match the declared provider.");
        var root = Path.GetFullPath(temporaryRoot);
        var temp = Path.GetFullPath(Path.GetTempPath()).TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar;
        if (!root.StartsWith(temp, StringComparison.OrdinalIgnoreCase) || Directory.Exists(root))
            throw new ArgumentException("A fresh owned temporary fixture is required.");
        Directory.CreateDirectory(root);
        var rows = new List<object>(); var setup = new List<object>(); var fixtureTotals = new List<object>(); var passed = false;
        var phase = "Setup"; var failure = "None";
        try
        {
            var cli = Assembly.LoadFrom(Path.Combine(runtimeDirectory, "deep.dll"));
            var protectorType = cli.GetType("Deep.Cli.WindowsProfile+CurrentUserProtector", throwOnError: true)!;
            foreach (var capacity in InventoryCapacities)
            {
                var path = Path.Combine(root, "inventory-" + capacity, "state.dss");
                Directory.CreateDirectory(Path.GetDirectoryName(path)!);
                var writes = CreateInventory(capacity);
                try
                {
                    phase = "CreateAndSeed";
                    var seedWatch = Stopwatch.StartNew();
                    using var seedProtector = CreateProtector(protectorType);
                    using (var seeded = await CreateAsync(path, seedProtector, factory).ConfigureAwait(false))
                        await seeded.WriteBatchAsync(writes).ConfigureAwait(false);
                    var seededCrypto = seedProtector.Snapshot();
                    setup.Add(new { inventoryCapacity = capacity, seededSlots = writes.Length,
                        seedMilliseconds = seedWatch.Elapsed.TotalMilliseconds, nativeUnprotectCalls = seededCrypto.NativeUnprotects,
                        protectorProtectCalls = seededCrypto.Protects, protectorEnvelopeBytesRead = seededCrypto.EnvelopeBytes,
                        protectorCiphertextBytesReturned = seededCrypto.CiphertextBytes,
                        committedFileLength = new FileInfo(path).Length });
                    // Every independent owner gets its own actual DPAPI adapter.
                    // Cold probes aggregate scalar counts only, never a shared
                    // protector, unwrapped key, plaintext or verified context.
                    using var protector = CreateProtector(protectorType);
                    using var store = new JournaledDeepSecureStorage(path, protector);
                    var probeSnapshots = new List<CryptoSnapshot>();
                    phase = "ColdAdmission";
                    await MeasureAsync("coldAdmission", false, 0, capacity, store, protector, work, rows,
                        () => CheckSingleAsync(store)).ConfigureAwait(false);
                    for (var iteration = 0; iteration < Warmups + Measurements; iteration++)
                    {
                        var warmup = iteration < Warmups;
                        phase = "SelectedRead";
                        await MeasureAsync("singleRead", warmup, iteration, capacity, store, protector, work, rows,
                            () => CheckSingleAsync(store)).ConfigureAwait(false);
                        await MeasureAsync("batchRead", warmup, iteration, capacity, store, protector, work, rows,
                            () => CheckBatchAsync(store)).ConfigureAwait(false);
                    }
                    for (var iteration = 0; iteration < AtomicCycles; iteration++)
                    {
                        phase = "AtomicMutation";
                        var expected = Counter((ulong)iteration); var next = Counter((ulong)iteration + 1);
                        await MeasureAsync("atomicRegisterAndDelete", false, iteration, capacity, store, protector, work, rows,
                            async () =>
                            {
                                Require(await store.CompareExchangeAndInsertAsync("guard", expected, next,
                                    new[] { new DeepSecureStorageWrite("insert-a", new byte[] { 11 }),
                                        new DeepSecureStorageWrite("insert-b", new byte[] { 12 }) }).ConfigureAwait(false));
                                Require(await store.CompareAndDeleteAsync("guard", next, new[] { "insert-a", "insert-b" }).ConfigureAwait(false));
                            }).ConfigureAwait(false);
                        phase = "ColdReopenAfterAtomic";
                        using var reopenedProtector = CreateProtector(protectorType);
                        using var reopened = new JournaledDeepSecureStorage(path, reopenedProtector);
                        await MeasureAsync("coldReopenAfterAtomic", false, iteration, capacity, reopened, reopenedProtector, work, rows,
                            async () =>
                            {
                                using var result = await reopened.ReadOwnedBatchAsync(new[] { "guard", "insert-a", "insert-b", "payload" }).ConfigureAwait(false);
                                Require(result[0] is not null && result[0]!.Use(value => value.SequenceEqual(next)));
                                Require(result[1] is null && result[2] is null);
                                Require(result[3] is not null && result[3]!.Use(value => value.Length == 1024 && value[0] == 7));
                            }).ConfigureAwait(false);
                        probeSnapshots.Add(reopenedProtector.Snapshot());
                        CryptographicOperations.ZeroMemory(expected); CryptographicOperations.ZeroMemory(next);
                    }
                    var scalarSnapshots = probeSnapshots.Concat(new[] { seededCrypto, protector.Snapshot() }).ToArray();
                    fixtureTotals.Add(new { inventoryCapacity = capacity, independentPlatformProtectors = scalarSnapshots.Length,
                        nativeUnprotectCalls = scalarSnapshots.Sum(value => value.NativeUnprotects),
                        protectorProtectCalls = scalarSnapshots.Sum(value => value.Protects),
                        protectorEnvelopeBytesRead = scalarSnapshots.Sum(value => value.EnvelopeBytes) });
                }
                finally
                {
                    foreach (var value in writes)
                        if (MemoryMarshal.TryGetArray(value.Value, out var array))
                            CryptographicOperations.ZeroMemory(array.AsSpan());
                }
            }
            Require(rows.Count == PlannedRows); passed = true;
        }
        catch (Exception error)
        {
            failure = error switch { OperationCanceledException => "Cancelled", CryptographicException => "AuthenticationRejected",
                IOException => "IoRejected", _ => "BenchmarkRejected" };
        }
        finally
        {
            // Only this newly created synthetic directory can be removed.
            if (!root.StartsWith(temp, StringComparison.OrdinalIgnoreCase) || root == temp.TrimEnd(Path.DirectorySeparatorChar))
                throw new InvalidOperationException("Disposable fixture escaped its temporary scope.");
            try { Directory.Delete(root, recursive: true); }
            catch { passed = false; failure = "FixtureCleanupRejected"; }
        }
        return JsonSerializer.Serialize(new { schema = "deep.cli.storage-provider-benchmark.v1", provider, passed,
            failurePhase = passed ? "None" : phase, failureCode = failure, plannedRows = PlannedRows, completedRows = rows.Count,
            warmupsPerReadOperation = Warmups, measuredReadsPerOperation = Measurements, atomicCyclesPerInventory = AtomicCycles,
            setup, fixtureTotals, rows, disposableSyntheticStores = true, retainedProfilesOpened = false,
            physicalDiskTrafficMeasured = false, networkTrafficMeasured = false, latencyQualified = false, releaseQualified = false });
    }

    private static DeepSecureStorageWrite[] CreateInventory(int capacity)
    {
        var result = new List<DeepSecureStorageWrite>
        {
            new("guard", Counter(0)), new("root", Enumerable.Repeat((byte)5, 32).ToArray()),
            new("payload", Enumerable.Repeat((byte)7, 1024).ToArray())
        };
        // Reserve two insertion slots so the declared 1024 cap remains exact.
        for (var index = result.Count; index < capacity - 2; index++)
            result.Add(new("unselected-" + index.ToString("D4"), Enumerable.Repeat((byte)9, 4096).ToArray()));
        return result.ToArray();
    }

    private static async Task<JournaledDeepSecureStorage> CreateAsync(string path, IDeepSecretProtector protector, MethodInfo? factory)
    {
        if (factory is null) return new JournaledDeepSecureStorage(path, protector); // Archived DSS1 binary only.
        var task = (Task)factory.Invoke(null, new object[] { path, protector, CancellationToken.None })!;
        await task.ConfigureAwait(false);
        return (JournaledDeepSecureStorage)task.GetType().GetProperty("Result")!.GetValue(task)!;
    }

    private static CountingProtector CreateProtector(Type type) =>
        new((IDeepSecretProtector)Activator.CreateInstance(type, nonPublic: true)!);

    private static async Task CheckSingleAsync(IDeepSecureStorage store)
    {
        using var result = await store.ReadOwnedAsync("root").ConfigureAwait(false);
        Require(result is not null && result.Use(value => value.Length == 32 && value[0] == 5));
    }

    private static async Task CheckBatchAsync(IDeepSecureStorage store)
    {
        using var result = await store.ReadOwnedBatchAsync(new[] { "root", "payload", "absent" }).ConfigureAwait(false);
        Require(result.Count == 3 && result[0] is not null && result[0]!.Use(value => value.Length == 32 && value[0] == 5));
        Require(result[1] is not null && result[1]!.Use(value => value.Length == 1024 && value[0] == 7) && result[2] is null);
    }

    private static async Task MeasureAsync(string operation, bool warmup, int iteration, int capacity,
        JournaledDeepSecureStorage store, CountingProtector protector, MethodInfo? work, List<object> rows, Func<Task> action)
    {
        var before = ReadWork(store, work); var cryptoBefore = protector.Snapshot();
        var allocations = GC.GetTotalAllocatedBytes(precise: true);
        using var process = Process.GetCurrentProcess(); var cpu = process.TotalProcessorTime.TotalMilliseconds;
        var started = Stopwatch.GetTimestamp(); var success = false;
        try { await action().ConfigureAwait(false); success = true; }
        finally
        {
            var elapsed = Stopwatch.GetElapsedTime(started).TotalMilliseconds;
            process.Refresh(); var processor = process.TotalProcessorTime.TotalMilliseconds - cpu;
            var allocated = GC.GetTotalAllocatedBytes(precise: true) - allocations;
            var after = ReadWork(store, work); var crypto = protector.Snapshot().Subtract(cryptoBefore);
            var storage = after is null || before is null ? null : after.Zip(before, (a, b) => checked(a - b)).ToArray();
            var readAdmission = operation is "singleRead" or "batchRead";
            var admissionCountsMatch = !readAdmission ||
                (crypto.NativeUnprotects == 1 && crypto.Unprotects == 1 &&
                 (storage is null || storage[0] > 0 && storage[1] > 0 && storage[11] == 1 &&
                  storage[3] == (operation == "singleRead" ? 1 : 2)));
            success &= admissionCountsMatch;
            rows.Add(new { operation, warmup, iteration, inventoryCapacity = capacity, success,
                admissionCountsMatch,
                wallMilliseconds = elapsed, processorMilliseconds = processor, allocatedBytes = allocated,
                protectorUnprotectCalls = crypto.Unprotects, protectorProtectCalls = crypto.Protects,
                nativeUnprotectCalls = crypto.NativeUnprotects, protectorEnvelopeBytesRead = crypto.EnvelopeBytes,
                protectorPlaintextBytesReturned = crypto.PlaintextBytes, protectorCiphertextBytesReturned = crypto.CiphertextBytes,
                ownerWorkFields = storage is null ? null : WorkFields, ownerWork = storage,
                // For archived DSS1 Load, each actual ReadAllBytes result is the
                // exact input to this wrapper. DSS2 counts actual owner I/O.
                managedStorageBytesRead = storage is null ? crypto.EnvelopeBytes : checked(storage[1] + storage[4]),
                managedStorageBytesWritten = storage is null ? (long?)null : checked(storage[7] + storage[9]) });
            if (!admissionCountsMatch) throw new InvalidOperationException("Selected admission performed unexpected provider work.");
        }
    }

    private static long[]? ReadWork(JournaledDeepSecureStorage store, MethodInfo? method)
    {
        if (method is null) return null;
        var snapshot = method.Invoke(store, null)!;
        return WorkFields.Select(name => (long)snapshot.GetType().GetProperty(name)!.GetValue(snapshot)!).ToArray();
    }
    private static byte[] Counter(ulong value)
    { var bytes = new byte[8]; BinaryPrimitives.WriteUInt64BigEndian(bytes, value); return bytes; }
    private static void Require(bool condition)
    { if (!condition) throw new InvalidOperationException("Synthetic storage contract differs."); }

    private readonly record struct CryptoSnapshot(long Protects, long Unprotects, long NativeUnprotects,
        long EnvelopeBytes, long PlaintextBytes, long CiphertextBytes)
    {
        internal CryptoSnapshot Subtract(CryptoSnapshot before) => new(Protects - before.Protects,
            Unprotects - before.Unprotects, NativeUnprotects - before.NativeUnprotects,
            EnvelopeBytes - before.EnvelopeBytes, PlaintextBytes - before.PlaintextBytes, CiphertextBytes - before.CiphertextBytes);
    }
    private sealed class CountingProtector(IDeepSecretProtector inner) : IDeepSecretProtector, IDisposable
    {
        private long protects, unprotects, envelopeBytes, plaintextBytes, ciphertextBytes;
        private int disposed;
        private readonly PropertyInfo nativeUnprotects = inner.GetType().GetProperty("NativeUnprotects", BindingFlags.Instance | BindingFlags.NonPublic)!;
        public byte[] Protect(ReadOnlySpan<byte> plaintext)
        { protects++; var result = inner.Protect(plaintext); ciphertextBytes += result.Length; return result; }
        public byte[] Unprotect(ReadOnlySpan<byte> bytes)
        { unprotects++; envelopeBytes += bytes.Length; var result = inner.Unprotect(bytes); plaintextBytes += result.Length; return result; }
        internal CryptoSnapshot Snapshot() => new(protects, unprotects, (long)nativeUnprotects.GetValue(inner)!, envelopeBytes, plaintextBytes, ciphertextBytes);
        public void Dispose() { if (Interlocked.Exchange(ref disposed, 1) == 0) ((IDisposable)inner).Dispose(); }
    }
}
