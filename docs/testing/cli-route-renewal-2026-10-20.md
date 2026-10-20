# Retained route renewal and original group work

Scope: the existing local Registry/three-XNode contour and retained CLI profiles.
No production, MAUI/Android, account reset, new contact, data import or node-key
replacement. Prior failed rounds remain failed. This is not release acceptance.

## Reproduced defects and bounded fix

The preceding [ONION checkpoint](cli-onion-latency-2026-10-20.md) stopped strict
round7 after the original A eighth group command was native-committed. Initial
counts: A22 messages /8 local commands; B/C21 /7,3 members,epoch2.

Actual authenticated route health was read through Shared, not by opening private
node storage or treating a cached latest route as authority. Within these exact
three accounts the advertisements for B held by A/C were expired; B's reverse
routes to A/C still covered current time. Original XUR descriptors did not.
Therefore the current reverse mailbox is usable for a normal ratcheted route
successor. An expired XUR is never used or made current.

Shared now schedules maintenance from actual native own-advertised history,
the adopted own publication and existing common authored custody. Unchanged
advertisement creates no event. Unfinished update selects its exact operation;
authoring/encryption/Store retain their independent currentness and custody
checks. Publication renewal is the existing atomic pending/commit saga. No new
private journal, generation, counter family, schema or network grammar is introduced.
One duplicate control preparation was removed; actual encryption admission remains.

The first real repair uncovered a second defect in Protocol's control author:
it included the old PMT snapshot expiry in the minimum control lifetime, despite
the verifier already supporting independently current same-assignment carriage.
That contradicted [DR-0122](../../../docs/survival-program/decisions/DR-0122-logical-mailbox-assignment-carriage.md).
Only that incorrect bound is removed. All FIVE logical route records' signed
expiry windows remain, as do the seven-day control ceiling, protected current
lease, exact original assignment/current eligibility, device/DCA and witness
checks. No timestamp is backdated and no signed expiry is extended.

`ReadContactRouteHealthAsync` exports three diagnostic Booleans only. It returns
no route, descriptor, capability, key, identifier or permission. `refresh-route`
accepts only an existing conversation, never caller route bytes or operation IDs.
The recovery driver validates exact retained semantic commands and labels its
result as recovery, not a fresh first-attempt/strict steady-state qualification.

Registration now reuses six owner-local pure canonical-grammar predicates,
including the four formerly unused route/grant/send/read decodes. The memo holds
only one32-byte digest per kind, including all account/instance/network bindings.
Actual authenticated storage reads, changing bytes, cross-root joins, SQL/native
floors, time, lease and effect checks are not memoized.

Actual concurrent closure reads also exposed the Registry's one-public-waiter
queue: a maintenance no-op encountered eight HTTP non-success responses. Public
waiting capacity is now three, still with one active frame/write permit, one
reserved issuer waiter, the original whole-operation deadline and overflow429.
Cancellation/exclusivity/overflow remain tested. This is bounded admission, not
proof caching, concurrent distribution of unbounded frames or weaker authority.

An additional new-work Deposit defect was reproduced by the existing logical
assignment fixture's third acquisition: the grant already ended at the route's
signed1130 ceiling, but the generic retry-window margin caused pointless holder
replacement. Scheduling now keeps that still-live winner when the same route
cannot improve its lifetime. All FIVE route expiries still bound it; pending
successors resume exactly and shorter issuer-limited grants still renew. The
original exact-request/callback-count assertions remain, with explicit ceiling
and renewal-margin assertions added, not waived.

The intermediate new strict round8 uncovered stale public memo composition:
independent receive/ACK advanced actual network custody while the serial host
kept an uncaptured established-group read. IL903 in the captured shipping binary
is the unchanged rejection `Group read scope no longer binds actual network custody.`
CLI now ends that uncaptured group phase BEFORE an independent network operation.
The next group phase acquires current authority afresh; no captured loan is
renewed. The actual memo reader's floor/fork/clock checks are unchanged. New
signed-successor/fork/captured-loan/clock tests exercise the boundary, including
negative cases. This is not a retry after accepting stale authority.

## Verification ledger

Ignored artifacts under `artifacts/cli-route-20261020` remain local receipts.

| Run | Result | Scope |
| --- | --- | --- |
| CLI `build-01`, `build-02` | Compile failures | New diagnostic initially omitted the explicit production-project include and namespace import; corrected, not presented as PASS |
| CLI `build-03`/`unit-03` |0 warnings/errors;65 PASS/native0|Read-only route diagnostics |
| CLI `build-04`/`unit-04` |0 warnings/errors;66 PASS/native0|Owned maintenance and strict closed command arguments |
| Shared `shared-01` |FAIL|New fixture selected the wrong grant-owner side at its final Store; corrected to the actual sender owner, no assertion removed |
| Shared `shared-02` |1 PASS/native0|Actual encrypted/native no-change→new-needed→exact control before/after native commit→verified Store→no-change |
| Shared `shared-03` |Compile FAIL|Regression addition initially reused an existing local name |
| Shared `shared-04` |18 PASS /1 FAIL, native1|Route renewal, native processing and maintenance; existing logical-assignment lost-grant-reply test failed its exact-request assertion before reaching the new control-author regression. This remains a failure, not full qualification |
| Shared `shared-05` |1 PASS/native0|Dedicated genuinely signed expired-PMT successor-control regression: current carriage succeeds; actual signed route expiry rejects current delivery while historical facts remain verifiable |
| CLI `build-05`/`unit-05` |0 warnings/errors;66 PASS/native0|Shipping runtime with the Protocol correction |
| `repair-01` |FAIL at command3|Actual publication renewal completed; control author then rejected its incorrect PMT lifetime minimum before creating a control command. Original group work retained |
| `repair-02` |FAIL at command11|Both current ratcheted route updates were stored, received and durably ACKed; both peer XRA intervals became current. The final no-op failed on closure admission. This partial success is not whole-run PASS |
| Shared `shared-06` |24 PASS/native0|Six-kind grammar, actual protected-root authentication, account owner, native maintenance and signed control regression |
| Shared `shared-07` |Compile FAIL|A renamed test parameter left one stale nameof; corrected without removing cases |
| Shared `shared-08` |13 PASS/native0|Final grammar/authentication cases, preserving original Boolean case identities |
| Registry `focused-01` |15 PASS/native0|Real TestServer public admission, bounded file reads, cancellation, overflow and single-response exclusivity; not PostgreSQL/full transport qualification |
| CLI `build-06`/`unit-06`, `build-07`/`unit-07` |0 warnings/errors;66 PASS/native0 each|Final six-predicate shipping composition; latest build after local Registry smoke |
| `repair-03` |11/11 PASS|Same already-updated peers, receive/ACK and current interval verification; both subsequent maintenance calls created zero new controls |
| `recovery-01` |FAIL at preflight command13|PowerShell equal-precedence and/or expression rejected B's valid7-command state. Parentheses corrected; no group send occurred in this run and its FAIL is retained |
| `recovery-02` |49/49 PASS|Exact A eighth command/full batch recovered; missing B/C eighth commands created once. All three histories24/8, current route, six receive/ACK checks, cold full-batch Store audit, dedup and empty mailbox/GSR; no automatic Store/mailbox resumes or lease waits. Explicit recovery, not first-attempt qualification |
| `steady-01` |FAIL at command29|New strict round8 delivered A/B ninth commands; C send failed its public memo/network-custody guard before ONION dispatch. One prior ACK used automatic mailbox resume and one lease wait. Original commands are retained; this incomplete run is not a new latency baseline |
| Shared `shared-09` |19 PASS/native0|Original logical-assignment failure fixed with assertions retained/tightened; shorter-grant renewal/reply loss, route maintenance, signed-expiry control and retry-window tests |
| Shared `shared-10` |18 PASS/native0|Actual signed successor across independent phases; fork/captured-loan/clock rejection, original one-command/working memo checks and independently acquired ACK |
| CLI `build-08`/`unit-08` |0 warnings/errors;66 PASS/native0|Shipping composition with useful-only route-capped Deposit renewal and explicit independent/group phase invalidation |
| `recovery-03` |50/50 PASS|Original A/B ninth commands verified already present on all members, no replacement send; missing C ninth command created once. All three histories27/9; full native Store audit26/19/19, dedup/empty mailbox/GSR. No automatic Store/mailbox resume or lease wait. Active415.514s; explicit recovery, not a new-round benchmark |
| `steady-02` |FAIL at command29|A/B tenth messages delivered/ACKed; C failed on a private grant hop with OutcomeUnknown. Initial A Store resumed once; C's owned Store continuation then encountered HTTP400 from issuer head-change fencing. This incomplete run is not a delivery speedup |
| Node `issuer-hop-01` |26 PASS/native0|Actual private HTTP client: exact intent and fresh signed forwarding nonce on503→paired response, maximum two503 attempts, no400 retry, cancellation; existing malformed/binding/size/descriptor/origin guards. In-process HTTP fixture, not socket/real issuer evidence |
| Registry `focused-02` |40 PASS/native0|Private grant HTTP shape/admission plus exact code-owned head-advance503 classification; generic crypto and wrapped/message-imitation remain400. Not PostgreSQL/full issuance qualification |

Closed node/Registry diagnostics for failed `steady-02` located the grant refusal
at `DeepIdV2DirectoryProofIssuer.RequireStillCurrentAsync`, IL570: the current
directory head changed during issuance. This was not invalid holder input.
That same rejecting guard remains; only this typed race maps to503 at the private
grant endpoint. XNode may repeat the exact idempotent issuer intent once after503
with fresh forwarding authentication inside the original cancellation and30s
cap. Other HTTP rejects do not repeat. No original XMG2/holder, route, evidence,
signed lifetime or winner is replaced. Failed repetitions remain uncertain.

Supported Registry `registry-build-02` and Node `node-build-01` exited0. Supported
`server-up-01` Up exited0; its immediate diagnostic correctly rejected four
containers still `starting`. A subsequent bounded read-only warmup check passed:
all nine services healthy, every mount/CPU hash preserved, only the six containers
in the two updated image families recreated; publisher/ingress/floor unchanged.
Original before/after and native terminals are retained, not overwritten.
Registry image:
`sha256:49adad7aea23d42c2e4621381f37e38cc632da0762a62619a10d30ae70ea719c`;
three-node image:
`sha256:fbfbb9dd7c39b76ae8e11876ef62e24de87757b59d69311e41d978e55adb32c5`.

`smoke-02` native0 verified the updated local composition. Its first outer
orchestration mistakenly included an already-used build directory and stopped
before any client command; the corrected driver required that actual smoke
terminal and left the shipping runtime unchanged.

`recovery-04`:53/53 PASS, all histories30/10, full original batches28/21/21.
One original ACK resumed automatically, no Store resume/lease wait. All original
messages and uncertainty were retained. `steady-03` then completed46/46 commands
on the updated server images, all CLI attempts1, histories33/11, full batches
30/23/23, six native receives/durable ACKs, cold dedup and empty mailbox/GSR.
One Store resume and one lease wait are explicit; this is NOT zero-recovery
qualification. Active776.550s / CPU346.013s: slower than prior632.739s, not a
delivery speedup. History/audit workload and grant state differ as documented.

Controlled local-history comparison `matched-read-01` used the immutable prior
runtime against the final CLI on the SAME retained33/11 histories, one warmup
and three measured reads per build/profile, reversing build order for B. Means
in ms: A746.0→232.0, B3032.0→2291.7, C4855.0→4846.3. A/B improve; C is effectively
unchanged in this sample. This is local read latency, not message/Signal parity.

The complete intermediate round exposed a concrete remaining head-of-line
coupling: private grant issuance held the same resource semaphore as public
closure downloads across external signing/guards; public fetches waited up to
10.349s. The permit was never a publication lock (source/floor guards remain).
It is now split into one public response plus one authority operation, each
bounded, with public queue3 / shared issuer queue1 and unchanged deadlines/frame
sizes. Anonymous public concurrency is still one. Only resource parallelism
changes; every authority check remains. Registry `focused-03`:16 PASS/native0,
including public download completion while authority is held, independent
permits, overflow, cancellation and response lifetime. TestServer shape evidence,
not cryptographic acceptance or deployed performance. A new complete round is
required before claiming delivery improvement from this split.

Protocol `graph-01` production build and actual assembly/resource/public-API,
source/build/lock graph passed/native0 (exact three packages). This is not an
unfiltered Protocol source/package qualification. Registry `registry-build-03`
and supported `server-up-02` exited0: Registry plus two signer containers updated,
all six other containers/images—including the three nodes—unchanged, all nine
healthy, every mount and CPU setting preserved. `smoke-03` exited0. Registry image
for the split-resource run:
`sha256:33bd279ae4f03d9eabb6a5a3c463df490b5f038fc650427cba14e0023198f685`.
Node image and CLI runtime remain exactly those recorded above.

Numeric-only existing mailbox timing was collected in DevOps `node-work-01`:
14 sampled slow terminal operations,125–201 lease checks per sample and maximum
lease-check total11.477s. These are rate-limited diagnostics, not all RPCs or an
overall benchmark. Raw logs, identifiers and bodies were not retained. One
separate native observation rejection also remains recorded; no guard was waived.

Final shipping runtime after `build-08`:
`c4b8fbd72311ed29af93607fe0605fc177d1bad69aa4790851522a69271626bc`.
The preceding intermediate runtime was
`4ff6607b3e6f3837f2fa99a7591fbc9be4daa3fb86d5907dc6c221316af01ca0`;
its failed strict round8 does not qualify the final composition. All connected
drivers archive their full shipping folders and frozen script/module hashes.

Supported local Registry Build/Up and smoke exited0. Up recreated Registry and
its two issuer signers because all three use that image. The initial diagnostic
that expected only Registry recreation rejected and is retained; the follow-up
verified exactly that shared-image family changed, all nine mounts and CPU
limits stayed unchanged, and the other six service containers/images—including
all three nodes—were unchanged and healthy. No reset, provisioning or new keys.

The final connected repair, original-round recovery and new strict timing are
recorded below when their terminal receipts exist. Neither a partial successful
Store nor a shorter failed command is a successful full delivery measurement.

## Final admission correction and connected qualification

`steady-04` completed46/46 PASS after the resource split:36 group messages /
12 local commands per profile, original full batches32/25/25. Active828.058s,
CPU358.575s; Store resumes2 and lease waits2, no ACK resume. C's fanout alone
took234.524s. This is a real successful round but not a speedup or zero-recovery
claim. The original failing sends and their exact ciphertexts were not replaced.

The finite native reason for this tail was `NetworkExpiry`. Initial diagnosis
incorrectly equated that bound with DTT1/nonce-proof expiry. Source inspection
and real signed fixtures established that it includes the **ADH1 signed end**,
not the nonce proof's monotonic deadline. A fresh proof of the same ADH1 cannot
extend this end. A newer independently verified ADH1 can cover a grant that was
issued under that newer head while the node still retains an older live head.

XNode now schedules at most one fresh directory/network acquisition at **new
grant admission**, only when the actual current-issuer signature/network match
and grant expiry exceeds the captured context's record bound. It then runs the
unchanged full host grant checks before effects. Old captured contexts, grant
bytes, policy/record expiry, floors and in-effect observational fences are not
extended. Unavailable acquisition fails closed; no resolver/stale fallback.

Node `grant-window-01` through`06` retained their FAIL receipts: initial positive
fixtures crossed PMA2, and an attempted short nonce lifetime could not model an
ADH1 bound. Those are not passing evidence. `grant-window-07`:5 PASS with actual
witness-signed ADH1 successors; `08`:91 PASS for adjacent runtime/admission/private
issuer paths; final`09`:92 PASS/native0, including an additional **same-head**
negative case. The latter proves a fresh nonce alone still cannot admit the
too-long grant. Positive/negative signature, unavailable proof, original context
immutability and outer signed policy/network bounds remain covered. No grant or
policy boundary was removed to make these tests pass.

Supported `node-build-02`, `node-up-01` and`smoke-04` exited0. All three node
containers updated to
`sha256:5ec421138f474d1ff3efd12e58186e8a95662c45f8f25183c8d899942332b940`;
the other six containers/images—including Registry and both signers—were
unchanged. All nine services were healthy, with every mount and CPU setting
preserved. No key, account, floor or volume reset. CLI runtime remains`c4b8fbd…`.

Signal's [Sesame](https://signal.org/docs/specifications/sesame/) describes
retained asynchronous encryption sessions, and [Double Ratchet](https://signal.org/docs/specifications/doubleratchet/)
advances per-message chains rather than rerunning initial key agreement. The
applicable lesson here is to retain native session state and separate independent
authority acquisition from ordinary work. These specifications provide no
matched latency measurement for our multi-hop/two-replica network. This run does
not establish Signal speed parity, and adds no crypto stack.

## Final full three-CLI timing (`steady-05`)

Strict round12 completed **46/46 PASS** on the final node/Registry images and
the same shipping CLI runtime. All three retained profiles have39 messages /
13 local commands, active group epoch2 with exactly3 members. Six native receives
and durable ACKs, complete original batches34/27/27, cold dedup, empty mailboxes
and empty GSR/control replay all passed. Every driver attempt was1, but B needed
one automatic original Store continuation and one lease wait. No automatic ACK
resume. All sessions closed normally. This is not zero-recovery qualification.
Next new strict cursor is13; do not rerun completed12 as new work.

| Operation family (sum, seconds) | Prior baseline | Before split | Before admission fix | Final |
|---|---:|---:|---:|---:|
| `account-cold-status` ×3 | 2.463 | 1.741 | 1.910 | 1.774 |
| `cold-control-cursor-empty-replay` ×2 | 9.255 | 16.204 | 16.128 | 13.993 |
| `cold-original-full-batch-replay` ×3 | 69.318 | 90.948 | 97.336 | 99.462 |
| `exact-three-active-owner-head` ×1 | 0.218 | 0.197 | 0.129 | 0.218 |
| `exact-three-active-recipient-head` ×2 | 0.421 | 0.435 | 0.265 | 0.496 |
| `fanout-recipient-native-receive-ack` ×6 | 228.180 | 235.386 | 232.963 | 206.301 |
| `one-command-two-recipient-fanout` ×3 | 256.742 | 348.865 | 383.062 | 366.048 |
| `owner-cold-control-receipt-reverification` ×1 | 0.337 | 3.963 | 3.865 | 3.360 |
| `pair-left-cold-list` ×3 | 5.327 | 6.748 | 4.240 | 6.777 |
| `pair-right-cold-list` ×3 | 19.071 | 23.793 | 14.654 | 24.348 |
| `post-replay-deduplicated-history` ×3 | 6.810 | 8.719 | 7.861 | 7.685 |
| `post-replay-empty-mailbox` ×3 | 19.174 | 23.903 | 53.012 | 24.805 |
| `retained-steady-owner-head` ×1 | 0.224 | 0.210 | 0.175 | 0.262 |
| `sender-original-command-count` ×3 | 0.559 | 0.669 | 0.546 | 0.697 |
| `steady-native-command-preflight` ×3 | 0.665 | 0.558 | 0.398 | 0.705 |
| `steady-native-history-preflight` ×3 | 6.947 | 7.769 | 4.708 | 8.309 |
| `three-way-cold-native-history` ×3 | 7.028 | 6.442 | 6.806 | 6.710 |
| **All 46 commands** | **632.739** | **776.550** | **828.058** | **771.950** |

Compared with the immediately preceding complete round: active828.058→771.950s
(-6.8%); three fanouts383.062→366.048s (-4.4%); six receive/ACK232.963→206.301s
(-11.4%). C's previous234.524s tail fell to110.586s (-52.8%) with no continuation;
A93.572s, B161.890s (one continuation). This does not hide B's remaining tail.
Fanout ONION RPC sum135.195→156.234s **regressed15.6%**, while ACK ONION RPC
sum124.526→97.108s improved22.0%. Client CPU358.575→377.078s also regressed5.2%.
The older632.739s baseline remains faster overall; final is22.0% slower than it.

These are operational single-round measurements, not a causal microbenchmark:
history grew18/6→33/11→36/12→39/13 and full original batches20/13/13→30/23/23→
32/25/25→34/27/27. Retained grants, acquisition state and continuations differ;
the last server update made nodes cold. Do not claim universally faster sending,
instant delivery or Signal parity. Controlled SAME-data local-read results above
are the separate evidence for pure registration work reduction.

Read-only, numeric-only final node diagnostics`node-work-03` retained21
rate-limited slow terminal samples, not all RPCs: maximum207 lease checks and
11.251s total lease-check work in one sample. Authority source dominates that
sample family (per-node maxima4.061–5.182s); new host verification maxima are
only3–13ms. Reusing that constructor is therefore not an evidence-backed main
optimization. No native terminal-incomplete entry was observed in this bounded
log slice; the client still had one uncertain ONION result and its owned Store
continuation. Raw logs, payloads, identities and authority times were not saved.

Route repair/original delivery are operational again. Proactive lifecycle and
remaining local/native/authority latency stay in S05; next optimization should
target measured repeated authority/native work without dropping effect fences,
not another speculative crypto-stack or constructor cache.

## Remaining boundaries

The bounded repair uses a CURRENT reverse mailbox route, not an XUR service
activation. Shared's XUR publication/fetch, successor overlap, both-directions
expiry/offline recovery, retained horizon and rollout/capacity gates remain open.
If all authenticated update paths have expired, no automatic public resolver
substitution or contact/account reset is authorized by this implementation.
The existing [contact-update owner](../../../docs/architecture/CONTACT-AND-GROUP-PROTOCOL-V1.md#10-contact-route-and-device-updates)
and [retention owner](../../../docs/architecture/RETENTION-AND-RECOVERY-V1.md#3-beyond-horizon-behavior)
still apply. Unfiltered full, package, scale, device and release qualification
are separate; a positive CLI slice does not close them.
