# Three-CLI GSR1 functional checkpoint

Owner: Mr. X. Updated: 2026-10-19. The current three-member functional cycle
passed through retained-state recovery in17–20. This is not first-attempt
reliability, release, device, scale or long-offline acceptance.

Subsequent public-read/native-grammar performance changes and the retained
three-CLI rerun are recorded in the
[2026-10-19 performance checkpoint](cli-gsr-performance-2026-10-19.md), including
all failed/recovery attempts and operation timings. The228s samples below are
the earlier baseline, not the current performance result.

Normative allocation: [DR-0145](../../../docs/survival-program/decisions/DR-0145-owned-group-control-rendezvous.md).
Custody/consumer mapping: [Shared](../../../deep-client-shared/docs/architecture/owned-connected-groups.md).

## Accepted current result

`e2e-20`: PASS/native0,51 cold CLI processes,0 failed steps. It continues the
same current-runtime group/profiles from17–19, not a replacement group or repaired
native state. The connected chain covers all three mutually consented pairs,
create/invite/accept, sequential activation to3 members/epoch2, empty ordinary
mailboxes and independent GSR catch-up on both recipients. All protected heads
match. One semantic message from each participant reaches both peers; every cold
native history contains exactly3 messages,1 local, with exact expected texts.
All three original full Store batches replay, all mailboxes remain empty and
histories deduplicate. Cold owner GSR receipt re-verification passes; both
recipient control cursors return0 events. No new send replaces an unknown one.

Runtime SHA256: `f788081a65a27ca8116f08b9b8388f7fd519873f115521d272d1fb34f8d5e8b7`.
Scenario SHA256: `eee94d8c07b91e0b45e26c6d63ad8f6d7575a6d8c2cb0f90f36b3bcbae262783`.
Accepted receipt SHA256: `1679947bef1f87ed46e4221ab0ac34178456257f2df2502a4c2e30e3b894bf14`.
Every run's original receipt/scenario/runtime archive remains under its ignored
`artifacts/cli-gsr-20261018/e2e-N/` directory. Earlier failures are not overwritten.

Latest focused source evidence: CLI unit09:49; Shared native06:12 and
store-fence01:2; Protocol focused05:29, forwarding03:35, registry04 and graph05;
Node control-pagination03:14 and forwarding09:25; Registry scope02:6 actual
pure/provider/HTTPS cases; DevOps contracts02:30. All PASS/native0, not full gates.
The final node candidate is supported build11/up10/imagea81582f, retaining
existing node keys/volumes and1-CPU quotas. Registry retains the documented2-CPU
local budget and imagefbc3ed4. Windows/Android and production were not changed.

Performance improvements are real but not an end-to-end latency qualification:
CLI native-protection cost is now milliseconds per read rather than re-opening
the entire DPAPI aggregate, and node reads no longer parse the same operation
snapshot twice. Nevertheless, original first two group fanouts took227858/
227826ms and retained third fanout recovery114369ms. Repeated directory/network
verification remains costly. First-attempt reliability, performance/SLO, expired
unknown operations and the scope exclusions below stay open.

## Current implementation

Current NETCODEC revalidates descriptor-anchored two-replica placement through the
exact PMS2 rank transcript, including the original PMT2 reference (DR-0146). A
routine current view/epoch renewal cannot silently move an existing CAS stream. Current DID2 owner-device custody
signs per-recipient descriptors, shared with their independent sealing keys only
inside authenticated pairwise E2EE. Protected group generation3 rejects older
generations without migration. Ordinary journal9 and SQL schema17 do not change.
Earlier profiles and receipts remain untouched; this scenario uses fresh CLI
profiles rather than importing/resetting device state.

Original sealed control chunks/requests precede dispatch. A write completes only
with independently checked signatures from both selected replicas. New successor
commits are fetched independently of ordinary mailbox retention; package/chunk
adoption and cursor advancement share the protected root CAS. An installed
control stream cannot be bypassed with a new ordinary-mailbox commit. Explicit
gaps, expiry, conflicts and unavailable authority are not empty successful sync.
Only descriptor generation0 is activated; unqualified successor/handover rejects.

Retained Store checks share an actual opened native scope and owned authority
within one held phase; every original event/receipt remains verified. Native
history opens each scope once per read. Multi-scope ACK batches actual joint
authority-floor reads for reference-identical own capabilities, independently
checking every peer, scope, clock and native row. Every callback phase reads
floors afresh. No plaintext DPAPI cache, deadline extension or Stored-bit shortcut.

## Source checks

Paths use each repository's `artifacts/cli-gsr-20261018/` prefix.

| Receipt | Result / boundary |
| --- | --- |
| Protocol `focused-05` | 29 PASS/native0/no skip: group reducers/grammar and sealing/carrier negatives |
| Protocol `graph-03` | normal Release/Debug build and exact-three assembly/resource/API/source graph PASS/native0 |
| Protocol `registry-01` | strict registry/source/anchor gate PASS/native0 |
| Shared `ack-02` | 8 PASS/native0/no skip: native descriptor, mandatory journal, held floor batch, lost ACK/cold receive before later acquisition correction |
| Shared `native-05` | 10 PASS/native0/no skip: current group/journal, real signed anchor renewal and mixed-view acquisition/captured-owner refusal |
| Shared `placement-02` | 2 PASS/native0: independent PMS2 formula and stable anchor through a real signed view/selection-epoch successor |
| Node `focused-05` | separate integration13/core8 PASS/native0; opaque CAS, receipt/replication, restart, lazy authority and explicit service-clock composition; not physical current source evidence |
| CLI `build-04`, `unit-04` | zero compiler warnings/errors; 47 PASS/native0/no skip, including closed GSS diagnostics |
| DevOps `node-build-05`, `node-up-04` | supported local current-node build/activation native0; existing node volumes, keys, ports and CPU limits retained |
| DevOps `contracts-01` | 30 PASS/native0/no skip |

Rejected/failed receipts stay unchanged. Protocol `focused-01/02` were test-import
compile failures, corrected before `focused-03/04`. `graph-01` and
`graph-review-01` rejected the changed positive API snapshot before actual metadata
review and the accepted current-only snapshot update. Shared `native-01` retained
a fixture assertion failure: bootstrap may be one chunk, so the malformed-chunk
test now independently covers canonical changed bytes as well as non-final total
geometry. `native-02` passed5 before later batching work. Shared `ack-01` was
explicitly interrupted with native-1: its inputs predated the completed batching
change and its broad Braid subset was not new-code qualification. Node
`focused-01` used a solution-wide TRX filename and overwrote project receipts;
`focused-02` reran the unchanged tests into separate per-project directories.
Shared `native-03/04` retained compile errors from attempts to use internal/nonexistent
head-core APIs. `native-05` compares the already independently verified DTT1 view
and ADH core hashes through existing public fields; no Protocol verifier weakened.
Node `focused-03` retained a compile error caused by an internal Protocol property
reference; `focused-04/05` use the existing public expiry ceiling and pass.
`graph-anchor-review-01` rejected the new API snapshots before actual metadata
review; `graph-03` accepts only the reviewed current signatures. `node-build-04`
failed the independent time prerequisite before Docker build; unchanged supported
retry `node-build-05` passed without replacing custody or weakening time checks.

## Connected receipts

Scenario: `eng/Invoke-ThreeClientGsrE2E.ps1`; real local TLS/H2, three-hop ONION,
current signed directory/network proofs, persistent node replica stores and real
SQLCipher/native-ratchet CLI profiles. No mock transport or direct service path.
Each run archives exact scenario and profile-free runtime, checked before/after
every child. Raw addresses, profiles, capabilities, payloads and keys are not
exported in the receipt.

- `e2e-01`: FAIL after4 commands, before groups. The new account was retained;
  original contact publication saw ingress unavailable and then PMS2 not-before.
- `e2e-02`: FAIL before groups. All three retained accounts published; the first
  contact request exhausted two exact attempts (pre-forward ingress unavailable,
  then unknown Store). No account or intent was reminted.
- `e2e-03`: FAIL after46 commands on the same three published profiles. All
  three contact pairs completed, including native receive/consent ACK. The first
  invitation published two-replica control and arrived/was accepted. One invite
  ACK recovered by exact retry. The first successor publication returned unknown;
  the repeat failed directory proof I/O before dispatch. There is no GSR catch-up
  or group-message PASS. The moving-current-PMT allocation could silently change
  the pair across routine view/epoch renewal; DR-0146 corrects this defect.
  The exact negative GSS status was not recorded by the original diagnostic;
  current code adds only its closed enum, never response bytes or capabilities.
  The uncertain GroupRevision0 write remains preserved, not reminted/recovered.
  During second-pair setup, supported node build/up03 installed the service-clock
  fix without resetting volumes/keys; this is not first-attempt reliability.
  All three nodes run image `sha256:1ffedb2cae4a85cc7d7d25d4e09172e4fbd2d325ea9bc53fa667d5eed5389c1a`.
  No full group cycle was qualified by this run.

- `e2e-04`: FAIL after22 commands on the same mutually consented accounts,
  GroupRevision1 under DR-0146. Invitation/acceptance completed and the first
  successor publication passed with both receipt signatures (135194ms). Ordinary
  mailbox was empty. Independent GSR sync rejected an uncaptured own/peer signed
  view mismatch before querying; no control-adoption PASS. This is a separate
  corrected-allocation candidate, not recovery of old uncertain GroupRevision0. The driver now skips redundant
  network setup only after both protected local lists prove the exact mutually
  consented pair; every group operation still checks actual current consent.
  All nodes use image `sha256:06636e2830a3c5159bab32eccddc1b7fbf65f4f01f901e13bbc55c09320baecd`.

- `e2e-05`: FAIL23, same accounts and SAME GroupRevision1. Independent GSR sync
  passed first attempt (35256ms) after an empty ordinary mailbox; both protected
  heads are active at epoch1. Third-member invitation reached native receive,
  but its ACK failed twice. Original accounts, invitation and ACK stay retained.
  Runtime04 uses bounded whole-pair reacquisition for a legitimate signed-view
  race, never replaces a captured multi-target owner, and reuses verified public
  GSR package/chunk work only inside one held pre-dispatch phase.
  Failed child steps now retain closed network/protection counters as well.

- `e2e-06`: FAIL16 on the same original ACK. Bounded native-read sampling
  reports only method/count/time, no slot names, arguments or plaintext.
  Node diagnostics independently identified `ExpiredOrStale`: a second replica
  never received an original first reservation within120 seconds. Retrying that
  unaided original request cannot fix the missing reservation. DR-0147 allocates
  PTR1 exact source-durable proof forwarding, not a new ACK/nonce or relaxed time.
- `e2e-07`: FAIL15 before wire. The already prepared original ACK grant had
  expired during extended diagnosis; current continuation correctly refuses to
  remint a prepared unknown operation. That entire original profile/cycle stays
  preserved as an explicit unqualified expired-prepared-ACK recovery case.
  PTR1 does not authorize an expired client grant.
  CLI build06 and unit06 passed (native0,47 tests), without warnings/errors. Supported
  node-build06/up05 passed native0; all9 services are healthy, no volumes/keys reset.
  No three-member GSR/fanout qualification.
- `e2e-08`: FAIL4, a separate independent three-profile candidate. Only its
  first account was created; both publication attempts rejected before forward.
  Actual node diagnostics: PublicationCurrent issue time1s above gateway lower
  bound, interval width2s. No old accounts, unknown writes or expiry were reset.
- `e2e-09`: FAIL60 on the SAME new profiles/original pending publication after
  supported node-build07/up06. A bounded one-time gateway maturity wait reacquires
  current authority and reruns all original strict predicates before any effect;
  it does not accept future-issued requests or extend deadlines.
  Node `coordination-maturity-02`12 PASS/native0 includes actual monotonic
  convergence versus no convergence; `01` retains a test static-member compile
  failure. No sockets/physical claim for these handler tests.
  All three contact pairs completed. First invitation218052ms and successor
  publication135962ms passed first attempt; its ACK recovered by exact retry.
  Independent GSR catch-up38044ms passed after an empty ordinary mailbox, and
  both protected heads matched at active epoch1/members2.
  Third-member invitation442846ms passed first attempt. Its ACK failed twice:
  the peer rejected PTR1 source durability ahead of its independently current
  upper bound. Exact original intents remain unchanged; this was not an empty
  mailbox, a successful ACK or a full group-cycle PASS.
- `e2e-10`: FAIL15, same retained third-member ACK, after node-build08/up07 and
  CLI build/unit07. It stopped before dispatch because the prepared ACK's original
  grant expired during diagnosis. Neither ACK recovery correction authorizes an
  expired client grant. Original profiles and the pending cycle remain preserved.
- `e2e-11`: FAIL39 on the SAME owner/second member and SAME created group,
  plus a new independent third QA account. Only its two contacts are new.
  The excluded expired-ACK account remains a nonmember with a retained older
  invitation/control stream; active membership must still be exactly3 and only
  those three candidates exchange messages. This is not repair of that old ACK.
  Its new original invitation completed by exact retry (443147ms); receive/ACK
  then failed at the node native deadline, followed by a client loan cancellation
  before wire on the exact retry. Both candidates and original ACK remain intact.
  Subsequent correction keeps actual native SQL owners open only for the existing
  held ACK lease, but reconciles current floors/rows and semantic/freshness/root
  fences afresh at every callback; no cached admission or deadline extension.
- `e2e-12`: FAIL24, same group and all three retained candidates, original prepared ACK,
  runtime build/unit08 (47 PASS/native0, zero warnings/errors). The original ACK
  completed in122455ms and explicit third-member acceptance in147049ms, first
  attempt each. Owner consent ACK88902ms, successor346722ms and Bob GSR
  catch-up45555ms also passed first attempt. Carol's ordinary mailbox was empty,
  but both GSR attempts received canonical ingress Unavailable/before-forward.
  Published epoch2 and all accounts/cursors remain preserved, not reset.
  Node now emits bounded closed category/method/IL diagnostics at the existing
  group terminal catch boundary; no payload, selector, request or key is logged.
  Three-way application fanout/replay remains unqualified.
- `e2e-13`: FAIL20 on those SAME accounts/group. The diagnostic-only node
  build09/up08 reproduced Carol's two pre-forward failures; the terminal now
  located the rejection in strict GroupCodec decoding. A separate native
  regression (`control-pagination-01`) reproduced RecordLengthOutOfRange: the
  runtime decoded the full retained aggregate before selecting a fitting page.
  The fix sizes the prefix before encoding/decoding and keeps canonical65535
  versus padding65536 limits distinct. `control-pagination-02` retains an overly
  narrow new test helper assertion (10 PASS/1FAIL); corrected `03`14 PASS/native0
  includes3 large records, exact continuation after restart, RecordTooLarge and
  exact65535/65536 boundaries. Node build10/up09 activates that source only;
  no account, group, cursor, replica state, node key or volume is reset.
- `e2e-14`: FAIL24, runtime08, same group/accounts and retained commands; node-build10 /
  up09 image22bf0ee. Bob GSR45744ms, Carol GSR50422ms (two actual queries)
  and all three protected active-head checks passed first attempt after empty
  ordinary mailboxes. The first semantic send retained its original fanout but
  failed during Store return/timeout (506971ms total;4408 protected unprotects,
  258535ms native protection;32 proofs97487ms,15 closures48964ms,4 frames32726ms).
  No duplicate DGM is issued on resume. Runtime Store had an extra full pre-guard
  immediately before the interceptor's same full fence; this duplicate is now
  removed in Shared, with both real callback fences and full final fence retained.
  `store-fence-01`2 PASS/native0 covers exact unknown attempt, reopened native
  text, grant/root/counter faults and durable receipt. This new source is not
  yet in runtime08; `e2e-15` resumes the original batch on that unchanged binary.
  It also explicitly checks exactly3 active members/identical epoch on all three
  cold clients before fanout, including retained-head skip/resume paths.
  This resumed cycle does not claim first-attempt creation/invitation reliability.
- `e2e-15`: FAIL27/runtime08. Exactly3 active-member heads passed on all three.
  Original Alice fanout completed by exact retry85328ms (no new DGM, no new wire
  on that retry), both recipients independently received/ACKed78261/63743ms.
  Bob's first send then hit a node native deadline; its original batch remains
  preserved. No complete three-way/current-runtime PASS is inferred.

The actual Alice platform-protected aggregate was801334 bytes. Each protected
slot read used native DPAPI over the whole growing aggregate. A synthetic
32-read native-only comparison measured1858ms for801334 bytes versus8ms for a
32-byte key. Runtime09 changes only the CLI platform envelope: every write uses
a fresh32-byte AES-256 key and96-bit nonce; current-user DPAPI wraps the key and
GCM's128-bit tag binds the whole ciphertext/header. Every read unwraps the key
again and clears it, with no retained key/plaintext cache, key file or weaker
account/floor checks. Raw-DPAPI profiles reject without reader/migration. Old
profiles/batches remain preserved; new envelope acceptance needs a new isolated
three-account run, not conversion or repair of old unknown operations.
CLI build/unit09 passed native0,49 tests, zero compiler warnings/errors.
Tests cover native calls on every large read, detached copies, every frame region,
wrapped-key splicing/fresh keys, hostile/truncated lengths, raw-format rejection
and two actual account cold reopens. `e2e-16` starts the independent candidate
on unchanged node-build10/up09 and existing network/node custody.

`e2e-16` ended FAIL31. All3 accounts published first attempt, the first pair
completed and the second request/receive ACK passed; the second acceptance's
private grant failed twice. Registry independently located a poisoned permanent
reservation: a valid release rejection on a changed view was followed by
RequireScope conflict because the scope included the transient DNH2 checkpoint.
[DR-0149](../../../docs/survival-program/decisions/DR-0149-stable-mailbox-grant-intent-scope.md)
separates exact verified intent from fresh authorization. The v2 private hash
has no checkpoint/policy-snapshot parameters; original request/evidence kind,
route/role and horizons remain bound. All existing current root/policy/replica/
forwarding/signing/release checks and permanent conflict/winner guards remain.
Registry scope01 passed2 pure cases; scope02 passed6 (2 pure,2 actual PostgreSQL
journal cases,2 actual current/retained HTTPS/Protocol/role-signer/native-mailbox
cases), native0/0skip. Old incompatible reservations are preserved/unavailable,
not converted, deleted, reminted or represented as recovered.

Registry build01/up01 uses imagefbc3ed4 and the original keys/DB/node volumes.
All9 services healthy. The local Registry quota was live-tuned1→2 CPUs without
restart during16 after128 of377 scheduler periods were throttled; the same2-CPU
budget is now rendered by Compose (DevOps contracts02:30 PASS/native0). Memory,
transport/signature windows, TLS and node quotas remain unchanged; no SLO claim.
`e2e-17` reuses the actual mutually consented first pair and creates only a
separate third QA account, not a repair/replacement of the old poisoned request.

`e2e-17` ended FAIL after35 cold commands: all three mutual contact
pairs, group creation and original invitation Store passed. The invitee's
retained-read response failed `IssuedAfterCurrentUpper`; no time predicate was
relaxed and the original profiles/group/invitation remain preserved. `e2e-18`
continues exactly those three accounts and the same group with published-account
reuse, not new identities or a new semantic invitation. That response now
verifies; the first invitation ACK hit the node native deadline, then its exact
cold retry passed. Consent, owner ACK and GSR successor publication passed on
the first attempt. The recipient's ordinary mailbox was empty, independent GSR
catch-up passed, and both protected heads matched. Third-member addition and
three-way messages/cold replay were still pending; this was not a full GSR PASS.

`e2e-18` ended FAIL/native1 after28 cold commands. The first member's GSR
catch-up and matching protected heads passed. Original third invitation Store
passed first attempt357158ms;6390 native unprotects cost3836ms, while42 directory
and20 network-closure calls cost108406/75585ms and8 ONION calls104352ms. Its
original receive/ACK timed out twice (134199/111728ms). Node diagnostics recorded
300/328 live lease checks and repeated whole operation-document work within the
unchanged25s terminal budget. No new group, reminted ACK or erased state follows.

Node `forwarding-09`25 PASS/native0/0skip (zero compiler diagnostics) covers
single-read parse reuse with post-callback re-read/hash/native commitment checks,
including equal-length snapshot tampering and existing native crash/ACK/HTTP
regressions. Build11/up10 deployed imagea81582f to all three existing nodes;
keys/volumes/CPU quotas remain unchanged and all9 services are healthy.
`e2e-19` ended FAIL/native1 after41 cold commands/3 failed steps. The same
third-member ACK recovered first attempt103622ms (ONION15344ms). Consent,
owner ACK and3-member successor publication passed; both recipients fetched
GSR independently and all three exact heads matched. Two empty-mailbox polls
needed exact retries. First two fanouts and their four receive/ACKs passed
first attempt; the third send returned unknown after a node current-network
cryptographic rejection. Its protected semantic command/original batch remains.
Receipt SHA256: `60aa8e346230872c11d664a3e157c6d08d67a8a9b0e88daed207ed645b79b830`.

`e2e-20` then passed51 cold commands/native0/0 failed steps on the same
runtime09, accounts, group and original semantic commands. Original third-batch
flush recovered first attempt114369ms with no new send. All messages/native
histories/full Store replays/empty mailboxes and cold GSR receipt/cursor checks
passed as detailed above. This is a retained-state recovery PASS, not a clean
first-attempt run or recovery of the older deliberately preserved blocked cases.

Shared `native-06`12 PASS/native0/0skip covers the current native-owner reuse,
real native group custody, endpoint phase freshness and actual publication /
retained semantic fault / lost ACK / empty-poll paths. Node `forwarding-08`
20 PASS/native0/0skip adds the neighbouring Store/ACK/HTTP/crash cases to the
current forwarding/whole-batch/time-convergence regressions. Protocol
`registry-04` strict PASS/native0. These are focused source gates, not full gates.

DR-0148 uses the existing authenticated whole-ACK AcceptedAt/exact-item custody
for sender items never visited after an earlier failure. It adds no journal,
timestamp parameter, wire frame or changed original request. Protocol
`forwarding-03`35 PASS/native0 includes signing-domain/key/request binding,
expiry, existing-admission preservation and strict future-durability rejection
before reservation. Node `forwarding-07`8 PASS/native0 covers real TLS/H2,
independent upper-bound convergence/no-convergence, an original two-item batch
after120s and native reopen (including the never-reserved item), exact cold
quorum replay and coordination lower-bound leads1/3s. All source signatures and
native effects remain actual; no clock substitution or fake journal state.
CLI unit07 remains47 PASS/native0, no compiler warnings/errors.

PTR1 source evidence: Protocol `forwarding-01`31 PASS/native0; Node
`forwarding-03`12 PASS/1FAIL (fixture contact-proof setup), corrected through
explicit genuine long-lived role grants, signed revocation successors and a
fresh network proof, without extending an existing authority window.
Node `forwarding-06`1 PASS/native0 proves delayed first recipient admission
over pinned TLS/H2, actual source mutation, exact quorum and cold replay.
`forwarding-01` was a test import compile failure. `forwarding-02` was explicitly
interrupted/native-1: too broad; it is not full/focused acceptance. It exposed
an old assertion inconsistent with accepted DR-0139's pre-first-intent recovery;
the corrected test requires protected absence, zero effects, non-adoption of the
unanchored temporary, one first committed intent and unchanged cold replay.
`forwarding-04/05` retain fixture time-window failures, not runtime qualification.
The HTTP negative now explicitly rejects retired raw tombstone carriage.
Protocol `registry-03` strict PASS; `graph-forwarding-review-01` retained the
expected new-surface rejection. Actual public metadata was reviewed: three closed
forwarding methods, overhead constant, frame/content type and generated magic.
The two additional native-owned ACK admission methods were independently
reviewed after `graph-owned-ack-review-01` rejected the new surface as expected.
Only the current Release/Debug12963-line snapshots remain; `graph-05` normal
build/actual exact-three API/resource/source/lock graph PASS/native0. No old
positive snapshot is retained as a compatibility alternative.

The driver requires create/invite/accept, two sequential additions, exact3-member
heads, GSR catch-up while the ordinary mailbox is empty, one semantic send from
each member to both peers, native cold histories, original batch replay, empty
mailboxes and cold control-cursor replay. It does not qualify400-day retention,
descriptor rotation/handover, expired unknown-write reconciliation, membership
removal/rekey/device/history policies, large fanout, full gates or a release.
