# ONION request and local verification latency

Scope: retained local real Registry/three-XNode topology and three CLI profiles.
No production, MAUI, Android, account reset or new cryptographic stack is involved.
This checkpoint is not release, device, full source/package or carrier acceptance.

## Bounded implementation changes

- XNode reuses HTTP/2 sockets only inside the same immutable verified network
  object and exact selected public next-hop binding. A different context/view,
  node/origin/address/pin cannot borrow that entry. The pool has16 retained
  entries, two-minute resource age, one-minute socket idle and draining active
  leases. Capacity uses non-retained one-shot transport. TLS resumption is off;
  the intersection of authenticated certificate validity is checked after headers
  and body, including clock rollback before `NotBefore`; another handshake cannot
  widen it. Each request still signs
  fresh peer authentication and traverses actual ONION/replay/authority owners.
  No automatic dispatch retry is added. See the
  [network owner](../../../docs/architecture/XPOINT-NETWORK-V1.md#11-request-circuit-and-operation-state-machines).
- Entry and peer TCP sockets use no-delay. This changes packet scheduling only,
  not TLS, canonical framing, privacy paths, timeouts or uncertainty semantics.
- Native ordinary-message preparation verifies complete policy/schema, retained
  prefix, journal/rows and independent protected floor in one SQL read snapshot.
  Exact replay selection, retention digest and current ratchet read use that
  same snapshot, without an await, callback or mutation. Actual commit/recovery
  and post-effect read-back remain independent; nothing is memoized across calls.
- Read-only secure-storage reads authenticate the complete actual aggregate and
  validate all slot encodings, lengths, ordering and trailing bytes, but allocate
  value buffers only for requested slots. Unselected malformed entries still
  reject. Mutation loads remain complete. All decrypted aggregate and temporary
  values are wiped; no private state or previous successful verification is cached.
  Vectorized slot checks preserve the exact control/surrogate rejection policy.
- Local group history and batch scheduling select at most32 operations per SQL
  snapshot, with complete journal/prefix and unselected-row verification. Inputs
  are bounded/copied before the snapshot, results are owned/disposed, and original
  cross-scope display order is preserved. No await/callback or validation memo
  crosses that batch; later effect owners still rejoin actual state themselves.
- Account registration reuses only a pure canonical-grammar predicate for exact
  current group/ordinary bytes and every network/account/instance binding. Two
  owner-local32-byte digests retain no private values, decoded states or authority.
  Every actual storage authentication, SQL integrity check, dynamic cancellation
  owner join and effect fence remains. Changed bytes/bindings rerun the original
  decoder; errors are never cached. Actual business consumers decode needed
  roots themselves, not from this registration grammar result.

No protocol bytes, protected/SQL format, floor, signed lifetime, quorum, original
Store/ACK identity or failure classification is relaxed. Client entry handlers
remain path-specific; this node-hop socket pool does not implement a shared
client circuit or claim the network `Ready` probe requirement is satisfied.

## Competitor comparison: applicable principles, not imported stacks

[Signal Double Ratchet](https://signal.org/docs/specifications/doubleratchet/#encrypting-messages)
derives a new message key from maintained sending-chain state. Its
[Sesame session management](https://signal.org/docs/specifications/sesame/#sending-messages)
uses an existing active device session and updates device/session selection when
necessary. The useful inference for Deep is to keep established ratchet state
and separate session setup/current authority maintenance from ordinary delivery;
not to redo bootstrap or audit all historical successful messages on every send.
This does not authorize ignoring Deep's current floors, expiry or revocation.

[SimpleX SMP's transport specification](https://github.com/simplex-chat/simplexmq/blob/stable/protocol/simplex-messaging.md#transport-connection-with-the-smp-router)
authenticates a router over a TLS connection and binds transmissions to the
connection handshake. It explicitly disallows TLS session resumption and
describes separate queue connections for stronger metadata privacy. This
supports careful scoped connection reuse, not a global pool across accounts or
arbitrary certificate pins. Deep retains its own framing and per-request
authentication; the SMP channel-binding protocol is not transplanted.

[.NET HTTP lifetime guidance](https://learn.microsoft.com/en-us/dotnet/fundamentals/networking/http/httpclient-guidelines)
explains the cost of repeatedly disposing clients and their connection pools.
The hop-local bounded pool applies that resource principle without caching
transport responses or treating a socket as a current-authority capability.

These sources do not establish a Signal-versus-Deep latency result. Three ONION
hops, replicated durable Store and semantic receive/ACK have different work from
a centralized transport. A claim of parity requires comparable measured delivery
semantics, topology, hardware and load; no such external benchmark is claimed.

## Verification ledger

Artifacts below are repository-local ignored receipts, not committed raw logs.

| Repository / run | Result | Scope |
| --- | --- | --- |
| Node `artifacts/cli-onion-20261020/focused-01` | Compile failed | Initial diagnostic omitted the repository's required source-cutover property; not a source-test PASS |
| Node `focused-02` | FAIL | The new real-TLS fixture used a Windows ephemeral certificate key unsupported by its Kestrel handshake; fixture fixed by the existing PFX import pattern, with temporary PFX wiped |
| Node `focused-03` |55 PASS/native0|Pinned certificate, pool lifecycle, real H2 connection reuse, privacy runtime/native C3 cases |
| Node `focused-04` |56 PASS/native0|Final source, also rejects clock rollback before the authenticated certificate start |
| Shared `artifacts/cli-onion-20261020/shared-01` |62 PASS/native0|Exact native SQL replay, unrelated-row corruption, compacted history, policy/schema and checkpoint cases |
| Shared `shared-02` |61 PASS/native0|Final selected-read implementation, unselected corruption, whole-plaintext wiping, actual-file reacquisition, guarded cleanup, real native group custody |
| Shared `shared-03` |24 PASS/native0|Bounded native SQL batches, ordered/missing selectors, unselected TEXT/ciphertext/deletion rejection without mutation, real native group custody |
| Shared `shared-04` |24 PASS/native0|Exact grammar inputs, actual storage reauthentication, changed/invalid roots, account owner, expired/rolled-back read scope and lost ACK |
| CLI `artifacts/cli-onion-20261020/build-01`, `unit-01` |Zero warnings/errors;63 PASS/native0|All-Release shipping graph and actual loaded-dependency optimization checks |
| CLI `build-02`/`unit-02`, `build-03`/`unit-03` |Zero warnings/errors;63 PASS/native0 each|Batch-read and registration-grammar shipping graphs |
| CLI `build-04`/`unit-04` |Zero warnings/errors;64 PASS/native0|Final runtime with closed numeric JIT diagnostics; diagnostics cannot change delivery or authority decisions |
| DevOps `artifacts/cli-onion-20261020/node-build-01`, `node-build-02` |Native0|Intermediate and final node-only supported builds |
| DevOps `node-up-01`, `node-up-02` |Up/native0; diagnostic postcheck rejected|Raw mount hash comparison detected Docker host-path spelling changes; follow-up exactly reproduced each old hash by changing only the same configuration file's host-path alias. No mount target, access mode, retained state/key volume or CPU limit changed |
| DevOps `smoke-01` |PASS/native0|Supported current-dev proof/ONION readiness, not message or device acceptance |
| DevOps `artifacts/rehearsals/multi-node/20261019T204813537Z-78683fd7047d` |PASS/native0|Required isolated three-node rehearsal: real Xray/no mock, Registry sees3 nodes, no reconciliation issues; privacy endpoint correctly503 without verified authority. Not authenticated message acceptance |

The pure synchronous decoder allocation test proves at least1 MiB less temporary
value allocation for an unrequested1 MiB slot. It is not a delivery benchmark.
All65,536 UTF-16 characters are compared with the prior control/surrogate policy.
Actual file reads retain independent authentication and process/storage leases;
mutation paths still load and preserve the full inventory. The final group/native
and connected tests use the real production path, not the decoder reflection seam
or resource-test fake handlers as transport evidence.

Final node image:
`sha256:e904a10e188f522577214543c6c19d2b16a307b6023f89320c73c2c48c6481aa`.
All three nodes retain one CPU and nine mounts. The previous complete baseline
is [the message-latency checkpoint](cli-message-latency-2026-10-19.md).
The separate rehearsal ran only after the final timed round stopped. Its fixed
isolated project and ports were verified unused before launch; its newly created
ephemeral services/volume/network were cleaned up by the supported script.

## Intermediate connected round: functional PASS, latency target not met

`artifacts/cli-onion-20261020/steady-01/receipt.json` is **PASS,46/46**, all driver
attempts1, zero Store/mailbox resumes or lease waits, normal session closure.
Runtime `de458aad3dd87fd726898275a0f7c386217bb5d04109e0e90ffabc2ac78405b6`.
It ends at21 messages /7 local commands per profile; cold replay audits22/15/15
original items. No account reset, pending replacement or manual repeat occurred.
The later SQL batch/registration grammar changes were NOT in this runtime.

| Operation family | Prior complete run, s | Intermediate run, s |
| --- | ---: | ---: |
| Three fanouts |256.742|289.188|
| Six receive/ACKs |228.180|237.167|
| Full cold original-batch audit |69.318|80.531|
| All46 active command times |632.739|705.378|
| All46 process CPU time |260.486|324.998|

The total active-command time regressed **11.5%**; this round is not presented as
an acceleration. Fanout ONION RPC time alone was147.839→147.513s, essentially
unchanged, while local CPU/history work grew. Larger retained history, grant/time
state, cold processes and background service activity prevent causal attribution
from these two whole-round samples alone. No non-success HTTP response or owned
retry was observed in this intermediate round.

## Matched local-history comparison

`matched-read-01/receipt.json` compares the exact archived prior all-Release
runtime with the intermediate batch-read runtime
`29279775112acd5dc2f4430aca1c49673b06ef7e915239f03099133f74ffe906`.
Both binaries' complete fingerprints are checked before/after. The same retained
three accounts each have21 messages /7 local commands. Each host warms once and
performs three measured local history reads; version order is reversed for B.
No account/data clone, reset, send, authority substitute or protocol fallback
is used. The archived current-DID2 binary is a measurement input, not a shipped
compatibility reader. The later registration-grammar optimization is NOT included.

| Candidate | Prior runtime mean, ms | Batch runtime mean, ms | Change |
| --- | ---: | ---: | ---: |
| A |412.7|232.0|−43.8%|
| B |2514.3|2128.7|−15.3%|
| C |5335.0|4864.7|−8.8%|

This isolates a local-read gain in that sample, not a full delivery or
Signal-speed claim. Subsequent same-data samples expose substantial variability:

| Candidate | Batch + grammar (`matched-read-02`), prior→new mean ms | Final diagnostic runtime (`matched-read-03`), prior→new mean ms |
| --- | ---: | ---: |
| A |435.3→203.7|387.7→212.7|
| B |1893.3→1636.7|2532.3→2402.7|
| C |3651.3→4472.0|5018.0→4998.3|

Each comparison has18 measured reads, the same21 messages /7 local commands,
one warmup per host and no state reset. Runtime fingerprints:
`matched-read-02`: `f87d766bd7341aac8e18295e8ddf10b4cd6c434c8a1cbc8621804d3b284cf1bb`;
`matched-read-03`: `8a6816e228cd453473a223553b2132c7f863363954137461eaa49e08fd098d67`.
The C regression in sample02 is retained, not averaged away or retried as PASS.

The final CLI reports only process-wide numeric
[JitInfo](https://learn.microsoft.com/en-us/dotnet/api/system.runtime.jitinfo?view=net-10.0)
deltas (compilation time, method count and IL bytes). These include background
tiered compilation, so they do not attribute CPU to a particular verifier or
prove that compilation caused an operation's delay. Native ML-DSA binding uses
the hash-pinned native library, not a per-operation collectible managed assembly.
No compiler-policy switch, crypto replacement or verifier trust bypass was made.

## Final-runtime strict round7: FAIL, retained original work

`steady-02/receipt.json` captures the final diagnostic runtime above and frozen
scenario/module. It stopped at command21:20 successful commands followed by
the first fanout failing `ProtectedState / RouteTimeXRA1Expiry` in
`DeepIdV2RouteTimeCoverage.Require`, reached through the authenticated peer-route
read. There was no driver retry, Store/mailbox resume, lease wait or abnormal
session close. Both attempted ONION requests returned successful HTTP responses;
the full fanout nevertheless **did not finish**. Its57.775s is failed partial
work, not a faster successful send and not comparable with the prior full fanout.

Read-only post-failure native history inspection (`retained-state-counts.json`):

| Candidate | Members / epoch / state | Messages | Local semantic commands |
| --- | --- | ---: | ---: |
| A |3 /2 /Active|22|8|
| B |3 /2 /Active|21|7|
| C |3 /2 /Active|21|7|

No new accounts, replacement logical commands, route substitution, data reset,
expired-route exception or altered signed lifetime was used to hide this FAIL.
The original A command remains owned; neither a successful two-target Store nor
any receive/ACK from this round is claimed. B/C's eighth commands do not exist.
**Do not rerun strict round7 or advance directly to8.** First close the existing
authenticated route-update/expiry-gap lifecycle, recover the exact original A
batch and separately qualify the missing semantic operations and receipts.

The existing CLI idle owner maintains working public group authority, not delivery
of adopted route successors to established contacts. Account permanent-publication
renewal and owned ratcheted route-update primitives exist, but they are not a
complete connected expired-mutual-reachability recovery. The relevant owners are
[transport-neutral contact route-update channels](../../../docs/architecture/TRANSPORT-NEUTRAL-MESSAGING.md#5-contact-bootstrap-без-циклической-зависимости)
and [DR-0072](../../../docs/survival-program/decisions/DR-0072-did2-route-renewal-lineage.md).
Historical predecessor verification cannot authorize a new Store on an expired
route. Fix the connected lifecycle, not its current-route rejection or the test.

## Complete operation timing ledger

Times sum active command wall time within each family, seconds. Both earlier
columns are complete46-command rounds. The final column is **incomplete21
commands** and must not be used as an overall acceleration result. Different
history/freshness/grant/cold-process state also limits causal attribution.

| Family (complete count) | Prior baseline | Intermediate | Final-runtime round7 |
| --- | ---: | ---: | --- |
| Cold account status (3) |2.463|2.735|1.779 (3) |
| Cold pair-left list (3) |5.327|7.254|6.885 (3) |
| Cold pair-right list (3) |19.071|25.762|23.795 (3) |
| Retained owner head (1) |0.224|0.301|0.251 (1) |
| Native command preflight (3) |0.665|0.900|0.827 (3) |
| Native history preflight (3) |6.947|8.914|7.849 (3) |
| Exact owner head (1) |0.218|0.234|0.211 (1) |
| Exact recipient heads (2) |0.421|0.429|0.460 (2) |
| Original command counts (3) |0.559|0.673|0.235 (1/3) |
| Two-recipient fanout (3) |256.742|289.188|FAIL57.775 (1/3) |
| Receive / durable ACK (6) |228.180|237.167|Not reached |
| Cold native history (3) |7.028|6.779|Not reached |
| Cold full original-batch replay (3) |69.318|80.531|Not reached |
| Empty mailbox (3) |19.174|22.314|Not reached |
| Deduplicated history (3) |6.810|8.454|Not reached |
| Owner control receipt audit (1) |0.337|0.496|Not reached |
| Empty GSR cursor replay (2) |9.255|13.247|Not reached |
| **All active commands** |**632.739**|**705.378**|**100.067, incomplete/FAIL** |
| Process CPU |260.486|324.998|63.107, incomplete |

Final-round wall envelope104.148s. Lower local-read allocation/repeated SQL work
is implemented and source-tested; a complete final-runtime delivery improvement,
first-attempt recovery, Signal parity and release readiness are **not proven**.
