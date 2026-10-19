# CLI message / ACK latency checkpoint — 2026-10-19

Scope: retained three-CLI group, actual local TLS/H2 Registry and three XNodes.
Windows/Android, production and release publication are excluded. This continues
[the previous strict send/DTT/ACK checkpoint](cli-dtt-send-2026-10-19.md), not a
fresh lifecycle or a relabelled recovery run.

## Causes and changes

1. **Mixed build configuration.** Earlier solution Release builds produced the
   Release console with Debug Shared and all three Debug Protocol assemblies;
   the earlier `cli-session-20261019/build-05/native.log` and this iteration's
   `cli-latency-20261019/build-01/native.log` show the actual output paths. The
   CLI solution now explicitly includes those owned projects. The actual loaded
   assemblies' JIT optimizer flags must match CLI, not merely an output folder
   named Release. `build-02` produces all Release. Four new unit cases pass;
   substituting only the archived Debug dependencies in an isolated test-output
   copy causes exactly four expected failures. The original runtime stays intact.
2. **Delivery mixed with old Store audits.** New group send drained and
   independently re-verified all previously completed original Stores, growing
   work with history. It now schedules unfinished entries using actual protected
   authored metadata only as a scheduling hint. Unknown/missing/unadopted work
   retains the existing full owned path. No receipt is supplied by the hint, no
   queue/history/audit state is removed. Explicit `group flush` retains the full
   historical original-batch audit. See the
   [delivery owner](../../../docs/architecture/TRANSPORT-NEUTRAL-MESSAGING.md#81-state-machine).
3. **ACK group lookup duplication.** ACK acquires a new phase-local public
   context after receive; group-member verification within that ACK shares it
   instead of issuing duplicate lookups. A nested working scope cannot supply
   its older proof. Actual floors/history, account binding, clock, expiry and
   all native/effect/readback checks remain mandatory; see the
   [authority owner](../../../docs/architecture/ACCOUNT-DIRECTORY-TRANSPARENCY-V1.md#working-public-authority-and-delivery).
4. **Disabled public connection reuse.** The public Registry client previously
   configured a one-tick pooled connection lifetime. It now pools for two minutes
   (one minute idle), scoped to the serial client/session. Every directory nonce,
   signature and floor verification remains; TLS/platform trust, online
   revocation, explicit system proxy, no direct fallback/redirect/cookie policy
   remain. Selected ONION handlers, routes and transport isolation are unchanged.
   This follows the [.NET HTTP lifetime guidance](https://learn.microsoft.com/en-us/dotnet/fundamentals/networking/http/httpclient-guidelines),
   not another transport or crypto stack.

No protocol bytes, journal generation, signed window, timeout, account identity
or original Store/ACK request is changed. Node image and node CPU limits stay
unchanged from the preceding strict round.

## Focused verification ledger

Paths below are repository-local ignored artifacts, not committed raw logs.

| Repository / run | Result | Scope |
| --- | --- | --- |
| Shared `artifacts/cli-latency-20261019/shared-01` |17 PASS/native0|ACK separation, actual encrypted/native lost ACK, real publication cases, scope rollback/expiry, public HTTP policy|
| Shared `shared-02` |71 PASS/native0|Authored queue/SQL mirror, five scheduling cases, endpoint read scope, clock rollback and public pooling invariants|
| Shared `shared-03` |11 PASS/native0|Actual native group batch keeps unfinished Store work even after native commit; unknown recovery policy|
| CLI `build-01`, `unit-01` |Build/native0;59 PASS|Pre-fix solution still mixes Debug dependencies; not the E2E runtime|
| CLI `build-02`, `unit-02` |Zero warnings/errors;63 PASS/native0|All-Release solution and four actual dependency optimization checks|
| CLI `configuration-negative` |Expected rejection,4/4 FAIL|Isolated old Debug dependency substitution only; this is negative evidence, not a passing source suite|

The scheduling tests distinguish pending/stable from successful, reject changed
payload/foreign authored scope, retain unknown and stopped-without-success work,
and prove that selecting a hint neither changes custody nor returns a receipt.
The actual native group case confirms that native commit alone does not remove
an unfinished Store from the pending batch.

A diagnostic original-batch replay on the earlier runtime also completed under
the supported .NET sampled-thread-time profiler. Raw metadata remains private.
Its all-thread waiting percentages are not claimed as CPU utilization or used
as a benchmark. The initial unsupported CPU-profile invocation was rejected
before starting a CLI; it is not delivery evidence.

## Connected result and timing comparison

`artifacts/cli-latency-20261019/steady-01/receipt.json`: **PASS,46/46 commands**,
every driver attempt1, zero owned Store resumes, zero mailbox resumes and zero
retry-lease waits. All sessions close normally. Runtime fingerprint:
`156beb1a0ad3ec0c1d2ead3dc488c4a885171dc4e2ec5220f01a627ca16c82ee`.

The same three profiles/group start at15 messages /5 local commands each and
finish at **18 messages /6 local commands each**, three active members, epoch2.
All three new sends drain exactly **two** unfinished target items. Six receives
commit one envelope and one durable tombstone each. Cold replay still audits
all **20/13/13** original fanout items, not just the newest command; every
post-replay mailbox and GSR cursor is empty, with one semantic copy per message.
No account/history reset, manual retry or pending-operation replacement occurs.
Next new strict round uses `SteadyStateRound=6`.

Baseline is the preceding complete `cli-session-20261019/steady-04`, not an
incomplete failure. Same node image,1 CPU per node and profiles. This is a single
operational comparison, not isolated attribution/statistical SLO: the new round
has more history and different grant/freshness state after an idle interval.

| Operation | Before, s | Now, s | Shorter |
| --- | ---: | ---: | ---: |
| A → two peers fanout |96.518|80.486|16.6%|
| B → two peers fanout |94.030|85.197|9.4%|
| C → two peers fanout |96.627|91.059|5.8%|
| All three fanouts, sum |287.175|256.742|10.6%|
| A → B receive / ACK |52.608|50.801|3.4%|
| A → C receive / ACK |57.366|53.916|6.0%|
| B → A receive / ACK |50.533|36.117|28.5%|
| B → C receive / ACK |51.982|34.314|34.0%|
| C → A receive / ACK |41.670|26.714|35.9%|
| C → B receive / ACK |42.956|26.318|38.7%|
| All six receive / ACK, sum |297.115|228.180|23.2%|
| All46 commands, summed active CLI time |761.626|632.739|16.9%|

Fanout CLI CPU totals126.375→99.563s (21.2% shorter); individual values
34.625→24.609,44.078→34.438,47.672→40.516s. This does not measure server CPU or
separately attribute savings to each of the four changes.

Public control-plane non-success responses are **not hidden**: first receive
on B and C includes one directory history request and one non-success proof
response each; C also records five non-success closure responses. These remain
in the receipt and timings. The existing bounded public authority acquisition /
catch-up behavior was not replaced by driver retry or relaxed freshness. The
metrics do not preserve individual HTTP status codes, so no exact status is
invented. Successful CLI-attempt1 is not a claim of single HTTP/wire attempt.

### Every operation family in the final round

| Operation | Calls | Failures | Min–max, s | Sum, s |
| --- | ---: | ---: | ---: | ---: |
| Account status |3|0|0.521–1.398|2.463|
| Left contact-list preflight |3|0|0.611–4.038|5.327|
| Right contact-list preflight |3|0|4.027–7.656|19.071|
| Retained owner group head |1|0|0.224|0.224|
| Native command preflight |3|0|0.210–0.235|0.665|
| Native history preflight |3|0|0.466–4.435|6.947|
| Active owner head |1|0|0.218|0.218|
| Active recipient heads |2|0|0.200–0.221|0.421|
| Sender command count |3|0|0.177–0.193|0.559|
| Two-recipient fanout |3|0|80.486–91.059|256.742|
| Receive + durable ACK |6|0|26.318–53.916|228.180|
| Cold native history |3|0|1.033–3.611|7.028|
| Full original-batch audit |3|0|16.176–29.112|69.318|
| Post-audit empty mailbox |3|0|5.857–7.261|19.174|
| Deduplicated history |3|0|0.507–4.126|6.810|
| Owner control receipt |1|0|0.337|0.337|
| Empty recipient GSR cursors |2|0|4.624–4.631|9.255|

Not every operation is faster: cold native history6.614→7.028s, deduplicated
history5.291→6.810s and empty GSR cursors7.433→9.255s are longer in aggregate.
Full original-batch audit81.491→69.318s and empty mailbox33.793→19.174s improve.

## Open limits

This focused source/steady-state work cannot close fresh lifecycle,
full/package/retention/scale/device or release qualification. Any remaining
latency must be reported from the actual complete receipt, not extrapolated
from an isolated read or from one faster operation.

Delivery remains slow. Each two-recipient send still makes four ONION requests
whose measured aggregate latency is47.664–50.382s, and consumes24.609–40.516s
of CLI CPU. Next work should separately profile actual data-plane/grant path and
remaining authenticated native SQL/history joins; it must not remove effect
fences, skip failed authority or claim TLS handshakes alone explain server time.
No Signal parity or instant delivery is claimed. All original custody remains;
no MAUI/Android or production change/publication was made.
