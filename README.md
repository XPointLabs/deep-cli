# Deep CLI

Headless client for the current DID2 stack. Uses
`deep-client-shared/Deep.Client.Shared.Production.csproj` and current Protocol;
no MAUI workloads, emulator or device deployment for the inner development loop.
Place this repository beside `deep-client-shared` and `deep-protocol`, as in the
XPointLabs workspace. Requires Windows and .NET SDK10.0.301 initially.

Connected commands report `recoveryWork` separately from driver attempts: bounded
Store/mailbox resumes and waits for protected retry leases. Recovery re-enters
the original owned operation, never reruns queue/group creation or relaxes signed
windows. See the [message/DTT checkpoint](docs/testing/cli-dtt-send-2026-10-19.md)
for retained failures. The current
[message latency checkpoint](docs/testing/cli-message-latency-2026-10-19.md)
records the complete three-client comparison and remaining data-plane delays.

Build the solution with its explicit owned Shared/Protocol projects. A Release
console with Debug dependencies is not a Release runtime: tests inspect all
four actual dependency optimizer flags and reject a mixed graph. New group send
drains unfinished work; explicit `group flush` still audits all original Stores.
`group resume` uses that same owned pending-only path without authoring a new
message. It does not qualify completed-archive integrity; `flush` keeps that
separate explicit verification. A retained `-DeliveryOnly
-RecoverIncompleteSteadyRound` scenario qualifies delivery recovery only, never
first-attempt latency, full history/lifecycle, device or release acceptance.
The E2E receipt records `completedBatchItems` to distinguish these operations.
Before an independent network/contact/mailbox operation, the serial host
discards only uncaptured public working reads. Established text, attachment and
group commands now share the same bounded `EstablishedMessagingSource`.
This avoids rebuilding the network/endpoint chain at each internal send step;
the actual protected state/time checks and the original expiry are unchanged.
A later established operation reacquires
actual protected network custody, rather than failing on a memo from before an
independent ACK advanced it. Captured loans and all floor/fork/clock guards remain
unchanged; this boundary does not retry a command or weaken authority.

## Available now

```powershell
dotnet build Deep.Cli.slnx --configuration Release
dotnet run --project src/Deep.Cli --no-build --configuration Release -- --help
```

For cold-command latency measurements, publish the same CLI graph with the
explicit `Latency` profile and the actual Windows host RID, for example:

```powershell
dotnet publish src/Deep.Cli/Deep.Cli.csproj -c Release -r win-arm64 --self-contained false -p:PublishProfile=Latency -o artifacts/latency-publish
```

This uses [ReadyToRun](https://learn.microsoft.com/dotnet/core/deploying/ready-to-run)
to move some JIT work to publish time. It adds no authority/state cache, trimming,
native-source rebuild or alternate business path. It is an explicit larger
host-specific CLI artifact, not a Windows/Android UI build. The ordinary build
remains available for the fast edit loop. Report published and ordinary-build
timings separately; ReadyToRun is not a claim that network or ACK delays are solved.
`Invoke-ThreeClientGsrE2E.ps1 -ExecutablePath <absolute published deep.exe>`
selects an existing publish output only beneath this repository's `artifacts`.
It retains the same runtime archive/fingerprint and full scenario checks; the
default still uses the ordinary Release build. Never overwrite either runtime
or change scenario inputs during a run.

Account commands:

```text
deep account create --profile alice --network <32 lowercase hex network ID> --name Alice
deep account status --profile alice --network <same network ID>
deep account address --profile alice --network <same network ID>
```

`create` generates the real Shared DID2 account and device state; it does not
register/publish on the network. `status` does not emit identity. `address` and
`create` explicitly return the public resolver address. JSON goes to stdout;
closed errors to stderr with nonzero exit. Ctrl+C cancels the operation.
Recovery phrases/keys/raw exceptions are never printed. There is no reset,
recovery export, arbitrary storage-path or raw-RPC command.

Profiles live only in the current user's local application-data directory under
`XPointLabs/DeepCli/<network>/<profile>`. Each has a private Windows ACL, current-user
DPAPI-wrapped per-write AES-256-GCM aggregate protection and the same Shared SQLCipher/account owner. Commands
hold an exclusive per-profile lease; no MAUI, Android or production state is opened.
Keep QA profiles for restart/recovery testing instead of resetting after failures.

For an established contact whose reverse route and XUR have both expired:

```text
deep contact reintroduce-route --profile alice --network <network> --bootstrap <public bundle> --registry <HTTPS origin> --conversation <existing conversation> --address <same peer permanent address>
```

The peer must first publish its current own route (`network verify`). This reads
and independently verifies a current same-peer publication and carries ONLY the
existing relationship's encrypted native route-maintenance control. It creates
no new contact/account/ratchet and never uses an expired XRA/XUR as authority.
The peer then runs `mailbox sync`, ordinary `contact refresh-route`, and the
sender runs `mailbox sync`. Native forks, gaps, changed endpoints and missing
original custody still refuse; a reset or new logical message is not recovery.
`eng/Invoke-ContactRouteRepair.ps1 -Reintroduce` exercises that bidirectional flow
on explicit retained CLI profiles, keeping public addresses only in memory.

Every aggregate decryption unwraps its32-byte key with native current-user DPAPI,
authenticates the complete ciphertext/header with a128-bit GCM tag, and zeroes
the key immediately. Every write uses a new random key and96-bit nonce. No
plaintext/key decryption cache or separate key file is retained. Native DPAPI no
longer processes the full growing inventory on each slot read. This is a local
CLI platform-envelope clean break, not a network/Shared format change: older
raw-DPAPI profiles reject without reader/migration. Preserve them as old evidence
and use new isolated QA profiles; device/prod profiles are never opened.
The .NET primitives are [AesGcm](https://learn.microsoft.com/en-us/dotnet/api/system.security.cryptography.aesgcm.encrypt?view=net-10.0)
and [current-user ProtectedData](https://learn.microsoft.com/en-us/dotnet/api/system.security.cryptography.protecteddata?view=windowsdesktop-10.0).
Numeric `protectionWork` reports call counts/complete protection time
only. `networkWork` groups public HTTP by a closed endpoint category;
it contains counts/status totals/durations, never URLs, bodies or identifiers.

## Real network and business commands

For an existing consented conversation, `contact route-health --conversation`
with the normal network options returns coarse interval diagnostics only.
`contact refresh-route --conversation` renews the own publication if due and
sends its exact successor over that conversation's CURRENT reverse mailbox path.
It returns `completed:0` when actual native advertisement is unchanged, or1 only
after verified Store. Receiver `mailbox sync` still performs actual native
receive and independently durable ACK. This is not an expired-route bypass or a
claim that the XUR update service is composed in Shared. If both usable paths
are gone, keep original work; do not reset contacts/accounts or substitute routes.

`eng/Invoke-ContactRouteRepair.ps1` qualifies explicit retained publisher/recipient
pairs without account creation. Its receipts capture frozen runtime/scenario,
numeric work, control receive/ACK and no-new-control replay. The group driver has
an explicit `-RecoverIncompleteSteadyRound` mode for the same semantic round:
it verifies exact retained local commands before original flush and marks
`recoveryQualified`, never `firstAttemptRequired`/`steadyStateQualified`.
Default strict rounds still reject incomplete starting state and allow no retry.

The DR-0145 GSR1 multi-account group candidate requires newly created isolated CLI profiles:
application SQL schema17, ordinary journal9 and mandatory protected group
generation3 registration. Older profiles reject without migration; keep them and their
earlier receipts, do not reset device/production accounts.

Group commands use the same network options and Shared owner:
`group create --name`, `group list`, `group messages --group`, and
`group invite/accept/advance/send/flush/sync --group --conversation`
and `group publish --group` (`send` also
requires `--text`). The candidate supports multiple accounts/one current device each; three-account
correctness is tested separately from the final scale/device gates.
After the invitee's explicit acceptance has been received, the owner runs
`advance` to retain the membership commit and publish sealed control chunks to
both descriptor-anchored GSR1 replicas under current network authority.
Routine operational view/selection-epoch renewal does not move a control stream. Acceptance alone is not membership. The invite and
initial descriptor/key travel inside pairwise E2EE; subsequent commits are
obtained with `sync` independently of ordinary mailbox retention. `publish`
resumes original pending control writes; it never recreates uncertain writes.
Gaps, expiry, conflicts or missing authenticated receipts fail closed. Descriptor
rotation/handover, expired unknown-write reconciliation and long-offline recovery
are not qualified.
`send` creates a new logical group message; after any uncertain result use
`flush`, never repeat `send` to retry. The selected conversation identifies an existing session, not a recipient-only
send: Shared derives the complete current membership and requires an accepted
session for every remote target before saving one batch. Flush drains all targets
of the original protected batch
with its original operations/sequences and independently verified Store results.
`stored` is not remote delivery. `eng/Invoke-ThreeClientGsrE2E.ps1` verifies three independent CLI
profiles, sequential membership additions, full two-target fanout and cold/dedup
history. `eng/Invoke-GroupE2E.ps1` retains the two-profile scenario and verifies both CLI
histories and durable ACKs through the real local network; it is not GSR1
long-offline, full multi-device group or Windows/Android release acceptance.
`eng/Invoke-ThreeClientGroupContinuation.ps1` continues the completed three-message
group without reset: Bob and Carol send before any recipient polls, exercising a
two-peer ACK page and exactly five cold-history messages. Resume this continuation
after an uncertain result; never run the first-round driver as a fresh scenario
against a group that already has second-round commands.
Group batch commands have a bounded30-minute host budget; every individual
transport deadline and signed authority window remains independently enforced.
The driver may resume already published profiles with `-ReusePublishedAccounts`.
`-RequireFirstAttempt` requires a new group with absent invitee state, disables
the driver's error retry and requires every command to succeed on attempt1.
Mailbox sync processes one page (new pages request at most two events) and
returns `hasMore`. The three-client driver drains at most four successful pages
using the real protected cursor; failed/unknown pages are never advanced or
hidden as pagination. Original larger captured pages/ACKs resume unchanged.
Run connected scenario scripts under PowerShell7.6.5 (`pwsh`), not Windows
PowerShell5.1; native source-test wrappers still select5.1 as the workspace requires.
After a completed cycle, `-GroupRevision 1` explicitly starts a separate named
QA group without deleting the old group/history; never advance it to evade
unknown work. Retry the same revision and its original `flush` operations.
Current GSR1 evidence and remaining limits: [GSR checkpoint](docs/testing/cli-gsr-groups-2026-10-18.md).
Historical ordinary-mailbox generation2 evidence: [three-CLI checkpoint](docs/testing/cli-three-groups-2026-10-18.md)
and the earlier [two-CLI checkpoint](docs/testing/cli-groups-2026-10-18.md).

The initial network adapter consumes the existing **public** `deep-dev-current`
bundle (`deep-dev.json`, genesis XNA1/DTS1/ADH1 and public `dev-ca.crt`). It reads
no operator/node/signer secrets. Pass its directory as `--bootstrap` and an
explicit canonical HTTPS origin as `--registry`; the bundle network must equal
`--network`. The CA is app-scoped, with hostname/EKU/current-chain/revocation
checks unchanged. No global trust import or TLS bypass.

Alongside `--profile` and `--network`, commands accept:

| Command | Additional options |
| --- | --- |
| `network verify` | `--bootstrap`, `--registry` |
| `contact request` | network options, `--address`, `--operation` |
| `contact accept` | network options, `--conversation`, `--operation` |
| `contact stop` | network options, `--operation` |
| `contact list`, `contact operations` | none; protected local projections only |
| `mailbox sync` | network options; one actual page/materialization/ACK |
| `message queue` | network options, `--conversation`, `--text` |
| `message send` | network options, `--conversation`, `--operation`, `--text` |
| `message list` | `--conversation`; explicitly returns message history |
| `message pending` | none; returns existing exact pending text commands |
| `attachment prepare` | network options, absolute `--file`, `--media`, stable asset `--operation` |
| `attachment queue` | network options, `--conversation`, `--asset` |
| `attachment send` | network options, `--conversation`, `--asset`, original offer `--operation` |
| `attachment pending`, `attachment operations` | none; protected operation projections, never capabilities/keys |
| `attachment list` | `--conversation`; key-free authenticated offer projection |
| `attachment download` | network options, `--conversation`, `--logical`, `--device`, absolute `--output` |

An asset operation and an offer operation are **different**. `prepare` adopts
the encrypted source durably; repeating identical input/metadata retains the
original object, key, chunks and expiry. `queue` creates one offer in Shared's
ordinary outbox and returns its owner-generated operation. `send` selects only
that original operation and the matching asset; it cannot create a message.
`operations` includes retained working Stored/stopped rows; compaction can retire
them. Its flags are not receipts or permission to recreate missing work.

Uploads use two current signed Blob nodes through the existing three-hop ONION
carrier. The manifest/key/name/media stay in E2EE, not in the blob descriptor.
Downloads reselect the manifest from authenticated native receive history, check
all ciphertext commitments and AEAD tags, and only then write verified plaintext
to a private staging file. A successful atomic move never overwrites an existing
destination and never uses the remote filename as an output path.

Attachment send/download have a bounded **3-hour composite command budget** for
up to100 chunks/two upload copies. Every proof, original expiry, currentness check
and shorter transport deadline remains independently enforced; other commands
keep5 minutes. Ctrl+C preserves original adopted/queued work. Partial download
staging is removed; a cold retry currently rechecks/refetches chunks, not a durable
local download-progress cache. Large-file throughput/retention/churn are not
qualified by the small fixture run.

`eng/Invoke-AttachmentE2E.ps1` uses two already accepted isolated profiles, a
generated three-chunk document and a valid PNG in the reverse direction. It
checks independent full-output hashes, cold exact retries, duplicate polls and
overwrite refusal. It reuses retained operations and refuses to replace a
completed offer whose original selector is no longer available. Receipts contain
hashes/counts/closed phases only, not message IDs, manifests or source paths.
See [attachment evidence](docs/testing/cli-attachments-2026-10-18.md).

Pass `-ExecutablePath artifacts/<publish>/deep.exe` to test an immutable published
runtime; the driver archives it and its scenario under the fresh run directory.
The pair may have other contacts: only its unique common explicitly accepted
conversation is selected. `-AssetRevision 1` explicitly starts a new QA asset
namespace without resetting profiles. Retry an interrupted asset with the SAME
revision, never advance it to evade pending/unknown work. Revision0 retains
the original test selectors. `eng/Test-AttachmentScenario.ps1` checks the
selection/identity and pre-I/O runtime guards without starting clients.
Current full-group and retained-attachment evidence:
[checkpoint](docs/testing/cli-full-retained-and-attachments-2026-10-23.md).
This driver does not silently repair expired peer routes: retain the SAME asset
and offer, perform the existing authenticated route-maintenance workflow, then
retry. A maintenance-assisted recovery is reported separately from first-attempt
delivery; proactive automatic route lifecycle remains an outstanding product
requirement, not a reason to accept an expired XRA1.

Logical operation IDs are nonzero **32 bytes /64 lowercase hex**; conversation
IDs are32 bytes /64 hex. `queue` durably authors one message and returns its
operation. `send` retries that exact operation/text, never queues a replacement.
`stored` means verified mailbox storage, not recipient acceptance/delivery.
`stop` uses the existing account-owned cancellation path, not remote recall or
proof of noncommit. Unknown outcome remains retained. The bounded host budget
below does not extend protocol windows or peer deadlines.
Failures emit only closed phase/category/check and owned method/IL metadata.

`eng/Invoke-ContactTextE2E.ps1` launches separate real CLI processes for two
persistent profiles: publication → request → mailbox receive → consent → text
both ways → cold history/duplicate checks. Arguments/results containing addresses,
operation IDs and plaintext remain in memory, never in its evidence receipts.
Use a fresh `-RunDirectory` beneath this repository's ignored `artifacts/`.
The driver fingerprints the complete bounded runtime output tree before/after
commands, including managed assemblies, native providers and configuration.
An apphost EXE hash alone does not identify .NET application code. The receipt
contains the combined digest, not runtime paths or profile state.
The driver also pins its own source SHA256 before/after every command.
`-ReusePublishedAccounts` resumes already initialized profiles without repeating
setup; it supplies no authority and all business/currentness checks still run.
`-IntentRevision` is an explicit separate QA command, not automatic retry: never
advance it to overwrite or silently evade an unresolved original intent.
`-ResumeContact` continues two already materialized, unique contacts only if
their exact conversation IDs and opposite initiator roles match. If both sides
already retain acceptance, it skips redundant control dispatch; otherwise it
sends the same owned acceptance operation and receives it. Text commands still
verify actual native/protected consent in Shared, not this scheduling hint.
Its receipt is explicitly a **retained-contact continuation**, not evidence
of a new Initial publication/store in that run; qualify the earlier receive
separately and use the full scenario for final fresh-cycle acceptance.
`-ObserveUnknownStore` is diagnostic scheduling: after those exact attempts,
an uncertain text Store may continue to the real inbox and reverse direction.
Failed steps remain in the receipt. Any unresolved Store forces `passed=false`
and a nonzero terminal even if both cold histories are verified. It cannot
turn an unknown into Stored/Delivered or queue a replacement logical message.

`-RetryExactTransient` tests one bounded cold-process retry of an identical
idempotent business command after an uncertain/cancelled or retryable-before-
forward result. It never repeats account creation/text queueing, changes an
operation ID, or extends authority. Both attempts and every failure diagnostic
remain in the receipt; all delivery/history checks must still pass.

`-TextRevision 1` (then2, etc.) explicitly sends a new synthetic regression pair
after a successful original cycle, for example after a node upgrade. It requires
both resume switches, retained consent, no prior/unrelated pending text and both prior texts
exactly once in each cold history. Never advance it to evade an unknown Store;
retry the same revision to retain its existing queue/operation. The receipt
records the numeric revision; this changes only QA content, not protocol bytes.
`pwsh -NoProfile -File eng/Test-ContactTextScenario.ps1` checks syntax and rejects
unsafe revision scheduling before any file creation, CLI process or network.

Closed failure diagnostics distinguish the known ingress control classes
MalformedFrame/WrongOrigin/Saturated/Unavailable from arbitrary exception text.
This does not authorize automatic retries or imply end-to-end noncommit.

Each CLI command has a bounded five-minute host budget and still accepts
Ctrl+C. The black-box driver allows30seconds for orderly exit beyond that.
This covers multi-hop business preparation; individual transport deadlines and
all signed proof/request/grant lifetimes remain independently enforced. A
cancelled/unknown attempt is retained, never converted to successful delivery.

## Next, in order

The authoritative sprint/acceptance plan is
[CLI-first in XPointLabs](../docs/architecture/IMPLEMENTATION-PLAN-V1.md#cli-first--первый-приоритет-внутри-s05):
shared headless composition → network/contact/consent → bidirectional text and
recovery → files/images → groups. Network commands are implemented; connected
contact/text acceptance is still being debugged, not claimed complete.
Do not interpret local account creation as network, message or device E2E PASS.
Two CLI profiles will use the real local Registry/three-node Docker topology,
existing TLS/authority/native crypto and persistent storage. No mock-success path.

Run `dotnet test Deep.Cli.slnx --configuration Release -m:1` for the focused CLI
suite. Full source/package gates and subsequent Windows/Android physical E2E
remain required for release. This repository publishes no release automatically.

## Initial account-slice evidence (2026-10-17)

`artifacts/cli-account-20261017/focused-02`:12PASS/native0/0skip, no compiler
warnings/errors, Windows PowerShell5.1 / SDK10.0.301. Includes real DPAPI tamper
refusal and native DID2/account/device persistence, strict arguments, cancellation
and refusal to overwrite an existing account. Initial `focused-01` failed before
account creation because CLI incorrectly expected a32-byte network ID; current
CLI uses the existing16-byte DID2 network ID. The failed receipt is retained.

`process-01/receipt.json`: separately launched actual `deep.exe` processes created
two distinct accounts, reopened the same public address, rejected duplicate
creation without changing the original, and omitted the address from status.
All six checks passed/native0. Output captured only in memory; the receipt has
booleans and executable SHA256, no account addresses, keys or private paths.
This qualifies **local account behavior only**, not network/contact/device E2E.

For isolated steady-state group latency, the existing three-client scenario
accepts `-ReusePublishedAccounts -SteadyStateRound N` with the exact retained
`-GroupRevision` and three profiles. N is each participant's actual existing
local message count, not a retry number. It requires matching native history,
exactly three active members and one new command per sender; driver retries
are disabled. It preserves old state and records a distinct steady-state result,
never fresh creation/invitation/acceptance or release qualification. A failed
round cannot be restarted as first-attempt evidence.

For repeated delivery-only measurements, add the explicit `-DeliveryOnly` switch
to a NEW retained steady round. It still verifies three senders, six native
receive/ACKs, exact cold semantic histories, empty mailboxes and deduplication.
It omits only the separate all-original-Store replay and GSR cold-control audit;
the default full scenario is unchanged. Its receipt records `deliveryOnly=true`,
`deliveryLatencyQualified`, and always `steadyStateQualified=false`; it cannot
qualify full lifecycle, recovery, retention, devices or a release. Run the full
scenario after the final runtime change. A failed delivery-only round must be
recovered with the FULL supported `-RecoverIncompleteSteadyRound` on the same
round, never replaced by a new command. Invalid scope combinations reject before
opening a profile/network. Check these guards with
`pwsh -NoProfile -File eng/Test-ThreeClientGsrScopes.ps1`.

The retained diagnostic driver accepts round ordinals0–63 so later measurements
can use the SAME profiles after round31. This is only a harness ordinal bound;
no native journal, mailbox quota, signed lifetime or runtime capacity is raised.

## Persistent CLI sessions

`deep session run --profile <alias> --network <hex> --bootstrap <public-bundle>
--registry <HTTPS-origin>` accepts newline-terminated JSON arrays of ordinary
CLI arguments on redirected stdin. Each command still includes its explicit
profile/network and usual options. The host returns one JSON object containing
`exitCode` and `result` per command. Send EOF to close; no TCP listener is opened.
Commands execute serially under one exclusive profile lease. Switching profile,
network, bootstrap or Registry, nested sessions, oversized frames and truncated
commands are rejected. Failed business commands are not automatically retried.

The Shared public composition and monotonic clock survive between commands.
Established group work may reuse its still-valid public authority, with actual
account/device/floor/time checks on every borrow. Contact Initial and fresh
mailbox ACK retain independent acquisition. Every ten seconds an idle-only
maintenance opportunity revalidates authority; it refreshes only when absent or
within thirty seconds of its original proof deadline. It skips busy work, has a
30s budget, and discards the composition on failure. `network refresh` forces a
separate pre-effect refresh. No signed window, request deadline, private-key
custody or durable retry semantics changes; see the
[authority owner](../docs/architecture/ACCOUNT-DIRECTORY-TRANSPARENCY-V1.md#working-public-authority-and-delivery).

The three-client driver accepts `-PersistentSessions`. It records this mode,
archives its stdio helper, and closes each host before cold replay/history
checks. Session measurements do not imply physical-device qualification.
