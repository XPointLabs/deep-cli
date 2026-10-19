# Three-CLI first-attempt latency checkpoint

Owner: Mr. X. Date: 2026-10-19. Local Docker / CLI only. Windows, Android and
production remain untouched. Baseline:
[previous performance checkpoint](cli-gsr-performance-2026-10-19.md).

The thirteenth strict candidate also **failed**:48 commands,1389.217 summed
CLI seconds, final third-member acceptance rejected at native `VerifyDtt`.
This is not a timeout or a ratchet performance result; exact DTT/view/policy
coherence rejected before successful completion. Its original consent batch
and all profiles were retained. Subsequent working-session recovery/latency
evidence is tracked separately in
[the session checkpoint](cli-working-session-2026-10-19.md); it cannot erase
this first-attempt failure or qualify release/device E2E.

## Why ratchet replacement is not the current fix

The [comparison owner](../../../docs/architecture/SESSION-PARITY-AND-SOURCES.md)
retains the normative claims and performance predicates. These observations are
an implementation comparison, not a new crypto suite or competitor benchmark:

- [Signal Double/Triple Ratchet](https://signal.org/docs/specifications/doubleratchet/)
  derives message keys from stored state; Triple Ratchet combines Double Ratchet
  and Sparse PQ Ratchet outputs through a KDF. The names do not mean two/three
  mandatory network handshakes per message.
- [Signal Sesame](https://signal.org/docs/specifications/sesame/#sending-messages)
  encrypts using active per-device sessions and submits ciphertexts to mailboxes;
  device-list rejection/reconciliation is distinct from encryption. This does
  not establish a Signal latency number on our hardware or network.
- [Matrix Megolm](https://spec.matrix.org/latest/olm-megolm/megolm/)
  uses a sender session shared through a secure pairwise channel and subsequently
  advances local ratchet state. Importing it would change group key/history and
  compromise-recovery semantics, not automatically repair Deep's hot path.
- [SimpleX SMP](https://github.com/simplex-chat/simplexmq/blob/stable/protocol/simplex-messaging.md)
  separates queue delivery and recipient ACK, including proxy forwarding. Its
  delivery structure is relevant; it does not replace our independent replica
  custody or authorize a speculative ACK.

Our measured pre-change mailbox requests performed67–245 lease checks, with
authority-source time around1.6–7.6s and operation work around1.0–8.4s in sampled
node logs. These nested times overlap and must not be summed. We found duplicate
authentication of identical signed public heads and PMA policy inputs; replacing
the ratchet or extending deadlines is not required to remove that work. Cold
CLI processes, independent directory acquisition and three-hop/quorum transport
also differ from an already running messenger. Their remaining costs must be
measured rather than explained away by privacy or post-quantum cryptography.

## Changes and unchanged security

Protocol host memoizes only the public PMA verifier result within its immutable
network/root/PMA instance and an identical actual trusted lower/upper interval.
All boot, network lease, full interval and monotonic rollback checks still run
for every read. A new actual interval requires new verification.

Node network source similarly keys a one-entry public PMA memo by exact signed
bytes, reference-identical verified authority and both actual time bounds.
Directory observation returns the signed head already authenticated by its
actual chain/anchor/index join; the reader's one-entry signature memo binds the
actual exact head/hash/generation and reference-identical authority. Actual
native reads, unprotection, joins, clock, expiry, revocation, holder, replay and
all effect fences remain. No TTL, private plaintext/key cache, version/schema
change, compatibility reader, deadline extension or CPU quota increase.

The connected failures also exposed a correctness bug: background recovery and
client-outcome persistence could retain different valid signed durable-at
evidence for the same exact Store PRQ2. Byte equality then rejected recovery
forever. Both receipts are now independently authenticated against the same
protected original request, and both immutable winners are retained. A genuine
RED regression reproduced the production error; cold replay passes after the
fix. Different requests, invalid receipts and changed native custody still
reject. Historical Store-prefix verification now does one full native document
rejoin after its denial-only verification loop, rather than one whole-ledger
read per old row. No effect or reservation occurs inside that loop.

`Invoke-ThreeClientGsrE2E.ps1 -RequireFirstAttempt` requires a new candidate group
and absent invitee state, disables the driver's exact retry, and rejects a
failed/retried command. Existing accounts/contacts and old groups are retained.
Process CPU time is recorded as count/time-only metadata beside wall time.

## Source evidence

Repository-relative prefix: `artifacts/cli-gsr-first-20261019/`.

| Receipt | Result / boundary |
| --- | --- |
| Protocol `protocol-01/integration` | 108 PASS/native0/no skip, initial private representation |
| Protocol `protocol-02/integration` | 108 PASS/native0/no skip, final private representation |
| Node `node-01/integration` | 78 PASS/1 FAIL/native1: new atomic fault test mutated a loose file instead of the actual bundle; original failure preserved |
| Node `node-02/integration` | 79 PASS/native0/no skip after faulting the actual atomic bundle; genuine clock/floor/tamper/TLS/H2/Store/ACK/crash coverage |
| Protocol `graph-01/Release` | Build0; graph1 rejected the initial private nullable-tuple metadata layout, not waived |
| Protocol `graph-02/Release`, `graph-02/Debug` | Normal builds and strict exact-three assembly/resource/API/source graphs PASS/native0 against the unchanged approved snapshots; private scalar fields avoid metadata relocation |
| CLI `build-01`, `unit-01` | Build0; 49 PASS/native0/no skip |
| Shared `shared-01`, `shared-02` | 10 and8 PASS/native0/no skip (overlapping); final exact-public grammar and single-chain getter capture |
| CLI `build-02`, `unit-02` | Final binary build0/no warnings; 49 PASS/native0/no skip |
| Shared `shared-03` | 38 PASS/native0/no skip: codec/adapter group capacity, in-memory parity, CAS/registration/guarded deletion, cold reopen and unchanged inventory bounds |
| CLI `build-03`, `unit-03` | Capacity-corrected binary build0; 49 PASS/native0/no skip |
| Shared `shared-04` | 51 PASS/native0/no skip: bounded new pages, retained/lost/expired-page ACK, semantic faults, publication renewal and Braid/read-journal predicates |
| Shared `shared-05` | 8 PASS/native0/no skip: command scope, actual floor/clock/splicing/expiry rejection and independent parent ACK capture |
| CLI `build-04`, `unit-04` | Final bounded-page/receive-scope binary build0; 49 PASS/native0/no skip |
| Protocol `protocol-03-red`, `protocol-04-green` | DTT intake regression6 cases:2 PASS/4 FAIL before correction, then6 PASS/native0 |
| Protocol `protocol-05` | 157 PASS/native0/no skip, final RTT mapping and large-boot-sample case plus host/clock/expiry predicates |
| Protocol `graph-03/Release`, `graph-03/Debug` | Normal builds/strict exact-three graphs PASS/native0 against unchanged approved snapshots after time correction |
| Node `node-10`, `node-11` integration | Closed GSR reason diagnostics:22 PASS/2 FAIL for an outdated exact log-key assertion, then25 PASS with the explicit new closed key and no-data-export checks |
| Node `node-12/integration` | 104 PASS/native0/no skip with corrected DTT mapping: actual proof/head/network/Store/ACK/TLS/recovery and GSR authority predicates |
| Shared `shared-06` | 9 PASS/native0/no skip with corrected DTT mapping: scope/floor/clock/independent ACK plus actual publication-promotion/lost-ACK case |
| CLI `build-05`, `unit-05` | Matching corrected-clock binary build0; 49 PASS/native0/no skip |
| Node `node-13/integration` | 103 PASS/3 FAIL: two exact observation-work counts changed, and moving the final observation exposed a missing post-callback cancellation check |
| Node `node-14/integration` | 106 PASS/native0/no skip after restoring that cancellation fence; exact work counts updated to one final actual observation, all denial assertions retained |
| Node `node-15/integration` | 187 PASS/3 FAIL/native1: initial diagnostic representation changed typed enums into text; the three exact typed-log regressions caught it; this intermediate build is not final qualification |
| Node `node-16/integration` | 22 PASS/native0/no skip: final typed diagnostics, bounded pre-effect interval convergence, cancellation, expiry, actual authenticated service-clock negatives and existing coordination convergence |
| Node `node-17/integration` | 20 PASS/native0/no skip: final denial-only operation-custody inspection, actual post-callback native tampering, crash boundaries, valid settlement preservation, Store/ACK/TLS predicates |
| Node `node-18/integration` | 13 PASS/native0/no skip: bounded owned async-local code names, finite authority labels, closed logging and actual independent-settlement cold replay |
| Node `node-19/integration` | 16 PASS/native0/no skip: three finite native lease reasons preserve the exact original built-in exception type/messages |
| Node `node-20-red/integration` | 1 FAIL/native1: genuine impossible-origin reproduction, exact ExpiredOrStale peer rejection instead of pre-capture rejection |
| Node `node-21-green/integration` | 4 PASS/native0/no skip: actual recheck/convergence, nonconvergence, cancellation, bound and no immutable peer intent/effects on an impossible origin |
| Node `node-22/integration` | 49 PASS/native0/no skip: final origin correction, actual Store/ACK/TLS, custody/crash/tamper/settlement and admission predicates |
| Node `node-03`, `node-04`, `node-05` integration | 29/33/6 PASS/native0/no skip (overlapping), parser and closed numeric diagnostics |
| Node `node-06/integration` | 1 FAIL/native1: genuine RED for the independently valid settlement race |
| Node `node-07/integration` | 45 PASS/native0/no skip: fixed settlement, current peer/TLS/H2/Store/ACK/recovery/fault predicates |
| Node `node-08/integration` | 1 PASS/1 FAIL/native1: new late-tamper fixture did not reach its async stack-based injection point; preserved |
| Node `node-09/integration` | 2 PASS/native0/no skip: deterministic actual-read injection, unchanged rejection assertions |

Protocol's final representation-only change was followed by its second108-case
run and normal graphs. Node's79-case run used the earlier equivalent private
representation; the connected image/CLI use the final one. No source full,
package, release, scale, retention or device gate is inferred from these receipts.

Local node build/up01–04 completed with native0, preserving the same keys,
volumes, custody and CPU quotas. Historical04 image:
`sha256:887d48961eb58997107e6b7e37db4e87688bbf9317e935ed03747ac7e71214f9`.
Diagnostic build/up05 and matching corrected-clock build/up06 also completed
with native0, preserving the same state/keys/mounts and one CPU per node.
The historical06 image was
`sha256:4ee72c5943f64e8f5b510fa2282f8dcb12c8c794bbc08f57dcd55cbe70ef26b5`.
Build/up07–09 also completed with native0. The historical09 image on all three
healthy nodes is
`sha256:dc83b61caea9541dc34e6f0acd7b7378079869d1b0096698a777713a17deda72`.
It contains typed contact interval reasons, bounded pre-effect convergence and
the final denial-only operation-custody inspection. Each node still has one CPU;
keys, protected custody and the same nine mounts remain retained.

The third strict candidate failed at group creation: the codec admitted32MiB
but the real secure-storage adapter admitted only1MiB per value. DR-0143 now
aligns the exact registered group aggregate at4MiB across the codec, both
adapters and all atomic/cold operations. Ordinary slots remain1MiB, the whole
authenticated inventory remains8MiB/1024 entries, and all bounds apply jointly.
This is not a format change or a larger inventory budget. Prior accounts,
groups, original requests and evidence are retained; no reset conceals the
failure. Large-history partitioning/retirement remains open S11 work.

The fourth strict candidate still timed out during ACK:354 lease checks,
11.924s nested lease time,9.664s nested authority time and6.543s operation work.
These overlapping measurements are not additive. Its original ACK remains
preserved, not resized. New pages now request two events while the closed
reader still accepts original captured pages up to eight. The driver can drain
four successful pages using actual protected continuations; it stops on failure
and never advances an unknown request. Receipt rows retain processed/tombstone
counts and `hasMore`, not identifiers or payloads.

Ordinary DPE2 receive now borrows immutable public endpoint capabilities only
inside a private page-local command scope. The source still rechecks actual
floors/history/currentness at every use. Retrieve, Initial, Braid and post-batch
ACK keep their independent parent source. A fresh ACK acquisition cannot obtain
the receive child's cached proof. No authority or transport window is extended.

The sixth strict candidate still exceeded the25s native Store budget, with
191–198 lease checks, about14.6–15.1s nested lease work and7.6–7.7s operation work.
It remains failed, with original pending Store preserved. Native replication now
coalesces adjacent full joins only when no callback or I/O intervenes; all real
mutation/crypto/HTTP/replay/release boundaries stay fenced. Peer replay grammar,
native index and independent-floor checks use the same actual synchronous read
pass, not a retained document. Observational network work defers its protected
proof rejoin to the existing final fence after all source/clock callbacks; it
does not commit a floor or release a capability before that rejoin, cancellation
check and stopped-owner check. This removes repeated work, not security checks.

The seventh strict candidate completed invitation, two successful receive/ACK
pages and consent with first attempts, then failed the owner's next grant
acquisition before forwarding (0.297s ONION response;10.641s whole command).
The node's closed phase/method identified full-interval contact admission, but
the old combined predicate did not distinguish future-issued from expired.
Neither reason is inferred solely from that historical log. The new typed
diagnostic separates them. The same bounded convergence already used by contact
coordination is now available before contact dispatch: at most one local wait,
bounded by verified root uncertainty, followed by actual time and exact placement
reacquisition and the original strict interval predicate. No transport retry,
grace, backdating, longer expiry or post-effect wait is introduced.

The eighth strict candidate failed a first invitation Store at the unchanged25s
budget (82.497s whole command;25.156s longest ONION response). Its native samples
still showed183–194 lease checks. Denial-only operation-custody inspection now
uses its existing mandatory post-validation full fence rather than an additional
pre-read full fence. Recovery replacement/commit and result/native rejoin fences
remain. The20-case final regression run includes actual callback tampering and
checkpoint crash cases; no assertion or timeout was relaxed.

The ninth strict candidate completed invitation/ACK/consent, two-member activation
and independent GSR catch-up with first attempts, then the third-member invitation
failed a Store with a cryptographic rejection after8.434s (54.799s whole command),
not a25s timeout. The previous code-name whitelist excluded the compiler's `|`
in async local functions and consequently hid the actual owned throw site behind
`MailboxCurrentOperationLease.CheckAsync`. Diagnostics now accept that bounded
compiler delimiter and emit the existing finite authority-check label separately
from mutation-check. The original candidate remains FAIL. A continuation of that
same retained group is recovery evidence only, regardless of later success.

## Connected result and operation timings

First-attempt qualification is OPEN: twelve strict connected candidates failed.
Failed candidates remain preserved and may only be resumed as recovery, never
relabelled first-attempt qualification. No new qualified three-member fanout
latency exists yet; the previous checkpoint's fanout numbers remain baseline,
not a successful result of this change.

Candidate11 completed both new contact-consent cycles and the first invitation
with first CLI attempts, but invitation receive/ACK failed (42.583s). Its
retained-original recovery also failed: the actual image13 binary/PDB mapped
the rejection to `ReserveCurrentAckAsync`'s lost-intent branch. The pending
authenticated client counter had survived before a complete peer ACK batch.
[DR-0152](../../../docs/survival-program/decisions/DR-0152-native-ack-pre-intent.md)
owns the correction. Native `node-24-red` reproduces two failures; `node-25-green`
passes6 cases/native0/no skip, including final/nonfinal cold recovery and
independent tombstone-floor/hostile-continuation rejection. This is source
evidence, not connected recovery or first-attempt PASS.

Additional diagnostic qualification: `node-23/integration`16 PASS/native0/no
skip adds only a bounded owned caller method/IL pair. It exports no exception
messages, payloads, paths, authority timestamps or exception Data.

`node-26/integration` is37 PASS/3 FAIL/native1, not a qualified gate. The three
exact exception expectations were stale: the owned-ACK proof producer rejects
a changed signature as typed `InvalidSignature`, and the new independent native
tombstone floor rejects a different replacement batch before its expired token
check. Assertions now require these exact closed failures; unchanged state,
original replay, tombstone and no-additional-HTTP assertions remain intact.

`node-27/integration`9 PASS/native0/no skip qualifies the changed assertions and
new positive/negative cases; the other37 predicates in node26 passed before
these test-only edits. No unfiltered full/package/device qualification is claimed.
Local build/up14 both native0; three healthy nodes use image
`sha256:7b325f5ccacdb3b65500c13be8a6dacd78a122022e3f4190422a787377b063d4`.
Keys, custody, volumes and CPU quotas remain unchanged.

Retained-original `recovery-10` is FAIL: original flush18.023s PASS, then ACK
40.935s/34.879s FAIL. Native rejection now reaches the unchanged continuation
expiry check instead of the incorrect lost-intent branch. The original page
token's600s lifetime elapsed during diagnosis; no extension/remint/reset occurs.

`steady-01` is a separate FAIL, not fresh lifecycle evidence: first new fanout
113.358s PASS/one CLI attempt, first recipient ACK84.776s PASS, second recipient
ACK67.173s FAIL. Some directory refresh requests are nonSuccess; the command's
success is not a claim that every HTTP request succeeded. The exact published
image14 PDB places peer IL1176 at the missing native tombstone target check.
A read-only metadata diagnostic of the actual latest pending ACK (accepted3s
before failure) found two targets: an older partial Store exists only on the
first replica; the new message exists completed on both selected replicas.
This diagnostic is not independent native authentication or permission to
fabricate a missing target/receipt. The old Store/grant/ACK remains retained.

Strict `e2e-12` uses three existing profiles whose prior receive/ACK completed,
two newly established contact pairs and a new group ordinal11. No account,
key, volume or original request is reset. This avoids conflating the known
unrecoverable historical partial Store with a new latency measurement; it does
not recover that Store or close unsettled-expiry/handover release blockers.

Candidate12 stopped during contact receive before group creation: new contact
request94.488s PASS; receive17.738s FAIL. The node capability owner reported only
`cryptographic-rejection`; this is not evidence for a specific predicate. New
bounded owned location diagnostics cover that pre-dispatch owner as well as
terminal dispatch. A genuine `node-28-red`2-case failure also exposed that a
throwing logger could replace the original capability failure; `node-29-green`
passes15 cases with non-fatal closed diagnostics and existing idle/startup/
cancellation/malformed-response recovery assertions.

Build/up15 native0, current image
`sha256:098470c3a7f4f4d76b3f3e064b13e1a1998b0c9b20eed338bf1881e9aa648696`.
One-command retained-original `recovery-11` passes:99.982s, one event/tombstone,
all observed HTTP responses successful. This does not diagnose or erase the
original transient failure. Candidate13 retains the exact contact and profiles
and still requires a new group with one maximum CLI attempt; no state is reset.

### DTT1 transport-time correction

The fifth strict candidate completed the first invitation, bounded-page ACKs,
consent, two-member successor and independent GSR catch-up, then failed a new
GSR write at current authority admission. Its retained original write had a
120s interval and still115s until expiry relative to the failing CLI host's
receipt time (diagnostic only, not an authority clock). It is not reminted.

Inspection found that a signed DTT observation was treated as if it happened
exactly at response receipt, despite actual network/issuer delay. Two consumers
with different RTTs could consequently have falsely precise, disjoint clocks.
The same bug could hide signed DTT expiry. Six real signed-proof tests gave
2 PASS/4 FAIL before correction (`protocol-03-red`), then6 PASS after it
(`protocol-04-green`). Final expanded tests add the large-boot-sample case.
[DR-0150](../../../docs/survival-program/decisions/DR-0150-dtt1-transport-time-envelope.md)
owns the conservative monotonic envelope; this report does not redefine it.
The lower is not moved forward by RTT, while the upper includes the bounded
challenge/response delay. Existing signed expiry/full-interval checks reject
more conservatively, with no extended nonce, grant or transport deadline.

### Proven native origin defect

The tenth strict candidate used three new profiles, preserving every older
profile and native intent. All three pairs completed mutual contact consent
with first CLI attempts. It then failed the invitee's group acceptance Store.
The exact running binary/PDB placed IL462 at the original ExpiredOrStale branch.
A read-only diagnostic of the actual pending PRQ2 found2592001 seconds between
origin and object expiry: one second more than the unchanged30-day bound.
Its grant had2016 seconds remaining at peer authoring. The native timestamp was
one second before the authenticated MEO1 origin, not an expired grant.

[DR-0151](../../../docs/survival-program/decisions/DR-0151-native-store-origin-time.md)
owns the pre-capture correction. The real native RED test reproduced the same
peer exception; four GREEN cases and49 expanded predicates pass. A near-future
MEO1 origin can wait once for at most5s, then the same full native check must
actually cover it before any immutable peer capture. TTL/skew/freshness and all
original bytes remain unchanged. Existing malformed/stale intents are retained,
not repaired, reminted or counted as recovered.

The eleventh strict candidate uses a new owner and the two established invitees,
retaining their mutual contact and all older state. It starts a new group with
one maximum CLI attempt. This is a changed client-history workload, not an
isolated code-speedup experiment against the older three-profile baseline.
Two private short thread-sampling traces were collected only during contact
setup in candidate10, not fanout in candidate11; they do not measure CPU shares
or establish a complete hotspot attribution. Raw traces/state remain outside
repositories/artifacts; only bounded code/count diagnostics were inspected.
