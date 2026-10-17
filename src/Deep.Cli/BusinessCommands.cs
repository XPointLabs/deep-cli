using System.Diagnostics;
using System.Security.Cryptography;
using System.Text.RegularExpressions;
using Deep.Client.Shared.Services;
using Deep.Protocol.Identity;
using Deep.Protocol.ApplicationCore;

namespace Deep.Cli;

internal static class BusinessCommands
{
    internal static async Task<object> RunAsync(CommandLine command, DeepIdV2AccountService accounts, CancellationToken ct)
    {
        var phase = "LocalRead";
        try
        {
            if (command is { Area: "contact", Operation: "list" })
                return new { status = "ok", contacts = (await accounts.ListConversationsAsync(ct)).Select(x => new
                { conversation = x.Conversation.ConversationId, state = x.ContactState.ToString(), initiator = x.Conversation.IsInitiator }).ToArray() };
            if (command is { Area: "contact", Operation: "operations" })
                return new { status = "ok", items = (await accounts.ListContactStartOperationsAsync(ct)).Select(x => new
                { operation = Convert.ToHexStringLower(x.LogicalIntent.Span), peer = x.PeerDid2Hash,
                    expires = x.ExpiresAtUnixMilliseconds, stopped = x.IsStopped }).ToArray() };
            if (command is { Area: "message", Operation: "pending" })
                return new { status = "ok", items = (await accounts.ListPendingTextOperationsAsync(ct)).Select(x => new
                { operation = Convert.ToHexStringLower(x.LogicalOperation.Span), conversation = x.ConversationId, text = x.Text }).ToArray() };

            DeepIdV2Conversation? conversation = null;
            if (command.Conversation is not null)
                conversation = (await accounts.ListConversationsAsync(ct)).Single(x =>
                    x.Conversation.ConversationId == command.Conversation).Conversation;
            if (command is { Area: "message", Operation: "list" })
                return new { status = "ok", items = (await accounts.ListMessagesAsync(conversation!, ct)).Select(x => new
                { text = x.Text, local = x.IsLocalAuthor, createdAt = x.CreatedAt }).ToArray() };

            phase = "Bootstrap";
            using var network = await NetworkBootstrap.OpenAsync(command, accounts, ct);
            phase = (command.Area, command.Operation) switch
            {
                ("network", "verify") => "NetworkVerify",
                ("contact", "request") => "ContactRequest",
                ("contact", "stop") => "ContactStop",
                ("contact", "accept") => "ContactAccept",
                ("mailbox", "sync") => "MailboxSync",
                ("message", "queue") => "TextQueue",
                ("message", "send") => "TextSend",
                _ => throw new ArgumentException("Unsupported business operation.")
            };
            if (phase == "NetworkVerify")
            { await network.VerifyAndPublishAsync(ct); return new { status = "ok", networkVerified = true, contactPublished = true }; }
            if (phase == "ContactRequest")
            {
                var result = await accounts.StartContactAsync(DeepPermanentIdV2.ParseCanonical(command.Address!),
                    Convert.FromHexString(command.OperationId!), network.Source, ct);
                return new { status = "stored", conversation = result.Conversation.ConversationId,
                    ingressDispatched = result.StorageReceipt.IngressDispatched };
            }
            if (phase == "ContactAccept")
            {
                var stored = await accounts.AcceptContactAsync(conversation!, Convert.FromHexString(command.OperationId!), network.Source, ct);
                return new { status = "stored", ingressDispatched = stored.IngressDispatched };
            }
            if (phase == "ContactStop")
            {
                await accounts.CancelOwnInitialContactAsync(Convert.FromHexString(command.OperationId!), network.Source, ct);
                return new { status = "stopped", remoteRecall = false };
            }
            if (phase == "MailboxSync")
            {
                var synced = await accounts.SynchronizeOwnMailboxAsync(network.Source, ct);
                return new { status = "ok", processed = synced.ProcessedEnvelopes, hasMore = synced.HasMore, tombstones = synced.DurableTombstones };
            }
            if (phase == "TextQueue")
            {
                var operation = await accounts.QueueTextAsync(conversation!, command.Text!, network.Source, ct);
                return new { status = "queued", operation = Convert.ToHexStringLower(operation.Span) };
            }
            var sent = await accounts.RetryTextAsync(conversation!, Convert.FromHexString(command.OperationId!), command.Text!, network.Source, ct);
            return new { status = "stored", ingressDispatched = sent.IngressDispatched };
        }
        catch (Exception error)
        { throw new CliBusinessException(phase, error); }
    }
}

internal sealed class CliBusinessException(string phase, Exception error) : Exception("CLI business operation failed.", error)
{
    internal object ClosedDiagnostic()
    {
        var rows = new List<object>();
        for (Exception? current = InnerException; current is not null && rows.Count < 8; current = current.InnerException)
        {
            var category = current switch
            {
                ClientMailboxDispatchOutcomeUnknownException => "OutcomeUnknown",
                DeepIdV2ContactRetryExpiredException => "ContactRetryExpired",
                CryptographicException => "ProtectedState",
                HttpRequestException => "HttpFailure",
                IOException => "IoFailure",
                InvalidDataException => "InvalidState",
                OperationCanceledException => "Cancelled",
                InvalidOperationException => "OperationRejected",
                ApplicationCoreFormatException => "ProtocolRejected",
                ArgumentException => "InvalidInput",
                _ => "Other"
            };
            var check = "Unclassified";
            var exceptionType = current.GetType();
            if (exceptionType.Assembly == typeof(DeepIdV2AccountService).Assembly && exceptionType.IsSealed &&
                exceptionType.FullName == "Deep.Client.Shared.Services.PrivacyIngressRejectedBeforeForwardException")
            {
                // This exact sealed owned type has a bool auto-property. Never
                // invoke a caller/third-party exception getter or print its text.
                category = exceptionType.GetProperty("Retryable", System.Reflection.BindingFlags.Instance |
                    System.Reflection.BindingFlags.NonPublic)?.GetValue(current) is true
                    ? "IngressRetryableBeforeForward" : "IngressRejectedBeforeForward";
                check = current.Message switch
                {
                    "Privacy ingress rejected the request before forwarding (MalformedFrame)." => "IngressMalformedFrame",
                    "Privacy ingress rejected the request before forwarding (WrongOrigin)." => "IngressWrongOrigin",
                    "Privacy ingress rejected the request before forwarding (Saturated)." => "IngressSaturated",
                    "Privacy ingress rejected the request before forwarding (Unavailable)." => "IngressUnavailable",
                    _ => "Unclassified"
                };
            }
            if (exceptionType.Assembly == typeof(DeepIdV2AccountService).Assembly && exceptionType.IsSealed &&
                exceptionType.FullName == "Deep.Client.Shared.Services.ContactV2.DeepIdV2PreKeyClaimUnavailableException")
                check = current.Message switch
                {
                    "DID2 pre-key claim is unavailable (PreKeysUnavailable)." => "PreKeysUnavailable",
                    "DID2 pre-key claim is unavailable (Expired)." => "ClaimExpired",
                    "DID2 pre-key claim is unavailable (StaleBundle)." => "ClaimStaleBundle",
                    "DID2 pre-key claim is unavailable (RateLimited)." => "ClaimRateLimited",
                    "DID2 pre-key claim is unavailable (Conflict)." => "ClaimConflict",
                    "DID2 pre-key claim is unavailable (OutcomeUnknown)." => "ClaimOutcomeUnknown",
                    _ => "Unclassified"
                };
            var method = "Unavailable"; var il = -1;
            foreach (var frame in new StackTrace(current, false).GetFrames().Take(32))
            {
                var member = frame.GetMethod(); var type = member?.DeclaringType;
                if (type?.Assembly.GetName().Name is not ("Deep.Client.Shared" or "Deep.Protocol" or "Deep.Protocol.MembershipRoutes")) continue;
                var candidate = type.FullName + "." + member!.Name;
                if (candidate.Length <= 240 && Regex.IsMatch(candidate, "\\A[A-Za-z0-9_.+<>`]+\\z"))
                { method = candidate; il = Math.Clamp(frame.GetILOffset(), -1, 1048575); break; }
            }
            rows.Add(new { category, check, method, il });
        }
        return new { phase, causes = rows };
    }
}
