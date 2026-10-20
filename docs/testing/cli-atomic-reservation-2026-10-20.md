# Reservation and original ACK recovery — 2026-10-20

Scope: retained local three-node development contour and native CLI profiles.
No production, Windows/Android application, account/key/floor or volume reset.
Owner: Mr. X. This is focused source/connected evidence, not release acceptance.

## Changes and original custody

The single normative owners are
[DR-0154](../../../docs/survival-program/decisions/DR-0154-peer-reservation-preparation.md),
[DR-0155](../../../docs/survival-program/decisions/DR-0155-durable-store-forwarding.md),
[DR-0156](../../../docs/survival-program/decisions/DR-0156-historical-peer-custody-repair.md),
[DR-0157](../../../docs/survival-program/decisions/DR-0157-current-absent-target-tombstone.md)
and [DR-0158](../../../docs/survival-program/decisions/DR-0158-expired-prepared-final-ack.md).
They replace reserve-before-protect with closed preparation, protect-before-native
commit and exact crash recovery. Source-durable PSR1 replaces raw Store HTTP;
no raw compatibility reader. PTR1 remains tombstone-only.

The actual original orphan had514 native replay records and513 independently
protected facts. Supported listener-free source export and recipient reconciliation
produced514/514, zero unpaired records, unchanged recipient mutation inventory and
zero Store/quorum effects. The original request is still Pending, not rewritten
as successful old quorum. The old grant was expired: historical metadata repair
does not authorize expired Store. The existing client successor delivered the
same retained native ciphertext through a current transport attempt.

The current original Store completed in13.352s: CPU12.234s, one ONION request
2.657s, zero Store resumes, mailbox resumes and lease waits. Receive then exposed
an absent partial replica target and later the unsupported expired prepared ACK.
Those failures are preserved; negative tombstone and exact ACK closure were
implemented instead of resurrecting the Store or resetting either account.

## Measurement ledger (not matched same-data benchmarks)

| Actual operation | Seconds | Outcome |
| --- | ---: | --- |
| Prior clean partial text Store | 46.669 | Store passed, later receive failed |
| Original continuation before historical repair | 74.522 | FAIL; one resume and one lease wait |
| Original Store after metadata repair | 13.352 | verified Store; no resume/wait |
| Subsequent original receive/ACK | 98.372 | FAIL; absent partial replica |
| ACK acquisition after node update | 10.499 | FAIL before dispatch; endpoint head race |
| ACK after endpoint-set correction | 14.108 | FAIL before dispatch; expired prepared ACK |

13.352 versus46.669 is3.50x lower observed Store latency (-71.4%), but different
retained recovery states, not a matched new-message result. Neither this nor a
local parser/read timing proves complete1–2s delivery or parity with Signal.
Final connected replay and new-message/group measurements are recorded below.

## Evidence ownership and preserved failures

All current run names below are under each repo's ignored
`artifacts/cli-atomic-20261020/`; raw proofs/snapshots/traces remain private.

- DevOps `historical-repair-01`:514/514 with original Pending preserved, zero
  unpaired and no recipient mutation/quorum effect.
- CLI `original-store-01`: failed original continuation. `original-store-02`:
  Store passed, receive failed; the whole run is not PASS.
- CLI `original-ack-01`: harness refused GUID formatting before network work;
  the diagnostic generated32 hex characters, not a hyphenated GUID.
  `original-ack-02/03`: actual pre-dispatch failures in the table above.
- Node `absent-target-01`: test compilation failed from an incorrect byte-array
  Span access; `absent-target-02`:12 PASS/native0 after the harness correction.
- Shared `ack-acquisition-01`:6 PASS/native0, independent endpoint capture and
  different-view rejection. `expired-ack-01`: missing using, build/native1.
  `expired-ack-02`:41 passed/4 failed/native1; the test terminal incorrectly
  reused one ACK request/receipt for all operations and the SQL corruption helper
  parsed ACK as Retrieve. Corrected to exact per-operation request/receipt custody
  and operation-specific decoding, without relaxing original-request equality.
  `expired-ack-03`:45 PASS/native0, including actual encrypted cold reopen,
  original SQL preservation, closure interruptions and hostile native requests.
- Node `final-focused-02`:54 PASS/native0; `final-focused-03`:21 PASS/native0,
  including current-clock recheck after custody recovery. `current-reack-05`:
  12 PASS/native0, both actual replicas, mixed two-item original batch, immutable
  old completed tombstone, captured/unadmitted item, missing/changed old intent
  and refusal to replace a still-pending native tombstone. Earlier re-ACK failures
  remain recorded; this does not qualify same-grant recovery after unknown reply.
- Protocol `focused-04`:43 PASS/native0, preparation/PSR1 and pure exact-request
  identity (no admission authority). CLI `build-05`:66 PASS/native0.
- Protocol `final-debug-build-01`:0 warnings/errors, native0. Graph checks
  `final-graph-03/04` rejected the stale positive snapshots as intended. Metadata
  review found exactly two additional methods, no public type/constructor or
  embedded resource additions: current absent-target preparation and pure replay
  digest. `final-graph-debug-05` / `final-graph-release-05`:PASS/native0 after
  updating both exact positive snapshots. The later approved normative-commit
  repin changes generated metadata and requires a new final build/check.

- Final post-repin Protocol `final-source-01`:54 PASS/native0; CLI
  `final-build-06`:66 PASS/native0. Registry generation/check, manifest integrity
  and ownership exact314/package219/final95 all passed. Protocol/Shared CI pins
  now select the exact committed normative snapshot, not the preceding docs.
- Node `final-source-06` is **aborted/unqualified**, native1: its final TRX
  records283 PASS/4 FAIL. The test host was explicitly stopped after the known
  failures to return to targeted fixes; this is not a completed broad PASS.
  Three failed cases were two old Writer fixtures still passing raw Store into
  the strict PSR1 client. Their replacements use a genuine fixture-key-signed
  malicious non-writer PSR1 claim and retain HTTP403, empty native state, counter
  and diagnostic assertions; raw input is additionally rejected before HTTP.
  These fabricated attack inputs belong ONLY to rejection tests, never connected
  E2E or positive durability evidence. `writer-psr-01`:3 PASS/native0.
  The fourth case expected blanket rejection of every new ACK over a terminal
  target, superseded by DR-0157. It now asserts exact old native tombstone bytes,
  original batch retention, current new ACK, and cold replay without extra HTTP.
  The independent pending-tombstone refusal test remains unchanged.
  Node `final-source-07`:71 PASS/0 FAIL/0 skip, native0, covering those four
  corrected cases plus the actual reservation/crash/currentness/PSR1/negative
  custody and exact-current-ACK regression union. This targeted PASS does not
  relabel the aborted broad run as successful or qualify unfiltered full.
  Final Protocol `final-debug-build-08` / `final-release-build-08`:native0,
  zero warnings/errors; their matching `final-debug-graph-08` /
  `final-release-graph-08`:PASS/native0 on the post-repin assemblies/resources.
  DevOps contract tests31/31 PASS; changed PowerShell scripts parse cleanly.

Normative DR-0154–0158 and the frozen §7.19 owner were committed before repinning
Protocol's approved normative binding. The existing219 executable mapping IDs and
test owners are preserved; the implementation scope additionally binds the new
source/fixtures. Manifest integrity-only passed; this alone is not execution of
the219 witnesses or full source/package qualification.

Supported latest node build/up/verify exited0 (31.470/10.893/9.951s). All nine
services are healthy; CPU limits and non-node images are unchanged. Node image:
`sha256:cfa1c2250a1a1788850a7d4287a94177838ae300ed83e9ad9a1e0a50d2f4511a`.
The literal topology comparison is not an all-mounts-identical PASS: one read-only
node bind source uses Docker Desktop's Linux host-mount spelling instead of the
Windows spelling. `deploy-06` resolves this exact drive-prefix correspondence to
the same existing host file; all other mount fields match and all named volumes
are unchanged. No custody path was substituted. `deploy-04` also omitted fields
in its comparison projection; `deploy-05` retains the corrected full-field
comparison and its one literal source-spelling delta.

Full unfiltered source, frozen/package, sustained/scale, device and production
acceptance remain separate and open. Original failed topology assertions also
remain failures; unchanged named data/key volumes do not prove all bind sources
unchanged. No unknown result, native orphan or missing completed history is
silently promoted to success.

## Final connected replay

`original-ack-06` PASS: the exact original message was received once, pending
sender work is empty, two objects were durably ACKed, then the next poll was
empty. Receive-only recovery queued zero commands. Original receive/ACK29.480s
(CPU13.391s; ONION13.986s), empty poll6.063s. Store/mailbox resumes and lease
waits were zero. This is original-work recovery, not a new first-attempt send.

`direct-clean-01` PASS on the retained pair: one newly queued message was stored,
received once and durably ACKed; the next poll was empty. No driver retry, Store
resume, mailbox resume, lease wait or HTTP non-success. Timings exclude network
warmup and history checks unless named explicitly:

| New direct operation | Seconds | CPU seconds |
| --- | ---: | ---: |
| Sender network warmup |14.827|7.812|
| Receiver network warmup |15.526|7.312|
| Queue |2.079|1.562|
| Store |42.105|14.688|
| Receive and durable ACK |26.684|11.484|
| History verification |5.257|4.609|
| Empty next poll |6.434|2.391|

New-message Store46.669→42.105s is an observed9.8% reduction; queue6.044→2.079s
is65.6% lower. Different retained states/times mean these are not controlled
same-data benchmarks. Active queue+Store+receive is70.868s: the1–2s objective
remains unmet. The recovery Store13.352s must not be substituted for fresh-send
latency. Fresh Store made two ONION calls totalling23.811s (max12.354s).

`steady-01` cursor14 FAIL after20 successful setup/preflight commands. The first
fanout stopped after27.708s on `RouteTimeXRA1Expiry`; no automatic resumes or
lease waits. Normal authenticated route-health reads showed both directions of
one pair's XRA1 and their original XUR1 expired. Exact original batch/commands,
all accounts and native histories remain retained. No expired-route permission,
replacement event or private-state import was used. This is a real offline-route
blocker, not a completed group round. The subsequent isolated three-account
lifecycle is separate evidence and cannot qualify recovery of this batch.

## Isolated three-CLI lifecycle: PASS, not retained-round recovery

`lifecycle-01/02` failed during account publication on a typed ingress
`Unavailable` rejection before forwarding. Both failed receipts are retained.
The same isolated accounts and their exact publication custody were continued;
they were not reset or replaced. No contact/group had been created in those
failed setup attempts. Therefore the entire setup is not a from-scratch
first-attempt qualification, even though every command in the successful run
used one driver attempt.

`lifecycle-03`:98/98 PASS, 19:04:38–19:27:17 UTC. All three pairs reached mutual
consent; group creation, two invitations, both acceptances and GSR1 succession
completed. All three members are Active at epoch2. Each authored one group
message, delivered to both other members: six native receive/durable ACK checks.
Cold history contains exactly three messages/one local command per profile.
Original full-batch replay, deduplicated history and empty mailbox/GSR checks
passed. Store resumes0, mailbox resumes0, lease waits0, HTTP non-success0, driver
attempts above1:0. Account/route/counter/native checks were not relaxed.

This uses three new isolated profiles with current routes, not the expired
retained cursor14 pair. It does not resolve mutual offline expiry or erase that
failure. Runtime and driver/module hashes plus the archived runtime are in the
receipt. The timed runtime is `build-05`; the subsequent approved normative
commit/manifest repin changes evidence metadata, not the transport/business
implementation used in this run. The final build is checked separately.

### Observed comparison, with different client histories

The earlier strict retained cursor13 has42 messages/14 local commands per
profile; the isolated lifecycle has3/1. Node data/keys/CPU limits are retained,
but client histories, setup, grants, time and load differ. These values show
actual runs, not causal same-data speedup or Signal parity. Do not compare their
whole-run totals: the new run additionally creates contacts and group state.

| Message-path operation | Retained cursor13, s | Isolated lifecycle, s | Observed change |
| --- | ---: | ---: | ---: |
| Three fanouts, sum |320.881|129.109|-59.8%|
| Fanout mean |106.960|43.036|-59.8%|
| Six receive/ACKs, sum |228.696|140.661|-38.5%|
| Receive/ACK mean |38.116|23.444|-38.5%|
| Fanout + receive/ACK, active sum |549.577|269.770|-50.9%|

Individual new fanouts:29.926 /40.134 /59.049s; receive/ACKs:
21.288 /23.315 /21.218 /25.914 /22.596 /26.330s. The rising fanout tail and
CPU8.719 /17.422 /31.625s remain a performance concern, not a solved1–2s SLO.

### All successful-run operations

Durations are active command sums in seconds, including setup; local inspection
commands are retained rather than hidden. Active sum1347.314s; wall1358.513s;
CLI CPU443.686s. No heavy build/test ran during this connected scenario.

| Phase | Calls | Total seconds |
| --- | ---: | ---: |
| account-cold-status |3|1.336|
| network-verify-publish |3|65.942|
| pair-left-cold-list |3|1.751|
| pair-right-cold-list |3|1.697|
| explicit-peer-address |3|0.301|
| pair-contact-request |3|106.008|
| pair-contact-receive-ack |3|147.166|
| pair-left-session-list |3|3.034|
| pair-right-session-list |3|6.816|
| pair-explicit-contact-accept |3|111.990|
| pair-consent-receive-ack |3|73.888|
| pair-final-contact-consent |3|1.933|
| owner-initial-group-list |1|0.126|
| owner-create-group |1|0.204|
| retained-owner-membership-head |2|0.302|
| retained-invitee-head-selection |2|0.303|
| owner-invite-original-batch |2|124.504|
| invitee-complete-lineage-invitation-ack |5|159.701|
| invitee-explicit-accept-original |2|53.521|
| owner-consent-ack |2|43.205|
| owner-successor-complete-fanout |2|18.006|
| owner-mailbox-batch-stored-head |2|0.268|
| ordinary-mailbox-does-not-carry-new-commit |3|23.169|
| gsr-independent-cold-control-catchup |3|18.219|
| exact-protected-successor-head |5|0.721|
| exact-three-active-owner-head |1|0.143|
| exact-three-active-recipient-head |2|0.231|
| sender-original-command-count |3|0.390|
| one-command-two-recipient-fanout |3|129.109|
| fanout-recipient-native-receive-ack |6|140.661|
| three-way-cold-native-history |3|6.964|
| cold-original-full-batch-replay |3|60.742|
| post-replay-empty-mailbox |3|17.894|
| post-replay-deduplicated-history |3|7.794|
| owner-cold-control-receipt-reverification |1|3.769|
| cold-control-cursor-empty-replay |2|15.506|

## Source handoff

Branch: `release-candidate/prod-20260909`. Author: zhigubigule (GitHub no-reply).
Normative freeze:`bab4de0`; Protocol:`34ee003`; Shared:`474b9ce`;
XNode:`b22125f`; DevOps:`f38d23d`. Root pointers are updated after the separate
repository commits. No GitHub release, production deployment, main merge or
Windows/Android work is included. Package/device/release acceptance remains open.
