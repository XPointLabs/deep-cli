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
    private readonly Dictionary<int, StreamState> streams = new();
    private readonly List<Row> rows = new();
    private bool rejected;
    public bool Rejected { get { lock (gate) return rejected; } }
    public DeliveryEventController() : this(Stopwatch.GetTimestamp, Stopwatch.Frequency) { }
    internal DeliveryEventController(Func<long> clock, long frequency)
    { this.clock = clock; this.frequency = frequency; }

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
            if (!streams.TryGetValue(client, out var stream) || stream.Submitted >= 4096)
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
                        if (frame.Length >= 512) { lock (gate) rejected = true; oversized = true; frame.Clear(); }
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
            if (rejected) return;
            try
            {
                if (!streams.TryGetValue(client, out var stream) || frame.Length > 512)
                    throw new InvalidDataException();
                using var document = JsonDocument.Parse(frame, new JsonDocumentOptions { MaxDepth = 2 });
                var root = document.RootElement;
                if (root.ValueKind != JsonValueKind.Object) throw new InvalidDataException();
                var names = new HashSet<string>(StringComparer.Ordinal);
                foreach (var field in root.EnumerateObject())
                    if (!names.Add(field.Name) || field.Name is not ("schema" or "sequence" or "command" or "phase" or "messageHash" or "deliveryHash" or "dropped"))
                        throw new InvalidDataException();
                if (root.GetProperty("schema").GetString() != "deep.delivery.v1") throw new InvalidDataException();
                var sequence = root.GetProperty("sequence").GetInt64();
                var command = root.GetProperty("command").GetInt64();
                var phase = root.GetProperty("phase").GetString();
                var message = root.GetProperty("messageHash").GetString();
                var delivery = root.GetProperty("deliveryHash").GetString();
                if (stream.Closed || sequence != stream.Sequence + 1 || timestamp < stream.Timestamp) throw new InvalidDataException();
                if (phase == "StreamClosed")
                {
                    if (names.Count != 7 || command != 0 || message != "" || delivery != "" || root.GetProperty("dropped").GetInt64() != 0)
                        throw new InvalidDataException();
                    stream.Closed = true; stream.Sequence = sequence; stream.Timestamp = timestamp; return;
                }
                if (names.Count != 6 || names.Contains("dropped") || command <= 0 || rows.Count >= 4096) throw new InvalidDataException();
                if (phase == "CommandAccepted")
                {
                    if (command != stream.Command + 1 || message != "" || delivery != "") throw new InvalidDataException();
                    stream.Command = command;
                }
                else
                {
                    if (phase is not ("NativeOutboxDurable" or "StoreQuorum" or "RecipientDurableReadable") ||
                        command != stream.Command || !IsHash(message) || !IsHash(delivery) ||
                        !stream.Seen.Add(phase + ":" + message + ":" + delivery)) throw new InvalidDataException();
                    if (phase == "StoreQuorum" && !stream.Seen.Contains("NativeOutboxDurable:" + message + ":" + delivery))
                        throw new InvalidDataException();
                }
                stream.Sequence = sequence; stream.Timestamp = timestamp;
                rows.Add(new Row(client, command, phase!, message!, delivery!, timestamp));
            }
            catch (Exception error) when (error is JsonException or InvalidDataException or InvalidOperationException or FormatException or OverflowException or KeyNotFoundException)
            { rejected = true; }
        }
    }

    private static bool IsHash(string? value) => value != null && value.Length == 64 && value.All(c => c is >= '0' and <= '9' or >= 'a' and <= 'f');

    public DeliverySample Sample(int sender, long command, int[] recipients)
    {
        lock (gate)
        {
            if (recipients == null || recipients.Length is < 1 or > 2 || recipients.Distinct().Count() != recipients.Length ||
                recipients.Any(role => role is < 1 or > 3 || role == sender)) throw new ArgumentException("Exact distinct recipient roles required.");
            var accepted = rows.SingleOrDefault(row => row.Client == sender && row.Command == command && row.Phase == "CommandAccepted");
            var outgoing = rows.Where(row => row.Client == sender && row.Command == command && row.Phase == "NativeOutboxDurable").ToArray();
            var hashes = outgoing.Select(row => row.MessageHash).Distinct(StringComparer.Ordinal).ToArray();
            if (rejected || streams.Values.Any(stream => !stream.Closed || !stream.Eof) || !streams.TryGetValue(sender, out var senderStream) ||
                !senderStream.Outcomes.TryGetValue(command, out var exitCode) || exitCode != 0 ||
                accepted == null || hashes.Length != 1 || outgoing.Length != recipients.Length ||
                outgoing.Select(row => row.DeliveryHash).Distinct(StringComparer.Ordinal).Count() != recipients.Length) return DeliverySample.Missing();
            var visible = recipients.Select(role => rows.Where(row => row.Client == role && row.MessageHash == hashes[0] &&
                row.Phase == "RecipientDurableReadable").ToArray()).ToArray();
            if (visible.Any(events => events.Length != 1 || events[0].Timestamp < accepted.Timestamp ||
                !outgoing.Any(row => row.DeliveryHash == events[0].DeliveryHash)) ||
                visible.Select(events => events[0].DeliveryHash).Distinct(StringComparer.Ordinal).Count() != recipients.Length) return DeliverySample.Missing();
            double Milliseconds(long ticks) => (ticks - accepted.Timestamp) * 1000.0 / frequency;
            var stores = rows.Where(row => row.Client == sender && row.Command == command && row.MessageHash == hashes[0] && row.Phase == "StoreQuorum").ToArray();
            if (stores.Length != recipients.Length || stores.Any(store => !outgoing.Any(row => row.DeliveryHash == store.DeliveryHash)))
                return DeliverySample.Missing();
            return new DeliverySample(true, Milliseconds(visible.Min(events => events[0].Timestamp)),
                Milliseconds(visible.Max(events => events[0].Timestamp)), Milliseconds(outgoing.Min(row => row.Timestamp)),
                Milliseconds(stores.Max(row => row.Timestamp)));
        }
    }

    public static double NearestRank(double[] samples, double percentile)
    {
        if (samples == null || samples.Length == 0 || !double.IsFinite(percentile) || percentile <= 0 || percentile > 1 ||
            samples.Any(value => double.IsNaN(value) || value < 0)) throw new ArgumentException("Measured samples required, including failures as positive infinity.");
        var sorted = samples.OrderBy(value => value).ToArray();
        return sorted[(int)Math.Ceiling(percentile * sorted.Length) - 1];
    }

    private sealed class StreamState
    {
        internal long Sequence, Command, Timestamp, Submitted;
        internal bool Closed, Eof;
        internal readonly HashSet<string> Seen = new(StringComparer.Ordinal);
        internal readonly Dictionary<long, int> Outcomes = new();
    }
    private sealed record Row(int Client, long Command, string Phase, string MessageHash, string DeliveryHash, long Timestamp);
}

public sealed record DeliverySample(bool Complete, double FirstRecipientMilliseconds, double AllRecipientsMilliseconds,
    double? NativeOutboxMilliseconds, double? AllStoresMilliseconds)
{
    internal static DeliverySample Missing() => new(false, double.PositiveInfinity, double.PositiveInfinity, null, null);
}
