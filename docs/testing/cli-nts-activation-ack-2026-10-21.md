# Retained NTS activation and ACK — 2026-10-21

Historical activation/strict37 baseline. The subsequent
[regression investigation](cli-authority-regression-2026-10-21.md) identifies
unused application-store integrity scans and measures the retained correction.

Continues the [pre-activation checkpoint](cli-nts-quorum-ack-2026-10-21.md).
Only the retained local `deep-dev-current` contour and the same three CLI
profiles/group are in scope. Windows/Android applications and production were
not changed. This is focused source and connected CLI evidence, not full,
package, device or release qualification.

## Installed redundancy

The installed signed DTS1 now contains **four sources in four independent
failure families**, retaining both original source tuples. Required source and
family counts remain **two**; maximum sample age **10s** and interval width
**30s**, source radii, normal CA/hostname validation, TLS 1.3, ALPN, exact SPKI
pins, authenticated NTS and protected floors are unchanged. A source-list count
is not proof that all four providers are reachable or sustained availability.

Actual cold Linux observer probes use the installed policy's exact source tuples,
without modifying the live source list, Registry clock or service processes:

| Probe | Authenticated observations / families | Duration | Two-family quorum |
| --- | --- | --- | --- |
| All four installed | 4 /4 | 1.417s | PASS |
| Omit original source one | 3 /3 | 1.298s | PASS |
| Omit original source two | 3 /3 | 1.404s | PASS |

Each probe runs the actual image's observer with no secret mounts. Its exact
signed subset, known unique IDs, actual observation radius plus monotonic age,
10s age bound and intersection width30s are checked. No provider time/ID/pin
or raw response is saved in the closed result. All three cold probes had zero
closed failure diagnostics; this proves observed failover, not an outage/SLO
guarantee. The earlier operator-host attempt with one KE failure remains a
separate observation, not evidence of four healthy sources at that earlier time.

All nine Compose services are healthy after supported activation/Up/Verify.
Registry image: `sha256:ebee47ca9860e88fb74f4ace75e1de36ca2a9f17e851ce9e6e80bba8c922e23a`;
publisher: `sha256:8a3e40f9f10e27a209e99f6e3cd97f22bfe031451fd3ce6bd72a223bb8a4ac50`;
all three nodes: `sha256:aa29eddeb8d71b8d02ab560cfbfa57cc260f23ab175305c7e3f9519f6a2ddc85`.

[DR-0161](../../../docs/survival-program/decisions/DR-0161-retained-time-source-activation.md)
extends the existing offline operational renewal with an explicit retained
mailbox ceremony. Preparation, activation and installed-state verification all
completed with native exit0. The old pre-mailbox guard remains for ordinary
calls: it was not bypassed. Offline roots were never mounted online.

Registered node identities, genesis, CA private key, accounts, native journals,
old protected role floors, old SQL role scopes and the network grant counter
remain. Fresh TLS/current-next traffic keys and independent deposit/retrieve
issuer keys were rotated by ordinary signed renewal. Existing LAN SANs and CRL
distribution extensions survive; the CRL number advances without dropping
revocations. Only new policy-scoped role roots are enrolled explicitly, with
listeners stopped and actual native state independently reopened. This is not
a data reset or an assertion that all operational keys were retained.

## ACK and retained issuer fixes

- [DR-0162](../../../docs/survival-program/decisions/DR-0162-exact-public-signature-arithmetic.md):
  bounded public Ed25519 arithmetic memo. Positive entries own and compare exact
  key/message/signature bytes; negative results are not cached. Policy, time,
  revocation, floors, endpoints, capabilities and native custody are not cached.
- [DR-0163](../../../docs/survival-program/decisions/DR-0163-historical-store-issuer-succession.md):
  past Store settlement previously tried the current issuer after operational
  rotation. Exact authenticated predecessor PMA/projection facts now verify the
  original grant and both actual signed durable receipts. They cannot authorize
  a new grant, Store or ACK. Current host/time and actual native recovery fences
  remain. Actual API review found exactly two additional verifier methods, no
  new public type/constructor, assembly reference or resource delta. Old public
  API snapshots were replaced, not additionally accepted.
- [DR-0164](../../../docs/survival-program/decisions/DR-0164-received-scope-scheduling-handoff.md):
  receive hands its key-free session scope to ACK scheduling instead of
  reopening/decrypting the catalog a second time. Actual ACK construction still
  reacquires native/catalog/peer/ratchet/materialized/protected-page facts before
  the signer loan. The real reopened-account receive test proves one scope
  lookup instead of two, retaining lost-ACK, cold-reopen and semantic-fault checks.

## Evidence and non-passing receipts

Root receipt directory: `artifacts/cli-nts-activation-20261021/`; CLI runtime,
scenario/module archives and connected receipts are under this repository's
same-named artifacts directory. Runtime inputs are fixed for each run. Heavy
builds, tests and connected measurements run serially.

Matching final focused evidence:

| Scope | Result |
| --- | --- |
| Windows Protocol authority/arithmetic/host/rollover | 318/318 PASS |
| Windows Shared actual mailbox receive/ACK | 5/5 PASS |
| Windows Shared retained read/Store settlement crash cases | 21/21 PASS |
| Windows Node succession/history consumers | 47/47 PASS |
| Linux ARM64 Node / Protocol succession image | 218/218 / 215/215 PASS |
| CLI / scenario contracts | 67/67 / 9 PASS |
| DevOps offline renewal/hostile inputs/retained seals | 126 closed checks PASS |
| DevOps script contracts | 36/36 PASS |
| Production assembly graph Release and Debug | PASS |
| Frozen executable manifest integrity | PASS; 219 mappings preserved |
| CLI ARM64 ReadyToRun publish | PASS; zero warnings/errors |

These are named focused scopes, not an unfiltered source/full or package gate.
The final DevOps rebuild/checks and rechecked Release/Debug graphs plus manifest
integrity also finish native0 after the connected runs (`final-contracts02`).
The final runtime build receipt ends with native1 at the intentional API snapshot
change **after** successful image tests, supported Up/Verify, CLI tests and
publish. The subsequent final-contracts receipt is native0 after reviewed exact
snapshot replacement and manifest regeneration. No failed receipt is relabelled.

Earlier preparation safely rejected an insufficient old operational horizon and
an unrecognized retained physical-peer mapping. The latter was fixed by matching
the exact validated installed ingress, not by widening endpoint trust. The first
activation stopped owners and rejected PowerShell5.1 nested shell quoting before
installation; the same sealed candidate then completed with closed literal
filenames. Failed receipts remain available.

The original strict round36 stopped before ONION on `RouteTimeXRA1Expiry`.
Actual route maintenance reused all accounts and relations. It exposed the old
Store issuer defect above. After that fix the AB pair completed; a newly issued
C threshold correctly refused `RouteTimePMS2NotBefore`. Its exact pending command
was resumed only after real time advanced, then AC and BC completed. Neither
backdating nor permissive time acceptance was added. Maintenance is not itself
group E2E and the partially failed multi-pair receipt is not called PASS.

Six broader Shared crash cases initially failed an old exact `IOException`
assertion. An isolated worktree at the pre-change Shared commit reproduced the
same six failures: actual code returns the more specific
`OutboxPrefixPinnedException : IOException`. The assertion now requires that
exact subtype; failpoint/state assertions remain. That temporary worktree was
removed after the evidence was captured. The first new receive-counter test
measured the fixture's other account instance; it was corrected to observe the
actual reopened account and the final five cases pass.

## Connected results

Recovery36: **49/49 PASS, native0**, `recoveryQualified=true`,
`steadyStateQualified=false`; no automatic Store/mailbox resume, lease wait,
retry, HTTP non-success or abnormal session close. The exact original sender
batch resumes, then all six recipient receive/ACK, three cold full-batch replays,
empty mailboxes, deduplicated native histories and GSR/control checks pass.
Every profile ends with 111 group messages /37 original local commands,
Active3/epoch2. Recovery never qualifies first attempt.

Recovery is **not** the latency baseline: fresh post-rotation grants add ONION
acquisitions. Its original A batch takes92.141s; B/C fanout60.984/66.466s;
receive/ACK30.431/30.473/32.961/22.351/18.044/20.122s;
cold full-batch45.866/39.439/44.413s. Active559.672s,
CLI CPU315.016s, driver wall563.976s. Original failed strict36 is retained.

Runtime fingerprint:
`cd43e1d4b21852689e167ee10fbb135d51b40f51e94500044a8f84cd4a6c69e6`;
scenario:
`c3ce35ceac8ee4096ff13b69bac795415ba9ec2ce131f47e0407abb80be8d8ff`;
session module:
`1961b8787f11725c75c2f4c470b4535f9fb5f2ff4dd85a746be11acf3e8b8687`.

New strict37: **46/46 PASS, native0**, `firstAttemptRequired=true`,
`steadyStateQualified=true`, recovery/delivery-only=false. Same runtime/scenario
as recovery36. No command retries, failed requests, HTTP non-success, automatic
Store/mailbox resumes, lease waits or abnormal session close. All three clients
end Active3/epoch2 with **114 messages /38 original local commands each**.
The run includes all six real receive/ACK, cold native reopen, original full
batch settlement replay, empty mailbox/deduplication and owner/GSR controls.

### Timing comparison

Prior baseline is strict35, not the post-rotation recovery. The number of actual
ONION requests in fanout and receive/ACK is unchanged at6/12. This is successive
retained history across operational succession, **not a causal same-history
A/B**. No general latency improvement is established by these measurements.

| Operation (mean unless marked) | Strict35 | Strict37 | Change |
| --- | --- | --- | --- |
| One command, two-recipient fanout | 32.610s | 38.480s | +18.0% |
| Recipient native receive + ACK | 19.807s | 20.881s | +5.4% |
| Cold original full-batch replay | 32.211s | 44.252s | +37.4% |
| Empty mailbox after replay | 5.998s | 6.473s | +7.9% |
| Active operation time, total | 353.443s | 427.203s | +20.9% |
| CLI CPU, total | 191.844s | 267.029s | +39.2% |
| Driver wall, total | 356.244s | 431.076s | +21.0% |

**ACK latency did not improve against strict35.** The receive scope lookup count
is reduced, but that does not establish a lower delivery duration. Sustained
lifecycle, historical/native work after authority succession, ONION/ACK latency
and the1–2s objective remain open S05 blockers. New functional first-attempt PASS
and NTS redundancy are not release readiness or a claim to be faster than Signal.

All measured strict37 operations, in execution order within each phase; seconds:

| Phase | Individual durations | ONION requests, total |
| --- | --- | --- |
| Account cold status | 0.394 /0.361 /0.361 | 0 |
| Retained pair left lists | 0.610 /0.982 /1.815 | 0 |
| Retained pair right lists | 1.276 /1.926 /1.713 | 0 |
| Retained owner head | 0.216 | 0 |
| Native command preflight | 0.204 /0.191 /0.149 | 0 |
| Native history preflight | 0.509 /0.915 /1.075 | 0 |
| Active owner head | 0.194 | 0 |
| Active recipient heads | 0.193 /0.173 | 0 |
| Original command count | 0.196 /0.175 /3.698 | 0 |
| Two-recipient fanout | 39.137 /39.016 /37.288 | 6 |
| Native receive + ACK | 22.920 /27.411 /17.959 /18.862 /20.101 /18.033 | 12 |
| Cold native group history | 0.652 /0.953 /0.947 | 0 |
| Cold original full-batch replay | 39.213 /47.498 /46.045 | 0 |
| Empty mailbox | 6.378 /7.028 /6.014 | 3 |
| Deduplicated history | 0.421 /0.957 /0.834 | 0 |
| Owner control receipt verification | 2.194 | 0 |
| Empty GSR cursor replay | 3.801 /6.215 | 2 |

Keep these original receipts and continue with cursor38 on the same retained
profiles; do not repeat or replace the already successful cursor37.
