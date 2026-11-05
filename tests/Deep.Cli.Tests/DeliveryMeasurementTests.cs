using System.Text.Json;
using Deep.Cli.Measurement;

namespace Deep.Cli.Tests;

public sealed class DeliveryMeasurementTests
{
    private static readonly string Message = new('a', 64), Left = new('b', 64), Right = new('c', 64);
    private static string Frame(long sequence, long command, string phase, string message = "", string delivery = "") =>
        JsonSerializer.Serialize(new { schema = "deep.delivery.v1", sequence, command, phase, messageHash = message, deliveryHash = delivery });
    private static string End(long sequence, long dropped = 0) => JsonSerializer.Serialize(new
        { schema = "deep.delivery.v1", sequence, command = 0, phase = "StreamClosed", messageHash = "", deliveryHash = "", dropped });
    private static Task Register(DeliveryEventController controller, params int[] roles)
    { foreach (var role in roles) controller.Register(role); return Task.CompletedTask; }
    private static void Close(DeliveryEventController controller, int role, long sequence)
    { controller.ObserveFrame(role, End(sequence)); controller.EndInput(role); }

    [Fact]
    public async Task ControllerMeasuresRealEventArrivalIndependentlyOfCommandAndAckCompletion()
    {
        long ticks = 1000;
        var controller = new DeliveryEventController(() => ticks, 1000);
        await Register(controller, 1, 2, 3);
        Assert.Equal(1, controller.BeginCommand(1));
        controller.ObserveFrame(1, Frame(1, 1, "CommandAccepted"));
        ticks += 10; controller.ObserveFrame(1, Frame(2, 1, "NativeOutboxDurable", Message, Left));
        ticks += 10; controller.ObserveFrame(1, Frame(3, 1, "NativeOutboxDurable", Message, Right));
        controller.ObserveFrame(2, Frame(1, 1, "CommandAccepted"));
        controller.ObserveFrame(3, Frame(1, 1, "CommandAccepted"));
        ticks += 30; controller.ObserveFrame(2, Frame(2, 1, "RecipientDurableReadable", Message, Left));
        ticks += 25; controller.ObserveFrame(3, Frame(2, 1, "RecipientDurableReadable", Message, Right));
        Assert.True(controller.HasRecipientObservation(1, 1, 2));
        Assert.True(controller.HasRecipientObservation(1, 1, 3));
        Assert.Equal(double.PositiveInfinity, controller.RecipientMilliseconds(1, 1, [2, 3], 2));
        var visibleBeforeStoreAndAck = controller.Sample(1, 1, [2, 3]);
        Assert.False(visibleBeforeStoreAndAck.Complete); // The sender outcome is still unknown.
        Assert.Null(visibleBeforeStoreAndAck.AllStoresMilliseconds);
        ticks += 1000; controller.ObserveFrame(1, Frame(4, 1, "StoreQuorum", Message, Left));
        controller.ObserveFrame(1, Frame(5, 1, "StoreQuorum", Message, Right));
        controller.CompleteCommand(1, 1, 0);
        Assert.False(controller.Sample(1, 1, [2, 3]).Complete); // Clean run closure is mandatory.
        controller.ObserveFrame(1, End(6)); controller.ObserveFrame(2, End(3)); controller.ObserveFrame(3, End(3));
        Assert.False(controller.Sample(1, 1, [2, 3]).Complete); // Terminal without actual EOF is insufficient.
        controller.EndInput(1); controller.EndInput(2); controller.EndInput(3);
        var completedStores = controller.Sample(1, 1, [2, 3]);
        Assert.True(completedStores.Complete);
        Assert.Equal(50, completedStores.FirstRecipientMilliseconds);
        Assert.Equal(75, completedStores.AllRecipientsMilliseconds);
        Assert.Equal(1075, completedStores.AllStoresMilliseconds);
        Assert.Equal(50, controller.RecipientMilliseconds(1, 1, [2, 3], 2));
        Assert.Equal(75, controller.RecipientMilliseconds(1, 1, [2, 3], 3));
        Assert.Equal(double.PositiveInfinity, controller.RecipientMilliseconds(1, 1, [2, 3], 1));
        Assert.False(controller.Rejected);
    }

    [Theory]
    [InlineData("unknown-field")]
    [InlineData("duplicate-field")]
    [InlineData("schema")]
    [InlineData("unknown-phase")]
    [InlineData("sequence-gap")]
    [InlineData("sequence-duplicate")]
    [InlineData("command-before-accept")]
    [InlineData("store-before-outbox")]
    [InlineData("invalid-hash")]
    [InlineData("duplicate-transition")]
    [InlineData("clock-rollback")]
    public async Task HostileOrOutOfOrderEventsPermanentlyRejectQualification(string defect)
    {
        long ticks = 1000;
        var controller = new DeliveryEventController(() => ticks, 1000);
        await Register(controller, 1);
        controller.ObserveFrame(1, Frame(1, 1, "CommandAccepted"));
        var frame = Frame(2, 1, "NativeOutboxDurable", Message, Left);
        switch (defect)
        {
            case "unknown-field": frame = frame[..^1] + ",\"payload\":\"forbidden\"}"; break;
            case "duplicate-field": frame = frame[..^1] + ",\"sequence\":2}"; break;
            case "schema": frame = frame.Replace("deep.delivery.v1", "deep.delivery.v2"); break;
            case "unknown-phase": frame = frame.Replace("NativeOutboxDurable", "Delivered"); break;
            case "sequence-gap": frame = Frame(3, 1, "NativeOutboxDurable", Message, Left); break;
            case "sequence-duplicate": frame = Frame(1, 1, "NativeOutboxDurable", Message, Left); break;
            case "command-before-accept": frame = Frame(2, 2, "NativeOutboxDurable", Message, Left); break;
            case "store-before-outbox": frame = Frame(2, 1, "StoreQuorum", Message, Left); break;
            case "invalid-hash": frame = Frame(2, 1, "NativeOutboxDurable", "private-address", Left); break;
            case "duplicate-transition": controller.ObserveFrame(1, frame); frame = Frame(3, 1, "NativeOutboxDurable", Message, Left); break;
            case "clock-rollback": ticks--; break;
        }
        controller.ObserveFrame(1, frame);
        Assert.True(controller.Rejected);
        Assert.Equal(double.PositiveInfinity, controller.Sample(1, 1, [2]).AllRecipientsMilliseconds);
    }

    [Theory]
    [InlineData(false)]
    [InlineData(true)]
    public async Task OversizedAndTruncatedEventStreamsAreBoundedAndRejected(bool oversized)
    {
        var controller = new DeliveryEventController();
        await controller.Attach(1, new StringReader(oversized ? new string(' ', 513) + "\n" : Frame(1, 1, "CommandAccepted")));
        Assert.True(controller.Rejected);
    }

    [Fact]
    public async Task StoreAndForeignSemanticEventsCannotStandInForDurableVisible()
    {
        var controller = new DeliveryEventController();
        await Register(controller, 1, 2);
        controller.BeginCommand(1); controller.CompleteCommand(1, 1, 0);
        controller.ObserveFrame(1, Frame(1, 1, "CommandAccepted"));
        controller.ObserveFrame(1, Frame(2, 1, "NativeOutboxDurable", Message, Left));
        controller.ObserveFrame(1, Frame(3, 1, "StoreQuorum", Message, Left));
        controller.ObserveFrame(2, Frame(1, 1, "CommandAccepted"));
        controller.ObserveFrame(2, Frame(2, 1, "RecipientDurableReadable", new string('f', 64), Left));
        Assert.False(controller.HasRecipientObservation(1, 1, 2));
        Close(controller, 1, 4); Close(controller, 2, 3);
        Assert.False(controller.Sample(1, 1, [2]).Complete);
        Assert.Equal(double.PositiveInfinity, controller.Sample(1, 1, [2]).FirstRecipientMilliseconds);
        Assert.False(controller.Rejected);
    }

    [Fact]
    public void NearestRankIncludesEveryTimeoutAndErrorAsInfinity()
    {
        var values = Enumerable.Range(1, 19).Select(i => (double)i).Append(double.PositiveInfinity).ToArray();
        Assert.Equal(19, DeliveryEventController.NearestRank(values, .95));
        Assert.Equal(double.PositiveInfinity, DeliveryEventController.NearestRank(values, .99));
        Assert.Equal(double.PositiveInfinity, DeliveryEventController.NearestRank([1, double.PositiveInfinity], .95));
    }

    [Fact]
    public async Task EventBoundCannotQualifyAnEarlierSuccessfulPrefixWithoutWholeRunClosure()
    {
        var controller = new DeliveryEventController();
        await Register(controller, 1, 2);
        controller.BeginCommand(1); controller.CompleteCommand(1, 1, 0);
        controller.ObserveFrame(1, Frame(1, 1, "CommandAccepted"));
        controller.ObserveFrame(1, Frame(2, 1, "NativeOutboxDurable", Message, Left));
        controller.ObserveFrame(1, Frame(3, 1, "StoreQuorum", Message, Left));
        controller.ObserveFrame(2, Frame(1, 1, "CommandAccepted"));
        controller.ObserveFrame(2, Frame(2, 1, "RecipientDurableReadable", Message, Left));
        Assert.False(controller.Sample(1, 1, [2]).Complete);
        for (var i = 2; i <= 4095; i++) controller.ObserveFrame(1, Frame(i + 2, i, "CommandAccepted"));
        Assert.True(controller.Rejected);
        Assert.Equal(double.PositiveInfinity, controller.Sample(1, 1, [2]).AllRecipientsMilliseconds);
    }

    [Fact]
    public async Task BrokenDiagnosticWriterDoesNotTurnAnAcceptedCommandIntoAFailure()
    {
        await using var diagnostics = new DeliveryDiagnostics(new BrokenWriter());
        using (diagnostics.AcceptCommand()) { }
    }

    [Theory]
    [InlineData(6)]
    [InlineData(130)]
    public async Task SenderErrorAndTimeoutRemainInfinityEvenIfRecipientBecameDurablyVisible(int exitCode)
    {
        var controller = new DeliveryEventController();
        await Register(controller, 1, 2);
        controller.BeginCommand(1);
        controller.ObserveFrame(1, Frame(1, 1, "CommandAccepted"));
        controller.ObserveFrame(1, Frame(2, 1, "NativeOutboxDurable", Message, Left));
        controller.ObserveFrame(1, Frame(3, 1, "StoreQuorum", Message, Left));
        controller.ObserveFrame(2, Frame(1, 1, "CommandAccepted"));
        controller.ObserveFrame(2, Frame(2, 1, "RecipientDurableReadable", Message, Left));
        controller.CompleteCommand(1, 1, exitCode);
        Close(controller, 1, 4); Close(controller, 2, 3);
        Assert.False(controller.Sample(1, 1, [2]).Complete);
        Assert.Equal(double.PositiveInfinity, controller.Sample(1, 1, [2]).AllRecipientsMilliseconds);
    }

    private sealed class BrokenWriter : StringWriter
    {
        public override Task WriteLineAsync(string? value) => Task.FromException(new IOException("Injected observation sink failure."));
    }

    [Fact]
    public async Task ExplicitBoundedBudgetSupportsTheDeclaredEngineeringPopulationWithoutChangingDefault()
    {
        Assert.Equal(4096, new DeliveryEventController().MaximumEvents);
        var controller = new DeliveryEventController(8192);
        await Register(controller, 1);
        for (var i = 1; i <= 5000; i++)
        {
            Assert.Equal(i, controller.BeginCommand(1));
            controller.ObserveFrame(1, Frame(i, i, "CommandAccepted"));
        }
        Close(controller, 1, 5001);
        Assert.False(controller.Rejected);
        using var summary = JsonDocument.Parse(JsonSerializer.Serialize(controller.StreamSummary()));
        Assert.Equal(5001, summary.RootElement[0].GetProperty("receivedFrames").GetInt64());
        Assert.Equal(0, summary.RootElement[0].GetProperty("dropped").GetInt64());
    }

    [Theory]
    [InlineData(0)]
    [InlineData(100001)]
    public void DiagnosticBudgetOutsideTheClosedHardBoundRejectsBeforeAttachingStreams(int maximumEvents) =>
        Assert.Throws<ArgumentOutOfRangeException>(() => new DeliveryEventController(maximumEvents));

    [Fact]
    public async Task ReceiverAckFailureDoesNotEraseAValidClosedDurableVisibleObservation()
    {
        var controller = new DeliveryEventController();
        await Register(controller, 1, 2);
        controller.BeginCommand(1); controller.BeginCommand(2);
        controller.ObserveFrame(1, Frame(1, 1, "CommandAccepted"));
        controller.ObserveFrame(1, Frame(2, 1, "NativeOutboxDurable", Message, Left));
        controller.ObserveFrame(1, Frame(3, 1, "StoreQuorum", Message, Left));
        controller.ObserveFrame(2, Frame(1, 1, "CommandAccepted"));
        controller.ObserveFrame(2, Frame(2, 1, "RecipientDurableReadable", Message, Left));
        controller.CompleteCommand(1, 1, 0); controller.CompleteCommand(2, 1, 6);
        Close(controller, 1, 4); Close(controller, 2, 3);
        Assert.True(controller.Sample(1, 1, [2]).Complete);
        Assert.True(double.IsFinite(controller.RecipientMilliseconds(1, 1, [2], 2)));
    }

    [Theory]
    [InlineData("none")]
    [InlineData("missing")]
    [InlineData("failed-read")]
    [InlineData("wrong-send")]
    [InlineData("wrong-read")]
    [InlineData("before-visible")]
    [InlineData("duplicate")]
    [InlineData("stream-failure")]
    public async Task OrdinaryHistoryResultUsesControllerCompletionAndRequiresExactClosedCorrelation(string defect)
    {
        long ticks = 1000;
        var controller = new DeliveryEventController(() => ticks, 1000);
        await Register(controller, 1, 2);
        controller.BeginCommand(1); controller.BeginCommand(2);
        controller.ObserveFrame(1, Frame(1, 1, "CommandAccepted"));
        controller.ObserveFrame(1, Frame(2, 1, "NativeOutboxDurable", Message, Left));
        controller.ObserveFrame(1, Frame(3, 1, "StoreQuorum", Message, Left));
        controller.CompleteCommand(1, 1, 0);
        controller.ObserveFrame(2, Frame(1, 1, "CommandAccepted"));
        ticks = 1010;
        if (defect != "before-visible") controller.ObserveFrame(2, Frame(2, 1, "RecipientDurableReadable", Message, Left));
        ticks = 1020; controller.CompleteCommand(2, 1, 0); // ACK result is not the read result.
        Assert.Equal(2, controller.BeginCommand(2));
        controller.ObserveFrame(2, Frame(defect == "before-visible" ? 2 : 3, 2, "CommandAccepted"));
        if (defect == "before-visible")
        {
            ticks = 1030;
            controller.ObserveFrame(2, Frame(3, 2, "RecipientDurableReadable", Message, Left));
        }
        ticks = 1050; controller.CompleteCommand(2, 2, defect == "failed-read" ? 6 : 0);
        if (defect != "missing")
            controller.RecordHistoryRead(1, defect == "wrong-send" ? 2 : 1, 2, defect == "wrong-read" ? 3 : 2);
        if (defect == "duplicate") controller.RecordHistoryRead(1, 1, 2, 2);
        Assert.Equal(double.PositiveInfinity, controller.HistoryReadMilliseconds(1, 1, [2], 2));
        ticks = 10000; // Final reporting must not become the measured timestamp.
        Close(controller, 1, 4);
        controller.ObserveFrame(2, End(4, defect == "stream-failure" ? 1 : 0)); controller.EndInput(2);
        Assert.Equal(defect == "none" ? 50 : double.PositiveInfinity,
            controller.HistoryReadMilliseconds(1, 1, [2], 2));
        if (defect == "none")
        {
            Assert.Equal(10, controller.RecipientMilliseconds(1, 1, [2], 2));
            Assert.Equal(double.PositiveInfinity, controller.HistoryReadMilliseconds(1, 1, [2], 1));
            Assert.False(controller.Rejected);
        }
    }

    [Fact]
    public async Task CompleteFramesWithoutMandatoryTerminalCannotQualify()
    {
        var controller = new DeliveryEventController();
        await controller.Attach(1, new StringReader(Frame(1, 1, "CommandAccepted") + "\n"));
        Assert.True(controller.Rejected);
    }

    [Theory]
    [InlineData(0, true)]
    [InlineData(6, true)]
    [InlineData(0, false)]
    public async Task OrdinaryReadObservationSurvivesFailedSenderOrMissingStoreWithoutQualifying(int senderExit, bool store)
    {
        long ticks = 1000;
        var controller = new DeliveryEventController(() => ticks, 1000);
        await Register(controller, 1, 2);
        controller.BeginCommand(1); controller.BeginCommand(2);
        controller.ObserveFrame(1, Frame(1, 1, "CommandAccepted"));
        controller.ObserveFrame(1, Frame(2, 1, "NativeOutboxDurable", Message, Left));
        if (store) controller.ObserveFrame(1, Frame(3, 1, "StoreQuorum", Message, Left));
        controller.CompleteCommand(1, 1, senderExit);
        controller.ObserveFrame(2, Frame(1, 1, "CommandAccepted"));
        ticks = 1010; controller.ObserveFrame(2, Frame(2, 1, "RecipientDurableReadable", Message, Left));
        controller.CompleteCommand(2, 1, 6); // A failed ACK cannot erase the ordinary history result.
        controller.BeginCommand(2);
        ticks = 1020; controller.ObserveFrame(2, Frame(3, 2, "CommandAccepted"));
        ticks = 1050; controller.CompleteCommand(2, 2, 0);
        controller.RecordHistoryRead(1, 1, 2, 2);
        Assert.Equal(double.PositiveInfinity, controller.ObservedHistoryReadMilliseconds(1, 1, 2));
        Close(controller, 1, store ? 4 : 3); Close(controller, 2, 4);
        Assert.Equal(50, controller.ObservedHistoryReadMilliseconds(1, 1, 2));
        Assert.Equal(senderExit == 0 && store ? 50 : double.PositiveInfinity,
            controller.HistoryReadMilliseconds(1, 1, [2], 2));
        Assert.False(controller.Rejected);
    }

    [Theory]
    [InlineData(0)]
    [InlineData(6)]
    public async Task DirectQueueAdmissionPrecedesDistinctDispatchAndIncludesAllAuthoringTime(int dispatchExit)
    {
        long ticks = 1000;
        var controller = new DeliveryEventController(() => ticks, 1000);
        await Register(controller, 1, 2);
        controller.BeginCommand(1);
        controller.ObserveFrame(1, Frame(1, 1, "CommandAccepted")); // Original queue admission.
        ticks = 1040; controller.CompleteCommand(1, 1, 0);
        controller.BeginCommand(1);
        ticks = 1050; controller.ObserveFrame(1, Frame(2, 2, "CommandAccepted"));
        controller.BindDirectDispatch(1, 1, 2);
        ticks = 1060; controller.ObserveFrame(1, Frame(3, 2, "NativeOutboxDurable", Message, Left));
        ticks = 1070; controller.ObserveFrame(1, Frame(4, 2, "StoreQuorum", Message, Left));
        controller.CompleteCommand(1, 2, dispatchExit);
        controller.BeginCommand(2);
        controller.ObserveFrame(2, Frame(1, 1, "CommandAccepted"));
        ticks = 1080; controller.ObserveFrame(2, Frame(2, 1, "RecipientDurableReadable", Message, Left));
        controller.CompleteCommand(2, 1, 0);
        controller.BeginCommand(2);
        ticks = 1090; controller.ObserveFrame(2, Frame(3, 2, "CommandAccepted"));
        ticks = 1100; controller.CompleteCommand(2, 2, 0);
        controller.RecordHistoryRead(1, 1, 2, 2);
        Assert.True(controller.HasRecipientObservation(1, 1, 2));
        Close(controller, 1, 5); Close(controller, 2, 4);
        Assert.Equal(100, controller.ObservedHistoryReadMilliseconds(1, 1, 2));
        Assert.Equal(dispatchExit == 0 ? 100 : double.PositiveInfinity, controller.HistoryReadMilliseconds(1, 1, [2], 2));
        if (dispatchExit == 0)
        {
            var sample = controller.Sample(1, 1, [2]);
            Assert.Equal(60, sample.NativeOutboxMilliseconds);
            Assert.Equal(70, sample.AllStoresMilliseconds);
            Assert.Equal(80, sample.AllRecipientsMilliseconds);
        }
        Assert.False(controller.Rejected);
    }

    [Fact]
    public async Task CleanClosureWithMissingCurrentStoreObservationStillCannotQualify()
    {
        var controller = new DeliveryEventController();
        await Register(controller, 1, 2);
        controller.BeginCommand(1); controller.CompleteCommand(1, 1, 0);
        controller.ObserveFrame(1, Frame(1, 1, "CommandAccepted"));
        controller.ObserveFrame(1, Frame(2, 1, "NativeOutboxDurable", Message, Left));
        controller.ObserveFrame(2, Frame(1, 1, "CommandAccepted"));
        controller.ObserveFrame(2, Frame(2, 1, "RecipientDurableReadable", Message, Left));
        Close(controller, 1, 3); Close(controller, 2, 3);
        Assert.False(controller.Rejected);
        Assert.Equal(double.PositiveInfinity, controller.Sample(1, 1, [2]).AllRecipientsMilliseconds);
    }

    [Fact]
    public async Task ActualBoundedDiagnosticChannelReportsDroppedFinalEventInItsMandatoryTerminal()
    {
        using var output = new PausedWriter();
        var diagnostics = new DeliveryDiagnostics(output);
        try
        {
            using (diagnostics.AcceptCommand()) { }
            await output.Started.Task.WaitAsync(TimeSpan.FromSeconds(5));
            for (var i = 0; i < 257; i++) using (diagnostics.AcceptCommand()) { }
        }
        finally
        {
            output.Release.TrySetResult();
            await diagnostics.DisposeAsync();
        }
        var frames = output.ToString().Split('\n', StringSplitOptions.RemoveEmptyEntries);
        using var terminal = JsonDocument.Parse(frames[^1]);
        Assert.Equal("StreamClosed", terminal.RootElement.GetProperty("phase").GetString());
        Assert.Equal(1, terminal.RootElement.GetProperty("dropped").GetInt64());
        Assert.Equal(259, terminal.RootElement.GetProperty("sequence").GetInt64());
        var controller = new DeliveryEventController();
        await controller.Attach(1, new StringReader(output.ToString()));
        Assert.True(controller.Rejected);
        using var summary = JsonDocument.Parse(JsonSerializer.Serialize(controller.StreamSummary()));
        Assert.Equal(1, summary.RootElement[0].GetProperty("dropped").GetInt64());
        Assert.Equal(double.PositiveInfinity, controller.Sample(1, 1, [2]).AllRecipientsMilliseconds);
    }

    private sealed class PausedWriter : StringWriter
    {
        internal readonly TaskCompletionSource Started = new(TaskCreationOptions.RunContinuationsAsynchronously);
        internal readonly TaskCompletionSource Release = new(TaskCreationOptions.RunContinuationsAsynchronously);
        private int calls;
        public override async Task WriteLineAsync(string? value)
        {
            if (Interlocked.Increment(ref calls) == 1)
            { Started.TrySetResult(); await Release.Task.ConfigureAwait(false); }
            await base.WriteLineAsync(value).ConfigureAwait(false);
        }
    }

    [Fact]
    public async Task OptInSessionKeepsCurrentStdoutFramesAndEmitsOnlyClosedStderrEvents()
    {
        var binding = CommandLine.Parse(["session", "run", "--profile", "delivery-" + Guid.NewGuid().ToString("N")[..20],
            "--network", new string('1', 32), "--bootstrap", "public-bundle", "--registry", "https://localhost/", "--delivery-events", "true"]);
        var args = new[] { "account", "status", "--profile", binding.Profile, "--network", Convert.ToHexStringLower(binding.Network) };
        using (await WindowsProfile.OpenAsync(CommandLine.Parse(["account", "create", .. args[2..], "--name", "Empty delivery-event fixture"]))) { }
        using var stdout = new StringWriter(); using var stderr = new StringWriter();
        Assert.Equal(0, await CliSession.RunAsync(binding, new StringReader(JsonSerializer.Serialize(args) + "\n"), stdout, default, stderr));
        using var response = JsonDocument.Parse(stdout.ToString());
        Assert.Equal(0, response.RootElement.GetProperty("exitCode").GetInt32());
        var controller = new DeliveryEventController(); await controller.Attach(1, new StringReader(stderr.ToString()));
        Assert.False(controller.Rejected);
        Assert.Contains("CommandAccepted", stderr.ToString());
        Assert.DoesNotContain(binding.Profile, stderr.ToString());
        Assert.DoesNotContain("accountPresent", stderr.ToString());
    }
}
