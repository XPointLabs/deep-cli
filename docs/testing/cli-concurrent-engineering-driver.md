# Concurrent engineering driver

The same driver now accepts `-MessageKind Direct`. It predeclares six directed
originals per round on the retained three accounts, or exactly one original with
`-SingleDirectSample -DirectSenderRole 1 -DirectRecipientRole 2`. Direct preflight
uses only ordinary local account, contact, pending and history reads. It does not
verify or maintain routes before the original admission. Pending originals block
new authoring only in each selected sender/conversation. Unrelated conversations
are not a new-authoring gate. The selected pair must retain mutual consent.

Direct submission first uses the genuine authoring command `message queue` and
then `message send` with its exact returned operation and original text. The
controller binds the queue admission ordinal to the distinct send ordinal:
queue admission is t0, while durable outbox and Store events belong to send.
Shared retains the protected original operation and exact text;
no operation, conversation or payload is copied into engineering artifacts. It
does not invent a resume operation or replace a failed original. The
recipient uses ordinary `mailbox sync` followed by `message list`, with exact
remote text correlation in RAM. A failed original send/receive stops future
authoring, collects already admitted operations under their original budget, and
allows one diagnostic ordinary local history read. Its original presence or
absence is inspected without treating an ACK or sender Store as the read result.

`-ObserveRecovery` permits continued ordinary observation after recovery counters
are nonzero. Those counters and raw
`observedHistoryReadResultMilliseconds` remain separate from the first-attempt
sample, which stays positive infinity for a recovery-assisted or failed command.
Raw ordinary-read timing also requires exact outbox/recipient event correlation,
successful ordinary history response, unchanged inputs and clean drop-free EOF.
It does not require sender success or Store, and cannot grant performance
qualification. The default Group mode continues to stop on recovery.

Example single-pair pilot, using an existing archived runtime and a fresh
repo-owned run directory (execute with PowerShell7.6.5):

```powershell
& ./eng/Invoke-ThreeClientDeliveryEngineering.ps1 -MessageKind Direct `
  -SingleDirectSample -DirectSenderRole 1 -DirectRecipientRole 2 -Rounds 1 `
  -ObserveRecovery -BootstrapDirectory $bootstrap -RegistryOrigin $registry `
  -ExecutablePath $archivedExecutable -RunDirectory $freshRunDirectory
```

With a runtime supporting the genuine deferred receive surface,
`-ReceiveBeforeAck -RecentReadLimit 20` changes both Direct and Group observation
to `mailbox receive` → ordinary bounded `message recent`/`group recent` → ordinary
`mailbox sync` → the same ordinary recent read again. It validates the exact
retained page's processed/tombstone counts during sync and the original remote
text (plus group sequence) exactly once afterward. Only the first successful
correlated recent response supplies the read timestamp. Later ACK failure or
recovery cannot erase that diagnostic read, and cannot qualify the full sample.
Prior pages without the planned original drain under the same bounds without
producing a read sample. Intentional deferred ACK continuation does not imply
recovery; actual recovery counters retain the existing infinity rule.

For a diagnostic group admission, `-LocalPreflightOnly` skips the separate
current-route preflight. Exact retained accounts, consent, group head, epoch,
cursor and native history remain required. Shared independently checks route
authority inside the original send. Receipts distinguish this local preflight
from verified current routes, and every release/warm qualification flag stays
false. This option does not permit authoring past a retained partial group
command or retrying a new direct operation in place of the original pending one.

The focused source filter for measurement and the new command surface is
`FullyQualifiedName~Deep.Cli.Tests.DeliveryMeasurementTests|FullyQualifiedName~Deep.Cli.Tests.RecentReceiveCommandTests`.

`Test-GsrEngineeringScenario.ps1` additionally compiles the small standalone
controller and exercises failed sender/ACK plus successful ordinary-read evidence
without opening profiles or making network calls. The new compiled xUnit cases
remain subject to the normal focused source gate.

`eng/Invoke-ThreeClientDeliveryEngineering.ps1` (PowerShell7.6.5) prepares the next bounded source
scenario. The runtime09 attempt at
`artifacts/retained-goal-20261105-09/engineering01/receipt.json` passed cohort
preflight, submitted sender1/sequence61 and stopped on a recipient command error;
it has zero finite samples. That original submitted work remains retained. The
separate normal-history read timing below is added source pending focused/live
evidence; the historical checkpoint below does not qualify it.
It requires an existing
Windows CLI runtime and the real public bootstrap/Registry inputs; it never builds
or publishes its own runtime.

Defaults select the retained Alice/Bob/Carol aliases, GSR group revision11 and
cursor60 from retained59. Four complete rounds author12 messages, four per role.
A successful run ends with192 group messages/64 original local commands per
profile and next shared cursor64. `-Rounds` permits1..4; qualification-sized
200 measured +20 warmups per role across three independent runs is deliberately
unavailable until the larger architecture is accepted.

The driver archives its runtime and exact helper sources and writes the complete
population before opening clients. Preflight requires existing accounts, exact
mutual contact consent, one matching Active/epoch2/three-member group, matching
native history/command counts, and strict verification of all six current routes
through `contact route-verify`. That command calls Shared's actual native current-L
verifier and returns closed success without exporting a descriptor or capability.
The `route-health` predicates remain informational in the command diagnostics;
the original inbound XUR interval can be historical after a current count8 route
was adopted. It cannot qualify or reject current L. The existing Shared operations
independently validate every effect. Expiry, mismatch or failure stops; there is
no contact repair, publication, account creation, group resume or reset.

All three stderr readers are armed before submissions. For each planned message,
the sender command and both recipients' ordinary mailbox commands start without
waiting for sender completion. Successful empty/non-final receives may schedule
another bounded page through the same Shared API. This is explicit engineering
scheduling, with deadline/page limits and one outstanding command per profile;
it supplies no product background receive or business retry implementation.
Empty successful polls wait at least100ms before another request; nonempty pages
drain immediately. The total request bound derives from the sample budget divided
by that cadence plus the16 nonempty-page allowance. The cadence, budget and bound
are recorded in the receipt, and polling time is never subtracted from latency.
The event controller keeps its4096 default. This driver explicitly supplies the
event budget derived from its predeclared sample/request caps, rejects any budget
above100000 before opening profiles, and reports exact stream counts/drop facts.

Actual durable projection events keep their existing measurement time. After a
recipient's Sync completes, the driver issues ordinary `group messages` through
that same serial session. It requires exactly one remote-author item with the
planned text and sequence in RAM. The controller separately measures from the
sender's accepted command to the successful history response release, using its
same monotonic clock. This includes any Sync/ACK wait and normal history read;
an ACK timestamp never substitutes for the read result. No message text enters
the receipt. Balanced-round history checks still only validate content/counts.
The receipt includes every planned sample, each directed recipient sample,
per-role p95 and all six directed-pair p95 values. Failed, recovery-assisted,
missing or unsubmitted samples remain positive infinity (`null` plus the explicit
flag in JSON), and nearest-rank retains their full denominator. A failure stops
future authoring; submitted Shared-owned operations and the role/sequence/session
command ordinals are retained. Hosts are never silently restarted.
After a recovery-assisted result or measurement-stream rejection, the driver
collects only commands already submitted to those hosts, using each command's
remaining original product budget (group send thirty minutes, other driver
commands five minutes). It submits no further send, receive, or history command.
Their returned counts and late dispositions are recorded separately. The run
and its full performance population remain failed/infinite even if those
original commands complete successfully and all streams close cleanly.
The receipt preserves the first closed failure phase/code, distinguishing cohort,
route expiry/fault, changed inputs, command error/timeout, invalid/recovery-assisted
results and assertion failure without recording raw exceptions or identifiers.
Failed steps also retain only whitelisted CLI code/category/check and bounded
code-owned method/IL frames from the already closed diagnostic. Unknown values
become closed placeholders; exception text, extra fields and paths are excluded.
An independently valid closed-stream durable-visible observation remains in the
sample's `observed` block if a later receive/ACK command fails. The qualification
sample and per-role/directed-pair percentiles still count that failure as infinity;
the raw observation is not a success or sender Delivered status.

Finite samples require matching current native-outbox, Store and durable-visible
events, successful sender completion, unchanged inputs, and clean drop-free
terminal/EOF from every host. Store timings are separate from first/all recipients.
The separate `historyReadResultMilliseconds` recipient fields, first/all history
result fields and `historyReadP95Milliseconds` role/pair fields keep the same
complete population and explicit infinity rules. Missing, failed, duplicate or
uncorrelated history results cannot become finite through a projection event.
Tombstone ACK and application receipt timings are explicitly unobserved; command
durations for receive+ACK are labelled separately. The driver always reports
warm-latency/product-background/release qualification false.

Command diagnostics include separate `nativeStorageWork` from Shared's closed
post-owner persistence Event2. Open/cipher/metadata/suffix/payload/audit/maintenance
costs sum across operations; working/archive inventory fields explicitly report
maxima across authenticated observations. These counters never enter the semantic
delivery stream or provide permission to read, send or ACK.

`eng/Test-GsrEngineeringScenario.ps1` checks only syntax, pure selectors, balanced
population and invalid-scope rejection; it opens no profile or network. Controller
unit tests additionally distinguish nonqualifying progress observations from
closed-stream directed-recipient timings. These checks are not live delivery or
proof of p95≤1s.

The captured pure-harness run at
`artifacts/concurrent-engineering-driver-20261026/harness01/terminal.json`
passed 40 engineering checks and 9 existing GSR scope checks under PowerShell 7.6.5,
SDK 10.0.301, native exits 0 and unchanged helper inputs. It opened no profiles and
made no network calls or managed builds/tests. The subsequent coherent compiled
receipt at `artifacts/concurrent-engineering-driver-20261026/compiled01/terminal.json`
used Windows PowerShell 5.1.26100.9457 and SDK 10.0.301: Release build exit 0 with
zero warnings/errors, then 41 focused cases passed with no failures/skips and native
exit 0. The 2112 captured source inputs stayed unchanged during the build and 2270
source/binary/normative inputs stayed unchanged during tests. The focused filter
covered delivery measurement, persistence diagnostics and session lifecycle. This
is focused acceptance only; the retained live scenario and full gate remain unrun.

Local diagnostic preparation retained both publication receipts under
`artifacts/concurrent-engineering-driver-20261026/`: `publish01/terminal.json`
records native exit 0 but rejected input preservation because RID restore changed
four tracked lockfiles. Their generated patches/hashes and exact restoration to
the captured baseline remain in `publish01/lock-restoration.json`. Fresh
`publish02/terminal.json` used `--no-restore`, native exit 0 and all 2110 source
inputs unchanged. Its Release win-arm64 Latency runtime is
`artifacts/concurrent-engineering-runtime-20261026-02/`; this is diagnostic
publication, without release or performance acceptance. The preceding local Node
Build/Up/Verify succeeded, but its preservation wrapper remains unqualified:
`ExactMountBindingsUnchanged=false`, with the exact mount diff unavailable.
The original receipt and closed annotation are
`../deep-devops/artifacts/deep-dev-current-node-upgrade-20261026-01/terminal.json`
and the sibling `preservation-annotation.json`; all three supported native actions
exited 0 while the preservation wrapper exited 1.
Preserved named volume identities, online keys and the older six containers do
not establish complete mount preservation.

`preflight01/receipt.json` confirmed all three retained profiles at 180 history
items/60 local commands, revision 11, Active epoch 2, three members and matching
consent. All six route directions had expired advertisement/update intervals and
no retained route fault. The separately authorized existing `ConnectionCycle`
stopped in `maintenance01/receipt.json`: role 1 publication succeeded in 47,591 ms;
role 2 `NetworkPublish` failed with business exit 6 after 36,519 ms, CPU 11,641 ms,
closed check `ProtectedState / RouteTimePMS2NotBefore`
(`maintenance01/failure-4.json`). The complete maintenance process took 89,855 ms
(`maintenance01.native.json`). These are maintenance durations, not warm delivery
latency. Successful publication and the failed role's pending work remain retained.

`blocked01.terminal.json` records three planned messages, zero authored, no
diagnostic execution and all 2110 source inputs unchanged through terminal;
the next shared cursor remains 60. Visibility/ACK timing and byte traffic are
unobserved. The runtime inventory is `blocked01.runtime.json`; file-length-only
before/after observations are `profile-metadata-pre01.json` and
`profile-metadata-after-blocked01.json`. No reset, reauthoring, automatic repeat,
second preflight or message round followed the failure.
