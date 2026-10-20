using System.Diagnostics;
using System.Security.Cryptography;
using System.Text.RegularExpressions;
using Deep.Client.Shared.Services;
using Deep.Protocol.Identity;
using Deep.Protocol.ApplicationCore;

namespace Deep.Cli;

internal static class BusinessCommands
{
    internal static async Task<object> RunAsync(CommandLine command, DeepIdV2AccountService accounts, CancellationToken ct,
        CliSession? session = null)
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
            if (command is { Area: "attachment", Operation: "pending" })
                return new { status = "ok", items = await accounts.ListPendingAttachmentOperationsAsync(ct) };
            if (command is { Area: "attachment", Operation: "operations" })
                return new { status = "ok", items = await accounts.ListAttachmentOperationsAsync(ct) };
            if (command is { Area: "group", Operation: "list" })
                return new { status = "ok", items = await accounts.ListGroupsAsync(ct) };
            if (command is { Area: "group", Operation: "messages" })
                return new { status = "ok", items = (await accounts.ListGroupMessagesAsync(Convert.FromHexString(command.Group!), ct)).Select(item =>
                    new { text = item.Text, local = item.IsLocalAuthor, sequence = item.Sequence }).ToArray() };

            DeepIdV2Conversation? conversation = null;
            if (command.Conversation is not null)
                conversation = (await accounts.GetConversationAsync(command.Conversation, ct)).Conversation;
            if (command is { Area: "message", Operation: "list" })
                return new { status = "ok", items = (await accounts.ListMessagesAsync(conversation!, ct)).Select(x => new
                { text = x.Text, local = x.IsLocalAuthor, createdAt = x.CreatedAt }).ToArray() };
            if (command is { Area: "attachment", Operation: "list" })
                return new { status = "ok", items = await accounts.ListAttachmentsAsync(conversation!, ct) };

            phase = "Bootstrap";
            using var ownedNetwork = session is null ? await NetworkBootstrap.OpenAsync(command, accounts, ct) : null;
            var network = session is null ? ownedNetwork! : await session.GetNetworkAsync(command, ct);
            // Established sends borrow the session's still-current public
            // authority. Independent receive/ACK/contact work may advance its
            // protected floors, so only those boundaries discard the memo.
            var established = command.Area is "group" or "message" or "attachment";
            if (session is not null && !established)
                await network.DiscardUncapturedGroupAuthorityAsync(ct);
            var messagingSource = session is not null && established
                ? network.EstablishedMessagingSource : network.Source;
            if (command is { Area: "contact", Operation: "route-health" })
                return new { status = "ok", health = await accounts.ReadContactRouteHealthAsync(conversation!, network.Source, ct) };
            if (command is { Area: "contact", Operation: "refresh-route" })
            {
                phase = "ContactRouteMaintenance";
                return new { status = "stored", completed = await accounts.RefreshContactRouteAsync(conversation!, network.Source, ct) };
            }
            phase = (command.Area, command.Operation) switch
            {
                ("network", "verify") => "NetworkVerify",
                ("network", "refresh") => "NetworkRefresh",
                ("contact", "request") => "ContactRequest",
                ("contact", "stop") => "ContactStop",
                ("contact", "accept") => "ContactAccept",
                ("mailbox", "sync") => "MailboxSync",
                ("message", "queue") => "TextQueue",
                ("message", "send") => "TextSend",
                ("attachment", "prepare") => "AttachmentPrepare",
                ("attachment", "send") => "AttachmentSend",
                ("attachment", "queue") => "AttachmentQueue",
                ("attachment", "download") => "AttachmentDownload",
                ("group", "create" or "invite" or "accept" or "advance" or "send" or "flush" or "sync" or "publish") => "GroupWork",
                _ => throw new ArgumentException("Unsupported business operation.")
            };
            if (phase == "NetworkVerify")
            { await network.VerifyAndPublishAsync(ct); return new { status = "ok", networkVerified = true, contactPublished = true }; }
            if (phase == "NetworkRefresh")
            { await network.RefreshGroupAuthorityAsync(ct); return new { status = "ok", groupAuthorityRefreshed = true }; }
            if (phase == "GroupWork")
            {
                // Only established group work shares the public session memo.
                // Initial/contact and mailbox receive/fresh ACK keep Source.
                var source = messagingSource;
                if (command.Operation == "create")
                    return new { status = "created", group = await accounts.CreateGroupAsync(command.Name!, source, ct) };
                var group = Convert.FromHexString(command.Group!);
                var completed = command.Operation switch
                {
                    "invite" => await accounts.InviteToGroupAsync(group, conversation!, source, ct),
                    "accept" => await accounts.AcceptGroupAsync(group, conversation!, source, ct),
                    "advance" => await accounts.AdvanceGroupAsync(group, conversation!, source, ct),
                    "send" => await accounts.SendGroupTextAsync(group, conversation!, command.Text!, source, ct),
                    "flush" => await accounts.FlushGroupAsync(group, conversation!, source, ct),
                    "publish" => await accounts.PublishGroupControlAsync(group, source, ct),
                    "sync" => await accounts.SyncGroupControlAsync(group, conversation!, source, ct),
                    _ => throw new ArgumentException("Unsupported group operation.")
                };
                return new { status = command.Operation == "sync" ? "synced" : "stored", completed };
            }
            if (phase == "AttachmentPrepare")
            {
                AttachmentFiles.RequireNoLinks(command.File!);
                using var input = new FileStream(command.File!, FileMode.Open, FileAccess.Read, FileShare.Read);
                AttachmentFiles.RequireNoLinks(command.File!);
                var prepared = await accounts.PrepareAttachmentAsync(Convert.FromHexString(command.OperationId!), input, input.Length,
                    Path.GetFileName(command.File!), command.MediaType!, messagingSource, ct);
                return new { status = "prepared", prepared.Operation, prepared.ObjectId, prepared.Bytes, prepared.PlaintextSha256, prepared.ExpiresAtUnixSeconds };
            }
            if (phase == "AttachmentSend")
            {
                var stored = await accounts.SendAttachmentAsync(conversation!, Convert.FromHexString(command.Asset!),
                    Convert.FromHexString(command.OperationId!), messagingSource, ct);
                return new { status = "stored", ingressDispatched = stored.IngressDispatched };
            }
            if (phase == "AttachmentQueue")
            {
                var operation = await accounts.QueueAttachmentAsync(conversation!, Convert.FromHexString(command.Asset!), messagingSource, ct);
                return new { status = "queued", operation = Convert.ToHexStringLower(operation.Span) };
            }
            if (phase == "AttachmentDownload")
                return await AttachmentFiles.DownloadAsync(command, accounts, conversation!, messagingSource, ct);
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
                var operation = await accounts.QueueTextAsync(conversation!, command.Text!, messagingSource, ct);
                return new { status = "queued", operation = Convert.ToHexStringLower(operation.Span) };
            }
            var sent = await accounts.RetryTextAsync(conversation!, Convert.FromHexString(command.OperationId!), command.Text!, messagingSource, ct);
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
                TimeoutException => "Timeout",
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
            if (current is ClientMailboxDispatchOutcomeUnknownException && current.Data["Deep.GroupControl.Status"] is string groupStatus &&
                new[] { "Expired", "RateLimited", "StaleView", "Conflict", "OutcomeUnknown", "SizeFailure", "RecordTooLarge" }.Contains(groupStatus, StringComparer.Ordinal))
                check = "GroupControl" + groupStatus;
            var exceptionType = current.GetType();
            if (current is CryptographicException && exceptionType.Assembly == typeof(CryptographicException).Assembly &&
                current.Data["Deep.MailboxGrant.Check"] is string grantReason &&
                new[] { "Lifecycle", "Network", "Membership", "Epoch", "Issuer", "Generation", "IssuerWindow", "RouteExpiry", "Lifetime", "Signature" }.Contains(grantReason, StringComparer.Ordinal))
                check = "Grant" + grantReason;
            if (current is CryptographicException && exceptionType.Assembly == typeof(CryptographicException).Assembly)
                check = current.Message switch
                {
                    "Held pre-key authoring no longer binds protected network custody." => "EndpointPairNetworkChanged",
                    "Refreshed messaging endpoints no longer bind owned network custody." => "EndpointPairNetworkChanged",
                    "Held authoring directory freshness expired." => "EndpointPairDirectoryExpired",
                    "The DID2 proof is older than the protected directory floor." => "EndpointPairDirectoryFloorAdvanced",
                    "The DID2 directory proof expired before account handoff." => "EndpointPairDirectoryExpiredBeforeHandoff",
                    _ => check
                };
            if (current is CryptographicException && exceptionType.Assembly == typeof(CryptographicException).Assembly)
                foreach (var artifact in new[] { "XNA1", "XNV1", "XNH1", "ADH1", "DeviceCertificate", "DCA1", "PMT2", "XRA1", "PMS2", "XRC1", "XSS1", "XIR1V2", "XRR1", "ThresholdAuthoring", "ResolveRequest" })
                    foreach (var reason in new[] { "InvalidInterval", "NotBefore", "Expiry" })
                        if (current.Message == $"DID2 route time coverage failed ({artifact}; {reason}).") check = "RouteTime" + artifact + reason;
            if (current is CryptographicException && exceptionType.Assembly == typeof(CryptographicException).Assembly &&
                current.Data["Deep.MailboxRetainedRead.Check"] is string retainedReason &&
                new[] { "GrantHorizon", "GrantOverlap", "RequestInterval", "GrantStart", "ResponseDeadline", "IssuedBeforeRequest", "IssuedAfterRequest", "IssuedAfterCurrentUpper" }.Contains(retainedReason, StringComparer.Ordinal))
                check = "RetainedRead" + retainedReason;
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
            var method = "Unavailable"; var il = -1; var trail = new List<object>();
            foreach (var frame in new StackTrace(current, false).GetFrames().Take(32))
            {
                var member = frame.GetMethod(); var type = member?.DeclaringType;
                if (type?.Assembly.GetName().Name is not ("Deep.Client.Shared" or "Deep.Protocol" or "Deep.Protocol.MembershipRoutes")) continue;
                var candidate = type.FullName + "." + member!.Name;
                if (candidate.Length <= 240 && Regex.IsMatch(candidate, "\\A[A-Za-z0-9_.+<>`]+\\z"))
                {
                    var offset = Math.Clamp(frame.GetILOffset(), -1, 1048575);
                    if (trail.Count == 0) { method = candidate; il = offset; }
                    trail.Add(new { method = candidate, il = offset }); if (trail.Count == 8) break;
                }
            }
            rows.Add(new { category, check, method, il, trail });
        }
        return new { phase, causes = rows };
    }
}
