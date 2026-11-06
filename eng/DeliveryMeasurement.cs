#nullable enable
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

namespace Deep.Cli.Measurement;

// Controller-only reader, shared by the real stdio harness and its tests.
// Every timestamp comes from this controller, when a complete event arrives.
public sealed class DeliveryEventController
{
    private readonly object gate = new();
    private readonly Func<long> clock;
    private readonly long frequency;
    private readonly int maximumEvents;
    private readonly Dictionary<int, StreamState> streams = new();
    private readonly List<Row> rows = new();
    private readonly Dictionary<(int Sender, long Command, int Recipient), long> historyReads = new();
    private readonly Dictionary<(int Sender, long Admission), long> dispatches = new();
    private bool rejected;
    private string? firstRejectionCode;
    public string FirstRejectionCode { get { lock (gate) return firstRejectionCode ?? (rejected ? "NonFrameRejection" : "None"); } }
    public bool Rejected { get { lock (gate) return rejected; } }
    public int MaximumEvents => maximumEvents;
    public bool HasCommandAdmission(int client, long command)
    { lock (gate) return rows.Any(row => row.Client == client && row.Command == command && row.Phase == "CommandAccepted"); }
    public DeliveryEventController() : this(Stopwatch.GetTimestamp, Stopwatch.Frequency) { }
    public DeliveryEventController(int maximumEvents) : this(Stopwatch.GetTimestamp, Stopwatch.Frequency, maximumEvents) { }
    internal DeliveryEventController(Func<long> clock, long frequency, int maximumEvents = 4096)
    {
        if (maximumEvents is < 1 or > 100000) throw new ArgumentOutOfRangeException(nameof(maximumEvents));
        this.clock = clock; this.frequency = frequency; this.maximumEvents = maximumEvents;
    }

    public Task Attach(int client, TextReader reader)
    {
        Register(client);
        return PumpAsync(client, reader);
    }

    internal void Register(int client)
    {
        lock (gate)
        {
            if (client is < 1 or > 3 || streams.ContainsKey(client)) throw new ArgumentException("Distinct bounded controller role required.");
            streams.Add(client, new StreamState());
        }
    }

    public long BeginCommand(int client)
    {
        lock (gate)
        {
            if (!streams.TryGetValue(client, out var stream) || stream.Submitted >= maximumEvents)
                throw new ArgumentException("Attached bounded controller role required.");
            return ++stream.Submitted;
        }
    }

    public void CompleteCommand(int client, long command, int exitCode)
    {
        lock (gate)
        {
            if (!streams.TryGetValue(client, out var stream) || command <= 0 || command > stream.Submitted ||
                !stream.Outcomes.TryAdd(command, exitCode)) rejected = true;
            else stream.CompletedAt.Add(command, clock());
        }
    }

    // Ordinary direct CLI authoring has two public commands. Queue admission is
    // t0; the exact returned operation is dispatched by the later send command.
    // Only ordinals enter this controller, never the operation or message text.
    public void BindDirectDispatch(int sender, long admissionCommand, long dispatchCommand)
    {
        lock (gate)
        {
            if (!streams.TryGetValue(sender, out var stream) || admissionCommand <= 0 ||
                dispatchCommand <= admissionCommand || dispatchCommand > stream.Submitted ||
                !stream.Outcomes.TryGetValue(admissionCommand, out var exit) || exit != 0 ||
                dispatches.Count >= maximumEvents || dispatches.Any(pair => pair.Key.Sender == sender && pair.Value == dispatchCommand) ||
                !dispatches.TryAdd((sender, admissionCommand), dispatchCommand)) rejected = true;
        }
    }

    private long DispatchCommand(int sender, long admissionCommand) =>
        dispatches.TryGetValue((sender, admissionCommand), out var dispatch) ? dispatch : admissionCommand;

    // Called only after the normal group-messages result contains exactly the
    // planned text/sequence/remote-author tuple. No payload enters this reader.
    public void RecordHistoryRead(int sender, long command, int recipient, long readCommand)
    {
        lock (gate)
        {
            if (sender is < 1 or > 3 || recipient is < 1 or > 3 || sender == recipient || command <= 0 ||
                !streams.TryGetValue(sender, out var senderStream) || command > senderStream.Submitted || historyReads.Count >= maximumEvents ||
                !streams.TryGetValue(recipient, out var stream) ||
                !stream.Outcomes.TryGetValue(readCommand, out var exit) || exit != 0 ||
                !historyReads.TryAdd((sender, command, recipient), readCommand)) rejected = true;
        }
    }

    public double HistoryReadMilliseconds(int sender, long command, int[] recipients, int recipient)
    {
        lock (gate)
        {
            if (!recipients.Contains(recipient) || !Sample(sender, command, recipients).Complete) return double.PositiveInfinity;
            return ObservedHistoryReadMilliseconds(sender, command, recipient);
        }
    }

    // The ordinary read result is independently correlated by the harness in
    // RAM before RecordHistoryRead. Background inbox maintenance can persist the
    // envelope outside a foreground diagnostic scope, so its visibility event is
    // not a prerequisite for this actual admission-to-return measurement.
    // This API does not certify Store, ACK, duplicate absence or recovery: the
    // driver must require those separately for a finite first-attempt sample.
    public double ValidatedHistoryReadMilliseconds(int sender, long command, int recipient)
        => ValidatedHistoryReadMillisecondsCore(sender, command, recipient, requireSuccessfulAdmission: true);

    public double ObservedValidatedHistoryReadMilliseconds(int sender, long command, int recipient)
        => ValidatedHistoryReadMillisecondsCore(sender, command, recipient, requireSuccessfulAdmission: false);

    private double ValidatedHistoryReadMillisecondsCore(int sender, long command, int recipient, bool requireSuccessfulAdmission)
    {
        lock (gate)
        {
            if (rejected || sender == recipient || streams.Values.Any(stream => !stream.Closed || !stream.Eof) ||
                !streams.TryGetValue(sender, out var source) ||
                !source.Outcomes.TryGetValue(command, out var sourceExit) || requireSuccessfulAdmission && sourceExit != 0 ||
                !historyReads.TryGetValue((sender, command, recipient), out var readCommand) ||
                !streams.TryGetValue(recipient, out var target) ||
                !target.Outcomes.TryGetValue(readCommand, out var readExit) || readExit != 0) return double.PositiveInfinity;
            var accepted = rows.SingleOrDefault(row => row.Client == sender && row.Command == command && row.Phase == "CommandAccepted");
            var read = rows.SingleOrDefault(row => row.Client == recipient && row.Command == readCommand && row.Phase == "CommandAccepted");
            var completed = target.CompletedAt[readCommand];
            return accepted is null || read is null || read.Timestamp < accepted.Timestamp || completed < read.Timestamp
                ? double.PositiveInfinity : (completed - accepted.Timestamp) * 1000.0 / frequency;
        }
    }

    // Diagnostic evidence survives a failed sender/ACK outcome, while Sample and
    // HistoryReadMilliseconds retain their strict first-attempt qualification.
    public double ObservedHistoryReadMilliseconds(int sender, long command, int recipient)
    {
        lock (gate)
        {
            if (rejected || streams.Values.Any(stream => !stream.Closed || !stream.Eof) ||
                !historyReads.TryGetValue((sender, command, recipient), out var readCommand)) return double.PositiveInfinity;
            var dispatch = DispatchCommand(sender, command);
            var outgoing = rows.Where(row => row.Client == sender && row.Command == dispatch && row.Phase == "NativeOutboxDurable").ToArray();
            if (outgoing.Length is < 1 or > 2 || outgoing.Select(row => row.MessageHash).Distinct().Count() != 1) return double.PositiveInfinity;
            var visibleRows = rows.Where(row => row.Client == recipient && row.MessageHash == outgoing[0].MessageHash &&
                row.Phase == "RecipientDurableReadable").ToArray();
            if (visibleRows.Length != 1 || !outgoing.Any(row => row.DeliveryHash == visibleRows[0].DeliveryHash)) return double.PositiveInfinity;
            var accepted = rows.Single(row => row.Client == sender && row.Command == command && row.Phase == "CommandAccepted");
            var visible = visibleRows[0];
            var read = rows.SingleOrDefault(row => row.Client == recipient && row.Command == readCommand && row.Phase == "CommandAccepted");
            var completed = streams[recipient].CompletedAt[readCommand];
            return read is null || visible.Timestamp < accepted.Timestamp || read.Timestamp < visible.Timestamp || completed < read.Timestamp
                ? double.PositiveInfinity : (completed - accepted.Timestamp) * 1000.0 / frequency;
        }
    }

    private async Task PumpAsync(int client, TextReader reader)
    {
        var buffer = new char[256]; var frame = new StringBuilder(); var oversized = false;
        try
        {
            int count;
            while ((count = await reader.ReadAsync(buffer, 0, buffer.Length).ConfigureAwait(false)) != 0)
                for (var i = 0; i < count; i++)
                {
                    if (buffer[i] == '\n')
                    {
                        if (!oversized) ObserveFrame(client, frame.ToString());
                        frame.Clear(); oversized = false;
                    }
                    else if (!oversized)
                    {
                        if (frame.Length >= 32768) { lock (gate) rejected = true; oversized = true; frame.Clear(); }
                        else frame.Append(buffer[i]);
                    }
                }
            lock (gate) if (frame.Length != 0 || oversized) rejected = true;
            EndInput(client);
        }
        catch (IOException) { lock (gate) rejected = true; }
        catch (ObjectDisposedException) { lock (gate) rejected = true; }
    }

    internal void EndInput(int client)
    {
        lock (gate)
        {
            streams[client].Eof = true;
            if (!streams[client].Closed) rejected = true;
        }
    }

    internal void ObserveFrame(int client, string frame)
    {
        lock (gate)
        {
            // Timestamp before parsing. No source-process/wall-clock timestamps
            // or response completion times participate in the measured path.
            var timestamp = clock();
            var closedPhase = "Unknown";
            try
            {
                if (!streams.TryGetValue(client, out var stream) || frame.Length > 32768)
                    throw new InvalidDataException();
                stream.Frames++;
                using var document = JsonDocument.Parse(frame, new JsonDocumentOptions { MaxDepth = 6 });
                var root = document.RootElement;
                if (root.ValueKind != JsonValueKind.Object) throw new InvalidDataException();
                var names = new HashSet<string>(StringComparer.Ordinal);
                foreach (var field in root.EnumerateObject())
                    if (!names.Add(field.Name))
                        throw new InvalidDataException();
                if (root.GetProperty("schema").GetString() == "deep.maintenance.v1")
                {
                    closedPhase = "Maintenance"; ObserveMaintenance(stream, root, names); return;
                }
                if (frame.Length > 512 || names.Any(name => name is not ("schema" or "sequence" or "command" or "phase" or "messageHash" or "deliveryHash" or "dropped")))
                    throw new InvalidDataException();
                if (root.GetProperty("schema").GetString() != "deep.delivery.v1") throw new InvalidDataException();
                var sequence = root.GetProperty("sequence").GetInt64();
                var command = root.GetProperty("command").GetInt64();
                var phase = root.GetProperty("phase").GetString();
                if (phase is "CommandAccepted" or "NativeOutboxDurable" or "StoreQuorum" or "RecipientDurableReadable" or "StreamClosed") closedPhase = phase;
                var message = root.GetProperty("messageHash").GetString();
                var delivery = root.GetProperty("deliveryHash").GetString();
                if (phase == "StreamClosed")
                {
                    var dropped = root.GetProperty("dropped").GetInt64();
                    if (names.Count != 7 || command != 0 || message != "" || delivery != "" || sequence <= 0 || dropped < 0 || dropped >= sequence)
                        throw new InvalidDataException();
                    stream.TerminalSeen = true; stream.ReportedDropped = dropped; stream.ReportedSequence = sequence;
                    if (rejected) return; // Keep closed loss diagnostics without restoring qualification.
                    if (stream.Closed || stream.MaintenanceActive || dropped != 0 || sequence != stream.Sequence + 1 || timestamp < stream.Timestamp)
                        throw new InvalidDataException();
                    stream.Closed = true; stream.Sequence = sequence; stream.Timestamp = timestamp; return;
                }
                if (rejected) return;
                if (stream.Closed || sequence != stream.Sequence + 1 || timestamp < stream.Timestamp) throw new InvalidDataException();
                if (names.Count != 6 || names.Contains("dropped") || command <= 0 || rows.Count >= maximumEvents) throw new InvalidDataException();
                if (phase == "CommandAccepted")
                {
                    if (command != stream.Command + 1 || message != "" || delivery != "") throw new InvalidDataException();
                    stream.Command = command;
                }
                else
                {
                    if (phase is not ("NativeOutboxDurable" or "StoreQuorum" or "RecipientDurableReadable") ||
                        command != stream.Command || !IsHash(message) || !IsHash(delivery) ||
                        !stream.Seen.Add(command + ":" + phase + ":" + message + ":" + delivery)) throw new InvalidDataException();
                    // A later, explicitly recorded recovery command can observe
                    // the same original envelope. A duplicate transition within
                    // one command still rejects the stream; recovery is never
                    // folded into a first-attempt latency sample.
                    if (phase == "NativeOutboxDurable") stream.Outboxes.Add(message + ":" + delivery);
                    // Exact-original resume may emit Store without repeating its
                    // earlier durable-outbox transition. It must still match an
                    // actually observed prior outbox on this same client stream.
                    if (phase == "StoreQuorum" && !stream.Outboxes.Contains(message + ":" + delivery))
                        throw new InvalidDataException();
                }
                stream.Sequence = sequence; stream.Timestamp = timestamp;
                rows.Add(new Row(client, command, phase!, message!, delivery!, timestamp));
            }
            catch (Exception error) when (error is JsonException or InvalidDataException or InvalidOperationException or FormatException or OverflowException or KeyNotFoundException)
            { firstRejectionCode ??= "Frame." + closedPhase + "." + error.GetType().Name; rejected = true; }
        }
    }

    private void ObserveMaintenance(StreamState stream, JsonElement root, HashSet<string> names)
    {
        if (stream.Closed || names.Count != 11 || names.Any(name => name is not
            ("schema" or "sequence" or "cycle" or "phase" or "acceptedContacts" or "controlsStored" or "deferredContacts" or "reintroductions" or "processedEnvelopes" or "hasMore" or "failure")) ||
            ++stream.MaintenanceFrames > maximumEvents) throw new InvalidDataException();
        var sequence = root.GetProperty("sequence").GetInt64();
        var cycle = root.GetProperty("cycle").GetInt64();
        var phase = root.GetProperty("phase").GetString();
        var counts = new[] { "acceptedContacts", "controlsStored", "deferredContacts", "reintroductions", "processedEnvelopes" }
            .Select(name => root.GetProperty(name).GetInt64()).ToArray();
        var hasMore = root.GetProperty("hasMore").GetBoolean();
        var failure = root.GetProperty("failure");
        if (phase != "Completed" && (counts.Any(count => count != 0) || hasMore) || phase != "Failed" && failure.ValueKind != JsonValueKind.Null) throw new InvalidDataException();
        if (phase == "Failed") stream.LastMaintenanceFailure = ValidateMaintenanceFailure(failure);
        if (sequence != stream.MaintenanceSequence + 1 || counts.Any(count => count is < 0 or > 65536)) throw new InvalidDataException();
        if (phase == "Started")
        {
            if (stream.MaintenanceActive || cycle != stream.MaintenanceCycle + 1 || counts.Any(count => count != 0)) throw new InvalidDataException();
            stream.MaintenanceActive = true; stream.MaintenanceCycle = cycle;
        }
        else
        {
            if (!stream.MaintenanceActive || cycle != stream.MaintenanceCycle || phase is not ("Completed" or "Cancelled" or "Failed")) throw new InvalidDataException();
            if (phase != "Completed" && counts.Any(count => count != 0)) throw new InvalidDataException();
            if (phase == "Completed") { stream.CompletedMaintenance++; stream.LastMaintenanceCounts = counts; stream.LastMaintenanceHasMore = hasMore; }
            else if (phase == "Cancelled") stream.CancelledMaintenance++;
            else stream.FailedMaintenance++;
            stream.MaintenanceActive = false;
        }
        stream.MaintenanceSequence = sequence;
    }

    private static readonly HashSet<string> MaintenanceCategories = new(StringComparer.Ordinal)
    { "OutcomeUnknown", "ContactRetryExpired", "Timeout", "ProtectedState", "HttpFailure", "DirectoryRateLimited", "DirectoryUnavailable", "IoFailure", "InvalidState", "Cancelled", "OperationRejected", "ProtocolRejected", "InvalidInput", "Other", "IngressRetryableBeforeForward", "IngressRejectedBeforeForward" };
    private static readonly HashSet<string> MaintenanceChecks = CreateMaintenanceChecks();
    private static HashSet<string> CreateMaintenanceChecks()
    {
        var result = new HashSet<string>(StringComparer.Ordinal) { "Unclassified", "PreKeysUnavailable" };
        void Add(string prefix, params string[] suffixes) { foreach (var suffix in suffixes) result.Add(prefix + suffix); }
        Add("GroupControl", "Expired", "RateLimited", "StaleView", "Conflict", "OutcomeUnknown", "SizeFailure", "RecordTooLarge");
        Add("RouteContext", "NetworkAuthority", "RecipientNetwork", "ViewAuthority", "HeadAuthority", "DirectoryAuthority", "TimeAuthority", "DirectoryWitnessPolicy", "TimeWitnessPolicy", "DirectoryHead", "ViewHash", "ViewGeneration", "ClockBoot", "ClockRegression", "ObservationExpiry");
        Add("HistoryAnnouncement", "FutureCreation", "ExpiredAnnouncement", "CreationOutsideSignedRoute");
        Add("Grant", "Lifecycle", "Network", "Membership", "Epoch", "Issuer", "Generation", "IssuerWindow", "RouteExpiry", "Lifetime", "Signature");
        Add("EndpointPair", "NetworkChanged", "DirectoryExpired", "DirectoryFloorAdvanced", "DirectoryExpiredBeforeHandoff");
        Add("RetainedRead", "GrantHorizon", "GrantOverlap", "RequestInterval", "GrantStart", "ResponseDeadline", "IssuedBeforeRequest", "IssuedAfterRequest", "IssuedAfterCurrentUpper");
        Add("Ingress", "MalformedFrame", "WrongOrigin", "Saturated", "Unavailable");
        Add("Claim", "Expired", "StaleBundle", "RateLimited", "Conflict", "OutcomeUnknown");
        foreach (var artifact in new[] { "XNA1", "XNV1", "XNH1", "ADH1", "DeviceCertificate", "DCA1", "PMT2", "XRA1", "PMS2", "XRC1", "XSS1", "XIR1V2", "XRR1", "ThresholdAuthoring", "ResolveRequest" })
            Add("RouteTime" + artifact, "InvalidInterval", "NotBefore", "Expiry");
        return result;
    }
    private static void ClosedNames(JsonElement value, params string[] names)
    {
        if (value.ValueKind != JsonValueKind.Object) throw new InvalidDataException();
        var seen = new HashSet<string>(StringComparer.Ordinal);
        foreach (var field in value.EnumerateObject()) if (!seen.Add(field.Name) || !names.Contains(field.Name, StringComparer.Ordinal)) throw new InvalidDataException();
        if (seen.Count != names.Length) throw new InvalidDataException();
    }
    private static void MaintenanceLocation(JsonElement value)
    {
        var method = value.GetProperty("method").GetString();
        var il = value.GetProperty("il").GetInt64();
        if (method is null || method.Length > 240 || il is < -1 or > 1048575 ||
            method != "Unavailable" && !System.Text.RegularExpressions.Regex.IsMatch(method, @"\ADeep\.(?:Client\.Shared|Protocol)\.[A-Za-z0-9_.+<>`]+\z")) throw new InvalidDataException();
    }
    private static object ValidateMaintenanceFailure(JsonElement failure)
    {
        ClosedNames(failure, "phase", "causes");
        if (failure.GetProperty("phase").GetString() != "ContactMaintenance") throw new InvalidDataException();
        var causes = failure.GetProperty("causes");
        if (causes.ValueKind != JsonValueKind.Array || causes.GetArrayLength() is < 1 or > 8) throw new InvalidDataException();
        foreach (var cause in causes.EnumerateArray())
        {
            ClosedNames(cause, "category", "check", "method", "il", "trail");
            if (!MaintenanceCategories.Contains(cause.GetProperty("category").GetString()!) || !MaintenanceChecks.Contains(cause.GetProperty("check").GetString()!)) throw new InvalidDataException();
            MaintenanceLocation(cause);
            var trail = cause.GetProperty("trail");
            if (trail.ValueKind != JsonValueKind.Array || trail.GetArrayLength() > 8) throw new InvalidDataException();
            foreach (var frame in trail.EnumerateArray()) { ClosedNames(frame, "method", "il"); MaintenanceLocation(frame); }
        }
        return new { phase = failure.GetProperty("phase").GetString(), causes = causes.EnumerateArray().Select(cause => new { category = cause.GetProperty("category").GetString(), check = cause.GetProperty("check").GetString(), method = cause.GetProperty("method").GetString(), il = cause.GetProperty("il").GetInt64(), trail = cause.GetProperty("trail").EnumerateArray().Select(frame => new { method = frame.GetProperty("method").GetString(), il = frame.GetProperty("il").GetInt64() }).ToArray() }).ToArray() };
    }

    public object MaintenanceSummary()
    {
        lock (gate) return streams.OrderBy(pair => pair.Key).Select(pair => new
        {
            role = pair.Key, active = pair.Value.MaintenanceActive, cycle = pair.Value.MaintenanceCycle,
            completed = pair.Value.CompletedMaintenance, cancelled = pair.Value.CancelledMaintenance, failed = pair.Value.FailedMaintenance,
            frames = pair.Value.MaintenanceFrames, acceptedContacts = pair.Value.LastMaintenanceCounts[0],
            controlsStored = pair.Value.LastMaintenanceCounts[1], deferredContacts = pair.Value.LastMaintenanceCounts[2],
            reintroductions = pair.Value.LastMaintenanceCounts[3], processedEnvelopes = pair.Value.LastMaintenanceCounts[4],
            hasMore = pair.Value.LastMaintenanceHasMore, lastFailure = pair.Value.LastMaintenanceFailure
        }).ToArray();
    }

    private static bool IsHash(string? value) => value != null && value.Length == 64 && value.All(c => c is >= '0' and <= '9' or >= 'a' and <= 'f');

    public DeliverySample Sample(int sender, long command, int[] recipients)
    {
        lock (gate)
        {
            if (recipients == null || recipients.Length is < 1 or > 2 || recipients.Distinct().Count() != recipients.Length ||
                recipients.Any(role => role is < 1 or > 3 || role == sender)) throw new ArgumentException("Exact distinct recipient roles required.");
            var accepted = rows.SingleOrDefault(row => row.Client == sender && row.Command == command && row.Phase == "CommandAccepted");
            var dispatch = DispatchCommand(sender, command);
            var outgoing = rows.Where(row => row.Client == sender && row.Command == dispatch && row.Phase == "NativeOutboxDurable").ToArray();
            var hashes = outgoing.Select(row => row.MessageHash).Distinct(StringComparer.Ordinal).ToArray();
            if (rejected || streams.Values.Any(stream => !stream.Closed || !stream.Eof) || !streams.TryGetValue(sender, out var senderStream) ||
                !senderStream.Outcomes.TryGetValue(command, out var exitCode) || exitCode != 0 ||
                !senderStream.Outcomes.TryGetValue(dispatch, out var dispatchExitCode) || dispatchExitCode != 0 ||
                accepted == null || hashes.Length != 1 || outgoing.Length != recipients.Length ||
                outgoing.Select(row => row.DeliveryHash).Distinct(StringComparer.Ordinal).Count() != recipients.Length) return DeliverySample.Missing();
            var visible = recipients.Select(role => rows.Where(row => row.Client == role && row.MessageHash == hashes[0] &&
                row.Phase == "RecipientDurableReadable").ToArray()).ToArray();
            if (visible.Any(events => events.Length != 1 || events[0].Timestamp < accepted.Timestamp ||
                !outgoing.Any(row => row.DeliveryHash == events[0].DeliveryHash)) ||
                visible.Select(events => events[0].DeliveryHash).Distinct(StringComparer.Ordinal).Count() != recipients.Length) return DeliverySample.Missing();
            double Milliseconds(long ticks) => (ticks - accepted.Timestamp) * 1000.0 / frequency;
            var stores = rows.Where(row => row.Client == sender && row.Command == dispatch && row.MessageHash == hashes[0] && row.Phase == "StoreQuorum").ToArray();
            if (stores.Length != recipients.Length || stores.Any(store => !outgoing.Any(row => row.DeliveryHash == store.DeliveryHash)))
                return DeliverySample.Missing();
            return new DeliverySample(true, Milliseconds(visible.Min(events => events[0].Timestamp)),
                Milliseconds(visible.Max(events => events[0].Timestamp)), Milliseconds(outgoing.Min(row => row.Timestamp)),
                Milliseconds(stores.Max(row => row.Timestamp)));
        }
    }

    // Progress only, never a finite sample or a product Delivered status. The
    // engineering driver uses this to stop successful bounded receive polling.
    public bool HasRecipientObservation(int sender, long command, int recipient)
    {
        lock (gate)
        {
            if (rejected) return false;
            var dispatch = DispatchCommand(sender, command);
            var hashes = rows.Where(row => row.Client == sender && row.Command == dispatch && row.Phase == "NativeOutboxDurable")
                .Select(row => row.MessageHash).Distinct(StringComparer.Ordinal).ToArray();
            return hashes.Length == 1 && rows.Any(row => row.Client == recipient && row.MessageHash == hashes[0] && row.Phase == "RecipientDurableReadable");
        }
    }

    public double RecipientMilliseconds(int sender, long command, int[] recipients, int recipient)
    {
        lock (gate)
        {
            if (!recipients.Contains(recipient) || !Sample(sender, command, recipients).Complete) return double.PositiveInfinity;
            var accepted = rows.Single(row => row.Client == sender && row.Command == command && row.Phase == "CommandAccepted");
            var dispatch = DispatchCommand(sender, command);
            var hash = rows.First(row => row.Client == sender && row.Command == dispatch && row.Phase == "NativeOutboxDurable").MessageHash;
            var visible = rows.Single(row => row.Client == recipient && row.MessageHash == hash && row.Phase == "RecipientDurableReadable");
            return (visible.Timestamp - accepted.Timestamp) * 1000.0 / frequency;
        }
    }

    public static double NearestRank(double[] samples, double percentile)
    {
        if (samples == null || samples.Length == 0 || !double.IsFinite(percentile) || percentile <= 0 || percentile > 1 ||
            samples.Any(value => double.IsNaN(value) || value < 0)) throw new ArgumentException("Measured samples required, including failures as positive infinity.");
        var sorted = samples.OrderBy(value => value).ToArray();
        return sorted[(int)Math.Ceiling(percentile * sorted.Length) - 1];
    }

    public object StreamSummary()
    {
        lock (gate) return streams.OrderBy(pair => pair.Key).Select(pair => new
        {
            role = pair.Key, receivedFrames = pair.Value.Frames, acceptedCommands = pair.Value.Command,
            recordedSequence = pair.Value.Sequence, terminalSeen = pair.Value.TerminalSeen,
            reportedSequence = pair.Value.ReportedSequence, dropped = pair.Value.ReportedDropped,
            closed = pair.Value.Closed, eof = pair.Value.Eof
        }).ToArray();
    }

    private sealed class StreamState
    {
        internal long Sequence, Command, Timestamp, Submitted, Frames;
        internal long MaintenanceSequence, MaintenanceCycle, MaintenanceFrames, CompletedMaintenance, CancelledMaintenance, FailedMaintenance;
        internal bool MaintenanceActive;
        internal long[] LastMaintenanceCounts = new long[5];
        internal bool LastMaintenanceHasMore;
        internal object? LastMaintenanceFailure;
        internal long? ReportedDropped, ReportedSequence;
        internal bool Closed, Eof, TerminalSeen;
        internal readonly HashSet<string> Seen = new(StringComparer.Ordinal);
        internal readonly HashSet<string> Outboxes = new(StringComparer.Ordinal);
        internal readonly Dictionary<long, int> Outcomes = new();
        internal readonly Dictionary<long, long> CompletedAt = new();
    }
    private sealed record Row(int Client, long Command, string Phase, string MessageHash, string DeliveryHash, long Timestamp);
}

public sealed record DeliverySample(bool Complete, double FirstRecipientMilliseconds, double AllRecipientsMilliseconds,
    double? NativeOutboxMilliseconds, double? AllStoresMilliseconds)
{
    internal static DeliverySample Missing() => new(false, double.PositiveInfinity, double.PositiveInfinity, null, null);
}
