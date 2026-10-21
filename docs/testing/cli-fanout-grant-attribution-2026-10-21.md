# Fanout ONION grant attribution — 2026-10-21

Continues the [retained native audit](cli-retained-native-grammar-audit-2026-10-21.md).
Same three CLI accounts/group and local network. No reset, rekey, device client
or production change. Required fresh authority is not removed to reduce a count.

## Why full30 had twice the requests

The CLI endpoint metric combines every `/api/ingress/v1/frame` request into
`OnionFrame`; by itself it cannot identify the inner operation. Source tracing
found no implicit route-update or Retrieve in ordinary group send. Captured
Store resumes and HTTP failures were zero. Group membership/head were unchanged.

A bounded read-only query of the existing local issuer journal decoded445
successful XMC2 responses using the SAME shipping Protocol codec. No raw request,
response, holder, key, capability, identifier or database credential was emitted
or committed. Database state was not changed and issuer records were not treated
as new client authority. Successful issuer HTTP calls were not present in the
warning-only service logs, so absence of log lines was not evidence of no work.

| Recorded run | Fanout ONION requests | Newly issued Deposit grants |
| --- | ---: | ---: |
| delivery28 | 6 | 0 |
| full30 | 12 | 6 |

Exactly two Deposit acquisitions occurred during each full30 sender command:
each recipient needed XMG2 acquisition followed by its Store. For EVERY new grant,
all pre-run grants for its exact route/placement/membership were already expired.
The latest prior expiry was1107s BEFORE full30 started. Replacements advanced
that expiry by3313s. Comparing a later issuance with another issuance from THIS
same run would wrongly mix different senders' independent holders: those must
not share private holder custody or replay counters.

Thus these six acquisitions were necessary, not duplicate Store, accidental
route refresh or demonstrated grant-cache failure. Existing native winner reuse
already skips issuer dispatch while the selected grant remains usable. The
40.648→54.749s fanout comparison did not isolate equivalent authority lifecycle
conditions; it must not justify accepting an expired grant or extending a window.

## Separate unnecessary proactive renewal

The new-work selector already avoids replacing a live Deposit winner at its
signed route ceiling. The actual issuance ceiling ALSO includes the current
verified operational network and PMA expiry. Ignoring these ceilings can issue
a different holder with no later expiry even while the old grant remains live.
This source defect is separate from full30's genuinely expired grants.

The bounded optimization suppresses only a non-pending, still-live Deposit
renewal whose expiry EQUALS the minimum of the original exact route's five
signed ceilings, the independently current network ceiling and current PMA
expiry. A tightened ceiling below the old grant does not suppress replacement.
Suppression additionally requires that the canonical old grant still fits the
CURRENT verified PMA issuer, generation floor, issuer window, maximum lifetime,
network and Active lifecycle. Policy rotation can require a useful same-expiry
replacement; that renewal is not suppressed. This predicate is scheduling only,
not a second signature verifier or authority cache.
The old grant's start+maximum-lifetime is not a fixed ceiling: a genuinely new
start can extend it. Pending successors retain their exact request; expired
grants and Retrieve scheduling keep their existing behavior. Complete protected
root reads, callback/currentness and actual winner verification/installation
remain required. No lifetime, policy, crypto, wire or native quota is increased.

## Focused qualification

Windows PowerShell5.1.26100.9457 / SDK10.0.301: focused02 passed30/30, zero
skipped, native0. Seven new scheduling rows cover live exact ceiling, expiry,
tightened/movable ceiling and unchanged Retrieve behavior. A new real signed
successor fixture caps network/PMA below the old route, advances into the actual
proactive margin, and cold-opens twice: EXACT old XMG2/XMC2 and the ENTIRE
encrypted protected grant journal remain unchanged, with zero issuer calls.
All four useful Deposit renewal fault cases and eight independent Retrieve
renewal cases also pass. This is not a full/package/device/release gate.

The first run compiled but had25 PASS /5 FAIL. Four renewal fault fixtures did
not establish a useful later grant under the new ceiling rule; they now use a
genuine role-signed200s first grant and real signed successor, explicitly proving
room under the route/network/PMA and a STRICTLY later renewed expiry. Original
lost-response/selection/SQL-interruption, old bytes and exact retry assertions
remain. No prior-baseline PASS is claimed for those unmodified fixtures.
The new cap fixture originally left too little room for its30s signed proof
window; its actual signed cap is now1400 instead of1200, still BELOW the old
route ceiling. No verifier, signature or freshness assertion was relaxed.

CLI67/67 PASS, zero skipped/native0; shipping build native0,0 warnings/errors.
Six driver scope checks PASS/native0 in PowerShell7.6.5. The driver ordinal
range is now0–63 to retain the SAME accounts beyond31; it changes no runtime
journal bound, quota or signed lifetime. Default full qualification still
requires all46 checks; delivery-only cannot qualify the full lane.

Final guarded source `58de8c1` + `997b106`: focused04 passed42/42, zero skipped,
native0 (10:59:06.459–11:00:41.044 UTC), including six expired-acquisition
regressions and six additional current signed-policy eligibility cases. Issuer
rotation, raised generation floor, later issuer window, shorter maximum lifetime
and non-Active lifecycle retain renewal; unchanged policy remains eligible.
These six are component scheduling tests with actual issued grants and genuine
root-signed policy variants, not installed PMT rollover E2E. Focused03 originally
passed38/42: four changed-policy fixtures omitted the generation successor's
predecessor hash and correctly failed `InvalidGenesisPredecessor`. The fixture
now signs its actual predecessor; no generation/verifier check was removed.
Original failed receipts remain unchanged. Final CLI67/67 PASS/native0,
build0 warnings/errors/native0, scope6 PASS/native0, completed11:01:11.774 UTC.

Local evidence roots (not committed):

- Shared `artifacts/cli-fanout-grant-20261021/focused04/results/focused.trx`
- CLI `artifacts/cli-fanout-grant-20261021/cli-final/results/cli.trx`
- CLI `artifacts/cli-fanout-grant-20261021/delivery-31/receipt.json`
- CLI `artifacts/cli-fanout-grant-20261021/steady-32/receipt.json`
- CLI `artifacts/cli-fanout-grant-20261021/recover-32/receipt.json`
- CLI `artifacts/cli-fanout-grant-20261021/steady-33/receipt.json`
- CLI `artifacts/cli-fanout-grant-20261021/recover-33/receipt.json`
- Superproject `artifacts/cli-fanout-grant-20261021/` captured native logs/exits.

## Retained delivery31

Delivery31 passed40/40, native0, with no Store/mailbox resumes, lease waits,
manual/driver retries, HTTP non-success or session-close failure. It used the
candidate before the policy-rotation guard; the final guarded runtime is a
separate qualification. Same accounts,96 messages /32 original local commands
per account, Active3/epoch2; no reset/rekey. Wall427.320s, active419.971s,
CPU155.422s. Fanout66.604/59.187/61.671s, four ONION requests each; six
receive/ACK33.297/33.763/31.686/27.649/29.108/29.040s, three requests each.

The exact issuer-journal window10:47:58.605–10:55:05.925 UTC contains12 newly
issued grants:6 Deposit and6 Retrieve (also12 in the expanded ±10s window).
Their lifetimes2961–3296s explain the additional requests in both directions;
this run does not show a warm-authority performance gain. Successful decodes457
at this checkpoint. All pre-run SAME-scope grants were expired by their
respective new acquisition. The latest prior Deposit expiry was runStart+6s
(first replacement at+49s); latest prior Retrieve expiry was runStart−129s.
They were not all expired at run start. Final full measurements follow separately.

Delivery31 runtime fingerprint:
`a96ee871298f8e3ad9399ac241bd59ad91870117ef6f79c74ba65b6e6c43c1a6`.
Scenario fingerprint:
`9ede8a2d2726c896b64d70c2172792435515fd26e85dfb8dce4aa77627358823`.

## Original strict full32 refusal (preserved)

The guarded runtime's first strict full32 run failed at command23. Its first
fanout completed in30.331s with2 ONION requests, and the first recipient's
receive/ACK completed in20.098s with2 requests. The next recipient's mailbox
sync refused after0.545s, before any ONION request: both DirectoryProof and
DirectoryHistory returned non-success. Closed cause: `IoFailure` in
`DeepIdV2DirectoryProofClient.CatchupAsync`. No Store/mailbox resume, lease wait,
driver retry or session-close failure. This is NOT full/first-attempt PASS.
Start11:01:35.666, finish11:02:40.928 UTC; active62.864s / CPU30.110s.
The pending original round must complete through its explicit recovery lane,
not a reset, replacement command or overwrite of this failed receipt.

Read-only Registry diagnostics attributed this window to four authenticated
NTS acquisition `CryptographicException/observation-quorum` failures and one
proof plus one history `ContactResolveDirectoryPackageUnavailableException`.
No policy-scope/interval-conflict/floor-rollback/authority-policy reason appeared.
Existing TLS-validated `/health/did2/ready` healthcheck recovered by11:05:25 UTC;
no NTS/source/time/TTL/configuration was changed. This is a real residual
authority-availability failure, not a successful first attempt or ignored check.

Guarded runtime fingerprint:
`4d12bae780a2f38a6a54d5909d0497bb337ec1638cee6d413ce823a41bafab39`.

## Exact32 recovery and terminal-wrapper correction

The same original32 batch completed its recovery lane:49 successful CLI command
receipts, no command retry, Store/mailbox resume, lease wait, HTTP non-success or
session-close failure. Same runtime/scenario hashes, Active3/epoch2,
99 messages /33 original commands per account. Start11:05:48.320,
finish11:11:17.456 UTC; wall329.136s / active324.084s / CPU192.858s.
New B/C fanouts31.780/31.857s, two ONION requests each. This does not replace
the original strict32 FAIL or qualify a new first-attempt round.

The outer invocation erroneously inspected `$LASTEXITCODE` after invoking a
PowerShell script in-process. That variable was null (no native child had set
it), so the wrapper threw AFTER the driver's successful receipt and returned1.
This terminal is preserved as a wrapper failure, NOT relabelled native0/PASS.
The semantic completion is backed by all49 captured command exits and final
exact histories. The next strict33 uses explicit native `pwsh -NoProfile -File`
and captures that process exit, avoiding the ambiguous in-process shell wrapper.
No script assertion, receipt or business retry was changed to hide the error.

## Completed original32 operations, not a fresh-run benchmark

The following rows join the original strict32 and its exact recovery. The
already-completed first B receive is counted once; recovery's empty B poll
(6.325s, processed0) and original failed C poll (0.545s) are NOT counted as
new-message receive latency. All six selected successful receives processed1.
There was also a28.863s historical original-batch revalidation with ZERO ONION
requests; that recovery overhead is reported, not silently folded into send.
These are completed operations across recovery, not first-attempt full PASS,
an isolated patch benchmark or UI delivery timestamps. Authority lifecycle and
retained history differ from both earlier runs.

| Actual operation, seconds | Full30 | Delivery31 | Completed original32 |
| --- | ---: | ---: | ---: |
| A → two members | 56.657 | 66.604 | 30.331 |
| Receive/ACK A → B | 23.047 | 33.297 | 20.098 |
| Receive/ACK A → C | 20.134 | 33.763 | 17.877 |
| B → two members | 54.957 | 59.187 | 31.780 |
| Receive/ACK B → A | 21.310 | 31.686 | 18.600 |
| Receive/ACK B → C | 21.077 | 27.649 | 20.335 |
| C → two members | 52.634 | 61.671 | 31.857 |
| Receive/ACK C → A | 20.675 | 29.108 | 15.897 |
| Receive/ACK C → B | 23.780 | 29.040 | 18.860 |
| **Mean fanout** | **54.749** | **62.487** | **31.323** |
| **Mean successful receive/ACK** | **21.671** | **30.757** | **18.611** |
| Fanout ONION requests | 12 | 12 | 6 |
| New-message receive/ACK ONION requests | 12 | 18 | 12 |

Original32's fanout mean is42.8% below30 and49.9% below31; receive/ACK mean
is14.1% below30 and39.5% below31. Warm valid-grant reuse explains the request
count difference. It already existed for ordinary live winners: these samples
do NOT prove the new fixed-ceiling branch caused that speedup. The real signed
ceiling/cold-reopen integration proves that specific no-extension renewal now
makes zero issuer calls while retaining exact protected custody. Mandatory
expired-grant acquisition remains necessary. Remaining ONION/native/history
latency is still far above1–2s.

Recovery32's post-history operations (total seconds across3 accounts unless noted):
cold full-batch replay86.015, cold native history3.457, empty mailbox17.895,
deduplicated history1.633, owner control re-verification1.184 (one account),
empty GSR cursor replay10.780 (two accounts). No whole-run timing improvement
is inferred from a recovery with different work.

## Strict33 residual authority refusal

Strict33 used the exact guarded runtime/scenario and an actual native `pwsh`
process: native exit1, driver FAIL22 commands. Start11:12:25.074,
finish11:13:14.162 UTC. First fanout35.290s completed; the first recipient's
mailbox sync refused after0.935s with DirectoryProof/DirectoryHistory non-success,
before ONION. Same closed catch-up cause, no session-close failure.

The Registry window11:11:40–11:13:35 contained15 NTS acquisition refusals, ALL
`CryptographicException/observation-quorum`, plus proof/history unavailable.
No policy-scope/interval-conflict/floor-rollback/authority-time-coverage category.
At11:15:57 UTC the existing CA-validated readiness check remained unhealthy;
seven quorum refusals appeared in its last60s. The original33 batch is retained;
no replacement message, profile reset or time/source-policy relaxation is allowed.
A successful first-attempt full round remains UNQUALIFIED.
One bounded read-only recheck found existing readiness healthy at11:17:19 UTC,
failingStreak0 and latest validated readiness exit0; exact native-process
recover33 then resumed. No managed authority query or policy change was used
as a substitute for that readiness.

## Latest completed33 delivery (includes exact recovery)

Do not select only the faster32 sample. All three original33 sends and six
successful new-message receives have now completed, using the original failed
strict33 sender operation plus exact recovery33 for the remaining work:

| Operation, seconds | Completed32 | Latest completed33 |
| --- | ---: | ---: |
| A → two members | 30.331 | 35.290 |
| Receive/ACK A → B | 20.098 | 22.014 |
| Receive/ACK A → C | 17.877 | 24.551 |
| B → two members | 31.780 | 37.736 |
| Receive/ACK B → A | 18.600 | 21.376 |
| Receive/ACK B → C | 20.335 | 19.801 |
| C → two members | 31.857 | 45.195 |
| Receive/ACK C → A | 15.897 | 21.491 |
| Receive/ACK C → B | 18.860 | 22.099 |
| **Mean fanout** | **31.323** | **39.407** |
| **Mean receive/ACK** | **18.611** | **21.889** |
| Fanout ONION count | 6 | 6 |
| New-message receive/ACK ONION count | 12 | 12 |

Latest33 fanout is28.0% below original full30's54.749s, but its ACK mean is
1.0% ABOVE full30's21.671s: no ACK gain is demonstrated in this latest round.
Same ONION counts did not produce identical latency. Original-batch native
revalidation additionally took51.211s with ZERO ONION requests (not a new send).
Remaining local/native/history work therefore matters independently of the
necessary cold grant issuance; a global latency solution is not claimed.

## Final exact33 recovery terminal

Actual native `pwsh -NoProfile -File` process exit0. Recovery33 PASS49/49 at
11:25:12.856 UTC (start11:17:59.752): all three accounts have102 messages /
34 original local commands, Active3/epoch2. Exact histories, all native original
batch replays, empty mailbox/dedup and GSR cursor/control checks pass. No driver
command retries, automatic Store/mailbox resumes, lease waits, HTTP non-success
or session-close failure. Runtime/scenario fingerprints unchanged from strict33.
Wall433.103s / active425.982s / CPU272.592s. This closes the original pending33,
NOT its failed first attempt and NOT a fresh full/source/package/device gate.
No round34, reset, rekey, deployment or Windows/Android client work was done.

Final recovery operation totals: cold batch replay106.095s, cold native
history3.610s, empty mailbox18.650s, deduplicated history1.768s, owner control
2.357s, empty GSR cursor replay10.016s. The extra native original-batch
revalidation51.211s and all recovery overhead remain visible. Neither full-run
speedup nor1–2s delivery is claimed. Next blockers remain authenticated-time
availability plus measured ONION/native/history latency; S05 and release stay open.
