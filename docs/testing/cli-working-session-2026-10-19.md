# Working-session latency checkpoint

Owner: Mr. X. Local real TLS/Registry/three XNode and Windows-hosted CLI only.
No physical Windows/Android UI or production deployment is claimed.

## Implemented slice

One CLI host retains the actual exclusive profile and Shared public composition
between serial commands, with bounded private-stdio frames and per-command
cancellation. EOF disposes the host. Ordinary failures never trigger a business
retry. Established groups reuse a public working scope, not private keys,
ratchet state or owner loans. Idle maintenance is separately serialized, bounded
and fail-closed. Normative lifetime/refresh rules belong to
[the authority owner](../../../docs/architecture/ACCOUNT-DIRECTORY-TRANSPARENCY-V1.md#working-public-authority-and-delivery).

XNode retains an exact immutable verified network context beyond the old10s
resource threshold only while its original capability and all actual
source/floor/time/issuer checks still hold. No signed lifetime, HTTP deadline,
wire format, crypto provider, profile, key or account reset changed.

## Evidence to date

All paths below are repository-local artifacts under `cli-session-20261019`.

- CLI `build-01`/`unit-01`:55 PASS; initial persistent host only.
- Shared `shared-01`: compiler failure, internal Protocol interface was not
  accessible; fixed by using the actual source clock, without exporting that
  interface or changing Protocol API.
- Shared `shared-02`:14 PASS; working scope and existing command-scope controls.
- Shared `shared-03`:18 PASS; additionally retained grant/result adversarial
  controls and bounded rejection reason. No expired/fork/rollback waiver.
- Node `node-01/integration`:29 PASS/1 FAIL; new expiry test expected the wrong
  exception type. Actual rejection was the existing exact issuer-time check.
- Node `node-02/integration`:30 PASS; expiry asserts that exact rejection and
  unchanged protected floor, alongside existing source/fork/rollback/cancel tests.
- CLI `build-02`/`unit-02`:59 PASS, zero warnings/errors. Includes real profile
  lease exclusion/release, actual serial stdio host, malformed/oversized/truncated
  frames, cancellation, binding switches and closed grant diagnostics.

`recovery-01` used the initial persistent host against unchanged image15, not
the later authority memo/node candidate.36 commands/561.687 summed CLI seconds;
FAIL, one mailbox exact retry and then Bob's retained-grant validation rejection.
All three native group heads reached the same Active/three-member state. Alice's
fanout84.004s and its two recipient receive+ACK49.261s/66.454s passed. These are
different retained histories from the older113.358s/84.776s baseline; they do not
prove an isolated code-speedup percentage or a full round PASS.

`diagnostic-01` then cold-reopened the same profiles and flushed Bob's original
batch successfully:111.254s, no replacement group/message/account. The preceding
grant rejection did not reproduce; its precise predicate is still unproven.
Closed finite grant rejection labels were added for future evidence; no raw
exception text, keys, IDs or payloads are exported by them.

Node build/up `node-build-01`/`node-up-01` both native0. All three nodes use
`sha256:3698fc7e9ae309f7cd86ad154237a67ea37904bfa836b21a1495c65061ac6ab4`,
healthy, with the original one-CPU quotas and retained custody/mounts.
The matching session/group runtime is being exercised by `recovery-02`.
`recovery-02` **PASS**:49 commands, zero command failures/retries,553.613 summed
CLI seconds. Actual native histories contain all three original messages at
each member, with one local author command each. Both recipients ACKed Carol's
new fanout. Cold full-batch replays, deduplicated histories, empty mailboxes and
empty GSR cursors all passed. Its new fanout101.014s is not a new three-sender
latency baseline: Alice/Bob batches were already staged in earlier receipts.

Final source hardening rejects clock rollback before replacement acquisition
and discards a failed refresh memo, not its monotonic fence. `shared-04`:18 PASS;
`build-03`/`unit-03`:59 PASS/zero warnings/errors; `node-03/integration`:30 PASS.

## Same-profile cold versus working control

`control-01` **PASS**,18 commands/184.217 summed seconds, one attempt per command,
same three profiles, exact same active native group/epoch and zero new messages.
Every control result remained empty. This measures retained owner publication
and member GSR cursor verification, **not message send/receive latency**.

| Actor / operation | Cold process, s | Separate refresh, s | First working call, s | Next working call, s | Next-call reduction |
| --- | ---: | ---: | ---: | ---: | ---: |
| Owner / retained publication |18.646|17.273|5.940|0.243|98.7%|
| Member B / GSR cursor |25.003|15.604|13.849|8.543|65.8%|
| Member C / GSR cursor |25.009|8.754|17.965|13.013|48.0%|

Refresh is shown separately, not hidden: including refresh plus both working
calls gives23.456/37.996/39.732s, versus37.292/50.006/50.018s for twice the
observed cold-call durations. The latter is a simple arithmetic comparison,
not two independently measured cold repetitions. No universal percentile or
competitor parity follows from this small sequential experiment.

The second working call required **zero DirectoryProof/NetworkClosure HTTP
requests** for every actor. Member B/C still made their real ONION query,217/241ms,
while CLI CPU remained8.141/12.109s. Thus substantial local verification cost
remains; this slice does not establish instant messages or superiority to Signal.

## New message round: first-attempt gate still FAIL

`steady-01` starts from the exact three-message histories and sends a genuinely
new second message from every actor.31 commands/656.670 summed CLI seconds;
all three fanouts passed on their first CLI attempt, but the final recipient ACK
failed. No driver retry, account reset or replacement message was used.

| New fanout | Whole command, s | CLI CPU, s | ONION sum, s |
| --- | ---: | ---: | ---: |
| A |97.560|32.406|49.648|
| B |83.001|38.391|38.258|
| C |121.070|69.641|38.294|

These are not instant-message timings. C's growing local CPU cost is a remaining
profiling target; these observations alone do not identify the exact hot method.
The current server failure is the same native `VerifyDtt` binding branch seen
before this session change (node1, caller IL168). Which binding predicate failed
has not been proved. No mismatched view/policy, expired proof or changed floor
was accepted to finish the operation.

`recovery-03` explicitly reopened the same saved Bob ACK and passed in36.503s,
one event/one durable tombstone, without a replacement intent. This does **not**
turn `steady-01` into PASS. The original failing ACK took46.467s; investigation
time between commands is not included in either active-CLI duration.

All operation families from the failed strict run (summed active CLI time;
min/max include the failed call where present):

| Operation | Calls | Failures | Min–max, s | Sum, s |
| --- | ---: | ---: | ---: | ---: |
| Account status |3|0|0.492–0.558|1.565|
| Left contact-list preflight |3|0|0.598–5.474|6.807|
| Right contact-list preflight |3|0|4.783–10.127|24.380|
| Retained owner group head |1|0|0.253|0.253|
| Native command preflight |3|0|0.222–0.298|0.765|
| Native history preflight |3|0|0.460–4.953|7.999|
| Exact active owner head |1|0|0.287|0.287|
| Exact active member heads |2|0|0.231–0.243|0.474|
| Sender command count |3|0|0.209–0.303|0.740|
| New two-recipient fanout |3|0|83.001–121.070|301.631|
| Receive + durable ACK |6|1|42.089–67.213|311.769|

`recovery-04` **PASS**:15 cold commands/140.265 summed CLI seconds. All three
native histories contain exactly six messages, two local commands and exactly
one copy of each sender's sequence1/2 text. All three mailboxes and both member
GSR cursors are empty; the owner's retained control receipt makes no progress.
No replacement message or account was created. No fresh lifecycle
first-attempt, release, package, retention, scale or device acceptance follows
from recovery/control results. Historical failures remain retained.

## Next bounded investigation

Do not start another fresh account/group lifecycle to hide the retained failure.
These profiles now have six exact messages/two local commands each; a future
new strict round starts with `SteadyStateRound=2`, after fixing the native DTT
coherence failure. Preserve the failed first-attempt receipt.

Profile local CPU before choosing another crypto implementation. One concrete
inspection target is `BusinessCommands` resolving a single conversation through
`ListConversationsAsync`, while group action/flush also enumerate conversations.
The measured cold contact lists and working member control both consume several
CPU seconds. This is a candidate repeated-work path, not yet a proved complete
CPU attribution or an implemented selected-conversation optimization. No new
crypto suite or private-key/plaintext cache was added to this slice.
