# Retained CLI critical-path attribution — 2026-10-21

This continues the [cursor19 checkpoint](cli-node-authority-latency-2026-10-21.md)
on the SAME three accounts/group/epoch2 and local `deep-dev-current` network.
No reset, rekey, native history deletion, replacement batch, production change,
Windows/Android client work or protocol/crypto change. CLI/Shared shipping
binaries are unchanged. This is not full/package/device/release acceptance.

## Measured and source-confirmed sources of repeated work

### 1. A failed IPv6 localhost connection, not slow TLS or proof cryptography

An isolated read-only HOST probe uses the actual shipping Shared factory,
app-scoped development CA, exact HTTP/2, online revocation and system-proxy
policy. It sends the existing public NCQ2 to the Registry closure endpoint;
no account API, evidence mint, private route or native custody is involved.
The diagnostic keeps only fixed numeric timings/status/length, not addresses,
headers, bodies or event activity identifiers.

| New client | Complete before, ms | Socket before, ms | TLS before, ms | Complete after, ms | Socket after, ms | TLS after, ms |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| First |2199|2033|75|426|1|292|
| Second |2073|2023|19|43|0|12|
| Third |2075|2030|20|32|0|12|

DNS returned IPv6 first. Its actual loopback socket attempt took2035ms and
failed `ConnectionRefused`; IPv4 connected in0ms. This agrees with the2.03s
socket timing, whereas Registry-container strict-H2/CA reads took13–273ms
including the roughly1.92MB response. Already connected HOST reads took
14/22/12ms before and19/11/19ms after. These are diagnostics, not sustained
latency distributions. The first corrected cold request is NOT omitted.

The supported dev Compose Registry already published IPv4 loopback but not
IPv6. It now publishes BOTH loopback families on its existing port; the explicit
physical/LAN listener remains unchanged. No new public interface, certificate,
proxy bypass, permissive TLS callback or client endpoint override is introduced.
Both project renderings and physical overlay endpoint sets are tested exactly.
This fixes the demonstrated Registry delay; the signed numeric-IP ONION
connector does not use DNS, so this is not falsely attributed to every hop.

### 2. Repeated whole native ledger parsing, not onion-layer cryptography

New optional numeric resource diagnostics distinguish ONION binding/open,
forward, native dispatch and seal; native diagnostics distinguish initial
admission, intent, local mutation, remote replication and completion. Origin
waits are measured without changing the DR-0151 `lead+1` scheduling or any
authenticated clock check. All observations are bounded/throttled, failure-safe
and contain no identities, operation payloads, routes, capabilities or headers.
The buckets are nested observations, NOT an additive CPU/wall partition.

On retained direct A-to-C traffic, binding/open were around10–31ms per hop and
seal14–25ms. Long forward time was downstream work, not an intrinsic10-second
ONION timer. One actual Store dispatch took16.336s: initial admission2.502,
intent1.158, local mutation1.203, remote HTTP3.261 and completion6.581s. The
remote receiver itself took3.207s, leaving only about54ms for that connection/
forwarding difference: fresh peer TLS is inefficient but NOT the main cause
in this observation. A subsequent ACK's remote work included a genuine2.002s
origin wait; it is not a grace period and remains required.

Actual native directories contain roughly1.5–1.9 thousand files; the largest
ledger files are2.3–4.0MB. `MailboxClientOperationLedger.LoadAsync` previously
deserialized the complete JSON on EVERY load, although its lease-scoped
structural-validation memo already recognized the same actual hash. Those
loads repeat within admission and native completion. The correction reuses ONLY
detached parsed grammar under the same actual operation lease after matching
the complete newly read bytes/length/SHA. Independent custody/MAC verification,
post-callback full file hash/readback, `RequireDocumentSnapshot`, lease/time,
native replay/intent and every existing effect fence STILL execute each time.

Every mutable dictionary and nested Store/ACK array is copied; callbacks and
consumer mutations cannot alter the memo. One snapshot up to8MiB per actual
lease is a resource bound only: larger valid files retain the old streaming
path. Buffered input is wiped, CWT values do not own their lease, and disposal
clears the memo. The same stream JSON parser preserves BOM behavior. No file
format, durability/fsync, source permission or captured lifetime changes.
A separate bounded reviewer found no blocking issue; executable tests and real
traffic, not that review alone, determine qualification.

### 3. Per-chunk synchronous disk writes to an unpublished JSON scratch file

The whole native operation document is serialized repeatedly while a Store or
ACK progresses through replay, exact intent and quorum settlement. Static
normal-Store analysis identifies seven full-document saves on the coordinator
and three on the remote replica; these are source-path counts, not profiler
counters. `SaveAsync` opened each GUID scratch file with `WriteThrough`.
On Linux this requests `O_SYNC`, so serialization chunks force synchronous
storage work even though the complete file is explicitly flushed again before
it can become a protected pending candidate. See the
[pinned .NET runtime implementation](https://github.com/dotnet/runtime/blob/v10.0.0/src/libraries/System.Private.CoreLib/src/Microsoft/Win32/SafeHandles/SafeFileHandle.Unix.cs#L275).

The minimal correction removes that option ONLY from the unique unpublished
operation scratch. Complete `Flush(flushToDisk: true)` still precedes
`PrepareAsync`; protected pending/commit, exact hashes/readbacks, atomic replace,
and every file/parent-directory barrier remain. An interrupted serialization
cannot authorize a prefix or publish an intent. The existing normative
[custody ordering](../../../xnode/docs/mailbox-operation-custody.md) is unchanged.
Independent code review found no blocking durability regression. Three focused
real-native-barrier cases cover success and interruption before/after replace;
actual gate and post-deployment measurements, not source review, qualify it.

Remaining history amplification is explicit: new actual snapshots still require
full validation/serialization and actual file/native inventory checks. This is
not a hidden whole-authority cache or a claim of constant-cost persistence.

## Diagnostic direct pairs (not the final group comparison)

`direct-01` and `direct-02` each pass all9 operations on the retained A/C pair:
queue exact original text, Store, native receive/ACK, exactly-once history and
empty poll; no implicit retry/reset. The latter includes dual-loopback and
additional timings, but PRECEDES the ledger grammar correction.

| Command, seconds | direct-01 | direct-02 |
| --- | ---: | ---: |
| Sender cold contact list |1.090|1.156|
| Receiver cold contact list |1.570|1.499|
| Sender network verify/publication |11.913|7.123|
| Receiver network verify/publication |13.300|8.602|
| Queue original text |2.152|2.188|
| Store original text |24.947|23.490|
| Native receive/ACK |33.295|25.436|
| Cold native history |1.262|1.136|
| Empty mailbox poll |5.833|6.670|

Sequential samples include real control-plane and history differences; do not
present these as a controlled Signal comparison or an established1–2s target.

## Qualification and retained group measurements

The first corrected retained cursor20 completed 46/46 PASS, all driver attempts1,
same runtime/scenario fingerprints as cursor19. All three participants have
63 messages /21 original local commands, Active3/epoch2. Every original fanout,
receive/durable ACK, cold full-batch replay, dedup and empty mailbox/GSR check
passed. It did include ONE owned mailbox resume and ONE protected lease wait;
one ONION HTTP non-success is retained, not hidden by final exit0.

| Delivery observation, seconds | Before cursor19 | Corrected cursor20 |
| --- | ---: | ---: |
| Fanout A |49.339|49.683|
| Fanout B |42.455|59.595|
| Fanout C |57.263|58.655|
| Fanout mean |49.686|55.978|
| Receive/ACK 1 |29.624|32.368|
| Receive/ACK 2 |38.979|27.220|
| Receive/ACK 3 |31.661|33.657|
| Receive/ACK 4 |31.956|33.557|
| Receive/ACK 5 |33.228|63.327|
| Receive/ACK 6 |33.412|25.060|
| Receive/ACK mean |33.143|35.865|
| All 46 commands, active |499.376|524.185|
| Complete driver wall |506.619|531.704|
| All command CPU |230.453|239.314|

Cursor20 is NOT an overall latency improvement. Fanout ONION requests changed
from8 to11 (83.142→101.012s total); receive/ACK from14 to16
(95.987→103.910s). Public DirectoryProof + NetworkClosure work became much
cheaper, but this did not offset the extra native work and recovery wait.
The histories and authenticated operation counters advance between samples;
these are retained successive rounds, not identical snapshots.

The63.327s ACK includes the existing fixed35s owned `RetryLease` delay in
`OwnedMailboxRecovery`, not an ONION socket or crypto delay: its three ONION
requests total13.984s, other HTTP4.873s, CPU9.625s. The other five ACKs average
30.372s. Subtracting the wait would give28.327s, but that is diagnostic
attribution ONLY, never a reported replacement latency or recovery-free PASS.
The35s helper delay is conservative, not the exact protected reservation
duration: the native owner's actual stored `NotBefore` remains authoritative.
Neither that floor nor this helper schedule is changed in this slice.

### Final scratch-fix round and all operation totals

Cursor21 was completed immediately after cursor20, BEFORE the scratch-write
correction:46/46 PASS with no owned recovery, wait, failed/non-success HTTP or
driver retry. Final cursor22 runs the corrected node image on the SAME retained
three profiles, unchanged CLI/scenario, without resetting any account/history.
It also passes46/46 with all attempts1 and ALL those exceptional counters0.
Every participant ends at69 messages /23 original local commands, Active3/epoch2.
Session closure succeeds. Runtime SHA256 remains
`7881ea90805cf732db00128521b1694c307a07fa7eeca07eb8f283f87768f036`;
scenario SHA256 remains
`360c082c9dd4f02570a8095d49a4f2622a53fe3b09bedbe397cbfcd6d2707215`.

| CLI command observation, seconds | Before19 | Warm21, before scratch fix | Final22 |
| --- | ---: | ---: | ---: |
| Fanout A |49.339|57.962|35.793|
| Fanout B |42.455|50.102|29.748|
| Fanout C |57.263|62.446|40.229|
| Fanout mean |49.686|56.837|35.257|
| Receive/ACK 1 |29.624|31.223|23.350|
| Receive/ACK 2 |38.979|30.811|21.813|
| Receive/ACK 3 |31.661|28.943|20.478|
| Receive/ACK 4 |31.956|23.863|15.522|
| Receive/ACK 5 |33.228|20.416|20.975|
| Receive/ACK 6 |33.412|20.516|18.622|
| Receive/ACK mean |33.143|25.962|20.127|
| All46 active commands |499.376|447.753|344.884|
| Driver wall |506.619|454.389|350.875|
| All command CPU |230.453|195.421|180.825|

Final vs19: mean fanout−29.0%, receive/ACK−39.3%, active cycle−30.9%.
Vs the immediately preceding warm21:−38.0%/−22.5%/−23.0%. These are observed
successive retained rounds, NOT percentages attributable solely to one code
line: authority/grant work differs and operation histories/counters grow.

| HTTP work | Before19 | Warm21 | Final22 |
| --- | ---: | ---: | ---: |
| Fanout ONION request count |8|12|6|
| Fanout summed ONION seconds |83.142|117.998|50.057|
| Receive/ACK ONION request count |14|15|12|
| Receive/ACK summed ONION seconds |95.987|95.346|58.985|

Final fanout CPU54.078s, receive/ACK CPU34.078s; final public proof/closure HTTP
6.012s/29.080s respectively. HTTP/CPU observations overlap and are not exclusive
partitions. Even after normalizing by request count, ONION observations differ
in authenticated operation mix, routing and native history; no causal per-hop
speed distribution is inferred. The lower fanout request count is not presented
as a new cache/refresh policy: CLI/Shared control-plane code is unchanged.

All17 phase totals below cover all46 commands, including cold/replay overhead.
Times are sums of complete CLI command durations, not simultaneous screen-to-
screen delivery latency or native-fsync-only measurements.

| Operation phase | Commands | Before19 seconds | Final22 seconds |
| --- | ---: | ---: | ---: |
| Cold account status |3|1.831|1.761|
| Pair-left cold contacts |3|3.111|3.485|
| Pair-right cold contacts |3|5.479|7.595|
| Retained owner head |1|0.246|0.254|
| Native command preflight |3|0.738|0.646|
| Native history preflight |3|2.358|2.266|
| Exact active owner head |1|0.239|0.231|
| Exact active recipient heads |2|0.410|0.445|
| Original sender command count |3|0.693|0.545|
| Two-recipient fanout |3|149.057|105.770|
| Native receive and durable ACK |6|198.860|120.760|
| Cold native histories |3|3.633|3.334|
| Original full-batch cold replay |3|96.914|68.466|
| Post-replay empty mailboxes |3|22.581|17.141|
| Post-replay deduplicated histories |3|2.393|1.820|
| Cold owner control receipt reverification |1|3.773|1.452|
| Cold control-cursor empty replay |2|7.060|8.913|
| TOTAL |46|499.376|344.884|

### Executable evidence and scope

- Windows native focused timings/origin/ONION diagnostics:62/62 PASS, native0.
- Windows native grammar/security + timing regression selection:23/23
  PASS, native0. Includes tampering after a warm custody callback, changed
  authenticated native intent, closed lease, deep-copy ownership, UTF8 BOM and
  valid documents larger than the memo budget.
- Final scratch-fix Windows native selection:34/34 PASS, native0, including the
  previous23 cases, all three actual scratch ordering/interruption cases and
  eight existing Store/ACK intent/quorum persistence failure/recovery cases.
- Actual Linux ARM64 `node-authority-tests` Docker targets:64/64 PASS before
  scratch correction, then67/67 PASS after it,0 skipped, native0. The final
  selection executes the original57 authority/path/floor cases,7 grammar and
  3 scratch cases, not Windows-only filesystem evidence.
- Final DevOps Compose/build contract suite:31/31 PASS, native0.
- An earlier overly broad native class selection was deliberately interrupted
  after10m39s. Its partial196 passes and native exit1 are UNQUALIFIED, not full
  source PASS. The subsequent bounded23-case run is a separate invocation.
- Supported retained Build/Up/Verify and smoke completed native0; all three
  native volumes/mount bindings stayed unchanged. Grammar-only node image:
  `sha256:130e08dcff105248279e8b863cdaddf8b107528df0c26dbab7847b788be42735`.
  Final scratch-fix image, all three nodes healthy:
  `sha256:d6515bef34f2153a22816afac406f7550337ad1fd190b4a5e32f2b33d9a176e6`.
  Existing physical-ingress `--check` emits permission-denied stderr while its
  validation and Up exit0; no new ingress/TLS/carrier acceptance is inferred
  from that terminal. Final Verify/smoke explicitly report device/message
  evidence false; delivery evidence comes from the separate real CLI scenario.

Local receipts: `artifacts/cli-critical-path-20261021/steady-01/receipt.json`,
`steady-02/receipt.json`, `steady-03/receipt.json`, `direct-01/receipt.json` and
`direct-02/receipt.json` under the same artifact root.
Native gate/deployment terminals are under xnode's repo-owned
`artifacts/cli-critical-path-20261021/`. Private host probe inputs stay outside
repositories; no private endpoint, account, request or credential is published.

The1–2s delivery objective, sustained recovery-free stability, unfiltered source,
package/carrier/retention/scale/device and release acceptance remain OPEN.
Diagnostics establish expensive native dispatch/completion, not a successful
elimination of all ONION/ACK latency. No Signal-equivalence claim is made.
