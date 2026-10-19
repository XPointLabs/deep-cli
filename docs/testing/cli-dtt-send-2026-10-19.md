# CLI send / DTT admission slice — 2026-10-19

This is the retained checkpoint before the subsequent
[message latency round](cli-message-latency-2026-10-19.md). Its handoff cursor and
timings below are historical; the linked result is the current continuation.

Owner: Mr. X. Local `deep-dev-current`, retained three CLI profiles and group
`GSR CLI QA 11`. No MAUI/Android, production deployment, account reset or new
cryptographic stack. Previous [working-session evidence](cli-working-session-2026-10-19.md)
and its strict `steady-01` FAIL remain unchanged.

## Changes and security boundary

Shared selects one conversation from the actual protected catalog before opening
its session. Account/root, selected peer/native/acceptance custody and final catalog
read-back remain checked. Unknown identifiers do not open unrelated sessions;
selected missing custody still rejects. Group candidate selection filters by the
protected group members. Flush enumerates protected catalog handles for scheduling
only; every nonempty batch independently verifies its exact native events, consent,
current authority and original Store evidence. No successful private-storage read,
private key or plaintext cache was introduced; account-operation serialization remains.

Node observers detect changed exact public closure bytes before mixing them with
an older observation. The initial mailbox admission may invoke the existing
acquisition owner once, before effects, to verify/join the new complete closure and
nonce-bound proof. Later effect fences cannot refresh, advance or redispatch.
Missing observation, invalid input, expiry, rollback and floor changes remain denials.
Captured ACK/grant/request bytes and deadlines are unchanged. See the single
[normative authority owner](../../../docs/architecture/ACCOUNT-DIRECTORY-TRANSPARENCY-V1.md#working-public-authority-and-delivery).

The old failure's exact `VerifyDtt` OR predicate was not recorded. It must not be
retroactively claimed as proved. The unchanged protocol rejection now carries only
a finite binding-check label, and Node logging exports only that allowlist, never
proof values or arbitrary exception data.

## Verification ledger

Artifacts below are relative to each repository's `artifacts/cli-session-20261019`.

- Node `node-04`: native exit1, 59 PASS / 4 FAIL. Two new successor fixtures reused
  old traffic keys (correctly rejected); two old counter assertions expected an
  issuer decode that changed-source denial now intentionally precedes.
- Node `node-05`: native exit1, 62 PASS / 1 FAIL. The new positive fixture omitted
  the complete signed predecessor prefix; production verification correctly rejected it.
- Node `node-06`: native exit0, 63 PASS. Actual signed successor and actual protected
  floor prove pre-effect join versus in-effect denial; invalid issuer cannot promote
  a floor or become a missing-observation fallback. Existing expiry/rollback/source/
  floor/cancellation/admission controls remain included.
- Shared `shared-05`: native exit0, 31 PASS, including actual publication / retained
  receive / semantic fault / lost ACK / next empty poll, working group boundaries,
  selected local history custody and coherent acquisition controls.
- Node `node-07`: build exit1 because a diagnostic test attempted to construct an
  internal protocol exception. The test now obtains the actual DTT/view rejection
  from real signed mismatched inputs instead of constructing a protocol capability.
- Node `node-08`: native exit0, 70 PASS, including all finite diagnostic labels and
  rejection of arbitrary exception data. The real signed mismatch reports `ViewCore`.
- Shared `shared-06`: native exit0, one focused real signed stale-closure control
  also asserts the protocol's exact finite `ViewCore` label.
- CLI `build-04`: native exit0, zero warnings/errors; `unit-04`: native exit0,
  59 PASS. These consume the current Shared/Protocol source composition.
- Supported DevOps `node-build-02` / `node-up-02`: native exit0. All three nodes
  run image `sha256:cdec1a20cedde799247999c1d05f987c0b24f05cdbe519f5b88c8bae5e36cbf1`
  with the original nine mounts and 1 CPU per node; no custody/key/volume reset.

`steady-02`: FAIL, 21 commands, max attempt1. A's new fanout stopped in76.700s
at mailbox-grant acquisition (`OutcomeUnknown`, deepest recorded server cause
`HttpContactReplicaPeerClient.SendAsync`). This was not a recorded DTT rejection.
The exact HTTP/peer failure was not proved; do not rename it a timeout or claim
that a specific HTTP status was fixed. The original third semantic command remains
retained. `recovery-05`: PASS, four cold commands; exact `group flush`60.092s,
no replacement group message. This does not turn `steady-02` into PASS.

Node `node-09`:70 PASS; added bounded endpoint diagnostics and closed replica
HTTP-envelope metadata without exporting bodies/headers/addresses/exception text.
The original peer failure did not reproduce in `recovery-05`.

The production receive-binding owner now polls actual custody instead of forcing
a new directory proof every ten seconds. Every ingress/poll checks the actual
source/floors/history/clock/issuer and installed handle, plus the retained context's
original live lease. Fresh independent acquisition occurs when due within30s of
the proof/signed closure bound, after changed source/view, or at a conservative
two-minute resource cap. Failed observations/acquisition grant no stale fallback;
effect checks cannot refresh. No signed validity or request timeout was increased.

- Node `node-10` and final `node-11`:117 PASS each, native exit0. Real signed
  source/floor/clock/expiry controls plus receive polling/no-extra-proof acquisition,
  due refresh, failed observation and stop/cancellation lifecycle controls.
- Supported `node-build-04` / `node-up-04`: native exit0. Final image
  `sha256:75c1994a69c4fa17740943c326c6bef1281048cd8a4c65e3c75864445ac719e0`,
  all three healthy, still nine original mounts and1 CPU per node.

At this intermediate checkpoint the further strict results were pending; final
results are recorded below, without changing these earlier receipts.
No release or full/package/device qualification is claimed by focused results.

## In-effect source change and owned continuation

`recovery-06`: PASS,23 cold commands. Round3 completed with nine exact messages /
three local commands at every profile and empty mailboxes. A's original command
was flushed, not recreated; B/C's previously unattempted commands were created once.

`steady-03`: FAIL,25 commands, driver attempt1. A fanout85.023s PASS; its two
receive/ACK calls56.678/52.856s PASS. B Store failed in75.241s. Actual image19
portable symbols map `ReadNetworkAsync` IL1268 to source line444: the explicit
changed-public-source denial, not a proved timeout. The in-effect check was
correct and remains mandatory. This exposes the missing **business continuation**
above a single attempt, rather than permission to admit mixed old/new authority.

[DR-0153](../../../docs/survival-program/decisions/DR-0153-owned-mailbox-automatic-continuation.md)
adds one bounded owned continuation after typed unknown. It reopens the same
operation/page through existing reconciliation and protected owners, discarding
only uncaptured memo state. No queue/group action is rerun. Live attempts stay
exact; existing authenticated retirement/succession rules remain owner-only.
One35s scheduling wait may be needed for a still-active retry lease; no time,
signature, route, counter or expiry check is waived. Repeated unknown/denial or
cancellation stops. CLI `recoveryWork` and receipts distinguish Store/mailbox
resumes and lease waits from driver attempts. Driver-attempt1 is not wire-attempt1.

- Shared `shared-07`: build exit1; the production source allowlist omitted the new
  recovery files. Explicit project entries were added, not broad compile globs.
- Shared `shared-08`: test build exit1; new tests referenced a private fixture
  helper and nonexistent result flags. Assertions now use actual owned result /
  protected counter facts; only the disposable fixture helper visibility changed.
- Shared `shared-09`:10 PASS, including actual encrypted/native lost-Store and
  lost-ACK continuation. Original request/counter, no duplicate native semantic
  event, durable tombstone and read-back invariants remain checked.
- Shared `shared-10`:21 PASS, group working/read-scope security regressions plus
  bounded recovery policy tests. `shared-11`:10 PASS, final scheduling/denial /
  cancellation policy tests. These are focused evidence, not a full-suite claim.
- CLI final `build-05`: exit0, zero warnings/errors; `unit-05`:59 PASS.

The failed strict receipts are retained and must never be overwritten or labelled
successful because of later continuation.

## Final three-CLI result

`recovery-07`: PASS,21 cold commands. The retained B round4 command was flushed,
not recreated; C's previously unattempted command was created once. All profiles
had twelve exact messages / four local commands and empty mailboxes. This included
one **live automatic ACK continuation**, zero lease waits, with its failed ONION
response still counted in network metrics. Transport copies were ACKed individually;
native/application semantic history remained deduplicated. It is recovery evidence,
not a repair of `steady-03`'s original FAIL.

`steady-04`: **PASS**,46 commands, every CLI/driver attempt1, zero failed commands,
zero automatic Store/mailbox resumes, zero lease waits, clean host shutdown.
Starts at twelve messages / four local commands and ends at **fifteen exact messages /
five local commands at each of three clients**, same active three-member epoch2 group.
All three senders reach both peers; all six receive/ACK operations commit durable
tombstones. Cold original-batch replay, empty mailboxes, semantic dedup and both
empty GSR cursors pass. Runtime fingerprint:
`a62d8ec990e4c37a47b4d691a9ea0ed7abd89890446dac9ef779feaa7a4b358d`.
Summed active CLI time761.626s; this is not a comparable full-run speedup against
the earlier incomplete FAIL.

### Message-path timings

Same retained profiles/group and unchanged1 CPU per node. The earlier receipt
had fewer historical messages and different grant-renewal state, so this is an
operational comparison, not an isolated/statistically qualified code benchmark.
Intermediate failures, control work and preparation are not subtracted.

| Sender / operation | Earlier `steady-01`, s | Final `steady-04`, s | Observation |
| --- | ---: | ---: | --- |
| A → two peers fanout |97.560|96.518|1.1% shorter|
| B → two peers fanout |83.001|94.030|13.3% longer in this run|
| C → two peers fanout |121.070|96.627|20.2% shorter|
| All three fanouts, sum |301.631|287.175|4.8% shorter, not uniform|
| A → B receive / ACK |55.073|52.608|PASS|
| A → C receive / ACK |67.213|57.366|PASS|
| B → A receive / ACK |42.089|50.533|PASS; longer|
| B → C receive / ACK |48.071|51.982|PASS; longer|
| C → A receive / ACK |52.856|41.670|PASS|
| C → B receive / ACK |46.467 FAIL|42.956 PASS|No speedup ratio against failure|

The five matched previously successful ACK pairs sum265.302→254.159s (4.2%
shorter). Actual sending/ACK latency is still tens of seconds; neither instant
delivery nor Signal parity is claimed.

### All operation families in the final strict round

| Operation | Calls | Failures | Min–max, s | Sum, s |
| --- | ---: | ---: | ---: | ---: |
| Account status |3|0|0.540–0.602|1.739|
| Left contact-list preflight |3|0|0.642–4.549|5.925|
| Right contact-list preflight |3|0|4.214–9.768|23.399|
| Retained owner group head |1|0|0.347|0.347|
| Native command preflight |3|0|0.253–0.278|0.799|
| Native history preflight |3|0|0.757–4.972|8.694|
| Exact active owner head |1|0|0.278|0.278|
| Exact active member heads |2|0|0.238–0.243|0.481|
| Sender command count |3|0|0.212–0.295|0.767|
| Two-recipient message fanout |3|0|94.030–96.627|287.175|
| Receive + durable ACK |6|0|41.670–57.366|297.115|
| Cold native history |3|0|0.897–3.496|6.614|
| Cold original-batch replay |3|0|20.024–36.877|81.491|
| Post-replay empty mailbox |3|0|9.732–14.270|33.793|
| Post-replay deduplicated history |3|0|0.432–3.065|5.291|
| Owner control receipt |1|0|0.285|0.285|
| Empty member GSR cursors |2|0|3.601–3.832|7.433|

### Isolated unchanged-history read comparison

`selection-01`: PASS, six commands: two pair-selection prerequisites plus four
offline `message list` calls on the same B→A conversation, in **old/new/new/old**
order. The old executable is extracted from the earlier archived current-protocol
runtime; both old and current full-file fingerprints are checked against their
original receipts before/after execution. No source compatibility code is restored,
no account/history reset and no new message is created. Returned native item arrays
match exactly. The archived measurement script and hashes are retained with receipt.

| Selection + message read | Old, s | New, s |
| --- | ---: | ---: |
| Cold process1 |5.035|3.264|
| Cold process2 |5.096|3.236|
| Mean |5.066|3.250|

Mean wall time is35.8% shorter; mean CPU5.165→3.352s. This establishes reduced
selection/read overhead, which is shared with send, **not** a35.8% full-message
delivery speedup. The actual fanout and ACK durations above remain authoritative.

## Handoff / open limits

All current profiles remain intact: fifteen group messages / five local commands
each, no pending fanout/ACK, empty GSR cursors. A new semantic steady round starts
with `SteadyStateRound=5`, never by replaying a failed run as first-attempt.
Next latency work should profile the six directory-proof / three-to-four closure
reads per ACK and repeated full native SQL tip verification in historical batch
reads, while retaining actual floors, snapshots and every effect fence. No extra
crypto stack, private-key/plaintext cache or larger timeout is justified by this slice.
Full source/package/retention/scale/device/release gates remain open. No MAUI,
Android or production deployment/release publication was performed.
