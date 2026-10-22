# Retained acquisition lifecycle and original round46 — 2026-10-22

Scope: the SAME three retained CLI profiles and original group rev11, Active3,
group epoch2; no reset/rekey/remint, device apps or production changes. The local
network selection epoch remains independently signed, not advanced for this run.

## Changes

- DR-0168: atomic move of complete inactive acquisitions into exact sealed
  protected custody. Working128, global storage and send/read replay-floor bounds
  do not increase. Floors/native/SQL and unresolved/captured work do not retire.
  Genuine later epoch exclusion restores the original for the existing strict
  dependency-closed retirement, then guarded slot deletion; cold handoffs tested.
- DR-0169: original Retrieve issuance PMA and logical assignment PMT need not
  name the same policy generation. Authenticate BOTH exact historical joins;
  return original facts only. Independent current ACK authority is unchanged.
- New Deposit scheduling reacts to a tightened verified ceiling or incompatible
  current issuer policy BEFORE its proportional refresh margin. Existing strict
  grant checks remain unchanged; exact pending work is resumed, not replaced.

## Immutable gate ledger

Root logs: `artifacts/cli-acquisition-lifecycle-20261022/`. CLI receipts and
runtime/scenario archives use the same prefix in this repository. Shared and
Protocol source receipts are in their respective repo-owned artifact trees.

| Gate | Native/result | Meaning |
|---|---|---|
| build01 |1 | Missing namespace import; corrected before subsequent gates |
| focused01 |0, Shared16/16 | Preflight, atomic/cold custody, hostile copies, real pressure, unknown-cap refusal |
| cli-build01 |0, CLI70/70 | Publish01 |
| recovery-46-01 |1,25 steps | B receive/ACK22.468s passed; C old captured-page historical join refused |
| captured01 |1,18 pass/2 fail | New fixture clock underflow; not waived, fixture fixed |
| captured02 |0, Shared8/8 + Protocol7/7 | Distinct-policy captured page/lost ACK and original-read checks |
| epoch01 |0, Shared11/11 | Genuine epoch/possible-ceiling cleanup; crash before/after restore/delete |
| cli-build02 |0, CLI70/70 | Publish02 |
| recovery-46-02 |1,33 steps | C captured page recovered; original C47 authored, fanout refused GrantRouteExpiry |
| ceiling01 |1,33 pass/2 fail | New fixture attempted a second successor in a single-successor fixture; corrected |
| ceiling02 |0, Shared35/35 | Tightened ceiling before margin, lost reply/cold exact retry, unchanged cap reuse and negatives |
| cli-build03 |0, CLI70/70 | Publish03; strict Protocol grant ceilings unchanged |
| recovery-46-03 |0,53/53 | Original round46 complete; no automatic Store/mailbox resume or lease wait |
| delivery-47 |0,40/40 | New retained round, first driver attempt, no automatic recovery/wait |
| batch01 |0, Shared72/72 | Batched staging, original atomic/cold/epoch cases and protected multi-slot storage conflicts |
| final-focused |0, Shared69/69 + CLI70/70 | Sustained128/129, eight-copy conflicts/cancellation, current ceiling and captured receive/ACK; publish04 |
| delivery-48 |0,40/40 | Functional PASS after idle; one owned mailbox resume and one ONION non-success, NOT clean no-recovery timing |
| delivery-49 |0,40/40 | Consecutive same-runtime round; zero automatic resumes/waits, retries, network failures/non-success |
| final-protocol |0, Shared7/7 + Protocol7/7 | Exact current unknown-cap refusal/preflight; original Retrieve; actual Debug/Release API/assembly graph and frozen manifest integrity |

These focused results are not unfiltered/full, package, device or release
qualification. Earlier failed receipts remain failed; later successful focused
tests do not rewrite them. Connected recovery and new delivery timings follow
only after the corresponding immutable receipt is terminal.

## Original46 recovery

`recovery-46-03/receipt.json`:14:48:00.611–14:55:01.036Z native terminal0;
receipt wall417.326s. Runtime
`429814ea1bf0af6174ea51e00fcf629dd52bbf18d021491a127692cd0b0d9016`.
All three native histories contain141 messages /47 local original commands,
each expected semantic copy exactly once. The missing C47 had been authored in
the preceding failed run: this recovery flushes that EXACT existing batch,
76.164s, not another message. Cold original FULL batch replay passes on all3
clients (mean54.235s); independently verified empty mailbox/control cursor and
deduplicated native history also pass. All commands use one driver attempt;
Store resumes0, mailbox resumes0, lease waits0. Recovery is NOT first-attempt
or delivery-only latency qualification.

## First independent delivery round

`delivery-47/receipt.json`: native0,14:55:19.318–15:01:36.458Z. SAME publish03
runtime, profiles and group;144 messages /48 local original commands each.
All40 steps pass, attempt1, zero Store/mailbox resumes, lease waits, network
failures or non-success. Receipt wall375.890s, active372.237s, CPU176.390s.

| Operation |45 prior completed |47 after lifecycle recovery |Change |
|---|---:|---:|---:|
| Two-recipient fanout, mean3 |58.911s |64.839s |+10.1% |
| Receive + ACK, mean6 |22.135s |22.114s |-0.1% |
| Empty mailbox poll, mean3 |7.438s |7.842s |+5.4% |
| Deduplicated history, mean3 |0.848s |0.907s |+7.0% |
| Active commands, complete round |356.269s |372.237s |+4.5% |

Fanout ONION12→11, proof8→8; receive/ACK ONION13→12, proof30→30. This proves
functional recovery, NOT a latency improvement. Grant-acquisition and maintenance
work differ, so this is an operational comparison, not causal A/B. A bounded
sealing batch optimization and its own unchanged-runtime successor measurement
are qualified separately below.

The final focused native0 ran15:09:36.882–15:23:50.945Z, zero warnings/errors or
skips. Real sustained cases passed:129 distinct grants across genuine namespace
closure with interrupted captured-page/cold recovery (303.021s),128 original
floors plus BEFORE-issuer backpressure (314.226s), and expired replacement
deferral/renewal. The eight-copy storage cases all pass: success16.397s,
root conflict16.265s, LAST-slot conflict20.297s, cancellation15.065s. The complete
protected predecessor/copies and independent read-floor root survive cold reopen.
These are source fixtures with real signed/native/encrypted custody, not physical
128-device/network availability evidence or unfiltered source qualification.

## Final same-runtime rounds

Publish04 runtime fingerprint for BOTH48 and49:
`71b9dd7c20cc8066afbb7b8f0bc9b32f47c812a3c862cf77d79728a5fb890c97`.
No source/runtime/scenario changes occurred during either round. Original
accounts, identities, group, counters, old batches and protected floors remain.

48 native0:15:23:50.974–15:30:47.670Z;147 messages /49 local original commands
each. Wall414.069s, active410.436s, CPU179.768s. The second receive/ACK31.956s
used ONE owned mailbox resume,4 ONION exchanges including one non-success.
No Store resume, lease wait or failed HTTP request. This is functional recovery,
not an all-first-attempt/no-recovery acceptance claim.

49 native0:15:31:13.079–15:36:50.388Z;150 messages /50 original local commands
each, Active3/group epoch2. All40 steps use attempt1; Store/mailbox resumes0,
lease waits0, network failures0, non-success0. All three cold native histories,
exact current semantic copies, empty mailbox and durable dedup checks pass.
Wall335.548s, active331.734s, CPU176.349s. Devices/release remain unqualified.

Operational comparisons, seconds;45/47/49 have no automatic recovery.48 is
explicitly marked above. Grant acquisition/maintenance and authority histories
differ: this is NOT a matched causal A/B, nor subsecond transport latency.

| Operation |45 prior |47 before batch |48 after idle |49 consecutive |49 vs45 |
|---|---:|---:|---:|---:|---:|
| Two-recipient fanout, mean3 |58.911 |64.839 |63.039 |47.750 |-18.9% |
| Receive + ACK, mean6 |22.135 |22.114 |27.735 |24.125 |+9.0% |
| Empty mailbox, mean3 |7.438 |7.842 |10.728 |7.533 |+1.3% |
| Deduplicated history, mean3 |0.848 |0.907 |0.962 |0.932 |+9.9% |
| Active command time, entire round |356.269 |372.237 |410.436 |331.734 |-6.9% |

49 versus47: fanout-26.4%, receive/ACK+9.1%, active-10.9%.49 versus48:
fanout-24.3%, receive/ACK-13.0%, active-19.2%, but48 had idle reissuance/recovery.
Fanout ONION45/47/48/49:12/11/12/6; proofs8/8/7/8. Receive/ACK ONION:
13/12/16/13; proofs30/30/31/32. Existing usable grants avoid issuer exchanges
only while all independent current checks permit reuse. No expired authority,
old counter or captured request is refreshed by a cache. A sealing maintenance
batch now performs ONE atomic inventory mutation for up to8 original copies;
its isolated end-to-end latency gain is not established by these different runs.
Total CLI CPU remains approximately176s; local native/persistence amplification
and ACK remain open performance work. Overall ACK acceleration,1–2s delivery and
Signal parity have NOT been achieved or claimed.

All CLI operations in FINAL49, seconds (non-overlapping command phases):

| Phase |Count |Mean |Total |
|---|---:|---:|---:|
| Cold account status |3 |0.356 |1.067 |
| Pair left contact list |3 |1.248 |3.743 |
| Pair right contact list |3 |1.953 |5.859 |
| Retained owner head |1 |0.235 |0.235 |
| Command preflight |3 |0.227 |0.681 |
| History preflight |3 |0.903 |2.708 |
| Exact active owner head |1 |0.225 |0.225 |
| Exact active recipient head |2 |0.208 |0.415 |
| Original-command counter |3 |0.184 |0.553 |
| Two-recipient fanout |3 |47.750 |143.249 |
| Recipient receive + ACK |6 |24.125 |144.752 |
| Cold native history |3 |0.951 |2.853 |
| Empty mailbox |3 |7.533 |22.598 |
| Deduplicated history |3 |0.932 |2.796 |
| ALL active commands |40 |— |331.734 |

The command durations include verification, disk, request and orchestration
work; they are not pure one-way network or sender-to-recipient latency.

Final protocol gate native0:15:37:45.842–15:39:16.260Z, zero build warnings/errors.
Debug/Release exact-three source/build/lock, actual assembly/resource/public-API
graphs pass. Frozen executable-manifest INTEGRITY passes; no executable case
discovery/full witness qualification is implied. Temporary publish RID lock
sections are removed; package versions/content hashes and production graph stay
unchanged (Shared lockfile EOF normalized by ordinary restore).

Remaining: ACK and local native/persistence latency, true1–2s delivery, canonical
unfiltered source/package/operational/device/release qualification. Prior separate
production-ingress Compose-Up failure and missing release evidence are not closed
by these CLI/source results. No Windows/Android application, production deployment,
identity/node-key reset, replay-floor deletion or GitHub Release publication.
Next retained delivery cursor50; do not rerun49 as a newly authored round.
