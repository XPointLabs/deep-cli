# Durable visibility observations — 2026-10-26

This is the first P0 measurement slice of the [current S05 work](../../../docs/NEXT-SPRINT.md).
It is source/unit evidence. No live E2E, retained send, publish, reset or device run
was performed; the retained cohort and next cursor60 were not used or changed.
Warm-online p95≤1s is not demonstrated. Shared full/package/release gates remain open.

## Implemented boundary

Shared stages optional domain-separated hashes of authenticated random semantic
IDs while materializing direct/group text. It publishes `RecipientDurableReadable`
only after final freshness succeeds and the private owner scopes are disposed,
before the separate mailbox ACK. Failed admission/materialization/final freshness
emits none; exact semantic replay emits no second observation. Observer exceptions
do not change the durable outcome. This observation does not mark sender delivery.

`NativeOutboxDurable` describes the committed encrypted per-target transition,
not the earlier logical command reservation. `StoreQuorum` is observed only when
the successful call actually dispatched ingress; cached original receipt reads
emit no new quorum event. Tombstone ACK and authenticated application receipt
timings remain unobserved and cannot be inferred from these events.

The CLI opt-in `--delivery-events true` preserves ordinary stdout responses and
streams closed diagnostic JSON on stderr. Valid bound command acceptance precedes
the serial operation wait. One controller stamps complete arriving events with
its monotonic clock, including observer/stdio overhead. It never uses source
wall clocks, command completion, history polling or ACK responses as visible time.

`Start-CliSessionCommand`/`Complete-CliSessionCommand` permit independent existing
processes to execute concurrently. The adapter implements no receive scheduler.
The controller requires successful sender completion, matching current native
outbox/Store/recipient observations, and clean terminal plus EOF from every
attached process before returning finite samples. Errors, timeouts, missing
observations and unfinished runs remain positive infinity. Nearest-rank includes
those samples. Unknown/duplicate/out-of-order frames and hostile bounds reject.

The 256-frame diagnostic queue never blocks an owned transition. Its mandatory
`StreamClosed` terminal bypasses the queue after draining and reports dropped
frames, detecting even a dropped last event. The controller's4096-event bound
also rejects the run. Use a fresh controller for each independent run and derive
final samples only after all clients close. The old sequential E2E drivers still
measure command durations; no concurrent engineering delivery run is claimed.

Shared's accompanying P1 change batches actual authenticated protected reads
within the existing owner operation and preserves missing/corrupt/cancellation/
cold-reopen checks. The [storage-owner proposal](../../../deep-client-shared/docs/architecture/semantic-operation-storage-owner-proposal.md)
describes subsequent work; it does not claim that a new owner architecture shipped.

## Captured validation

Native runs used Windows PowerShell5.1.26100.9457 and SDK10.0.301, the existing
`scripts/TestGate.psm1` native runner and TRX reader, and source/binary/normative
input captures. Every successful build had zero warnings/errors. Artifacts are
local ignored evidence; the manifests pin the executable content tested before
this checkpoint was written.

| Receipt | Result | Scope |
| --- | --- | --- |
| [Initial Shared build](../../../deep-client-shared/artifacts/p0-p1-focused-20261026-01/build-terminal.json) | native1, preserved FAIL | New test xUnit2031 assertion; corrected to predicate overload before rebuilding. |
| [Initial Shared focused](../../../deep-client-shared/artifacts/p0-p1-focused-20261026-02/terminal.json) | native0,29PASS/0FAIL/0skip; inputs unchanged |26 P1 batch/compaction/read-scope cases +2 diagnostic release cases +1 actual receive/lost-ACK case. |
| [Initial CLI suite](../../artifacts/p0-delivery-measurement-20261026-01/terminal.json) | native0,108PASS/0FAIL/0skip; inputs unchanged |87 existing +21 initial measurement cases. This predates the two review fixes below. |
| [Final affected Shared](../../../deep-client-shared/artifacts/p0-review-fixes-20261026-01/terminal.json) | native0,3PASS/0FAIL/0skip; inputs unchanged | Final freshness/observer failure, actual pre-ACK visibility/lost ACK/replay, cached Store suppression. |
| [Final affected CLI](../../artifacts/p0-review-fixes-20261026-01/terminal.json) | native0,31PASS/0FAIL/0skip; inputs unchanged |24 measurement +7 session cases, including actual queue tail overflow, required terminal/EOF, missing Store and sender errors/timeouts. |
| [PowerShell harness smoke](../../artifacts/p0-review-fixes-20261026-01/harness-smoke.json) | Core7.6.5 PASS | Clean terminal accepted; absent terminal rejected; missing sample remains infinity. No CLI process/profile/network. |

Independent review found two defects after the initial29/108 receipts: cached
Store observations could be emitted again, and a dropped final diagnostic frame
had no later sequence gap to reveal it. Both were corrected and the affected
3/31 cases rerun on captured unchanged inputs. Initial receipts remain intact;
they are not presented as validation of the corrected implementation.

Required next work is the concurrent engineering driver, the larger Shared/node
owner and dispatch/receive changes, then the sprint's short progress proof and
separate acceptance runs. No latency target or physical readiness is qualified here.
