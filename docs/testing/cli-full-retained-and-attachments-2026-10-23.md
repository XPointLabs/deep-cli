# Full retained group57 and attachment recovery

Date:2026-10-23. Local contour, same three retained CLI accounts, Active3/epoch2.
No account reset/rekey, production rollout, device app operation or release.
This continues the [55/56 checkpoint](cli-idle-authority-scheduling-2026-10-23.md),
not a replacement or re-authoring of any old round.

## Complete retained group scenario

`artifacts/cli-full-retained-20261023/steady-57/receipt.json`:46/46 PASS,
native0,03:52:12.927–04:01:16.173Z. **Not delivery-only**:
`steadyStateQualified=true`. All commands attempt1, automatic Store/mailbox
resumes0, lease waits0, network failed0/nonSuccess0, maintenance failures0
(reported maintenance maximum1ms). All three cold histories contain174 group
messages /58 original local commands, exact new-round semantic copies once.
Next retained group cursor58; never re-author55/56/57.

The unchanged ordinary runtime fingerprint is
`d70f2a5b56bfc0fa17f2fcfab12eb7c2c18bb8c18bee06d5a35e131531403e75`;
GSR scenario remains
`4c33e9d224361d0705293351fb738375422955ffd3cf62ac2a010b03f5695475`.

| Phase |Count |Mean seconds |Total seconds |
|---|---:|---:|---:|
| Cold account status |3 |0.404 |1.211 |
| Pair left contact list |3 |1.380 |4.139 |
| Pair right contact list |3 |2.058 |6.175 |
| Retained owner head |1 |0.201 |0.201 |
| Command preflight |3 |0.187 |0.560 |
| History preflight |3 |0.896 |2.689 |
| Exact active owner head |1 |0.194 |0.194 |
| Exact active recipient head |2 |0.172 |0.343 |
| Original-command counter |3 |0.197 |0.592 |
| Two-recipient fanout |3 |49.001 |147.003 |
| Receive plus independent ACK |6 |18.092 |108.551 |
| Cold native history |3 |1.171 |3.513 |
| Full original Store audit |3 |73.324 |219.971 |
| Post-audit empty mailbox |3 |7.425 |22.276 |
| Deduplicated history |3 |1.014 |3.041 |
| Owner cold GSR/control receipt reverification |1 |6.901 |6.901 |
| Cold recipient control cursor replay |2 |5.854 |11.708 |
| ALL active commands |46 |— |539.068 |
| Scenario wall |— |— |543.246 |
| CLI CPU |— |— |401.388 |

Full Store audit samples75.912/74.499/69.560s verify124/117/117 original
elements. They rejoin actual protected/native/SQL custody and original receipt
evidence without re-authoring or resending completed Stores. Every post-audit
empty mailbox and native dedup check passes. This covers the path that failed
in full54-01; its immutable original FAIL receipt remains unchanged. It is not
GSR1 long-offline retention, canonical source-suite, device or release acceptance.

Ordinary means56→57: fanout49.370→49.001s, receive/ACK19.736→18.092s. These are
observations across different authority/history/warmth conditions, not causal
A/B. Full57 wall includes the extra archive/control phases; do not compare its
539.068s active total directly with delivery-only56's315.769s as a regression.
No1–2s claim is made.

## Attachment harness and retained route expiry

The attachment driver now accepts the same archived published executable as the
GSR driver, validates its owned artifact path before I/O and archives immutable
runtime/scenario inputs. It selects exactly one common explicitly accepted
conversation from both real contact lists, not the first contact or an assumed
one-contact profile. Opposite acceptance orientation and the actual CLI hex
contract are preserved; ambiguous/missing/unaccepted selectors still reject.

An explicit `-AssetRevision` chooses a separate QA asset namespace; zero keeps
the original deterministic test selectors. It is not a wire/state version or
permission to replace failed work. Revision1 remains identical across this
attempt and its recovery. `eng/Test-AttachmentScenario.ps1`:15 checks PASS/native0
for the actual pure selector/identity functions and early runtime rejection;
no CLI/network/fake authority is used by those harness unit checks.

`attachments-01` FAIL/native1 occurs after only two contact reads: the first
selector incorrectly required lowercase although the CLI exposes uppercase
conversation hex. No asset/offer was authored. That assertion is corrected to
the existing CLI contract, with an uppercase and trailing-newline regression.

`attachments-02` FAIL/native1 is a **real fail-closed route expiry**, not a
crypto bypass candidate: first file/manifest and original offer were authored,
then Store refused `RouteTimeXRA1Expiry`. Alice's retained Bob XRA1 and XUR1 no
longer cover current trusted time; Bob's reverse XRA1 still covers it. Neither
side has a native route-fault marker. The original asset/offer is preserved.

The existing `Invoke-ContactRouteRepair.ps1` ordinary maintenance path, Bob→Alice,
passes6/6/native0 (`route-maintenance-01`). It renews own publication, sends the
native successor control through the valid reverse route, independently
receives/ACKs it, checks the resulting interval and verifies that another
maintenance call creates no duplicate control. Publication/control127.200s,
receive/ACK74.389s, interval check2.886s, exact no-op maintenance6.288s.
This repair includes **one automatic Store resume, one mailbox resume and two
lease waits**; it is not first-attempt low-latency evidence.

This proves an outstanding product liveness gap: a cold ordinary attachment
send cannot itself arrange the peer's missing route refresh. Current fail-closed
checks are correct, but routine publication/route maintenance must be scheduled
before expiry across all retained contacts. Explicit maintenance here is
reported as such, not hidden inside the latency or first-attempt qualification.
No manifest, ciphertext, logical offer or ratchet is replaced by the repair.

## Original attachment recovery and reverse PNG

`attachments-03/receipt.json`:PASS/native0,04:13:20.290–04:16:16.809Z,
26 commands, two expected overwrite refusals (exit6), **zero unexpected failures**.
Same runtime fingerprint above; attachment scenario fingerprint
`c7ef85dde07a500c64553dca856e0778e10bef3b056e8f25b3af4373aac0d896`.
AssetRevision remains1. The document's prepared object is reused and its exact
existing offer is selected through owned operations: **no document queue command
occurs in this recovery**. Only the previously absent reverse PNG is queued.

| Operation, seconds |524325-byte document A→B |68-byte PNG B→A |
|---|---:|---:|
| Prepare existing/new asset |0.824 |2.324 |
| Cold prepare, same object/expiry |0.877 |0.888 |
| Owned operation projection |0.526 |0.502 |
| New offer queue |Not run: original retained |5.186 |
| Original offer send |26.051 |23.406 |
| Receive plus independent ACK |26.727 |26.850 |
| Received offer list |1.553 |0.930 |
| Cold complete download |13.023 |11.450 |
| Expected overwrite refusal |1.250 |1.004 |
| Cold exact original Store retry |4.630 |6.504 |
| Duplicate mailbox poll |6.653 |6.480 |
| Deduplicated offer list |1.605 |0.906 |

The reverse PNG's own-list prerequisite is1.525s; initial contact reads total
2.704s. All active commands174.378s; wall176.518s. These recovery/new-asset
durations are not a clean first-attempt attachment latency A/B, and exclude the
explicit preceding route maintenance.

Both independent whole-file output SHA256 checks pass:

- Document: `28d74fa5755c48ed29abc801895d72119129c7e3a37be3aee13116e689f551e5`.
- PNG: `1e8f472d1b58b5c8b29fd9d3ec58f5e34451f05d1ff114748e136d8442b13308`.

Both receipts record coldPrepareReusedObject=true, retainedStoreReplay=true,
duplicateOffers=0 and overwriteRefused=true. Existing output hashes remain
unchanged after refusal, and no download staging file leaks. No image rendering
or physical-device result is claimed by a byte-verified CLI download.

Final serial scenario guards pass/native0: attachment15, GSR scope9,
contact/text scheduling4. Shared13/CLI70 receipts from the previous checkpoint
still cover the unchanged application runtime; this turn changes only the
attachment driver, its focused guard tests and documentation, not Shared,
Protocol, node binaries or application permissions. No rebuild was needed.

## Remaining release work

Automatic proactive publication/route maintenance (including all existing
contacts and mutually expired recovery) remains a required S05 liveness slice;
do not present the explicit six-command repair as an automatic product fix.
The third CLI and all prior group/contact/asset histories remain retained.
Also open: substantial ONION/native latency, GSR long-offline retention,
interrupted/corrupt/expiry attachment qualification, canonical unfiltered source
and package/rehearsal gates, production matching and physical device E2E.
Windows/Android remain untouched under the current user restriction; no GitHub
Release/main merge. The full thread goal remains active, not achieved.
