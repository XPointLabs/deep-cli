# Retained CLI native grammar audit — 2026-10-21

Continues the [cursor22 checkpoint](cli-critical-path-latency-2026-10-21.md).
Same three profiles, group and local `deep-dev-current` network; no reset,
rekey, history replacement, production change or Windows/Android client work.
Node-only rounds23–25 used unchanged CLI/Shared/Protocol shipping binaries and
scenario. The subsequent client slice changes Shared's private native read
composition; Protocol bytes, account keys and profiles stay unchanged. Round26
retains the original full scenario. A later explicit delivery-only diagnostic
scope changes the scenario fingerprint, not the default full qualification.

## Installed specialist audit

Selected the installed **Backend Architect**, **Performance Benchmarker** and
**Security Architect** profiles, not UI/device or generic load-test agents.
Initial audits were independent/read-only. Implementation ownership was then
split by file; the security reviewer separately inspected the final native
grammar change. Root review and executable tests are separate evidence.

| Finding | Evidence | Decision |
| --- | --- | --- |
| Repeated native mutation JSON parsing/hex validation | Every fresh native recovery inventory calls `MailboxPeerMutationStore.Read` on actual records | Reuse only immutable parsed grammar after reading/hashing complete actual opened bytes; no authority reuse |
| Repeated canonical Store/Tombstone identity serialization | Retained nodes:451/226,395/205,689/351 replay floors/distinct targets; max3/2/2 facts per target | Compute each identity once per record within ONE fresh inventory join; still compare EVERY independent floor |
| Duplicate ACK target repeatedly scans all peer floors | `ValidateAckOperations` scans floors per repeated target; retained duplicate items2/0/0 | Invocation-local lazy lookup, not a claimed main current latency cause. Large-history test proves semantics, not wall-time gain |
| Repeated SQLCipher/genesis/account checks | Client source audit identifies full DB integrity/schema and custody joins; final22 fanout CPU54.078s, ACK34.078s | No whole-account authority cache or removed integrity checks: callbacks separate some checks |
| Fanout serialization | Transport loans hold the actual account lease | Keep account semaphore; removing it is not safe concurrency optimization |

## Security and resource boundaries

Mutation grammar reuse is scoped to the existing store instance. Each read still
opens the actual file, applies the existing16KiB bound, reads through EOF and
checks opened length/position before hashing. Only successful immutable
string/scalar grammar can be remembered by exact SHA256/length. Path/mtime,
previous file permission, currentness, replay, native index or protected floor
results cannot authorize a hit. Every caller's existing filename/RecordKey,
fresh inventory, independent custody/floor, actual file/lease and callback fences
remain. Authentic rollback to old valid grammar must still reject against the
current protected tombstone floor.

The memo has fixed entry/source-byte limits, bounded eviction, no raw-byte
retention, and synchronized disposal. Source bytes are a resource-accounting
bound, not an exact managed-heap size claim. Misses/eviction take the same parser
and validation; no valid input is rejected merely to fit a memo. Stream parsing
preserves BOM behavior; input buffers are wiped. No schema, crypto, signed
window, listener, retry, checkpoint/flush or recovery contract changes.

Identity reuse and ACK indexing end at their respective method return. They
never replace actual file reads or native floor comparisons at the next join.
All conflicting matching ACK facts must be considered, including a late
absent-target marker or a later different tombstone digest.

## Diagnostic round before deployment

Unchanged-node cursor23 completed46/46 PASS on the same accounts:72 messages /
24 original local commands each, Active3/epoch2. Every driver attempt1, but it
includes ONE owned mailbox resume and ONE lease wait. Fanout30.949/45.398/39.340s;
receive/ACK22.251/22.601/73.566/18.845/18.692/19.113s. Active438.817s,
CPU241.248s, driver wall444.995s. The73.566s ACK is retained, not hidden.

Two bounded60s managed-thread sampling windows were collected privately during
that round; an initial unsupported profiler-mode invocation failed before
attachment and was corrected using the tool's installed profiles. Sampling
contains substantial idle/wait time, including idle CLI sessions. It is NOT
kernel CPU sampling or a causal ranking of SQLCipher, ML-DSA or DPAPI. The
diagnostic round is not a controlled latency baseline; profiler overhead and
owned recovery are not removed from its reported timings. No raw trace, method
arguments, local path, account identifier or request is committed.

## Qualification and post-change measurements

- Windows PowerShell5.1 / SDK10.0.301: final focused46/46 PASS, native exit0
  (`focused-04`), then strengthened closed-owner/BOM/warm/cold case1/1 PASS,
  native0 (`focused-05`). No new compiler/analyzer warnings in the final build.
  The first launcher failed before tests due to quoting. An earlier46-case
  run passed TRX but displayed an analyzer warning and masked its native-exit
  field through table formatting; it is NOT the relied-on final terminal.
  The assertion was changed to the equivalent predicate overload, not relaxed.
- Actual Linux ARM64 supported `node-authority-tests` target:103/103 PASS,
  0 skipped, native0. Includes original authority/path/floor coverage and all
  new grammar/identity cases plus the existing damaged-native and authentic
  pre-ACK rollback checks.
- DevOps Compose/build contract suite:31/31 PASS, native0.
- Supported retained Build/Up/Verify/smoke: native0. All three nodes healthy on
  `sha256:0a44d43fd591b717842bc81409e0dd0131b88e8b718516b1552abac8ca48ae7e`.
  Expected project-scoped state/custody/key volumes remain mounted; retained
  Store/ACK/floor counts advance with cursor23, not reset to empty. Whole-mount
  serialized fingerprints differ for two containers, so bit-identical mount
  configuration is NOT claimed from those fingerprints alone. Readiness/smoke
  are not device/message-delivery evidence.

Native/deployment logs: xnode's `artifacts/cli-audit-latency-20261021/`.
CLI receipts: `artifacts/cli-audit-latency-20261021/profile-23/receipt.json` and
the separately qualified post-change round. Private traces stay outside repos.

## Interrupted original batch and retained recovery

Post-deployment cursor24 failed during the second sender's receive, before
mailbox HTTP. The receipt is preserved as FAIL, not counted as a clean run.
Shipping `CatchupAsync.MoveNext` throw offset472 maps to the typed directory
unavailable branch, not the different history/floor rejection. Correlated
Registry warnings identify a real NTS observation-quorum failure followed by
proof/history503. A generic CLI `IoFailure` alone did not establish this cause.

The local setup has exactly two independent authenticated time sources. One
UDP timeout plus its existing backoff can leave fewer than two observations;
once the real anchor expires, Registry correctly stops authority issuance.
No time anchor, policy, TTL, floor or account was replaced to continue.
The same unavailable branch interrupted cursor25's final empty-mailbox check
after all three senders and six receive/ACK commands succeeded. This is another
FAIL, not sustained or first-attempt acceptance. Cursor25 recovery has its own
artifact directory; no failed receipt is overwritten.

The installed NTP client resolves one UDP endpoint per attempt. Multiple A
records exist for both configured KE hostnames, but this does not prove the
actual authenticated KE-returned NTP endpoint or the cause of its timeout.
Therefore no speculative IPv6 toggle, unauthenticated fallback, extra query,
longer freshness window or endpoint substitution was deployed. A third
independent authenticated NTS provider is a redundancy option, not an applied
fix: the supported same-key renewal currently retains the signed source list,
and mailbox-enabled activation needs a proper source-update ceremony first.

Supported `RecoverIncompleteSteadyRound` finished the SAME cursor24 batch,
including the not-yet-queued third sender, native receive/ACK, cold history,
original full-batch replay, empty mailbox and deduplication checks. Its separate
receipt is PASS but is explicitly recovery evidence, not first-attempt latency
qualification. The initial FAIL and recovery timings are not merged into a
synthetic successful original round. Cursor25 is a new strict measurement on
the same retained accounts/group, not a substitute for recovering cursor24.

| Attempt | Result / steps | Active / CPU / driver wall, s | Recovery boundary |
| --- | --- | --- | --- |
| strict24 | FAIL /27 | 217.451 /85.763 /221.728 | Directory unavailable before second sender receive; original batch preserved |
| recover24 | PASS /50 | 311.124 /196.719 /318.626 | Same batch; one owned mailbox resume; not first-attempt qualification |
| strict25 | FAIL /42 | 362.709 /217.826 /370.629 | All3 fanouts/6 receives completed; final empty poll unavailable |
| recover25 | PASS /52 | 216.376 /165.141 /224.477 | Same batch; zero owned resumes/waits; cold replay/empty/dedup/control all complete |

After recover25 each retained profile has78 messages /26 original commands,
Active3/epoch2. Strict25's completed fanouts36.548/36.509/37.603s and six
receive/ACK24.275/19.680/21.166/22.713/18.556/18.928s did NOT demonstrate a
node-only end-to-end gain over baseline22 (means36.887 vs35.257s and20.886 vs
20.127s). The retained history has grown and the whole run failed, so these
completed phases are diagnostic comparisons, not a controlled benchmark or PASS.
This is why the client history amplification was investigated next.

## Remaining client amplification identified by the audit

`ReadRetainedGroupStoresAsync` iterates retained commands. Each retained Store
reconstructs its historical peer route twice; nested initial/accept/route-control
selectors each verify the complete native SQL history. This is batch × history
amplification, not evidence that onion layer crypto or DPAPI alone dominates.
DPAPI unprotect time in the diagnostic cold replay was about2.9s of34.4s.
Removing the selectors' full-tip checks or reusing authority across callbacks
is NOT an acceptable fix. A scoped native read transaction can instead share
one actual SQL verification while synchronously streaming historical selectors;
outer protected-floor/root/currentness and callback reread fences must remain.

Implemented as `Did2MessagingSqlJournal.HistoricalRouteRead`: its closed factory
owns a deferred read transaction, authenticates the COMPLETE actual SQL tip
against the owner's freshly reconciled independent protected floor, and only
then exposes internal native
selectors. No caller can supply an unchecked transaction. Hello, selected
acceptance and earliest duplicate queries share that same snapshot; route
controls stream one bounded event at a time, including the retained prefix.
There is no lifetime-sized materialization, new history limit or result reuse
across read transactions.

`ReadOriginalPeerStoreRouteAsync` captures cross-owner inputs before entering
the synchronous native helper. It closes the snapshot before any further await,
then checks exact consent/application readbacks and freshly reconciles native
custody. Native Hello/Accept/relationship/policy/route-lineage checks remain;
the surrounding before/after Store evidence reads are unchanged. Source-level
standard-path full-tip sites fall9→3 (initiator) and11→3 (responder with local
winner), plus removal of extra duplicate-control lookups' full-tip passes.
These are source counts, not profiler samples or a promised wall-time gain.

Six new real SQLCipher/owned-contact cases exercise positive working/compacted
history, foreign floors, nested selectors, cancellation, disposal, subsequent
fresh reads and corrupted ordinary/control rows. Existing original-route,
callback-input-fence and hostile retained-prefix cases are separate regression
coverage. No checks were relaxed to pass them.

Shared focused qualification:31/31 PASS, zero skipped, native exit0 under
Windows PowerShell5.1 / SDK10.0.301 (`cli-historical-snapshot-20261021/focused-02`).
The first run had26 PASS and5 FAIL: two stale exact-`IOException` assertions
produced five theory failures. Baseline commit`de3d305a` already changed the
intentional refusal to the sealed `OutboxPrefixPinnedException : IOException`;
the old tests predated that change. Only those two compaction assertions now
require the EXACT specialized type and exact fixed message. All root/SQL/native
immutability assertions and unrelated injected-IOException checks remain.
The initial failed TRX is preserved; it was not counted as a successful run.

CLI tests67/67 PASS, zero skipped, native0; shipping CLI build native0 with
zero warnings/errors. Round26 on the new runtime completed46/46 PASS on first
driver attempts, without Store/mailbox resumes, lease waits or session-close
failures. All3 profiles now retain81 messages /27 original commands, Active3 /
epoch2. Scenario SHA256 remains
`360c082c9dd4f02570a8095d49a4f2622a53fe3b09bedbe397cbfcd6d2707215`;
new runtime fingerprint is
`5ee66d92bb1e36bda2280e71b98c98aa35405cc9288133c4c9f95433e9430af2`.
The long test pause preceded additional ONION work (4 requests per fanout vs2
in round25); this is not a controlled steady-state latency comparison.

### Same-history ABBA check of the client change

After round26 and before any further message command, the archived round25
runtime was safely extracted to a fresh artifact directory. Complete extracted
runtime fingerprint matched its original receipt (`7881ea90805cf732db00128521b1694c307a07fa7eeca07eb8f283f87768f036`).
Both runtime inventories were checked again after the comparison. No database,
profile, key, snapshot, history or floor was replaced. Supported original
`group flush` was run in separate cold sessions, baseline→new→new→baseline.
Each run verified the SAME62 original batch items and retained81 messages /
27 local commands. All ran with0 ONION,0 non-success HTTP,0 owned recovery/waits
and exactly3 directory-proof /2 network-closure exchanges. These are real
retained Store verifications, not newly authored messages or an HTTP fixture.

| Cold replay | Wall, s | Process CPU, s | Native unprotects | Native protection, s |
| --- | ---: | ---: | ---: | ---: |
| Baseline A1 | 39.151 | 40.000 | 3008 | 3.199 |
| Snapshot B1 | 36.383 | 36.141 | 2758 | 3.080 |
| Snapshot B2 | 35.473 | 35.891 | 2758 | 2.971 |
| Baseline A2 | 41.366 | 39.922 | 3006 | 3.116 |
| Mean baseline | 40.259 | 39.961 | 3007 | 3.158 |
| Mean snapshot | 35.928 | 36.016 | 2758 | 3.026 |

Measured mean gain:10.8% wall /9.9% process CPU on this same-history read path.
This small ABBA sample is not a statistical significance claim, and is NOT
message-delivery latency. JIT contribution is6.4–7.6s in these cold processes;
DPAPI/protection is about3s, so neither alone explains the remaining~36s CPU.
The snapshot patch is a measured constant-factor improvement, not removal of
batch×history amplification or achievement of1–2s delivery.

Full source/package/carrier/retention/device/release acceptance, sustained
recovery-free stability and the1–2s delivery objective remain separate open
requirements. No required crypto/integrity/currentness/account-lock boundary was
bypassed; duplicate whole-SQL verification was coalesced only within one freshly
authenticated read transaction.

## Recipient completion join audit

The node call-graph audit counted13 sender/exit and6 recipient complete native
joins for one fresh Store; a fresh ACK with N tombstones costs6+13N. Thus a
Store and its one-target ACK perform38 complete joins, excluding additional
targeted checks and ledger loads/saves. These are source-path counts, not CPU
samples. Each join reconciles protected client outcomes/replay, peer floors and
actual native mutation/blob inventory. Most protect distinct effect/callback
boundaries and cannot safely be memoized as authority.

The recipient's post-sign join immediately preceded a second pre-commit join
without an intervening effect. The private fused continuation now signs,
performs the complete post-sign join, and commits the exact receipt BEFORE
returning it. This removes one join per fresh recipient: Store19→18 and ACK
6+13N→6+12N (one-target19→18). Cached-completed replay retains its separate
pre-commit join; sender work and the generic post-callback join are unchanged.
There is no reuse across a method return or untrusted callback. The node still
persists local durable evidence before forwarding its one remote Store request.
The ACK loop remains ordered under its real revocation owners: wrapping it in
`Task.WhenAll` would not establish safe independent ownership or help one-target
ACKs.

Four new tests exercise real HTTP Store/ACK with protected response custody
before response release, exact cold replay without new HTTP, and post-callback
mutation/protected-document/authority corruption denial. Focused Windows gate:
48/48 PASS, zero skipped, native0; actual Linux ARM64 `node-authority-tests`:
107/107 PASS, zero skipped, native0; DevOps31/31 PASS/native0. An initial Windows
launcher omitted source-cutover properties and failed compilation before this
gate; the corrected project invocation is the qualification, not that attempt.

Supported retained Build/Up/Verify all returned native0. The three healthy nodes
now run `sha256:e3704142b27bc0ab5b7e8779fdf89303950def1888ac82cb6f70d49950191850`.
All seven named-volume Name/Destination/RW tuples on EACH node hash identically
before/after this update. This proves retained named mounts, not byte-identical
whole-container mount configuration or device/release acceptance. No key,
account, database, native history or floor was replaced.

## Short delivery diagnostics and profiling limits

`-DeliveryOnly` is explicit and disabled by default. It requires a new retained
round and rejects fresh-account, first-attempt-lifecycle and recovery scopes
before profile/network access. It retains all3 sends,6 real receives/ACKs,
three cold exact histories, empty-mailbox and deduplication checks. Only the
three full original-Store batch replays and three GSR control checks are omitted.
A PASS sets `deliveryLatencyQualified`, NEVER `steadyStateQualified` or release
qualification. A failed short round must recover the SAME original round in
the full lane. A permanent five-check scope contract passed/native0.

Rounds27/28 both passed40/40 without resumes, lease waits, non-success commands,
driver retries or session-close failure; counts advanced84/28 then87/29 per
profile. They used the same client runtime as26, with scenario SHA256
`956f223c82110f231fd4fb742f63989553075c7255c139a69bc422ce48a0de5e`.
They are not substitutes for full46-step qualification. Round28's fanout mean
was40.648s (total121.945s); receive/ACK mean25.044s (total150.261s).

The two recent60s traces captured79,020/79,093 and36,382/36,789 explicit wait
samples. ACK has an Ed25519 network-proof burst, not evidence that it dominates
cold replay. An older cold trace has a SQLCipher pre-key-open hotspot, but its
runtime provenance does not match the current memo-qualified runtime. Thread
samples are not kernel/native CPU attribution; no new cache or removed security
check was justified by that old trace. Current ABBA CPU remains~36s, with
JIT6–7s and native protection~3s, so the remaining native/history amplification
is unresolved. The host lacks elevation for a kernel capture; none was forced.

## Post-recipient full round29: failure retained

The strict full round29 completed all three sends, six receives/ACKs, exact
three-way cold histories, original full-Store replay, empty mailbox and dedup
checks, but FAILED at step44, `owner-cold-control-receipt-reverification`.
The closed diagnostic is `ProtectedState / EndpointPairDirectoryFloorAdvanced`,
not the earlier NTS-unavailable branch. The original failed receipt remains
separate. There was one automatic mailbox resume and one lease wait; one
OnionFrame was non-success. Therefore this is neither clean first-attempt nor
full steady-state qualification, despite all three profiles reaching90 native
messages /30 original commands before the final control check.

Completed fanouts40.135/60.979/53.433s; receives/ACKs
45.291/29.636/30.701/15.725/31.752/75.562s. The last includes the automatic
resume/wait. Active501.402s, CPU181.045s, driver wall505.989s. These timings
do NOT demonstrate improved delivery over round28. The recipient join reduction
is source-proven and regression-qualified, not an independently measured
end-to-end speedup. Full original-batch replay total81.226s is a different
operation on longer history and cannot be equated with delivery latency.

Source audit identified a separate availability bug: fetching an absent third
member's real nonce-bound proof can legitimately advance the protected
directory floor, while group publish still holds its previously acquired own
proof in the same command read scope. The stale proof correctly fails closed.
The failure occurs before control selection/authoring, journal save or HTTP;
any fix must refresh at that pre-effect owner boundary with a new command
scope, not ignore the floor or catch generic protected-state corruption.

Supported recovery29 completed the SAME original batch:52 steps PASS,
active226.074s /CPU116.185s /driver wall231.265s; one owned mailbox resume,
zero lease waits. The recovery receipt is not full steady-state or clean
first-attempt qualification. All90 messages /30 local commands per profile and
the existing three-member group were retained. No later round was started
before this recovery completed.

### Bounded pre-control authority reacquisition

The fix introduces a private group-acquisition refusal, not a capability. It is
classified only after the actual jointly protected floor read, exact captured
network LKG/history equality, unlatched/current network and BOTH endpoint clocks
pass. Every mismatching endpoint must be strictly behind the verified directory
generation. Null/lower/same-generation divergent floors, changed network,
expired clock and invalid proof retain terminal failures. Ordinary pair checks
do not enable this group-only mode.

Only the initial `VerifyGroupHeadAsync` inside `PublishOneGroupControlAsync`
wraps this refusal into a sealed pre-control-effect scheduling signal. The
native account may already have performed its normal housekeeping; control
selection, chunk mutation, GSW authoring, group save and dispatch have not run.
The real root/current/held owners unwind before the service permits ONE new
acquisition using `OpenIndependentCommandReadScope`. Existing captured GSR/GSW
bytes are not renewed or reminted; later-loop, generic crypto, I/O, cancellation
and unknown captured outcomes are not caught by this path. The second strict
advance propagates rather than retrying indefinitely.

Six new component cases use an independently created third account, real signed
head advancement during an uncached proof fetch, old-memo refusal and a fresh
independent scope. They also exercise exact terminal network/clock/corrupt-floor,
unavailable-member and nonce-mismatch refusals. They do NOT inject exhaustion
through the full service or prove retained-write lifecycle by themselves; the
owner catch/retry bound and immutable captured-request path were independently
source-reviewed. The first focused launcher compiled the patch and found a
missing codec namespace import; that failed build was corrected and retained
as an unsuccessful attempt, not counted as passing tests.
The next run compiled and reported14 PASS /4 FAIL: the new fixture attempted
to issue a non-successor head from the initial protected floor without a
forward checkpoint. The protocol correctly refused before the test action.
The fixture now authenticates the existing generation1 before admitting the
third account at generation2; no verifier or protocol check was weakened.
The following run again had14 PASS /4 FAIL because the test assumed no group
journal slot existed. Normal account initialization already owns an empty
journal. That assertion now requires EXACT before/after owned-byte SHA256
equality, preserving absence when absent, rather than assuming absence. The
final focused04 run passed18/18, zero skipped, native0 (PowerShell5.1 /
SDK10.0.301). All six new cases and ordinary proof/clock/network/cancellation
regressions ran; failed attempts are not included in this passing terminal.

## Final retained full round30

CLI67/67 PASS, zero skipped, native0; shipping build native0 with0 warnings /
0 errors. Full round30 on that runtime passed46/46, EVERY driver attempt1,
zero Store/mailbox resumes, lease waits, non-success HTTP or session-close
failures. All three profiles retain93 messages /31 original commands,
Active3/epoch2. Cold original-Store replay, native semantic history, empty
mailboxes, deduplication and GSR control receipt/cursor checks all completed.
This is full retained steady-state qualification, not fresh group lifecycle,
device, retention, sustained stability or release acceptance.

Final runtime SHA256:
`ee87e0174eda2cb10a1d8e1568486ef59efb1b94af400d2b1f73b32c5aa20904`.
Scenario SHA256 remains `956f223c82110f231fd4fb742f63989553075c7255c139a69bc422ce48a0de5e`.
The ABBA experiment above used the earlier5ee runtime containing the SAME SQL
snapshot patch; it is not a controlled ABBA measurement of this final binary.

### All operation totals, seconds

Each row sums ALL listed calls, not the mean of one message. Both columns are
complete46-step PASS runs. Native retained history grew69→93 messages per
profile; network work and cold-start conditions also differ. No normalization,
subtraction of security checks or synthetic successful timing is applied.

| Operation | Calls | Baseline22, s | Final30, s |
| --- | ---: | ---: | ---: |
| Cold account status | 3 | 1.761 | 2.808 |
| Left contact list | 3 | 3.485 | 4.218 |
| Right contact list | 3 | 7.595 | 6.698 |
| Retained owner head | 1 | 0.254 | 0.278 |
| Command preflight | 3 | 0.646 | 0.725 |
| History preflight | 3 | 2.266 | 2.586 |
| Active owner head | 1 | 0.231 | 0.269 |
| Active recipient heads | 2 | 0.445 | 0.487 |
| Original sender command count | 3 | 0.545 | 0.646 |
| One command → two-recipient fanout | 3 | 105.770 | 164.248 |
| Native receive + durable ACK | 6 | 120.760 | 130.023 |
| Cold exact native history | 3 | 3.334 | 3.413 |
| Full original-Store batch replay | 3 | 68.466 | 124.044 |
| Empty mailbox after replay | 3 | 17.141 | 18.873 |
| Deduplicated history | 3 | 1.820 | 2.653 |
| Owner GSR receipt reverification | 1 | 1.452 | 3.927 |
| Empty GSR cursor replay | 2 | 8.913 | 7.578 |
| **Active operation total** | **46** | **344.884** | **473.474** |
| Process CPU total | | 180.825 | 280.562 |
| Driver wall | | 350.875 | 481.604 |

### Latest delivery prefix comparison, seconds

Delivery-only28 and full30 execute the SAME send/receive prefix before their
different post-history lanes. Accounts/group were retained, not reset; history
still grew87→93. This is an observational comparison of the final node/client
slices, not an isolated causal benchmark of one patch.

| Actual operation | Round28 | Final30 |
| --- | ---: | ---: |
| A → two members | 37.677 | 56.657 |
| Receive/ACK A → B | 25.722 | 23.047 |
| Receive/ACK A → C | 26.569 | 20.134 |
| B → two members | 42.916 | 54.957 |
| Receive/ACK B → A | 25.025 | 21.310 |
| Receive/ACK B → C | 24.748 | 21.077 |
| C → two members | 41.352 | 52.634 |
| Receive/ACK C → A | 24.638 | 20.675 |
| Receive/ACK C → B | 23.559 | 23.780 |
| **Mean fanout** | **40.648** | **54.749** |
| **Mean receive/ACK** | **25.044** | **21.671** |
| Fanout ONION request count | 6 | 12 |
| ACK ONION request count | 12 | 12 |

Observed ACK mean fell13.5% versus28, but remains7.7% above baseline22's20.127s.
Final fanout is34.7% slower than28, with twice the ONION requests; CPU also
grew54.828→73.766s for the three sends. No overall delivery speedup is claimed.
Another full run would grow history again, not make these samples controlled.
The measured SAME-history SQL replay improvement remains10.8%; required1–2s
delivery and removal of the main ONION/native/history amplification are OPEN.

Subsequent [issuer-journal attribution](cli-fanout-grant-attribution-2026-10-21.md)
identified the extra six full30 fanout requests as six necessary new Deposit
grants: every prior exact-scope grant was already expired. They were not
duplicate Store requests. The later report separately qualifies suppression of
unproductive live renewal at an unchanged current issuance ceiling; it does not
relabel full30's expired-grant acquisitions as avoidable.

Qualified source commits: xnode95b9d43 +6837168; DevOps8f666d8 +862ba33;
Shared d9ebdd4 +2ae51d8. No Windows/Android client or production node was changed.
No crypto/time-policy relaxation, native floor/profile replacement, account
reset or rekey was used; legitimate protected floors advanced normally. Logs
and receipts remain in the local artifact paths
listed above; raw custody, credentials and traces are not committed.
