# Connected groups through two CLI clients — 2026-10-18

Decision: [DR-0143](../../../docs/survival-program/decisions/DR-0143-owned-connected-group-candidate.md).
Shared custody/ACK owner: [owned connected groups](../../../deep-client-shared/docs/architecture/owned-connected-groups.md).
This is the two-account/one-device-per-account connected candidate, not full
S11, GSR1 retention, large fanout, device or release qualification.

## Implemented path

CLI delegates create/invite/accept/advance/send/flush/list/history to Shared.
The owner captures exact typed group events and original operations/common
sender positions in protected custody before native encryption or dispatch.
Complete GCP1 packages travel as authenticated GCF1 fragments through the
existing E2EE/replicated ordinary mailbox, not JSON text or a second transport.
Invitation acceptance alone is not membership: the owner publishes activation.
Receive/native materialization precedes durable tombstone ACK. Histories join
actual native rows, not a caller record or SQL processed bit.

The candidate requires group registration1, ordinary journal9 and application
SQL17. New isolated group profiles preserve the prior text/file profiles and
their receipts; no device or production account was reset/deployed.

## Real local network evidence

`artifacts/cli-owned-groups-20261018/e2e-06/receipt.json`:
PASS, parent native0,35 separate CLI processes, real TLS/Registry/three XNodes,
existing native crypto and SQLCipher, same retained pair throughout retries.

Observed create -> GCP1/invitation Store -> receive/ACK -> explicit consent Store
-> owner receive/ACK -> activation Store -> invitee receive/ACK -> both Active
-> text each direction -> cold native histories (one own/one remote each) ->
exact original batch replay -> empty mailbox and no duplicate histories.
The run includes a cancelled first activation ACK and one successful exact
cold retry; that failed step remains in the receipt. It is not reported as35
individually successful first attempts. Runtime SHA256:
`3a796c9a1b08b38818da695712c775182f6ae8555e8ea21d1369c39dbc36ade6`.

The final ACK batching correction was qualified separately on a new group
using the same retained pair; the earlier runtime hash is not evidence for
the later assembly. `-GroupRevision` explicitly creates/selects a distinct
synthetic QA group only after the previous cycle completed; it is not a retry,
protocol version or permission to evade unknown work. Retry the same revision
to preserve its original pending operations. Selection is by unique name then
exact ID, never array position; both activated heads must match that ID.

## Defects found and preserved receipts

- `e2e-01`: fresh publication time-coverage rejection; no time/TLS weakening.
- `e2e-02`: retryable ingress rejection before forwarding; accounts retained.
- `e2e-03`: scenario source changed during child; input fence rejected the run.
  Harness failure, not product success; no restoration/reclassification.
- `e2e-04`: retained-Store probe wrongly selected a prepared, not-yet-native
  group command. Fix: independently read actual native custody before that
  scheduling probe. Adopted plaintext is not a native send or Store proof.
- `e2e-05`: uncertain ingress response, original page/work retained. The driver
  eligibility predicate also needed explicit PowerShell logical parentheses.
- `e2e-06`: complete recovered cycle. Activation ACK exposed redundant cold
  receiver/session/group-root reconstruction per fragment. The subsequent
  correction reuses actual snapshots only under the same held lease and keeps
  per-operation native checks, final floors/freshness/exact-root readback and
  unchanged transport deadlines. It is not a current-proof cache across calls.
- `e2e-07`: new final-binary group created/invited/accepted/activated and both
  messages stored. Store/activation transport uncertainty recovered using exact
  operations; the last reverse poll stopped on uncertainty then the adapter's
  still-active retry lease. No work/reset/new message was substituted.
  Local node restarts exposed the separate missing sealed Onion-boundary catch
  in the Store recovery worker; see the [node checkpoint](../../../xnode/docs/testing/cli-group-store-worker-2026-10-18.md).
- `e2e-08`: after the supported same-key/same-mount node update, resumed the
  **same final group/revision1**, not another group. PASS/native0,34 cold CLI
  processes, zero failed steps. It consumed the pending reverse message and
  independently requalified both exact group heads, all original Store outcomes,
  receive/ACK, two cold histories, full batch replay, empty mailbox and no
  duplicate messages. This is a retained-group continuation; new creation and
  earlier control sends are recorded in07, not falsely repeated in08.

Final runtime SHA256:
`9dc82b69ade30c89d8f94afc0bcccfcbddfeea5434e218073a63819cf690258b`.
Final scenario SHA256:
`0634ecf39bd602d07fa40ce6e396e3c8fd7d8410836d062afb7dad57d8a6a1d4`.
Receipt: `artifacts/cli-owned-groups-20261018/e2e-08/receipt.json`.
All three updated local nodes were healthy with restart count0 at the final
observation; that bounded observation is not sustained availability acceptance.

The driver pins its own source and full runtime tree before/after each child;
selectors and plaintext remain in memory. Receipts contain closed phases,
counts/times and hashes only. `send` is new logical work; uncertain sends resume
through `flush`, never automatic re-queue. There is at most one exact retry for
eligible idempotent commands, never account creation or new group text.

## Source receipts

- Protocol `artifacts/cli-owned-groups-20261018/focused-01`:25 PASS/0skip/native0.
- Protocol `graph-04`: normal Release/Debug build and exact-three actual API/
  assembly/resource graph PASS/native0, zero build warnings/errors.
- Protocol `registry-01`: strict registry PASS/native0.
- Shared `focused-03`:83 PASS/0skip/native0, including real owned/native group
  cycle, cold history/replay, changed-byte and premature-send refusal.
- Shared `ack-batch-01`:11 PASS/0skip/native0 (lost ACK, publication promotion,
  expired read/Initial custody, route/Braid and native group regressions).
- CLI `unit-02`:39 PASS/0skip/native0; final normal CLI `build-07`: zero warnings/
  errors. Matching final-source and fresh-group receipts are recorded below
  after completion, not inferred from earlier snapshots.

Final-source `Shared/artifacts/cli-owned-groups-20261018/final-focused-01`:
93 PASS/0skip/native0, zero compiler warnings/errors. It combines group/ordinary
custody, mandatory account registration, real native group lifecycle, hostile
send/replay, lost-ACK/publication/expiry/route/Braid regressions. CLI `unit-03`
also completed39 PASS/0skip/native0 against the final normal output.

These are focused/source and connected business observations, not a canonical
unfiltered full/package or sustained profile acceptance. Full S11 membership/
device/rekey/history/fork recovery, GSR1 retention, larger fanout and complete
release qualification remain open. Windows/Android were not built or used.
