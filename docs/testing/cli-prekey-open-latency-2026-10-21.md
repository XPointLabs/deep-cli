# Retained three-CLI fanout/ACK — pre-key open cost, 2026-10-21

Scope: SAME three CLI accounts, three-member group/epoch2 and local
`deep-dev-current` contour as the [previous checkpoint](cli-retained-route-reintroduction-2026-10-21.md).
No account, relationship, ratchet, keys, database or volume reset, rekey, data
import, node image/configuration change, production deployment or physical
Windows/Android work. This is not full/package/device/release acceptance.

## Evidence-led correction

A real cold group flush/replay (no new logical send) on the retained third profile was sampled
using EventPipe `dotnet-sampled-thread-time`. Around14.148s of non-wait sampled
thread time had `SqlitePreKeyV2InventoryStore.Open` as the nearest Shared owner.
This is sampled thread time, not exact CPU duration or a latency benchmark.
The raw trace remains private; no payload/identifier/secret is published.
The initial unsupported `cpu-sampling` profile invocation did not run a child;
the subsequent supported trace completed/native0. It is diagnostic only.
The Docker host and retained node image are both ARM64, not amd64 emulation.

The account/session/application databases already use raw keys. PKV2 instead
passes its32-byte account-derived password into native SQLCipher on every open,
repeating the deliberately expensive derivation even within one current-account
read. Receiver source custody opens this database repeatedly on both sides of
native reconciliation. Skipping source/retirement validation would be unsafe.

The correction preserves the EXACT existing PKV2 encrypted representation:
PBKDF2-HMAC-SHA512 with256000 iterations, the actual16-byte file salt and32-byte
result. Platform-backed .NET computes the same key; native SQLCipher receives
it using its documented wipeable raw-key syntax. A closed disposable context
belongs only to one verified current-account read, never the working network
authority/session. Reuse requires the same path, original password and freshly
read file salt; mismatches/disposal reject. The codec's current KDF settings are
checked, key buffers are wiped and no key string/SQL diagnostic is produced.

Every open STILL creates a fresh non-pooled SQLCipher connection and executes
the existing page integrity, exact schema, inventory signatures, protected
publication/receiver history and initial-key retirement checks. No accepted
verification result, SQL connection, private route or admission is cached.
No signed TTL/skew/deadline, retry, quorum, native floor or ratchet rule changes.
New files and independent native password opens use the same current format;
there is no migration, old-generation reader or alternate wire/crypto suite.
See the provider's [key/API documentation](https://www.zetetic.net/sqlcipher/sqlcipher-api/)
and [design](https://www.zetetic.net/sqlcipher/design/) for the exact SQLCipher4
KDF and raw-key mechanism. Existing frozen normative binding remains unchanged.

## Source gates

Receipts under each repository's `artifacts/cli-fanout-ack-20261021/`:

| Receipt | Observed result |
| --- | --- |
| Shared `key-01` |4 PASS/native0; original native-password file → optimized read/write → cold native-password read |
| Shared `guard-01` |15 PASS/native0; final deterministic salt-tamper fixture, wrong key/file/salt, disposed/truncated input, interrupted retirement/cold recovery, route-reintroduction and consent-input refusals |
| CLI `cli-01` |67 PASS/native0; shipping all-Release graph rebuilt with the correction |

The encrypted interoperability test modifies actual rows between fresh opens;
only derivation is reused. It is not a schema/floor/semantic permission test.
Real owner guards remain independently covered by the larger focused slice.
No unfiltered Shared/Protocol source run or new package qualification is claimed.

## Connected results

`steady-01` (cursor17) and `steady-02` (cursor18) each pass46/46 commands,
`steadyStateQualified=true`, `firstAttemptRequired=true`,
`noOwnedUnknownRecovery=true`. All driver attempts1; Store/mailbox resumes,
lease waits, HTTP non-success and session-close failures0. Each round includes
three sends to both peers, all six native receives/durable ACKs, three complete
cold original-batch audits, dedup and empty ordinary mailboxes/GSR cursors.
The retained profiles reach54 messages /18 local commands, then57/19 each,
still Active3/epoch2. No cursor is replayed as a new logical send.

Both new rounds capture runtime SHA256
`7881ea90805cf732db00128521b1694c307a07fa7eeca07eb8f283f87768f036` and the
UNCHANGED scenario SHA256
`360c082c9dd4f02570a8095d49a4f2622a53fe3b09bedbe397cbfcd6d2707215`.
Code, runtime and contour are unchanged between these rounds. The baseline
cursor16 is `cli-reintroduction-20261021/steady-02`; its runtime is archived
in that original run. Histories grew; these are sequential observations, not
identical-data snapshots, a statistical guarantee or a Signal benchmark.

### All operations, seconds (phase totals)

| Operation | Count | Cursor16 before | Cursor17 after | Cursor18 after |
| --- | ---: | ---: | ---: | ---: |
| Account cold status |3|1.815|3.184|1.678|
| Pair left cold list |3|7.683|3.143|3.709|
| Pair right cold list |3|24.771|5.349|5.546|
| Retained owner head |1|0.193|0.219|0.325|
| Native command preflight |3|0.666|0.692|0.739|
| Native history preflight |3|8.142|2.310|2.384|
| Exact active owner head |1|0.229|0.211|0.223|
| Exact active recipient heads |2|0.492|0.449|0.367|
| Original sender command count |3|0.695|0.683|0.743|
| Two-recipient fanout |3|186.497|190.164|164.206|
| Recipient native receive/ACK |6|184.058|210.970|184.138|
| Cold native history |3|6.653|3.500|3.425|
| Cold original full-batch audit/replay |3|113.575|91.755|93.223|
| Post-replay empty mailbox |3|20.409|33.067|22.925|
| Post-replay deduplicated history |3|7.877|2.648|2.218|
| Cold owner control receipt audit |1|3.382|3.816|1.752|
| Cold empty control cursor |2|11.881|13.309|7.000|
| All46 active commands |46|579.018|565.469|494.601|
| Whole run wall time |1|586.267|572.890|501.885|

Individual fanout A/B/C:
48.436/59.989/78.072 →65.850/57.314/67.000 →61.750/57.046/45.410s.
Individual receive/ACK in scenario order:
34.384/33.176/25.304/36.193/27.974/27.027 →
37.761/52.613/34.391/30.450/26.975/28.780 →
35.011/31.560/34.833/27.782/27.270/27.682s.
Do not omit cursor17's52.613s sample.

### CPU and actual HTTP workload

| Measured work | Cursor16 | Cursor17 | Cursor18 |
| --- | ---: | ---: | ---: |
| Fanout aggregate process CPU, s |106.015|62.875|65.000|
| Receive/ACK aggregate process CPU, s |59.093|49.984|46.782|
| All46 aggregate process CPU, s |335.167|224.546|228.999|
| Fanout ONION HTTP requests |6|12|10|
| Receive/ACK ONION HTTP requests |12|15|13|
| Fanout aggregate HTTP duration, s |81.039|129.061|100.344|
| Receive/ACK aggregate HTTP duration, s |124.986|163.563|140.447|

Mean fanout62.166→54.735s (**12.0% lower**), all46 active commands
579.018→494.601s (**14.6% lower**). Mean receive/ACK30.676→30.690s:
**no demonstrated wall-time ACK improvement** (0.04% higher).
Fanout CPU falls38.7%; ACK CPU20.8%; full-run CPU31.7%.
The third sender is the cleanest matched request-count observation: two ONION
requests in both cursors16/18, fanout78.072→45.410s (41.8% lower), process
CPU49.203→20.312s; ONION duration24.044→22.758s.

Extra ONION work is real, but the encrypted-frame aggregate does not identify
its inner terminal/purpose. Specific attribution to grant renewal is not proven
by these receipts. No grant scheduling policy was changed based on that guess.
HTTP durations and process CPU are different measures and may overlap; do not
sum/subtract them into a fabricated sender-to-visible-message latency.

## Still open

- The major demonstrated local pre-key-open cost is reduced; wire/authority
  latency remains. ACK CPU improved but its end-to-end command time did not.
- Instrument the remaining ONION/authority stages with closed numeric metrics,
  distinguish acquisition/maintenance from delivery and optimize the measured
  owner. Do not stretch TTL/skew/loans, skip independent ACK proof acquisition
  or replace durable uncertainty with success to get a faster receipt.
- These sequential commands are NOT an instrumented simultaneous visible-message
  latency measurement. The1–2-second target is not achieved.
- General offline/XUR catch-up, uncertain-prefix reclamation, full source/package,
  sustained retention/scale, devices and final release qualification stay open.

No release publication, main merge or Windows/Android/prod deployment included.
