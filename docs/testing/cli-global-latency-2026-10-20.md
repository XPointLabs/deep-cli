# Global message latency investigation — 2026-10-20

Scope: local retained three-node development network, native ARM64 Windows CLI
and Linux containers. No production, Windows/Android application, account/key,
volume or network-floor reset. Previous successful group round13 remains
historical evidence, not qualification of this source slice. Group round14
has NOT been started. The three profiles still have42 group messages /14 local
commands; the diagnostic direct messages do not advance that group cursor.

## Findings and implemented changes

The established group path had an explicit working public-authority scope, but
ordinary text and attachments did not use it. A single archived text Store
performed9 DirectoryProof requests and5 NetworkClosure requests. Queue alone
performed4 and2 respectively. Ratchet advancement did not require these repeated
independent network acquisitions.

Shared QueueText/RetryText and attachment queue/send now establish one explicit
command scope. Their consent, authoring, native send and transport objects use
the same source. The serial CLI supplies `EstablishedMessagingSource` for text,
attachments and groups, discarding only uncaptured reads before independent
network/contact/receive work. Actual protected account/device state, directory
and network floors, fork/clock fences, signatures and original lifetimes remain
mandatory; independent receive/ACK phases are not merged. No stale fallback,
new crypto stack, timeout extension or private-state cache was introduced.

The profile also found pure algorithmic repeated work. NETCODEC's PMT-to-view
join linearly searched the entire view chain for each projection, recomputing
canonical core hashes during the search. This was quadratic in history size.
Protocol now retains the pure digests on immutable parsed objects and indexes
policy/view lookups. Exact retained projection lookup uses a bounded artifact
index followed by exact byte equality. Public exports remain defensive copies.
Node's complete PUBLIC source read-back uses vectorized exact byte comparison;
secret, capability and MAC comparisons were not changed. All original chain,
signature, currentness, actual file and protected-floor checks remain.

See the single [execution owner](../../../docs/architecture/TRANSPORT-NEUTRAL-MESSAGING.md#32-steady-state-execution-и-стоимость-проверки).
No wire, hash preimage/domain, local schema, node identity or key was changed.
Consumers must rebuild for the established-source property rename; there is no
old-name compatibility alias. Existing refresh/maintenance/discard methods keep
their names.

## Systemic failure exposed, NOT fixed

The clean post-update run crossed a legitimate operational-view change. The
recipient refused changed source authority inside native work. A subsequent
read-only inventory found **514 native peer replay records,513 independent
protected facts, exactly1 unpaired Pending record**. No raw records, digests,
identifiers or secret values are included here.

The implementation has this gap in `CurrentMailboxReplicaReceiver.WithAdmittedPeerAsync`:

1. Protocol `VerifyAndReserve` durably creates native PRQ2 Pending.
2. `CaptureCurrentPeerFactAsync` awaits current-authority checks.
3. `RecordCurrentPeerFloorAsync` persists the independently protected fact.

A failure between1 and3 can leave native custody without its independent fact.
Later `DurableMailboxPeerReplayJournal.ValidateNativeRecovery` correctly refuses
that state. Repeating the original request does not restore the missing fact;
it returns503 and triggers the client's original35s retry-lease scheduling.
This is an atomicity/recovery defect, not a reason to weaken the refusal.

Closed diagnostics confirmed the source-change branch in `ReadNetworkAsync`
and the missing-independent-fact branch in `ValidateNativeRecovery`. Exact
compiled IL and code-owned constants were inspected; no exception payloads or
raw service logs were published. The raw read-only inventory and sampling traces
remain in private local diagnostic custody, outside repositories/artifacts.

**Next required slice:** a durable, independently authenticated pre-reservation
intent and native/protected reconciliation across authority change, cancellation
and crash. Freeze the minimal preparation/commit boundary before implementing
missing APIs. Existing unpaired state must not be imported as authority, deleted
to produce GREEN, repaired from an unsigned native file, or hidden by a reset.
An old unpaired reservation also needs an explicitly justified recovery decision;
a future-path fix alone does not prove recovery of this existing operation.

The affected local mailbox remains fail-closed. No further group send was
started after this diagnosis, avoiding another predictably incomplete round.

## Measurement ledger

All paths below are relative to this repository's `artifacts/cli-global-20261020/`.
Sampling runs are diagnostics, not latency qualification. The direct probe
queues one unique message, Stores that exact operation, then explicitly syncs
the recipient and checks exact plaintext/native tombstones and empty replay.
It is not concurrent UI-visible delivery or a sender-visible application receipt.

| Stage | Archived runtime, no profiler | New runtime, no profiler |
|---|---:|---:|
| Queue | 6.044s,4 proof requests | 1.945s,1 proof request |
| Store | 46.669s,9 proof requests,1 ONION frame | **FAIL**,65.438s including1 resume/1 lease wait |
| Receive/ACK | **FAIL**,11.972s at directory catch-up | Not reached after failed Store |

Queue was3.11× faster in these samples. **There is no successful matched
end-to-end speedup result, no1–2s delivery claim and no Signal parity claim.**
The failed/partial runs must not be averaged into a successful Store latency.

- `profile-before-01`: sender queue22.356s/Store60.065s completed, but redirected
  manual trace stop failed; no receive was run. Original message was retained.
- `profile-before-02`: sampling completed; queue6.250s/Store46.436s; receive
  processed the resulting backlog. PASS is diagnostic, not a matched one-message
  baseline. Its raw trace stays private.
- `scoped-after-01`: PASS for a direct message before the Protocol/node update;
  queue2.189s/Store46.547s/receive+ACK30.809s. Store included grant acquisition
  and2 ONION frames, unlike the later archived baseline. Not a matched comparison.
- `node-profile-before-01`: node sampling attached externally. Although the
  original receipt's `Profiled` flag is false, this run IS externally profiled
  and is explicitly excluded from clean timing. Store88.968s is not benchmark
  evidence. The probe now has an explicit external-profiling marker.
- `clean-before-01`: archived previous shipping runtime from the round13 runtime
  ZIP; queue/Store succeeded, recipient directory catch-up failed. Preserved FAIL.
- `original-receive-01`: separate native completion of that original mailbox
  item: processed1/tombstones1/hasMore=false. It overlapped image preparation,
  so its28.356s is not a clean timing sample and does not relabel the failed run.
- `clean-after-01`: new source failed Store after operational renewal; its exact
  original logical command and ciphertext remain pending.
- `original-store-01`: explicit continuation selected the sole original pending
  command, with no new queue or plaintext substitution. Still FAIL at67.351s,
  with peer503 and independent-fact refusal. No subsequent blind retries.

## Verification and deployment limits

- Shared `focused-02`:10 PASS/native0. Includes a new real signed/native queue
  case proving one own/peer pair per command, no cross-command scope leak and
  no ratchet advancement from queueing; existing floor/clock/independent-ACK checks.
  Final `focused-03`:19 PASS/native0 against the updated Protocol, additionally
  covering working authority refresh/discard/clock guards and attachment replay/
  pending selection. This is still focused evidence, not the full source gate.
- Protocol `focused-03`:205 PASS/native0. Pure hash ownership/defensive-copy
  cases, frozen contact primitives, complete closure, authority/view rollover,
  retained projection and hostile input checks. `focused-01/02` each retained
  one stale pre-GSR API-surface assertion failure. The guard now requires the
  exact accepted DR-0145/0146 closed factories and no public capability constructor,
  rather than incorrectly requiring that the implemented feature not exist.
  `graph-01`:native0, actual exact-three assembly/resource/public-API and
  production source/build/lock graph PASS. This is not a full source/package release gate.
- Node `focused-02`:82 PASS/native0, including real signed source changes,
  expiry/clock/floor and current mailbox admission. `focused-01` used a shared
  TRX filename across solution projects and overwrote earlier project results;
  it is not qualified. The corrected run targets the actual integration project.
- CLI `build-01`: Release build/native0, zero warnings/errors; `build-02`:
  Release build plus66 CLI tests PASS/native0, unique TRX prefix.
- Supported node Build and Up completed using the retained current-development
  contour. New node image:
  `sha256:35463c8324464a9959b53922369eea56081f110f1162450496ea190968294b85`.
  All nine containers later healthy; Registry/signers and the other non-node
  containers were not recreated. Nodes remain1CPU, Registry2CPU. Existing mounted
  named volumes predate this run; no data/key/floor reset was performed.
- The auxiliary `node-up-01` before/after topology assertion returned false;
  its original receipt is preserved, not accepted as unchanged-topology evidence.
  The cause of that comparison failure is not established. Later read-only checks
  confirmed the recorded post-Up mount hashes/CPU settings and healthy containers.
  Ingress `--check` also emitted read-only PEM permission warnings. These are not
  silently converted into a release acceptance claim.
- Supported readiness Verify eventually passed after21s, including two initial
  Registry-readiness refusals. Its proof/ONION smoke explicitly does not establish
  mailbox delivery; the persistent native gap above still blocks that lane.

Full source/frozen/package, sustained/scale, physical device and release gates
remain separate and OPEN. This source slice does not constitute a ready release.

Follow-up: [protected reservation and exact original recovery](cli-atomic-reservation-2026-10-20.md)
records the supported metadata repair, successful original Store/ACK, fresh text
timings and subsequent three-CLI results. This checkpoint's failures and partial
measurements are retained; its unfinished reservation is not the current verdict.
