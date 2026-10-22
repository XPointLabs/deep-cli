# Ordinary fanout and ACK path — 2026-10-22

Continues the [post-rotation investigation](cli-authority-regression-2026-10-21.md).
Same three retained CLI accounts, group revision11, active3/epoch2, no reset,
rekey, authority rotation, production or device work. Supported same-peer route
maintenance after the failed43 is recorded separately below. Registry images,
quotas, signed time policy and persisted formats are unchanged. The later
coordinated Node/internal-peer upgrade is recorded below.

## Attribution before changing authorization

Real client and Node managed sampling traces are retained only in private local
custody. Managed thread-time includes blocked/idle threads and is not kernel CPU
attribution. ARM64 apphost, SQLCipher and libsodium were confirmed; no x64
emulation was introduced. SQLCipher already uses random raw-key syntax, not a
human-password KDF. No key-format change, key cache or TLS relaxation is made.

Diagnostic rounds40/41 both complete40/40/native0 but each contains one owned
mailbox resume/lease wait.40 also has DirectoryHistory catchup and expired-grant
acquisitions. Sampling overlaps these runs; they are functional attribution,
not clean latency or no-recovery evidence. The server refusal was an actual
atomic network-source change during `ReadNetworkAsync`; its guard remains.
The actual compiled throw location was resolved rather than guessing from the
sanitized `cryptographic-rejection` category. No raw exception/payload is logged.

Diagnostic42 has40/40 PASS/native0, no resumes/waits/retries/non-success, but is
delivery-only, not a full control/history audit. Numeric phase timings were
added with seven fixed labels, count/total/max only. They contain no slot, SQL,
path, account, key, payload, exception or activity identifier. Nested totals
overlap and cannot be added into a synthetic critical path. Observation failures
cannot replace storage outcomes; disabled observation does not change checking.

For the first two-recipient send, diagnostic42 records2,092 secure-aggregate
loads (4.141s),62 application opens (2.435s, including1.768s full integrity),
323 account-DB validations (1.345s),171 native reconciliations (2.599s) and319
native verifications (2.712s), plus26 group decodes (0.344s). ACK local phase
totals are substantially smaller; its ONION/proof exchanges remain significant.
These observations identify amplification; they do not authorize dropping
MAC, schema/integrity, native prefix, current clock/floor or callback fences.

## Retained corrections

[DR-0165](../../../docs/survival-program/decisions/DR-0165-page-authority-and-noop-group-publication.md)
owns the bounded orchestration change; no wire/schema/version is allocated.

1. Ordinary group send previously entered the full publication path even when
   every GSR write already had a receipt. This reconstructs the group lineage,
   rendezvous and prior package chunks merely to return "nothing to publish",
   before the actual send owner independently verifies its head and receipts.
   The owner now reads the actual protected root for a scheduling-only hint.
   Pending work still takes the existing full publication path. A false hint
   is not permission: actual send reopens the root, verifies current membership,
   complete original receipt sets and signatures before authoring or advancing
   a sequence. Invalid nonempty receipts and missing/forked state do not pass.
   Explicit publication and cold full control audit remain unchanged.
2. A mailbox page formerly acquired its own endpoint for Retrieve, then acquired
   another own endpoint immediately for ordinary receive. Now the page starts
   a fresh independent command scope and may borrow that same still-current
   PUBLIC own endpoint after actual clock/floor/issuer revalidation. No private
   Retrieve loan, key, captured request or outcome crosses the boundary. Initial
   and Braid retain parent paths; ACK still acquires a separate fresh independent
   scope after materialization and reconstructs native semantic/page custody.
   No old nonce-proof deadline or signed lifetime is extended.

Focused source gate: Shared73/73, CLI68/68 PASS/native0; zero build warnings/errors.
Includes independent page/ACK and clock refusal, unpublished-control refusal,
hostile group chunk/native replay, lease/floor/publication-expiry and lost-ACK/
cold recovery cases in the declared filter, plus genuine fixture prerequisites.
This is a focused gate, not unfiltered/package/device/release acceptance.

## Measurements

The unprofiled diagnostic42 before the correction is retained for comparison:

| Operation | Individual wall times | Mean | ONION | DirectoryProof |
| --- | --- | ---: | ---: | ---: |
| Two-recipient fanout | 48.196 /45.491 /41.972s | 45.220s | 8 | 8 |
| Receive + native ACK | 23.306 /21.787 /20.365 /23.808 /20.590 /19.224s | 21.513s | 12 | 36 |
| Empty mailbox | 6.311 /6.914 /9.085s | 7.437s | 3 | 3 |

Active305.554s, CLI CPU143.075s, driver308.595s. The additional two fanout
ONION requests are retained, not hidden as "warm" work. Different retained
history, grants and scheduling make subsequent rounds observational comparisons,
not an identical-state A/B or a1–2s delivery claim.

Full43 FAILED at its first two-target fanout (40.316s), with one owned Store
resume, four ONION calls and two HTTP non-success results. Original group
authoring is retained. `recovery-43-01` also FAILED at exact original-batch
continuation (51.419s), with one Store resume and two HTTP non-success results.
Neither failed attempt is a clean delivery benchmark or a new command.

Actual deployed Registry code locates both refusals at `DecodeRequestCore`,
IL316: `CurrentRoute` evidence arrived with effective horizon0. XNode's
non-current resolver branch constructs that shape; Registry deliberately accepts
only success/current or the separately authenticated retained-read shape. No
decoder, lifetime, quorum, route or issuer guard is loosened. This explains the
400→unknown outcome, not the precise resolver disposition: the sanitized
diagnostic does not distinguish not-found, expiry and conflict. All six
authenticated retained XRA health checks are current/no-fault; that fact alone
does not prove a current resolver publication exists.

Supported same-peer re-introduction/normal reverse maintenance for B↔A
(`repair-ba-01`) completed11/11/native0: actual current publication, existing
relationship control, native receive/ACK, current route health and a no-new-
control check. No text/group command, account, session, ratchet, pending Store,
capability lifetime or journal was reset/imported/replaced. Remaining pair
maintenance and original43 completion are separate from a new-round benchmark.
`repair-ca-cb-01` then completed21/21/native0 for C↔A and C↔B, including the
same current-publication/control/receive/ACK/no-duplicate checks.

`recovery-43-02`:49/49 PASS/native0, no automatic Store/mailbox resume, lease
wait, command retry or abnormal session close. The exact original A batch was
continued, not reauthored; missing B/C commands were authored once. Each retained
account now has132 group messages /44 original local commands, active3/epoch2.
All three cold original batches, six receive/ACK checks, dedup/empty mailbox,
owner full GSR receipt audit and empty recipient GSR cursors pass. Active435.858s.
Recovery cannot qualify a new first-attempt latency round. New delivery44 is
run immediately afterwards with no recovery flag on the same three accounts.

Delivery44 FAILED at command31, after all three new fanouts were stored. One
receive used an owned mailbox resume; another retained-read grant request
received peer HTTP503. The recipient's actual diagnostic is
`ContactReplicaRequestReceiver.EnsureExactPlacement`, IL303, called from the
HTTP endpoint; no returned grant was accepted. The diagnostic does not identify
the unequal field, so this failure alone is not evidence of one specific field.

The source audit separately reproduces an invalid coupling: `ValidUntil` in
the wire projection was compared byte-for-byte with a receiver's independently
minted local bound, which includes ADH1 validity. This is not stable assignment
identity. [DR-0166](../../../docs/survival-program/decisions/DR-0166-replica-assignment-and-local-admission.md)
removes that local deadline from the internal wire entirely: only CRQ2/CRS2
at the v2 private endpoint. The untrusted decoded projection has deadline0,
cannot pass local EnsureUsable or supply VerifiedPlacement, and cannot mint
authority. Receivers still independently mint/check their own original current
NETCODEC, time, custody and request/effect authority. Network/view/shard/epoch/
placement/ordered-peer identity still matches exactly. No old reader/route or
client wire/schema/key/journal reset is introduced.

Node focused source:262/262 PASS/native0, zero skip, including actual signed
placement, hostile assignment/old-wire refusal, independent local expiry,
replica staging/claim/final commit, retained-read custody and fixture prerequisites.
Supported Node Build and Up/native0 updated all three local peers together to
`sha256:e74ad1e40401172338b0c320196a68d4b8ab1f69028b74128f553274afca294e`;
the existing physical ingress was restarted for the new allowlist. All nine
services are healthy; Registry/publisher/issuer/floor images are unchanged.
This is not full, scale, package, device or release qualification.

`smoke-current01`: native0, actual Registry proof and three verified ONION nodes;
not device/message evidence by itself. `recovery-44`:52/52/native0,135 messages /
45 original local commands each, full original Store/GSR audits. One owned
mailbox resume and one lease wait remain explicit; not first-attempt evidence.

Delivery45:40/40 PASS/native0, zero Store/mailbox resumes, lease waits, network
failure/non-success, command retries or abnormal close. Each unchanged account
retains138 group messages /46 local commands, active3/epoch2. Delivery-only
does not replace full control/history/package/device/release qualification.

| Operation | Diagnostic42 | Delivery45 | ONION42 /45 | DirectoryProof42 /45 |
| --- | ---: | ---: | ---: | ---: |
| Two-recipient fanout mean |45.220s|58.911s|8 /12|8 /8|
| Receive + native ACK mean |21.513s|22.135s|12 /13|36 /30|

Delivery45 fanouts57.932 /57.805 /60.997s; receive/ACK22.519 /21.484 /26.649 /
20.413 /19.931 /21.816s. Active356.269s, CLI CPU175.986s. Fewer public proof
exchanges are demonstrated, but **an overall delivery speedup is NOT**. All six
Deposit grants required acquisition after the idle interval (12 rather than8
fanout exchanges); receive has an extra acquisition too. History, grant state
and server restart differ: these are operational comparisons, not causal A/B.

Tiered-JIT experiment46 used a separately archived R2R host policy, after CLI68
tests/native0 and explicit runtimeconfig verification. Project R2R ARM64 headers
were independently confirmed. Compilation counters fell from seconds to hundreds
of milliseconds, but46 FAILED on Directory history availability before completing
the round. Its two sends have different grant-acquisition workloads from45; this
does not establish delivery improvement. The runtime override was REMOVED, and
the final host keeps the default policy. [Runtime setting semantics](https://learn.microsoft.com/en-us/dotnet/core/runtime-config/compilation)
are not a substitute for an actual matched measurement.

Registry's closed46 diagnostics show Directory proof/history503 with
`ContactResolveDirectoryPackageUnavailableException`; the same slice has real
NTS query timeouts. No stale time or lower quorum is accepted. A second source
defect was identified: successful empty catchup suppressed the one independent
fresh nonce-bound proof when the floor had not advanced, even after transient
availability recovered. [DR-0167](../../../docs/survival-program/decisions/DR-0167-bounded-history-read-availability.md)
retains full signed history/floor verification, then permits that single fresh
proof even without head advance. Current proof remains mandatory.

Read-only history now permits ONE exact POST repeat per entire catchup, only
after503 with explicit positive Retry-After<=5s and original cancellation/deadline.
429, other rejects, absent/zero/long hints and a second503 still refuse. Failed
responses are disposed before waiting; the request is owned/canonical and cannot
be changed by a callback. Scheduling mints no capability. No NTS policy, bound,
TLS, private holder, message, grant, ciphertext, counter or journal is replaced.
CLI exposes only closed DirectoryUnavailable/DirectoryRateLimited categories.

Final source ledger: `final-build01` compile FAIL (new test used the wrong
bootstrap verifier type), then `final-build02`89 PASS/3 FAIL/native1 (new retry
fixtures incorrectly used zero, which the existing transport treats as no hint).
Assertions were not waived: fixtures now use1s, and zero is an explicit refusal
case. `final-build03`: Shared26/26 and CLI70/70 PASS/native0, zero warnings/errors,
including genuine signed unchanged-head fresh-proof success/refusal, exact
request/catchup-wide retry budget, malformed body/shape,429 and cancellation.
This focused correction does not turn the retained broader FAIL into full PASS.

Production ingress lab attempts remain FAIL: the first hit inherited PowerShell
ACL module loading; an engine-owned import fixes that without skipping ACLs.
Later attempts pass certificate preflight/config but stop at Compose Up. The
new closed diagnostic records phase/code/category only. Free loopback port28444
does not resolve it; the original deep-dev stack/default28443 was not stopped.
Lab teardown verified its own disposable resources/secrets cleanup. Real local
smoke or CLI success does not close this separate production TLS/echo gate.

Original46 recovery on the default-tiering final runtime FAILED/native1:
2026-10-22T05:38:44.845Z–05:39:10.724Z,24 recorded steps,0 Store resumes,
0 mailbox resumes,0 lease waits. First recipient receive/ACK refused before
issuer callback,3.257s. Compiled `AcquireRetainedMailboxReadUnderLeaseAsync`
IL1813 maps exactly to `Protected retained-read holder custody is full`:
the protected grant journal has reached its128-entry cap. This is not another
ONION timeout or evidence that the Directory correction failed.

The existing dependency-closed retirement requires an independently signed
selection epoch strictly above the original and authenticated lower time past
the original possible-issuance ceiling. Current selection epochs last seven
days. Expiry alone is not safe deletion permission. No profile, grant, counter,
unknown work or replay floor was reset/removed; no cap or signed epoch was
changed to manufacture a passing run. Original46 remains incomplete; new47 was
not authored. A/B authored their47th original commands in46; C's47th command
has not been authored. Final delivery and equal history counts are NOT claimed.

The next required change is safe sustainable acquisition retention/capacity,
including replacement headroom and original native/dependency closure, before
same-profile recovery46 and a new matched delivery round. Neither overall
speedup nor1–2s delivery/Signal parity has been achieved in this slice.

Operational comparison, seconds; different grant-acquisition work is NOT a
matched causal benchmark.42 and45 both completed40/40 with no automatic
resumes/waits or network failures.46 recovery did not complete.

| Operation |42 before|45 latest completed|Change|
|---|---:|---:|---:|
| Fanout to two recipients, mean of3 |45.220|58.911|+30.3%|
| Receive plus ACK, mean of6 |21.513|22.135|+2.9%|
| Empty mailbox poll, mean of3 |7.437|7.438|~unchanged|
| Deduplicated history read, mean of3 |1.135|0.848|-25.3%|
| Active command time, entire round |305.554|356.269|+16.6%|

Fanout ONION exchanges8→12, public proof exchanges8→8; receive/ACK ONION12→13,
public proof exchanges36→30. Less duplicated public acquisition is measured,
but grant availability and sustainable retained custody remain dominant open
operational problems. These counters do not prove a single complete latency
root cause or successful end-to-end acceleration.

Final gate ledger:

- `final-broader` native0,05:50:32.734–05:56:54.556Z: Shared93/93 PASS,
  0 skipped; genuine fixture preflight, group/control/read-scope, receive/ACK,
  historical route, input-fence and Directory cases. This supersedes the earlier
  broader focused FAIL for this case set, not an unfiltered source gate.
- `protocol-integrity01` native0,05:58:06.778–05:58:26.312Z: actual Release
  source/assembly/API graph and frozen executable-manifest integrity PASS.
  Integrity-only performed no executable witness discovery/full qualification.
- `devops-ingress-focused01` native0,06:06:05.139–06:06:05.841Z: ingress
  static security contract1/1 PASS, including v2-only private replica route.
  `devops-contracts01` contains a successful51-command release-gate SELF-TEST;
  the enclosing native exit is1 because real production-readiness status is
  blocked on10 missing release/device/ops/security/GA evidence inputs. Template
  acceptance is never real release/device acceptance.
- `multi-node-rehearsal01` native1,05:57:12.965–05:57:14.281Z: the legacy
  helper is incompatible with PowerShell5.1 (`UnixFileMode`), before Compose.
  Explicit PowerShell7 repeat `multi-node-rehearsal02` native1,
  06:02:09.170–06:05:33.728Z: disposable image build exceeded its180s limit
  downloading Ubuntu ARM64 packages; zero lab containers reached startup.
  Own-project cleanup completed; its captured redacted evidence secret scan
  passed. The helper regenerated legacy rehearsal fixture credentials; no active
  container in either local dev project mounts those files (15 inspected).
  Neither rehearsal is transport PASS or replacement for actual three-CLI E2E.

Required unfiltered/full, production-ingress, sustained/capacity and release
qualification remain open. Windows/Android apps and production were not touched.

Root logs: `artifacts/cli-main-latency-20261022/`; CLI receipts and matching
runtime/scenario archives: `artifacts/cli-main-latency-20261022/` in this repo.
No source/runtime/scenario inputs are edited during a connected round.
