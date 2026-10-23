# Retained connection maintenance — 2026-10-23

Scope: SAME three retained CLI profiles and local nine-service Docker contour.
No account reset/rekey, replacement of original failed work, node deployment,
Windows/Android application action, main merge or GitHub Release.

Normative ownership: [DR-0174](../../../docs/survival-program/decisions/DR-0174-connection-contact-maintenance.md).
This report records observations, not a second lifecycle specification.

## Retained baseline

Original55 delivery recovery already passed43/43/native0; new56 delivery passed
40/40/native0 with mean fanout49.370s and receive+ACK19.736s. Full57 subsequently
passed46/46/native0, mean fanout49.001s and receive+ACK18.092s, with174 group
messages/58 original local commands per profile. Next new group cursor is58;
55–57 must not be re-authored. Full57 and original document/PNG evidence belong
to the [previous checkpoint](cli-full-retained-and-attachments-2026-10-23.md).

## Failures retained, not reclassified

- `artifacts/cli-contact-maintenance-20261023/focused03`: native1, compilation
  rejected a new metadata test's use of an internal Protocol text encoder.
  Corrected to public DID2 author/descriptor APIs; this is parsing metadata,
  not a native authentication fixture or E2E proof.
- `artifacts/cli-contact-maintenance-20261023/cycle-01/receipt.json`: native1.
  The first real Shared cycle completed on Bob in42.822s with4 accepted scopes,
  zero stored controls,3 deferrals and an empty mailbox. The driver incorrectly
  assumed two contacts per running profile. Actual retained accepted counts are
  Bob4/Alice3/Carol4. Historical offline contacts are not removed or ignored by
  the consumer; current-cohort route checks remain separately mandatory.

Read-only native diagnostics also found mutually expired peer advertisements.
A DID2 hash cannot yield the descriptor's resolver-read capability. The new
consumer can accept actual caller-known descriptors as bounded, copied data and
invoke ONLY the existing strict native control re-introduction owner. The driver
obtains the SAME accounts' descriptors through explicit `account address` and
keeps them in RAM/private session input, never receipts or process arguments.
No expired ordinary route is admitted and no relationship is recreated.

## Source and harness checks

- Shared `focused04` and final `focused05`:23/23 each, native0, zero skips.
  Final05 includes16 scheduler/data ownership cases and the existing real
  proactive renewal, route-maintenance and strict re-introduction owners.
  The cycle calls private published-route helpers only after its single own
  publication saga; native/currentness/consent/effect validation is unchanged.
- CLI `unit03`:87/87/native0, zero skips, under Windows PowerShell5.1 / SDK10.0.301.
- Harness `scenarios03`: connection22, GSR scopes9, attachments15, contact/text4
  checks pass/native0. These parser/selector negatives launch no CLI or network.
- Fresh immutable `publish02`: native0, ReadyToRun Latency profile, win-arm64,
  no trimming or single-file transformation. `publish01` and its failed cycle
  remain separate inputs/evidence; it is not reused for the new implementation.

## Connected owned cycle

`artifacts/cli-contact-maintenance-20261023/cycle-02/receipt.json`:33 commands,
PASS/native0,05:42:33.810–05:53:58.211Z. Runtime fingerprint
`026ac62abf765b204fb8d9dfb5315c435cac8ebbb32c456ec87c0eaf08e7746e`.
Every command attempt1, no automatic Store/mailbox resumes or lease waits,
no failed/nonSuccess network calls. Actual accepted scope counts stay4/3/4.

The first pass stores3 native controls (one strict re-introduction), receives
and independently ACKs one; the second receives/ACKs the remaining two. Third
cycles are actual no-op: zero stored controls, receives or tombstones, no HasMore.
Historical offline relationships remain explicit2/1/2 deferrals. ALL six native
route-health directions inside the live three-account cohort cover trusted now
without a retained fault. No manual `contact refresh-route` or `reintroduce-route`
command substitutes for the Shared cycle in this lane.

| Cycle phase |Count |Mean seconds |Total seconds |
|---|---:|---:|---:|
| Own bootstrap publication |3 |17.750 |53.251 |
| Explicit existing descriptor read |3 |0.066 |0.198 |
| First connection cycle |3 |109.784 |329.353 |
| Second convergence cycle |3 |46.426 |139.278 |
| Quiescent cycle |3 |34.133 |102.398 |
| Six native route interval checks |6 |5.595 |33.570 |
| Contact projections across phases |12 |— |19.419 |
| ALL active commands |33 |— |677.467 |
| Wrapper wall including archive/startup |— |— |684.401 |

This is successful cold mutually-expired **control recovery with actual supplied
descriptors**, not normal-send latency, background liveness, persistent address
exchange or a1–2s delivery claim. No-op cycles are still expensive; they must not
be polled every10s instead of DR-0173's cheap idle denial-only scheduling hint.

## New retained58 and remaining-lease correction

`artifacts/cli-contact-maintenance-20261023/delivery-58/receipt.json`:40/40,
PASS/native0,05:54:18.521–06:00:39.728Z. This is delivery-only, not full/archive.
SAME profiles now retain177 group messages/59 original local commands each.
All driver commands attempt1, but first fanout has ONE internal Store resume
and ONE lease wait, with one nonSuccess ONION response. It is **not** no-recovery
or first-wire-attempt evidence. Means: fanout70.945s; receive+ACK19.873s.
Individual fanouts105.069/60.574/47.191s. The regression is retained, not hidden
by excluding the slow sample or replacing its original command.

Node's existing closed diagnostic identifies a cryptographic refusal inside
`DeepIdV2NetworkPlacementRuntime.ReadNetworkAsync`; its exact authority check is
Unclassified. That location alone does NOT prove which source/floor/clock changed
and is not grounds to bypass the refusal. No node/source guard is relaxed.

A separate, concrete recovery delay is visible in the implementation: after
expensive fresh-authority/prepared-state work, the helper always sleeps another
full35s rather than the remaining protected NotBefore interval. The adapter now
captures a denial-only scheduling duration using the SAME clock reading that
refused dispatch. Recovery waits0..35s once, then re-enters the SAME ordinary
owner, which must independently authorize retry; repeated lease denial remains
unknown. No new attempt/semantic message, signature bypass or lease extension.
See the amendment to existing
[DR-0153](../../../docs/survival-program/decisions/DR-0153-owned-mailbox-automatic-continuation.md).

## Final delivery59

Final recovery `focused06`:45/45/native0, zero skips. Includes actual encrypted
lost-Store/exact-reopen/durable-receipt owner, existing recovery negatives and
the remaining-delay/next-protected-denial cases. CLI `unit04`:87/87/native0,
zero skips. Fresh immutable `publish03`: native0, same Latency/RID configuration.
These are focused source/CLI checks, not canonical full source acceptance.

`artifacts/cli-contact-maintenance-20261023/delivery-59/receipt.json`:40/40,
PASS/native0,06:05:22.678–06:10:53.827Z. SAME retained profiles,180 group
messages/60 original local commands EACH, Active3/epoch2. Next new cursor60;
55–59 must never be re-authored. No account reset, hand-edited custody or manual
retry. All driver attempts1, Store/mailbox resumes0, lease waits0, network
failed/nonSuccess0. `noOwnedUnknownRecovery=true`, delivery-only qualified;
not full/archive, GSR long-offline, device or release acceptance.

Final runtime fingerprint
`a8ad72344965962432afd5af9060057aaf91907885bc455cfaddc6506f0224ea`.
Both group58/59 scenarios retain
`4c33e9d224361d0705293351fb738375422955ffd3cf62ac2a010b03f5695475`.
Final group59 uses immutable `publish03`; recovery cycles used `publish02`.
The ConnectionCycle branch is unchanged after cycle02; the separate explicit
manual repair mode now correctly uses bootstrap-only `network publish`, not
the newly connected `verify`. Its parser/guard tests are rerun; a new connected
manual repair run is not claimed.

| Operation |Count |Mean seconds |Total seconds |
|---|---:|---:|---:|
| Cold account status |3 |0.672 |2.017 |
| Pair left contact projection |3 |1.388 |4.164 |
| Pair right contact projection |3 |2.183 |6.548 |
| Retained owner head |1 |0.189 |0.189 |
| Native command preflight |3 |0.196 |0.589 |
| Native history preflight |3 |0.938 |2.814 |
| Active owner head |1 |0.178 |0.178 |
| Active recipient head |2 |0.183 |0.366 |
| Original-command counter |3 |0.185 |0.555 |
| Two-recipient fanout |3 |46.312 |138.935 |
| Receive + independent ACK |6 |20.894 |125.365 |
| Cold native history |3 |1.122 |3.365 |
| Post-delivery empty mailbox |3 |13.183 |39.549 |
| Deduplicated history |3 |0.956 |2.869 |
| ALL active commands |40 |— |327.503 |
| Scenario wall |— |— |331.149 |
| CLI CPU |— |— |186.343 |

| Retained run |Fanout mean seconds |Receive+ACK mean seconds |Owned resumes/waits |
|---|---:|---:|---|
|57 full (extra archive phases excluded from these means) |49.001 |18.092 |0/0 |
|58 delivery |70.945 |19.873 |1 Store/1 wait |
|59 delivery |46.312 |20.894 |0/0 |

Observed59 versus57: fanout−5.5%, ACK+15.5% (worse). Versus the recovery outlier58:
fanout−34.7%, ACK+5.1% (worse). Overall active58→59:375.424→327.503s (−12.8%).
Conditions/history/authority/warmth differ; this is NOT causal A/B. The new
remaining-wait branch is unit/native-source tested but NOT exercised by59,
which has no uncertain effect; its speed must not be attributed to that branch.
Normal latency is still far from1–2s and ACK has not improved.

Twelve rate-limited existing node diagnostic samples during59 report a mean
209.1 lease checks per sampled RPC and2499ms lease work, including1396ms authority
work. These are sampled/nested timings, not additive complete command costs.
Repeated current/native checks and ONION work remain the next measured hot path;
they must be reduced by safe batching/ownership changes, not skipped guards.

Periodic/background scheduling, durable descriptor exchange/address book,
sustained availability,1–2s delivery, canonical full/package/device and release
acceptance remain open. No GitHub Release or main merge is authorized here.
