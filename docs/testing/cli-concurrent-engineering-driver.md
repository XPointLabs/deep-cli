# Concurrent engineering driver

`eng/Invoke-ThreeClientDeliveryEngineering.ps1` (PowerShell7.6.5) prepares the next bounded source
scenario. The concurrent message scenario has not been run against the retained
cohort; the separate local preflight/maintenance checkpoint is recorded below.
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

Only actual durable observations supply measurement time. History checks after
each balanced round validate content/counts and never set a visible timestamp.
The receipt includes every planned sample, each directed recipient sample,
per-role p95 and all six directed-pair p95 values. Failed, recovery-assisted,
missing or unsubmitted samples remain positive infinity (`null` plus the explicit
flag in JSON), and nearest-rank retains their full denominator. A failure stops
future authoring; submitted Shared-owned operations and the role/sequence/session
command ordinals are retained. Hosts are never silently restarted.
The receipt preserves the first closed failure phase/code, distinguishing cohort,
route expiry/fault, changed inputs, command error/timeout, invalid/recovery-assisted
results and assertion failure without recording raw exceptions or identifiers.
An independently valid closed-stream durable-visible observation remains in the
sample's `observed` block if a later receive/ACK command fails. The qualification
sample and per-role/directed-pair percentiles still count that failure as infinity;
the raw observation is not a success or sender Delivered status.

Finite samples require matching current native-outbox, Store and durable-visible
events, successful sender completion, unchanged inputs, and clean drop-free
terminal/EOF from every host. Store timings are separate from first/all recipients.
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
