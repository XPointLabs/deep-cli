# Anchored native directory-floor lifecycle — 2026-10-23

Scope: same three retained CLI accounts and group revision11/Active3/epoch2.
No account/key/replay-counter reset; Windows/Android, production, releases and
main branches are untouched. Original46 was already recovered in the
[acquisition lifecycle checkpoint](cli-acquisition-lifecycle-2026-10-22.md).
The immediately preceding terminal cursor is completed53, not46; see
[the exact previous runtime and measurements](cli-node-floor-read-batching-2026-10-23.md).
All timestamps below are UTC. Focused/source and connected qualification differ.

## Implementation and actual activation

[DR-0170](../../../docs/survival-program/decisions/DR-0170-anchored-directory-floor-prefix-retirement.md)
owns this lifecycle. Native owner restore/commit authenticates the complete
retained chain, finishes genuine pending successors, durably joins the exact
current tip/independent anchor/index, then retires at most64 older tips in
ascending order. Each deletion flushes before the next. Global revisions do not
reset. Read-only observations still authenticate EVERY actual retained file,
path/permissions/EOF, Data Protection (including key revocation), signed scope,
chain, anchor and index; they never repair or collect. Mailbox/acquisition replay
floors and original retained operations are not deleted or reconstructed.

The rollback boundary is unchanged: a journal-only rollback refuses; coordinated
rollback of journal AND independent anchor is outside this local store's threat
boundary, and live threshold freshness is still separate. Deliberately retired
historical tip files are no longer available from the live store. Older binaries
expecting revision-zero history need a coherent pre-upgrade journal/anchor/key-ring
snapshot. Restoring only a journal or resetting an account is not rollback.

Actual local inventory before upgrade:251 tips on EACH node. After ordinary
node-only Build/Up/Verify:1 current tip on EACH. Three nodes run image
`sha256:12d6f4c73deaf36790522d97e3cf848cb88383cf5aa733ccf12a0433b2622d1a`.
Readiness completed in12s. Named volume bindings are separately compared below;
no Init/Provision/reset or resource-limit changes were made.

## Test ledger

- Windows PowerShell5.1 / SDK10.0.301 `focused01`:75/75 PASS/native0.
- Expanded `focused02`:82/82 PASS/native0, zero skips. Actual32 signed-head
  lifecycle keeps revision31 through cold reopen; warm native acquisition is
  exactly3 Unprotect calls instead of34. An intentionally uncollected genuine
  32-record prefix still requires ALL34 reads and drains four bounded workers
  on typed failure. Its original assertions are preserved, not weakened.
- Genuine80-head history demonstrates the64-record maintenance bound and
  interrupted-prefix recovery. Tests interrupt after durable tip/anchor/index
  publication and actual prefix deletion, then cold-recover the SAME revision.
  Advanced journal-only rollback, interior gaps, renamed records, ciphertext
  damage and actual linked custody refuse. Native protection is never memoized.
- Actual Linux ARM64 `node-authority-tests`:124/124 PASS/native0, zero skips,
  including protected custody, actual symlinks and existing recipient/native
  operation guards. This is focused, not a canonical full/transport rehearsal.

## Connected measurements

The retained delivery54 uses the IDENTICAL previous CLI ReadyToRun runtime:
`18712a1e0af49f6e8b147c24b2f8146524b5d022b4e2a065b326825ee816eb45`.
Only the three local node binaries change; retained account/history work and
authority windows still differ. A cold post-upgrade round is not causal A/B or
Signal parity. Terminal receipt and complete operation timings are recorded
after completion; initial fanout is58.184s, first receive/ACK27.451s, both without
resumes. These are NOT evidence of a latency gain over completed53.

`delivery-54`: native1,21:04:19.560–21:12:57.946Z. First two fanouts58.184/60.034s
and four receive/ACK27.451/28.454/34.178/31.153s succeed. Third original fanout
fails after251.001s in `RequireOriginalNamespaceAsync` during late Store settlement.
Original A55/B55/C55 authoring is retained; C55's pending operation must be resumed,
NOT queued again. The failed receipt is not a latency PASS and remains unchanged.
A host performance snapshot also observes Defender consuming about235% CPU;
it is a confounder, not proof that antivirus explains the product defect/regression.
No protection or resource limit was disabled/raised. No application CPU trace
was collected in this round; a private compiler-only sample lacks symbols and
cannot qualify any application hot-path or performance claim.

The Store consumer still used the strict single policy/projection join despite
DR-0122's distinct issuance and logical assignment. It now calls the existing
owned dual-namespace verifier, preserving BOTH strict authenticated historical
joins, original grant/request/body/counter/native/SQL/quorum guards and current
dispatch authority. See
[DR-0171](../../../docs/survival-program/decisions/DR-0171-original-store-namespace-joins.md).
No Protocol public API or wire implementation changes are needed.

### Store verification ledger

`settlement01` is INTERRUPTED/UNQUALIFIED: its20-minute native budget includes a
long rebuild and the broad existing multi-Store fault/reopen families. The
runner stops its owned process tree; there is no terminal TRX/full PASS. Do not
count completed-but-unreported cases or classify the timeout as a proven product
failure. A separate private testhost sample has partial missing symbols; it is
neither a CLI delivery profile nor performance qualification.

`settlement02`: native0,4/4 PASS,21:37:40.878–21:42:56.042Z. Actual native
PQ/SQLCipher cases exercise ordinary/Initial/ContactAccept with a signed
same-epoch renewal, DIFFERENT issuance and assignment, expired returned reply,
exact original request, unchanged messaging floor, cold reopen and only ONE
issuer/Store call. The existing hostile metadata case also passes, including
both roles and unsupported role/missing/substituted namespace refusals.
This targeted result does not turn the interrupted broad run into PASS or
qualify canonical unfiltered/package/device/release gates.

## Full recovery54-01 is not complete

`recovery-54-01`: native1,21:48:36.371–22:08:49.570Z, two owned mailbox resumes,
zero Store resumes/lease waits. The Store namespace refusal does not recur.
Two clients pass cold original full-batch replay (256.973/239.160s); the next
post-replay empty-mailbox sync fails after226.190s, OutcomeUnknown/Cancelled in
onion entropy custody. Preserve that incomplete read and the failed receipt.
No reset, manual original reauthoring or weakened deadline is used.

A private10s sampled-thread-time trace of the first cold archive replay points
to `ReadRetainedGroupStoresAsync` → retained Store/peer-route verification →
`VerifyForOwnMessagingAsync` and repeated SQLite access. It includes blocked
threads and is NOT a CPU attribution or ordinary-send profile. That replay has
3 directory-proof calls/2 closure calls, no ONION calls,4538 native Unprotects
(19.321s cumulative protection time). It cannot explain ordinary transport
latency by itself; do not equate a completed-archive audit with new fanout.

## Pending resume / explicit qualification split

[DR-0172](../../../docs/survival-program/decisions/DR-0172-pending-group-resume-and-delivery-recovery.md)
adds a thin `ResumeGroupAsync` / `group resume` entry to the existing pending-only
producer used by ordinary send. `group flush` remains the full original receipt
audit. Actual protected completed hints only skip old work; unknown/missing/
stopped work remains eligible and all selected native/SQL/receipt/replay/current
guards remain. No message, policy, key or wire is recreated.

Explicit `-DeliveryOnly -RecoverIncompleteSteadyRound` runs pending resume on
ALL original senders, even if semantic copies already exist, then real receive/
ACK, cold histories, dedup and empty-mailbox checks. It marks only delivery
recovery; first-attempt latency/full recovery/archive/release remain false.
Existing failed full54 receipts are not reclassified. The same current state
must complete rather than starting a replacement business round.

`resume01`: native0,5/5 pending/completed/stopped/expired-hint cases, zero skips;
source compilation completes before tests. `scopes01`: native0,9/9 executable
scope guards (PowerShell7.6.5), including allowed explicit recovery reaching
the artifact boundary before bootstrap/profile access. CLI `unit02`:70/70
PASS/native0, zero skips, including closed resume selectors and unchanged
bounded host versus single-hop authority budgets. `publish02` succeeds/native0.
These do not qualify the new public resume entry without actual connected use.

### Terminal delivery recovery54-02

Native0,49/49 PASS,22:43:54.273–23:00:03.000Z. SAME profiles now each contain
165 semantic group messages/55 original local commands, Active3/epoch2. No
authored operation is recreated. Resume counts0/0/1: the final sender actually
finishes its one pending original item. The three actual resume calls take
4.667/39.762/118.805s, distinct work from a completed-history audit. Cold semantic
histories, dedup and empty mailboxes pass on all three. Two owned mailbox resumes,
zero Store resumes/lease waits, no session-close failure; all49 native commands
exit0. This is NOT no-recovery evidence.

Flags explicitly record `recoveryDeliveryQualified=true`, `recoveryQualified=false`
and `deliveryLatencyQualified=false`. Full/archive54-01 remains failed; current
delivery recovery does not waive its cancelled/unknown sync. Active commands
total906.830s, CLI CPU131.251s, scenario wall961.845s. Local history commands also
vary from ordinary1–3s to29–46s, so these observations are not causal performance
A/B or proof of a network speed gain. Protections/system settings are unchanged.

The actual published resume runtime fingerprint is
`a5efeb02857abfa126bd60b7e67e008f98c8ad160ce70bead12daf61c5a64238`;
scenario fingerprint
`4c33e9d224361d0705293351fb738375422955ffd3cf62ac2a010b03f5695475`.
Next NEW retained business round55;54 is complete for delivery and must not
be re-authored. A new delivery55 is measured separately, without the profiler.

## New55 terminal failure and comparison

`delivery-55`: native1,23:00:45.284–23:05:49.356Z. FIRST new fanout fails after
199.632s, Cancelled in `JournaledDeepSecureStorage.ReadOwnedAsync` while
`RequireExactProtectedMailboxRootAsync` rejoins protected Store custody. Zero
owned resumes/waits. The first sender's command56 has been authored; the other
two remain at55. Preserve that exact pending batch: next work is original55
recovery, NOT a replacement round55/56 or account reset. This run does not prove
first-attempt delivery or a latency improvement.

| Measurement, seconds |Last clean53 |Delivery55 |Delivery recovery54-02 |
|---|---:|---:|---:|
| New two-recipient fanout mean |51.299 (3 successes) |FAIL199.632 first command |No new commands |
| Pending-only resume |Not run |Not run |4.667 /39.762 /118.805 (0/0/1 items) |
| Receive/ACK mean |24.541 (6) |Not reached |61.255 (6, recovery work differs) |
| Empty mailbox mean |9.269 (3) |Not reached |40.609 (3) |
| Deduplicated history mean |0.785 (3) |Not reached |10.803 (3) |
| ALL active commands |350.329 |Incomplete failure |906.830 |
| CLI CPU total |168.954 |Incomplete failure |131.251 |
| Scenario wall |353.798 |298.644 |961.845 |

There is NO measured ordinary fanout/ACK acceleration in this checkpoint.
Counts251→1 native tips and34→3 test Unprotects prove bounded native floor work,
not an end-to-end speed gain. Pending resume avoids full archive verification by
performing DIFFERENT explicitly labelled work, not by making that audit faster.
Current sampled local-only commands are also highly variable; the original
storage/authority deadline and repeated local validation remain open product
availability/performance work. No security check/deadline is waived as a remedy.

Complete operation durations for the successful delivery recovery (not a new-send
latency baseline):

| Phase |Count |Mean seconds |Total seconds |
|---|---:|---:|---:|
| Cold account status |3 |1.492 |4.476 |
| Pair left contact list |3 |4.442 |13.327 |
| Pair right contact list |3 |8.303 |24.908 |
| Retained owner head |1 |0.558 |0.558 |
| Command preflight |3 |0.852 |2.555 |
| History preflight |3 |5.447 |16.340 |
| Exact active owner head |1 |0.782 |0.782 |
| Exact active recipient head |2 |0.641 |1.282 |
| Original-command counter |3 |3.560 |10.679 |
| Retained semantic copies |9 |15.491 |139.421 |
| Pending original resume |3 |54.411 |163.234 |
| Recipient receive + ACK |6 |61.255 |367.531 |
| Cold native history |3 |2.500 |7.501 |
| Empty mailbox |3 |40.609 |121.826 |
| Deduplicated history |3 |10.803 |32.410 |
| ALL active commands |49 |— |906.830 |

Final local inspection:9/9 services healthy,1 floor tip per node. All34 named
volume bindings compare identically with the pre-upgrade canonical rows:
`F11970121831199C9DA8A51A1C8E63424611D27637B504A77262E6F3DBFC30B8`.
No material mailbox/acquisition custody or replay floor was deleted. The native
owner retired obsolete authenticated PUBLIC directory-head prefix files; those
files are recoverable only from a coherent prior snapshot, not the live store.
Actual anchor/current tip/index, revisions, keys and volumes remain intact.

Canonical unfiltered/source, package, operational/transport rehearsal and
device/release qualification are NOT complete. The interrupted broad Shared
gate, full54 failure and new55 failure stay unqualified/failed. The earlier
production-ingress rehearsal/missing release evidence blockers remain open.
No Windows/Android client, production deployment, GitHub Release or main merge
was performed. This is a source checkpoint with an explicitly retained failure,
not release acceptance or completion of the overall goal.

The structural change eliminates repeated acquisition of hundreds of obsolete
native head files. It does not eliminate repeated public-closure read/clone,
native mailbox custody checks, client protected storage, network proofs or ACK.
No1–2s/full/package/device/release acceptance is claimed by this checkpoint.
