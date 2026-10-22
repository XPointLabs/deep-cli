# Signed-history arithmetic and retained CLI recovery — 2026-10-23

Scope: SAME retained three CLI accounts, group rev11/Active3/group epoch2.
Windows/Android, production and GitHub Releases are not touched. No account,
identity, native state, replay floor, signed interval or capacity is reset/raised.
Run timestamps below are UTC; repo artifacts use `cli-ack-profile-20261022`.

## Evidence before optimization

Previous completed49: fanout mean47.750s, receive/ACK24.125s; entire active
round331.734s, CPU176.349s. Group decode accounts for only0.558s over SIX
receive/ACK commands: caching that parsed state cannot explain24-second ACK.
The three group sends have6523 protected aggregate reads and947 native SQL
verifications. These nested measurements overlap; do not add their totals.

Exploratory direct probes use the SAME published04 runtime and retained A/B.
They are NOT clean performance/E2E acceptance receipts:

- `receiver01` native1: own-publication maintenance refused PMS2 NotBefore,
  BEFORE a message was queued. The exact pending successor remained retained.
- `receiver02` native1: actual direct Store and receive/ACK returned success
  (processed1/tombstones1,29.153s). Diagnostic collector was force-stopped;
  trace incomplete and later history/empty checks did not run. No acceptance.
- `receiver03` native1: direct receive/ACK35.376s, CPU11.500s, processed1/
  tombstones1, no recovery. Trace is readable, but harness completion failed
  before native-history/empty checks. Original failed receipts stay failed.
  Experimental profiler script changes were removed; no broken harness ships.

Raw trace and converted stacks stay in private local custody, never this repo.
Sampled managed thread time includes waiting threads and is NOT kernel CPU.
Within samples of `PublicKeyAuth.VerifyDetached`, the nearest Protocol caller
`XPointOnionCapabilityProducer.VerifyEd25519` accounts for1704 sampled thread-ms,
versus204 for holder signature verification. This identifies a candidate for
investigation, not a precise CPU percentage or a complete latency root cause.

## Bounded arithmetic correction

[DR-0162](../../../docs/survival-program/decisions/DR-0162-exact-public-signature-arithmetic.md)
now uses O(1) random replacement instead of FIFO. A sequential scan larger than
a FIFO memo can evict every upcoming tuple on every pass. The new policy changes
only residency of native-verified exact PUBLIC key/message/signature bytes.
SHA-256 is still an index, never a positive decision: all exact bytes compare.
Only successful native verification inserts; negatives/malformed/large inputs
remain uncached. Entry4096/8MiB/64KiB limits and all independent current policy,
scope, lineage, clock, threshold, membership and replay checks remain unchanged.
Randomness selects an evicted PUBLIC arithmetic entry; it is not cryptography,
an authority source or a persisted trust decision. No suite/wire/API/reset change.

Fixed-seed source comparisons (NOT connected latency):

| Capacity |Distinct tuples |Passes |Native verifications |FIFO sequential misses |
|---|---:|---:|---:|---:|
|4 |6 |16 |55 |96 |
|24 |32 |12 |195 |384 |
|64 |80 |8 |269 |640 |

All exact-input ownership, changed key/message/signature, repeated negatives,
byte/entry bounds, large-input bypass and concurrent positive-hit tests remain.
The capacity test keeps its exact native-verification assertions using a fixed
eviction seed; no assertion is waived to permit a different result.

## Gate and connected ledger

- `memo01`: native0,8/8 Protocol cases, including actual fixture preflight.
- `memo02`: native0, Protocol319/319, CLI70/70,0 skips; current network/issuer/
  host/expiry/hostile/callback cases and actual memo tests. Published01 CLI.
- `delivery-50`: native1,25 steps. Original A51 was authored and delivered;
  B51 was authored but stopped on peer XRA1 expiry before a new Store. C51 was
  not authored. Keep this original batch; do not rerun50 as a fresh round.
  First A fanout45.625s/CPU18.203s, receive/ACK20.989s and37.032s. These partial
  numbers are diagnostic, NOT a completed improvement claim.

Supported same-peer route maintenance and original50 recovery follow below
only after terminal receipts. Unfiltered/package/device/release, automatic
NotBefore scheduling/idle peer-route liveness and overall ACK latency remain open.

## Retained local maintenance

- `repair-a-bc01`: native0,21/21 PASS; existing A/B and A/C introductions,
  actual native control Store/receive/ACK and independent current-route checks.
- `repair-b-c01`: native0,11/11 PASS; the remaining existing B/C pair. Neither
  helper creates a new identity, group, invitation or replacement user message.
- `linux-memo01`: native0; actual Linux ARM64 XNode218/218 and Protocol218/218,
  zero skips, via the existing `time-source-succession-tests` Docker target.
- `contour-build01`: native0; supported Build of the shared Protocol consumers
  (Registry, publisher and common three-node image), with retained sealed inputs.
- Native `contour-up01` and `contour-verify01`: both0. Registry proof and all
  three verified ONION capabilities ready after20s; all9 services healthy.
  All three nodes use image
  `sha256:3b118cc33b9f6cb013a9c33c70b08f09e97e0bd0debd75b197ab883c87523214`.
  Registry image is now
  `sha256:507c7c2015fc4ca5d7b87e55d811ae4873f5700dddc577d93ff3da79447311c7`;
  this is LOCAL development only, not production deployment/release evidence.

An additional host-side whole-mount JSON equality assertion failed AFTER the
successful native Up/Verify. Its before snapshot was not retained; exact mount
metadata equality is therefore NOT qualified. Subsequent read-only Docker
inspection confirms28 pre-existing named volumes, zero newly created volumes,
and all9 healthy services. No reset/provision/authority-authoring command ran.
Do not turn the failed auxiliary assertion into a passing rollout/custody gate.

## Original50 terminal recovery

`recovery-50-01`: native0,51/51 PASS,19:23:25.513–19:31:46.992Z.
Same three accounts now each retain153 semantic group messages /51 original
local commands, Active3/group epoch2. Original B51 was flushed, not authored
again; the previously unauthored C51 was authored exactly once. The original
A51 remained unique. Actual cold history, exact plaintext/sequence checks,
three full old-batch replays, empty mailbox/ACK and GSR control cursor replay pass.
Runtime fingerprint remains
`bb7fd56d16d15e8cd01d0fcd060dbe2d61733f9863fa85404a66bbe3cae42c63`.

There is ONE automatic mailbox resume and ONE actual lease wait, zero Store
resumes, zero failed network requests and ONE ONION non-success. This is
successful ORIGINAL recovery, NOT a no-recovery/first-attempt latency claim.
Active commands495.706s/CPU303.845s; scenario wall499.709s. The three explicit
cold full-history replays take51.479/51.831/47.950s (CPU50.594/51.375/45.234s);
they are additional recovery validation, not ordinary new-message delivery.
Next new delivery cursor51; never re-author50 as another batch.

## New51 delivery terminal and comparison

`delivery-51`: native0,40/40 PASS,19:32:31.939–19:38:14.270Z. All40 commands
attempt1; zero automatic Store/mailbox resumes, lease waits, network failures
or non-success responses. Same runtime, profiles and group; no intervening
build/reset/repair after original50 recovery. Each CLI retains156 messages /
52 original local commands, including each new sender/sequence exactly once.
Cold history, all six recipient receive/ACKs and three empty mailboxes pass.
Delivery-only is not fresh group lifecycle, retention, device or release evidence.

| Measurement, seconds |Completed49 |New51 |Observed difference |
|---|---:|---:|---:|
| Fanout mean,3 commands |47.750 |52.055 |+9.0% |
| Receive/ACK mean,6 commands |24.125 |22.151 |-8.2% |
| Empty mailbox mean,3 commands |7.533 |9.882 |+31.2% |
| Deduplicated history mean |0.932 |0.785 |-15.7% |
| All active commands |331.734 |337.379 |+1.7% |
| Total CLI CPU |176.349 |146.997 |-16.6% |
| Scenario wall |335.548 |340.508 |+1.5% |

These are observed runs, NOT causal A/B. Fanout has7 rather than6 ONION calls
(per sender2/3/2), while receive/ACK has12 rather than13. Directory proofs are
8/30/4 for fanout/ACK/empty versus8/32/3 before. The mandatory extra grant
exchange is not duplicate Store and is not removed to improve a benchmark.
Network-operation totals for fanout89.210s versus67.447s before, ACK95.893s
versus93.789s and empty19.058s versus14.251s. Nested network/CPU measurements
are NOT additive causal critical-path attribution. No server CPU profile or
actual production memo-hit counter was collected; oversized-scan tests cannot
prove that this specific history thrashed the old memo.

New fanout times48.281/60.711/47.173s, CPU21.938/26.984/24.281s. Aggregate
fanout CPU73.203s versus85.219s, ACK CPU42.766s versus57.392s before. CPU and
ACK improved in this observation, but TOTAL delivery/fanout acceleration and
the1–2s objective remain NOT achieved. Next work is actual ONION/authority
waiting and native/persistence amplification, not another group-codec cache.

All ordinary CLI operation durations in completed51:

| Phase |Count |Mean seconds |Total seconds |
|---|---:|---:|---:|
| Cold account status |3 |0.348 |1.043 |
| Pair left contact list |3 |1.140 |3.421 |
| Pair right contact list |3 |1.570 |4.709 |
| Retained owner head |1 |0.175 |0.175 |
| Command preflight |3 |0.173 |0.519 |
| History preflight |3 |0.822 |2.467 |
| Exact active owner head |1 |0.202 |0.202 |
| Exact active recipient head |2 |0.167 |0.333 |
| Original-command counter |3 |0.156 |0.467 |
| Two-recipient fanout |3 |52.055 |156.165 |
| Recipient receive + ACK |6 |22.151 |132.906 |
| Cold native history |3 |0.990 |2.971 |
| Empty mailbox |3 |9.882 |29.645 |
| Deduplicated history |3 |0.785 |2.356 |
| ALL active commands |40 |— |337.379 |

Next retained delivery cursor52; do not re-author completed50 or51. Private
traces remain private. Production, Windows/Android and GitHub Releases remain
untouched. Canonical unfiltered/package/operational/device/release gates,
automatic NotBefore scheduling and idle peer-route liveness are still open.

## Production graph review

`final-protocol01` and `graph-release-review01` are native1, NOT passing gates:
both builds are warning/error-free, but the raw Protocol metadata snapshot
differs after internal cache-container TypeRef/signature-index renumbering.
The row count stays12989. Read-only reflection against the prior approved
published04 assembly finds15093 IDENTICAL decoded API/resource/reference rows;
canonical semantic SHA256
`DD1A3A11D12598AC63DFFC9AF98B7CF4FCDF4A4EFEC0BE7FE0B1F5681D2C5AD2`.
The prior binary also passes the existing strict actual-assembly graph tool.
This diagnostic does not substitute for final graph acceptance. Only the two
exact current Debug/Release hashes are rebound after that review; both previous
hashes are removed. No extra accepted predecessor or relaxed assertion is added.

`final-protocol02`: native0,19:46:44.464–19:47:13.044Z, Windows PowerShell5.1 /
SDK10.0.301. Both Debug/Release builds have zero warnings/errors. Strict
actual-assembly/resource/public-API and exact-three source/build/lock graph
gates PASS for both configurations. Executable manifest INTEGRITY ONLY PASS;
regeneration changes exactly its implementation-scope hash, not mappings/cases
(219 of314 frozen IDs remain mapped). No executable-case discovery or full
evidence qualification is implied. Focused Protocol319/319 passes again after
the graph/manifest correction; zero skips, other two project receipts are exact
zero-case filtered receipts. Temporary restore-only lockfile EOF changes are
removed; no package versions/content hashes or production dependencies change.
