# Retained route re-introduction and three-CLI recovery — 2026-10-21

Scope: the SAME three retained CLI profiles, original three-member group,
epoch2 and local three-node contour. No account, relationship, ratchet, node
key, data/volume reset, state import, production deployment or Windows/Android
application work. Old failed receipts remain failed. This is not release GO.

## Corrections

- [DR-0159](../../../docs/survival-program/decisions/DR-0159-established-contact-route-reintroduction.md):
  explicit same-peer permanent-address re-introduction obtains a separately
  current ContactResolve publication through owned ONION. That route carries
  ONLY the exact native DMC2/14 control of the existing mutually consented
  relationship. Ordinary data, acceptance and braid cannot use it. Expired
  XRA/XUR remain expired; the receiver independently verifies ratchet, consent,
  exact successor and predecessor. No private head is replaced by discovery.
- Existing MAC-bound Store evidence retains original DCR/ADP/route facts for
  native-purpose-qualified cold replay, closure, settlement and retirement.
  Presence of publication evidence no longer incorrectly means "Initial".
- Settled-consent private Store reuses already verified semantics inside ONE
  held lease only. Every boundary still reauthenticates all native SQL rows and
  protected history, exact floor, protected/SQL consent inputs, current endpoint
  pair and signed time windows. First/unsettled acceptance performs complete
  reconstruction instead: its own completion legitimately changes consent.
- Real A↔B recovery exposed soft32-row outbox cleanup blocking a new control on
  an unresolved predecessor despite available hard capacity. Optional cleanup
  now conservatively defers below both actual hard limits. No old attempt,
  request, native event, evidence or floor is evicted or called successful.
  Explicit/required cleanup still needs the complete original outcome chain;
  unrelated IO/corruption/cancellation is not suppressed. Writers independently
  enforce the unchanged limits. Closed-prefix selection avoids repeatedly paying
  for optional cleanup that cannot yet prove all original outcomes.

## Verification ledger

Receipts below are under `artifacts/cli-reintroduction-20261021/`, except the
Shared/Protocol receipts in their own repositories. Raw node diagnostics stay
private and are not copied here.

| Receipt | Observed result |
| --- | --- |
| Shared `focused-01`/`focused-02` | Compile/input failures retained; no acceptance claim |
| Shared `focused-03` |4 PASS/native0: native control only, wrong-purpose refusal and cold exact Store replay |
| Shared `focused-04` |Stopped after a defective empty-root fixture; TRX16 PASS/1 FAIL, native1; NOT qualified |
| Shared `focused-05` |9 PASS/1 FAIL, native1; negative fixture supplied authority request instead of signed publication response |
| Shared `focused-06` |10 PASS/native0; subsequent review found first-acceptance completion needed separate full reconstruction |
| Shared `focused-07` |11 PASS/native0: final settled/first-acceptance paths, cold replay, scope/expiry/purpose refusals and consent-input tampering |
| Shared `pinned-prefix-01` |6 PASS/1 FAIL, native1; test incorrectly assumed a128-entry send limit |
| Shared `pinned-prefix-02`/`pinned-prefix-03` |7 PASS/native0 each; tests use actual hard-limit constants and reject unrelated errors |
| CLI `cli-05` |67 PASS/native0, final all-Release shipping graph |
| Protocol `route-reintroduction-20261021/build-01` |Debug/Release builds native0; exact-three actual assembly/API/resource graphs PASS both configurations |
| Protocol strict registry / executable manifest / ownership |Generated inputs current; integrity-only PASS (not executable discovery); exact314/package219/final95 ownership PASS |
| `repair-ac-01` |11/11 PASS; original mutual-expiry A↔C recovered |
| `repair-ab-01` |FAIL before new control authoring, pinned original outbox prefix; state retained |
| `repair-ab-02` |11/11 PASS after soft-maintenance correction |
| `repair-bc-01` |11/11 PASS; all three pairs current, no retained route fault |
| `recovery-01` |49/49 PASS, `recoveryQualified=true`; zero owned Store/mailbox resumes and lease waits |
| `steady-01` |46/46 PASS, no driver retry; ONE owned mailbox resume and ONE lease wait |
| `steady-02` |46/46 PASS, all driver attempts1; ZERO owned Store/mailbox resumes and lease waits |

The original incomplete cursor14 is closed on the original identities and
group. It is NOT substituted with the preceding fresh-profile lifecycle.
Each original profile reaches45 group messages /15 local commands. Cold full
batch replay, deduplicated histories, empty ordinary mailboxes and empty GSR
cursors pass. The first receiver of A's old batch had already processed that
message; its recovery poll is empty. The other receiver processes and ACKs the
unchanged original ciphertext. Recovery active time628.136s, wall636.065s;
it is not a fresh-send benchmark.

The following independent cursor15 reaches48 messages /16 local commands on
each profile. All three senders fan out to both others; all six receive/ACKs,
cold full-batch replay/dedup and empty ordinary/GSR cursors pass. The driver
makes one attempt per command, but that does NOT mean zero owned recovery.

A second independent cursor16 then reaches51 messages /17 local commands on
each of those same profiles. All six receive/ACKs, three cold original-batch
replays/deduplicated histories, empty ordinary mailboxes and GSR cursors pass.
`steadyStateQualified=true`, `firstAttemptRequired=true`,
`noOwnedUnknownRecovery=true`; Store/mailbox resumes and lease waits are0.
No code, runtime, contour or account changes between cursors15 and16.
Active579.018s, wall586.267s. This confirmation does not erase cursor15's ACK tail.

## Matched-profile comparison, seconds

Baseline: retained cursor13, `cli-native-20261020/steady-01`,46/46 PASS.
New: retained cursors15/16, `cli-reintroduction-20261021/steady-01` and
`steady-02`,46/46 PASS each.
Same identities, group, host/topology and node image; histories grew rather than
being reset. Not identical-history samples, a statistical speed claim or a Signal
benchmark. Commands are sequential: fanout plus complete receive/ACK is NOT
an instrumented simultaneous sender-to-visible-message latency.

| Operation | Count | Cursor13 total | Cursor15 total | Cursor16 total |
| --- | ---: | ---: | ---: | ---: |
| Account cold status |3|1.945|1.725|1.815|
| Pair left cold list |3|6.434|6.336|7.683|
| Pair right cold list |3|25.908|26.467|24.771|
| Retained owner head |1|0.237|0.245|0.193|
| Native command preflight |3|0.697|0.675|0.666|
| Native history preflight |3|7.842|7.666|8.142|
| Exact active owner head |1|0.218|0.236|0.229|
| Exact active recipient heads |2|0.397|0.404|0.492|
| Original sender command count |3|0.596|0.565|0.695|
| Two-recipient fanout |3|320.881|216.090|186.497|
| Recipient native receive/ACK |6|228.696|229.835|184.058|
| Cold native history |3|6.589|7.046|6.653|
| Cold original full-batch audit/replay |3|86.322|107.158|113.575|
| Post-replay empty mailbox |3|21.943|19.303|20.409|
| Post-replay deduplicated history |3|6.956|8.583|7.877|
| Cold owner control receipt audit |1|4.098|4.835|3.382|
| Cold empty control cursor |2|11.092|16.546|11.881|
| All46 active commands |46|730.851|653.715|579.018|

Fanout A/B/C:105.112/103.950/111.819 →65.826/72.818/77.446s.
Mean106.960 →72.030s, **32.7% lower**. All46 active commands are10.6% lower.
Receive/ACK35.600/32.731/27.369/35.078/24.862/74.195s:
aggregate is **0.5% higher**, not an ACK speedup. The final ACK has one owned
resume/wait and one ONION non-success. Do not omit that74.195s sample.
Actual node logs in the bounded window have no native-terminal-incomplete
event; a missing-observation exception also exists in that window, but causality
to this particular ACK is NOT established by the available aggregate diagnostics.

Cursor16 fanout A/B/C:48.436/59.989/78.072s, mean62.166s
(41.9% below cursor13). Receive/ACK:34.384/33.176/25.304/36.193/27.974/27.027s,
mean30.676s (19.5% below cursor13). All46 active commands20.8% below cursor13.
These are observations of two successive rounds, not guaranteed latency bounds;
the growing cold full-batch audit is actually slower than the baseline.

Both new-round archives capture the same runtime SHA256
`fa531f6267517e7964a24ee11d7bfa675eeb258219fccb24b14dbe75ad5222b5`,
scenario SHA256`360c082c9dd4f02570a8095d49a4f2622a53fe3b09bedbe397cbfcd6d2707215`
and session-module SHA256`1961b8787f11725c75c2f4c470b4535f9fb5f2ff4dd85a746be11acf3e8b8687`.

## Still open

1. 1–2-second latency is NOT achieved. Both local authority/history work and ONION
RPCs remain substantial. Separate routine authority maintenance, new delivery
and historical audits; do not relax signature/currentness/clock/counter guards.
2. Ordinary ACK tail/retry diagnosis and old full-batch audit cost remain open.
3. This explicit re-introduction is not a complete long-offline XUR service:
missing successor generations/forks, changed endpoints and unavailable current
publication still refuse. No expired capability or fabricated checkpoint bypass.
4. Deferred uncertain prefixes are NOT reclaimed. Hard-capacity/long-running
retirement, full source/package/independent security review, physical devices
and final release acceptance remain separate and unqualified.

Approved normative binding:`e568992ccf40de1e1b6d7791394ed689450ff1b7`.
No release publication, main merge or production/client deployment is included.
