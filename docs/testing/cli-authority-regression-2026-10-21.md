# Post-authority-rotation fanout/ACK investigation — 2026-10-21

Continues the [NTS activation checkpoint](cli-nts-activation-ack-2026-10-21.md).
Same local contour, three retained CLI profiles, group revision11, active3/epoch2.
No account/node reset, key rotation, new authority, production deployment or
Windows/Android application work in this iteration. Node and Registry images
remain the activation checkpoint's images. Only Shared client code changes.
Retained Shared source commit:
`45cd65f6f745ddf08fc33cbb358492db581f6b14`.

## Confirmed amplification, not another cryptographic stack

Strict37 still used6 fanout and12 receive/ACK ONION requests. Its regression
against35 was not a doubling of network work. Cold full-batch replay rose from
32.211s to44.252s mean and consumed substantial client CPU. Those rounds have
different history/authority and are not a controlled causal comparison.

Current-runtime private thread profiles identify repeated SQLCipher opens,
schema checks and full application-store integrity scans. Thread-time samples
include waits and are not a kernel CPU attribution. The exact local history
owner was then traced in code and tested by the same-history experiment below.

`RequireRetainedOrdinaryEventUnderLeaseAsync` opened the application SQLCipher
store **before** selecting group authored history from the independently
protected group journal. For a group event the SQL object was never used.
Historical Store re-verification calls the helper twice for each batch item;
every unused open still scanned/validated the application database. Current
retained application files are roughly3.4–4.2MB. Repeated whole-store work
amplifies history growth; rotation itself is not proven to explain every timing
change between35 and37.

The helper now first authenticates the actual native operation and actual
protected group root. If that owns the exact adopted event, it does not open
the unrelated direct projection. Direct-event fallback still opens and fully
validates SQL exactly as before. No cached authority, decrypted state, private
key, schema result, floor or earlier successful outcome replaces an actual read.

Native/protected checkpoints, original event/hash, authored sequence, group
custody and all pre/post-callback/Store fences remain. Parent Store-evidence SQL
opens and the actual contact-consent SQL open are unchanged. The regression
test proves an exact native group replay still performs its **one required
contact-consent application open**, without the second unused history open.
Existing hostile group chunk, unpublished-control refusal, native replay,
ordinary text and original Store crash/settlement checks remain.

Full SQLCipher verification was not replaced with a quick check or skipped:
[SQLCipher's integrity API](https://www.zetetic.net/sqlcipher/sqlcipher-api/#cipher_integrity_check)
authenticates individual database pages. An8MiB connection-local page-cache
experiment, following [SQLite's session-local cache setting](https://www.sqlite.org/pragma.html#pragma_cache_size),
gave31.231s/29.312s CPU on the same replay, versus30.426s mean/28.844s CPU
without it. That is not an improvement; **the cache experiment is removed**.
No SQLCipher configuration, schema, persistence or wire generation changes.

## Controlled same-history old/new/new/old

All four runs are separate cold CLI sessions reading the same completed group
batch, with38 original local commands /114 group messages per client. No new
message, route maintenance or account reset occurs between them. Each completes
with native0,3 directory-proof and2 network-closure exchanges,0 ONION,0 failed
requests/non-success HTTP. Runtime and scenario hashes are captured in each
closed receipt; raw profiles remain only in private custody, not Git/artifacts.

| Trial | Replay wall | CLI CPU | Native unprotects |
| --- | ---: | ---: | ---: |
| Old A1 | 36.677s | 34.984s | 3553 |
| New B1 | 31.238s | 28.750s | 3382 |
| New B2 | 29.613s | 28.938s | 3382 |
| Old A2 | 36.493s | 34.031s | 3550 |
| Old mean | 36.585s | 34.508s | 3551.5 |
| New mean | 30.426s | 28.844s | 3382 |

Observed gain: **16.8% wall /16.4% CPU** for this exact retained read path.
JIT compilation remains around4.3–4.5s in both variants. This small ABBA sample
does not establish a statistical/general or1–2s delivery claim.

## ACK server attribution and focused evidence

Twenty retained slow-request diagnostic rows from strict37 average171 lease
checks,2.841s lease work,2.152s authority work and0.632s native-join work.
Nested authority diagnostics average1.271s proof observation,0.446s source-file
work,0.002s lineage,0.005s mailbox policy and0s network verification at that
logging resolution. These overlapping, warning-threshold-selected summaries
are not all-request latency totals. They do **not** justify removing fresh proof,
file, protected floor, issuer or lease checks. No server authorization changed.

Final retained-code focused gate: Shared87/87, CLI67/67 PASS/native0;
production assembly/source graph and frozen executable manifest integrity PASS.
Final gate builds have zero warnings/errors. No full/package/device/release
qualification is claimed. Root receipts are under
`artifacts/cli-authority-regression-20261021/`; connected receipts/runtime archives
are under the same-named directory in this CLI repository.

Earlier receipts remain: one test helper accessibility compile failure, followed
by a test that incorrectly counted *every* application-registration inventory
read as an SQL open. The final assertion distinguishes the exact six-root SQL
open and preserves the mandatory consent read. An analyzer warning was corrected
using the exact predicate overload; the final87-test gate is warning-free.
The page-cache prototype and its passing tests are not the retained runtime.

Additional root governance contracts:29/30 PASS, one pre-existing FAIL. The
program-guard positive fixture expects to reach the missing-local-links refusal
but instead stops at the release document-set digest mismatch (pinned
`bf20a19400c01ae98ac69d3e90f811c2a12cc8e25b2b4af7414eb2bfd1a91c70`, actual
`b2de586eb52aea3e9a0dfa7c9ac869e8e6250eaebe38cf6825e39f45b8489e64`). All six
hashed program documents, manifest, guard and contract test are unchanged from
the turn-start HEAD. This unrelated failure is not waived or repinned; root
governance/full acceptance remains open.

## Connected measurements

Full38: **46/46 PASS/native0, first attempt**, steady-state qualified,
117 messages /39 original local group commands at every client, active3/epoch2.
Zero automatic Store/mailbox resumes, lease waits, failed requests/non-success,
command retries or abnormal session close. Six actual receive/ACK, all three
cold original-Store batch replays, empty mailboxes, exact deduplicated history
and owner/GSR control replays pass. No reset or route repair was needed.

| Full38 operation | Individual durations | Mean | ONION, total |
| --- | --- | ---: | ---: |
| Two-recipient fanout | 50.740 /59.229 /55.475s | 55.148s | 12 |
| Native receive + ACK | 32.822 /27.245 /24.987 /21.261 /19.180 /20.263s | 24.293s | 15 |
| Cold original batch | 36.822 /37.812 /35.948s | 36.861s | 0 |
| Empty mailbox | 6.750 /7.303 /7.972s | 7.342s | 3 |

Active operations471.198s, CLI CPU247.919s, driver wall474.686s. Grants from the
previous round expired during the investigation: the six additional fanout and
three additional receive ONION requests fit the previously attributed
Deposit/Retrieve acquisition pattern. This iteration did not independently
attribute their operation types from issuer journals. No command retry or
automatic Store/mailbox resume occurred. Thus full38 is **not** a warm
latency comparison with strict37's6/12 requests; its slower fanout/ACK is retained
and not relabelled as an improvement. Cold replay, at0 ONION in both rounds,
is36.861s versus44.252s in37 (-16.7%), with a slightly longer native history.

Current runtime:
`bca3b859d42891c11a9c5e7b45e6c5b8fb2197a58211e78e18a96874a758a5d1`;
full scenario:
`c3ce35ceac8ee4096ff13b69bac795415ba9ec2ce131f47e0407abb80be8d8ff`;
session module:
`1961b8787f11725c75c2f4c470b4535f9fb5f2ff4dd85a746be11acf3e8b8687`.

The subsequent warm round39 uses the existing explicit **delivery-only** lane:
same three sends and six real receive/ACK, cold exact histories and empty
mailbox/dedup checks, but no second cold full-batch/control audit after full38.
It can qualify delivery latency, never full steady-state or release acceptance.

Delivery39: **40/40 PASS/native0, first attempt**, delivery-latency qualified,
not full steady-state qualified. No automatic Store/mailbox resume, lease wait,
command retry or abnormal close. Each unchanged account now retains120 group
messages /40 original local commands, active3/epoch2. Next new cursor is40.

| Operation | Strict37 mean | Delivery39 mean | Change | ONION37 /39 |
| --- | ---: | ---: | ---: | ---: |
| Two-recipient fanout | 38.480s | 42.223s | +9.7% | 6 /6 |
| Native receive + ACK | 20.881s | 21.317s | +2.1% | 12 /12 |

Fanout39 individual durations42.903 /41.478 /42.289s; receive/ACK23.532 /
25.163 /18.010 /19.718 /20.045 /21.432s. Empty mailbox10.629 /7.556 /6.177s,
mean8.121s. Active operations296.420s, CLI CPU136.483s, driver wall299.789s.
Total wall is not comparable with full37/38 because delivery-only omits the
second cold batch/control audit. Runtime/scenario/module fingerprints match38.

**Ordinary fanout/ACK regression remains unresolved.** Group replay optimization
does not improve these operations. Fanout CPU totals61.109s versus61.453s in37;
its ONION duration totals58.262s versus54.733s, and DirectoryProof durations
11.398s versus4.154s (eight exchanges versus seven). Network durations can
overlap; they must not be added to CLI CPU or presented as exact critical paths.
Different history and scheduling also prevent attributing this entire change
to rotation or this patch. The controlled same-history replay result above is
the only causal improvement claimed here.

Twenty warning-selected authority summaries from39 still average1.269s proof
observation and0.495s source reads, with0.004s lineage and0s network verification
at logging resolution. Container CPU limits remain unchanged; cumulative
throttling is not evidence of a quota regression during39. No quota was changed.
An acquisition-cache proposal was rejected: a new acquisition still needs a
fresh nonce-bound DTT1; artifact validity windows do not supply current time.
Existing retained-proof observation continues to re-read/authenticate actual
native head/anchor/index and current clock. No Node/Registry change is shipped.

Next investigation: attribute remaining ordinary client/native history work
separately from per-hop protected-proof/source costs, using bounded measurements
on these retained profiles. Do not add another crypto stack, waive original
history checks, reset the profiles or return to device testing as a substitute.
