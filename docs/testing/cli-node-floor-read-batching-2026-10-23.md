# Native floor acquisition and retained grant ceiling — 2026-10-23

Scope: SAME three CLI accounts, group revision11/Active3/epoch2. No account,
node key, group state, replay floor, signed interval or resource limit is reset.
Windows/Android, production and GitHub Releases are untouched. Timestamps UTC.
The preceding accepted checkpoint is
[completed51](cli-signed-history-memo-2026-10-23.md).

## Evidence and change

Read-only numeric logs from completed51 locate ONION terminal dispatch, not
layer cryptography, as the main server cost. Typical binding/open phases are
10–20ms; representative terminal dispatch is6.3–12.1s. Mailbox summaries report
132–299 lease checks and2.1–6.6s cumulative lease duration. These nested timings
overlap and are NOT additive critical-path partitions. Server-side origin wait
also occurred once (1.998s), despite zero CLI recovery/lease-wait counters.

Actual native inventory counts249 directory-floor tips on EACH node. Each lease
source still rejoins that complete protected history. Roughly298 x249 is74k tip
acquisitions for such a request, plus anchor/index and other checks: this is an
amplification estimate from source/counters, not a measured syscall total.

The candidate changes native acquisition only: at16+ records, at most4 workers
perform the SAME actual path/ACL/handle/EOF, Data Protection Unprotect and grammar
checks. Existing owner serialization pins the public grammar memo until ALL
workers finish. Ordered signature/lineage, independent anchor, index, scope,
currentness and replay checks remain. Failures drain workers and preserve the
typed first source-order exception. Grammar counts are atomic. There is no
private plaintext/authority cache, new file format, key or signed lifetime.
[Microsoft's consumer API contract](https://learn.microsoft.com/aspnet/core/security/data-protection/consumer-apis/overview?view=aspnetcore-10.0)
allows concurrent IDataProtector calls; no additional crypto stack is introduced.

## Gate and local activation ledger

- Windows `focused01`: native0,66/66,0 skips, genuine32-head chain test plus
  directory proof/current network families. Warm read requires all32 actual
  Unprotect calls PLUS anchor/index, no repeated signature/grammar work. Actual
  ciphertext damage still rejects. An earlier injected IO error wins over a
  later genuine damaged record; no worker remains active on success/failure.
- Linux ARM64 `linux01`: native0,108/108,0 skips, existing node-authority target.
  This is focused, not canonical unfiltered/transport-rehearsal qualification.
- Supported node-only Build/Up/Verify: native0. Registry proof/all three ONION
  capabilities ready after11s, all9 services healthy. Named native-volume bindings
  compare identically before/after (canonical row SHA256
  `F11970121831199C9DA8A51A1C8E63424611D27637B504A77262E6F3DBFC30B8`).
  All three nodes run image
  `sha256:2d0a884512458be36ca021011261c9ed156372405943bd2fb44a71f645fbd8d9`.
  Registry/publisher/signer/ingress images are unchanged in this node-only rollout.

## Original52 failure and bounded scheduling correction

`delivery-52`: native1, first fanout fails at `GrantRouteExpiry`, before a new
Store is captured. A53 is already authored and MUST be resumed; B53/C53 are not
yet authored. Do not create a fresh round52 or reset this state. The failed
receipt stays failed, not a successful timing sample.

DR-0153 now permits ONE uncaptured public-authority discard/re-entry after that
exact built-in exception/closed Protocol label. Different client/issuer closure
ceilings can otherwise strand the existing work. The denial is NOT a valid
signature, current permission or proof of absence. The same owned operation and
captured-original guards re-enter all strict proof/route/issuer/grant checks.
Repeated ceiling denial, other crypto failures and cancellation stop. No
queue/create/group action is replayed, no expiry is extended and no holder or
protected state is reset. This counts as an owned resume, not no-recovery evidence.
Existing signed-lower closure of an expired original acquisition remains separate.

Shared/CLI focused verification and original52 terminal recovery are recorded
below only after native terminal receipts. Full/canonical/package/device/release,
automatic idle-route liveness and the1–2s objective remain open. Parallel I/O
does not remove O(history) validation; its connected benefit is not yet proven.

## Terminal receipts

`recovery01`: native0, Shared18/18 scheduling cases and CLI70/70,0 skips;
published current CLI ReadyToRun runtime. Cancellation, repeated/other crypto
denial and unchanged owned-operation identity are checked. These scheduling
tests are not genuine proof-refresh/socket evidence.

`recovery-52-01`: native0,49/49 PASS,20:17:05.872–20:29:55.131Z. Each retained
CLI now has159 semantic messages /53 original local commands. Original A53 was
flushed, not re-authored; B53/C53 authored once. All exact plaintext/sequence,
cold history, old full-batch replays, empty-mailbox and GSR control cursor checks
pass. Zero Store resumes, ONE mailbox resume/lease wait and ONE ONION non-success
remain visible. Active760.993s/CPU430.094s, scenario wall765.849s. This is original
recovery, not first-attempt/no-recovery timing. Runtime SHA256
`18712a1e0af49f6e8b147c24b2f8146524b5d022b4e2a065b326825ee816eb45`.
The new ceiling-refresh branch did NOT fire in this live recovery: Store resumes
are zero. Fresh command context completed the original; only source tests prove
the new within-command scheduling branch. Do not claim a live reproduction of
that specific branch or general idle-route/NotBefore liveness qualification.

`delivery-53`: native0,40/40 PASS,20:30:46.464–20:36:42.106Z, all commands attempt1,
zero automatic resumes/waits/network failures/non-success. Same three profiles,
now162 messages/54 local commands each, Active3/group epoch2. All six receives
and ACKs, cold exact native histories, empty mailboxes and deduplication pass.
No source/runtime/scenario changes between recovery and this new delivery round.

| Measurement, seconds |Completed51 |New53 |Observed difference |
|---|---:|---:|---:|
| Fanout mean,3 |52.055 |51.299 |-1.5% |
| Receive/ACK mean,6 |22.151 |24.541 |+10.8% |
| Empty mailbox mean,3 |9.882 |9.269 |-6.2% |
| Deduplicated history mean |0.785 |0.785 |approximately unchanged |
| Active commands total |337.379 |350.329 |+3.8% |
| CLI CPU total |146.997 |168.954 |+14.9% |
| Scenario wall |340.508 |353.798 |+3.9% |

This is NOT causal A/B: retained history/grant work and runtime change. Fanout
has6 rather than7 ONION calls, ACK12/12, empty3/3; proofs8/30/3 versus8/30/4.
Overall53 has21 ONION calls (164.785s),41 directory proofs (28.563s) and23 closure
calls (3.390s). Fewer calls alone do not prove an algorithmic latency gain.
The small fanout change with one fewer grant exchange does NOT establish a
benefit of parallel floor acquisition. ACK/CPU/whole-round acceleration and
the1–2s objective are NOT achieved. Both runtimes have actual ReadyToRun native
headers196 bytes for CLI/Shared/Protocol and identical runtime config; a missing
R2R publish is not the explanation. No CPU/kernel profile was collected in53.

All ordinary operation durations in completed53:

| Phase |Count |Mean seconds |Total seconds |
|---|---:|---:|---:|
| Cold account status |3 |0.401 |1.204 |
| Pair left contact list |3 |1.354 |4.063 |
| Pair right contact list |3 |2.053 |6.159 |
| Retained owner head |1 |0.199 |0.199 |
| Command preflight |3 |0.202 |0.606 |
| History preflight |3 |0.938 |2.815 |
| Exact active owner head |1 |0.198 |0.198 |
| Exact active recipient head |2 |0.166 |0.332 |
| Original-command counter |3 |0.193 |0.579 |
| Two-recipient fanout |3 |51.299 |153.898 |
| Recipient receive + ACK |6 |24.541 |147.243 |
| Cold native history |3 |0.958 |2.873 |
| Empty mailbox |3 |9.269 |27.806 |
| Deduplicated history |3 |0.785 |2.354 |
| ALL active commands |40 |— |350.329 |

Next retained cursor54; do not re-author52/53. The next architectural work must
address repeated full-history authority I/O and public-closure cloning per
lease, not another arithmetic memo or a skipped currentness/integrity check.
Any bounded active-floor/checkpoint design needs explicit replay/crash/rollback
proof and authoritative specification first; no historical files were deleted
or native checks waived by this candidate. Canonical full/package/operational/
device/release qualification remains open.

## Final source checkpoint

`final01` is native1: the diagnostic solution build omitted the mandatory
source-cutover properties and selected the wrong Protocol composition, producing
382 missing-type errors. No removed types/compatibility references are restored
to make that command pass. No tests launched after that failed build.

`final02`: native0,20:44:19.686–20:44:47.578Z, Windows PowerShell5.1/SDK10.0.301.
Explicit source-cutover restore plus complete XNode solution Release build pass
with zero warnings/errors. Final Shared21/21 scheduling cases pass,0 skips,
including a derived-exception refusal, failed refresh and already-cancelled
ceiling denial. These extra tests do not change the already-measured runtime.
Production Protocol source/graph, package versions and native assets are not
changed in this slice; restore-only RID/EOF noise is removed.

The next structural candidate is explicitly NOT implemented here: distinguish
the current independently authenticated directory-floor anchor/tip/index from
historical audit material, while full acquisition/recovery/commit still checks
all required lineage and pending descendants. First prove that journal-only
rollback, lost/corrupt current files, pending post-write crashes, key revocation,
scope/clock discontinuity and changed callbacks cannot produce permission.
Any change in historical-integrity observation must be reviewed explicitly,
not silently traded for speed. No checkpoint format, history deletion, prefix
retirement or new trust rule was introduced by this I/O-only candidate.
