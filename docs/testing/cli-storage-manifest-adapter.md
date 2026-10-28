# Private storage adapter and disposable benchmark

[DR-0176](../../../docs/survival-program/decisions/DR-0176-bounded-protected-storage-inventory.md)
owns the format, enrollment, atomic commit and cleanup contract. This checkpoint
records only CLI composition and engineering evidence. The three retained CLI
profiles were enrolled under the bounded 2026-10-28 diagnostic authorization
below; no storage performance or release claim is accepted here.

`storage enroll --profile <alias> --network <hex>` is standalone. `--network`
selects the existing private namespace; the command performs no network I/O and
accepts no authority/transport overrides, reset, force or raw-path options.
Program dispatches it before ordinary profile
and account-service opening. It requires the existing private profile and takes
the same exclusive `command.lock`; reparse paths refuse. Shared's explicit
`EnrollAggregateAsync` owns audit, exact-byte staging/resume and adoption. The CLI
does not read a legacy inventory on normal commands or implement a second engine.

`account create` explicitly calls `CreateNewAsync` only for an empty private
profile. Existing state opens through the strict constructor. Missing committed
storage beside native files, an object directory or other prior state refuses
initialization. Ordinary account status, network, group and session commands
never create an empty replacement. Session commands share one async profile
factory and reject enrollment before storage access. Disposal first drains the
session, then closes account scheduling, storage, platform protection and the
command lock.

Command `storageWork` contains deltas of the Shared owner's thirteen scalar
counters: actual manifest/object reads and acknowledged bytes, decoded/decrypted
bytes, writes, cleanup tombstones and protector calls. These include cold audit
and recovery work. They are not network traffic or physical disk/cache-miss
measurements. Scalars remain readable after disposal; no key, slot, path or
capability enters the response. Engineering delivery/maintenance receipts retain
this separate block; semantic delivery-event frames remain unchanged.

`eng/Invoke-SecureStorageProviderBenchmark.ps1` runs in a fresh Windows
PowerShell 7.6.5/.NET 10 process for each exact runtime. It compiles the same
`SecureStorageProviderBenchmark.cs` against either archived DSS1 or actual DSS2
assemblies. The archived baseline is software only, at
`artifacts/p1-storage-baseline-20261026/runtime/`; all 32 hashes match the prior
runtime02 inventory, with source-input provenance retained beside it. The real
CLI DPAPI protector is instantiated from that exact runtime. Every independent
store owner receives its own protector and owns its disposal; only scalar totals
cross cold instances. No prior backend source is compiled into production.

The fixed population uses capacities 16/256/1024, reserving two slots for atomic
insertion, fixed 32-byte/1-KiB selected values and 4-KiB unselected values. Each
inventory records seed cost, cold admission, three warmups and sixteen measured
single/batch reads per operation, four exact CAS/insert plus guarded-delete
cycles, and independent cold reopen checks. All 141 declared rows per provider
must complete; failures remain in the receipt. Missing batch entries are checked
against the same snapshot, and cold reopen verifies the complete atomic result.
Warm selected reads require one actual native Unprotect and, for DSS2, only the
one/two selected objects. Raw manifest rereads for exact-source guards remain
fully counted: one inventory admission is not one raw filesystem read. Full cold audits
are reported separately. Timing and allocations remain descriptive.

For archived DSS1, every actual `ReadAllBytes` result is the counting protector's
exact input, so its envelope-byte counter measures complete aggregate reads.
The old binary has no owner write counter: actual managed storage bytes written
remain `null`; produced ciphertext bytes are reported with that narrower label.
DSS2 uses its actual owner I/O counters. DPAPI itself unwraps a small key in both
providers; envelope bytes are not native wrapped-key bytes. No old/new matched
performance result exists until both complete with unchanged sources/runtimes.

The first archived attempt is preserved at
`artifacts/p1-storage-benchmark-20261026/baseline01.terminal.json`: native exit 1,
35 unchanged inputs, compiler CS1069 before fixture creation. The framework
reference fix compiled successfully in the separate
`artifacts/p1-storage-benchmark-20261026-baseline02/baseline02.terminal.json`, but
that run ended native exit 1 after one failed cold row of 141: its original
harness reused a protector disposed by the seeded store. Neither is valid timing
evidence. Source now gives seed/current/cold-reopened owners separate actual
protectors. No candidate build, retained profile action, network call or
enrollment occurred in either failed attempt.

The disposable DID2 conversion case creates an actual account and SQLCipher
state, encodes every logical slot into an explicit DSS1 test fixture without
changing identity/instance/keys, enrolls through the standalone command, compares
all slot values and native file bytes, then reopens address/status through the
real account service. This is conversion of genuine DID2 state; it is not
historical old-binary E2E or conversion of the retained three profiles.

The first coherent CLI gate remains at
`artifacts/dr0176-cli-20261026-01/terminal.json`: build exit 0 without warnings,
23 PASS/6 FAIL, native exit 1, all 2127 source/2285 test inputs unchanged. Shared's
strict path check rejected ordinary packaged LocalApplicationData virtualization;
the two closed `path-identity-probe.json`/`path-mapping-probe.json` receipts prove
the intended tail and opened physical parent/leaf without exporting private paths.
The Shared handle-bound parent fix and its 10-case gate are recorded separately
at `../deep-client-shared/artifacts/dr0176-protected-path-20261026-01/terminal.json`.
The unchanged CLI29 repeat at `artifacts/dr0176-cli-20261026-02/terminal.json`
passed all 29 cases with no failures/skips, native exit 0 and the same source/test
input counts unchanged; Release build had zero warnings/errors. This includes
the genuine disposable DID2 state-conversion proof above. Full gates remain
unqualified.

Corrected baseline03 completed 141 rows, but is not the matching comparison:
before candidate execution, source review caught an overly strict harness check
requiring one raw manifest read. The approved helper correction requires one
actual Unprotect plus exact selected objects and retains every raw read/byte.
The final matched runs use identical helper hashes, PowerShell 7.6.5,
.NET 10.0.11 and SDK 10.0.301:

- `artifacts/p1-storage-benchmark-20261026-baseline04/baseline04.terminal.json`:
  native exit 0, all 141 rows successful, 35 archived/helper/tool inputs unchanged.
- `artifacts/p1-storage-benchmark-20261026-candidate01/publish01/terminal.json`:
  Release win-arm64 Latency `--no-restore` publication, native exit 0, all 2125
  captured source inputs unchanged, no warnings/errors.
- `artifacts/p1-storage-benchmark-20261026-candidate01/candidate01.terminal.json`:
  native exit 0, all 141 rows successful, 2159 source/runtime inputs unchanged.
  Candidate software is `artifacts/p1-storage-candidate-20261026/runtime/`.

The candidate is slower in **every** measured operation/capacity. Each cell below
is aggregate → manifest. Times are medians of 16 reads or four atomic cycles;
one cycle includes CAS/register and guarded deletion, not one write.

| Capacity | Operation | ms | Managed read KiB | Native Unprotect | Allocated MiB |
| ---: | --- | ---: | ---: | ---: | ---: |
| 16 | single | 0.295 → 5.815 | 45.6 → 6.6 | 1 → 1 | 0.10 → 1.28 |
| 16 | batch | 0.298 → 6.921 | 45.6 → 7.7 | 1 → 1 | 0.10 → 1.57 |
| 16 | atomic cycle | 16.080 → 289.648 | 91.3 → 248.7 | 2 → 43 | 0.46 → 44.09 |
| 256 | single | 1.034 → 8.985 | 1010.5 → 97.3 | 1 → 1 | 2.06 → 1.53 |
| 256 | batch | 1.091 → 10.115 | 1010.5 → 98.4 | 1 → 1 | 2.06 → 1.82 |
| 256 | atomic cycle | 20.527 → 447.018 | 2021.1 → 3544.2 | 2 → 43 | 10.14 → 55.49 |
| 1024 | single | 2.767 → 9.745 | 4098.3 → 387.5 | 1 → 1 | 8.06 → 2.32 |
| 1024 | batch | 3.416 → 11.011 | 4098.3 → 388.6 | 1 → 1 | 8.06 → 2.61 |
| 1024 | atomic cycle | 58.959 → 448.725 | 8196.6 → 14090.0 | 2 → 43 | 40.53 → 92.70 |

The candidate reports three raw manifest reads per warm admission, with exactly
one/two selected object reads. Atomic cycles report 109 raw manifest and 30 object
reads; their additional I/O, native calls and allocations are not hidden by the
selected-read byte reduction. The complete comparison, including CPU medians and
candidate write bytes, is
`artifacts/p1-storage-benchmark-20261026-candidate01/comparison-baseline04-candidate01.json`.
Small process-CPU samples can read zero because the observed timer quantum is
15.625 ms; this does not mean zero CPU work. Baseline actual write bytes remain
unmeasured, so no write-byte savings claim is made.

Cold/seed costs are separate, also aggregate → manifest in milliseconds:

| Capacity | Seed | First cold admission | Median cold reopen after atomic cycle |
| ---: | ---: | ---: | ---: |
| 16 | 14.115 → 439.134 | 5.780 → 27.297 | 8.114 → 29.524 |
| 256 | 5.452 → 8908.534 | 12.022 → 568.634 | 7.520 → 553.802 |
| 1024 | 14.571 → 32758.206 | 9.364 → 2105.776 | 10.254 → 2181.122 |

These are disposable local provider measurements, not delivery latency, p95,
physical storage traffic or release acceptance. No retained account enrollment,
connected send or network request occurred. Later root NEXT-SPRINT/DR-0176
retirement-mapping documentation edits were made after terminal/freeze release;
they do not change these runtimes or retroactively enter captured gate hashes.

## Bounded path-buffer follow-up

Shared changed only the Windows physical-name buffer from 32768 to 512 characters
with bounded growth. The identity predicate, callbacks, writes and counters stayed
unchanged. The long-path growth, LocalApplicationData and wrong-parent cases
passed in
`../deep-client-shared/artifacts/dr0176-path-buffer-20261026-01/terminal.json`:
Release build/native exits 0, zero warnings/errors, 3 PASS/0 FAIL/0 SKIP and 2267
inputs unchanged. CLI product code/tests did not change; CLI29 was not repeated.

The identical benchmark helpers then completed another matched pair, all 141 rows
successful per provider and native exits 0:

- `artifacts/p1-storage-benchmark-20261026-baseline05/baseline05.terminal.json`:
  35 inputs unchanged.
- `artifacts/p1-storage-benchmark-20261026-candidate02/publish01/terminal.json`:
  fresh Latency win-arm64 `--no-restore` publish, zero warnings/errors and 2125
  source inputs unchanged.
- `artifacts/p1-storage-benchmark-20261026-candidate02/candidate02.terminal.json`:
  2159 source/runtime inputs unchanged; software at
  `artifacts/p1-storage-candidate-20261026-02/runtime/`.

All nine latency comparisons still regress. Allocation reduction from the buffer
change does not close the underlying filesystem/authority amplification. Cells
remain aggregate → manifest, with the same sample counts and operation definitions
as the first pair:

| Capacity | Operation | ms | Managed read KiB | Native Unprotect | Allocated MiB |
| ---: | --- | ---: | ---: | ---: | ---: |
| 16 | single | 0.300 → 6.417 | 45.6 → 6.6 | 1 → 1 | 0.10 → 0.17 |
| 16 | batch | 0.310 → 7.126 | 45.6 → 7.7 | 1 → 1 | 0.10 → 0.22 |
| 16 | atomic cycle | 15.227 → 279.708 | 91.3 → 248.7 | 2 → 43 | 0.46 → 6.31 |
| 256 | single | 0.910 → 5.691 | 1010.5 → 97.3 | 1 → 1 | 2.06 → 0.42 |
| 256 | batch | 0.812 → 7.027 | 1010.5 → 98.4 | 1 → 1 | 2.06 → 0.46 |
| 256 | atomic cycle | 16.464 → 337.779 | 2021.1 → 3544.2 | 2 → 43 | 10.14 → 17.72 |
| 1024 | single | 2.319 → 6.175 | 4098.3 → 387.5 | 1 → 1 | 8.06 → 1.21 |
| 1024 | batch | 3.273 → 7.571 | 4098.3 → 388.6 | 1 → 1 | 8.06 → 1.26 |
| 1024 | atomic cycle | 83.771 → 340.778 | 8196.6 → 14090.0 | 2 → 43 | 40.53 → 54.92 |

Raw read counts/bytes and native admissions are unchanged from candidate01,
including 43 Unprotect, 109 manifest reads and 30 object reads per atomic cycle.
For example, candidate allocations at capacity 16 fall from 1,342,856 to 181,640
bytes for a single read; capacity-1024 atomic allocations fall from 97,202,360 to
57,593,208 bytes. These memory improvements are separate from latency acceptance.

| Capacity | Seed ms | First cold admission ms | Median cold reopen ms |
| ---: | ---: | ---: | ---: |
| 16 | 23.425 → 456.367 | 4.536 → 26.995 | 8.255 → 24.914 |
| 256 | 4.998 → 6267.344 | 9.065 → 354.408 | 6.329 → 344.012 |
| 1024 | 13.218 → 27212.551 | 8.081 → 1322.022 | 14.378 → 1286.182 |

Full scalar evidence is
`artifacts/p1-storage-benchmark-20261026-candidate02/comparison-baseline05-candidate02.json`.
No retained enrollment, connected send, network access, activation, delivery/p95
or performance acceptance follows from this iteration. P1.2 remains separate;
the measured closed-operation amplification still needs correction.

## Closed-operation follow-up — 2026-10-28

Shared's bounded package at
`../deep-client-shared/artifacts/dr0176-closed-operations-20261028-03/terminal.json`
passed 206 cases (187 storage, 19 contact), native exit 0, zero build warnings/errors
and 2279 unchanged inputs. The explicitly approved contact fixture correction
preserves its signature assertion and all production checks; the original
18 PASS/1 FAIL receipt remains immutable. This is focused evidence, not a full gate.

The dependent CLI gate at `artifacts/dr0176-cli-20261028-03/terminal.json` passed
the same 29 cases, including genuine disposable DID2/SQL enrollment, with no
failures/skips and native exit 0. Release build had zero warnings/errors; 2131
build-source and 2289 source/binary inputs stayed unchanged. The actual coordinator
was Windows PowerShell 5.1.26100.9711 with SDK 10.0.301.

Unchanged benchmark helpers then completed 141 successful rows per provider in
separate PowerShell 7.6.5/.NET 10.0.11 processes:

- `artifacts/p1-storage-benchmark-20261028-baseline06/baseline06.terminal.json`:
  native exit 0, 35 archived/helper inputs unchanged; exact archived 32-file runtime.
- `artifacts/p1-storage-benchmark-20261028-candidate03/publish01/terminal.json`:
  fresh Release win-arm64 Latency `--no-restore` publish, native exit 0 and 2129
  source inputs unchanged. Software is `artifacts/p1-storage-candidate-20261028-03/runtime/`.
- `artifacts/p1-storage-benchmark-20261028-candidate03/candidate03.terminal.json`:
  native exit 0, 2163 source/runtime inputs unchanged and 32 runtime files.

Both helper hashes remain exactly those used by baseline05/candidate02:
`D41A526FF3381965618A187D89A7BBE508539DE1A2B746EC6BBDF55512428946` (PowerShell)
and `75B274DC976447CEC2B02CD51B8658883F7AF22DA276562E174CCD0A7CB7C86D` (C#).
Every declared sample completed; no successful subset replaces the population.
All nine latency comparisons still regress. Cells are aggregate → manifest;
sample counts and atomic-cycle definitions remain those above.

| Capacity | Operation | ms | Managed read KiB | Allocated MiB |
| ---: | --- | ---: | ---: | ---: |
| 16 | single | 0.310 → 4.550 | 45.6 → 4.4 | 0.10 → 0.16 |
| 16 | batch | 0.309 → 5.513 | 45.6 → 5.5 | 0.10 → 0.20 |
| 16 | atomic cycle | 15.484 → 142.236 | 91.3 → 114.0 | 0.46 → 3.09 |
| 256 | single | 0.853 → 8.826 | 1010.5 → 64.9 | 2.06 → 0.38 |
| 256 | batch | 0.930 → 8.863 | 1010.5 → 66.0 | 2.06 → 0.41 |
| 256 | atomic cycle | 37.295 → 174.357 | 2021.1 → 1595.5 | 10.13 → 7.07 |
| 1024 | single | 3.036 → 7.500 | 4098.3 → 258.4 | 8.06 → 1.08 |
| 1024 | batch | 2.874 → 9.597 | 4098.3 → 259.5 | 8.06 → 1.11 |
| 1024 | atomic cycle | 50.913 → 174.073 | 8196.6 → 6336.2 | 40.53 → 20.18 |

Warm reads retain one actual native Unprotect, now with two raw manifest reads
and one/two selected object reads. Atomic cycles use eight native Unprotect calls
versus two for the aggregate and 43 in candidate02, with 49 manifest reads and 29
object reads versus the previous 109/30. Reduced work does not establish latency
acceptance. Capacity-16 atomic read bytes and allocations still exceed the aggregate;
larger atomic cycles reduce those costs but remain slower. No writes or raw reads
were removed from the measurements. Baseline actual write bytes remain unmeasured.

Cold/seed costs remain separate, in milliseconds:

| Capacity | Seed | First cold admission | Median cold reopen after atomic cycle |
| ---: | ---: | ---: | ---: |
| 16 | 10.774 → 313.108 | 8.575 → 10.513 | 7.716 → 8.440 |
| 256 | 4.891 → 3929.040 | 8.433 → 94.457 | 7.233 → 92.582 |
| 1024 | 20.233 → 16590.992 | 21.314 → 291.170 | 12.048 → 302.886 |

Full CPU/read/write/counter medians and setup rows are preserved in
`artifacts/p1-storage-benchmark-20261028-candidate03/comparison-baseline06-candidate03.json`.
Every native stage ended before this checkpoint edit; build-server shutdown also
exited 0, the lease closed and no dotnet/testhost/deep process remained. These are
disposable provider results: no retained enrollment, connected messages or network
calls occurred. Performance, delivery/p95, full/package and release remain
unqualified; the same three retained profiles still await the coordinated next step.

## Pinned-path follow-up and retained diagnostic — 2026-10-28

Shared focused04 preserved 206 PASS/1 FAIL: its new actual ACL probe did not
establish denial. The corrected fixture-only focused05 passed 207/207 with native
exit 0, zero build warnings/errors and 2280 unchanged inputs, including all 19
contact cases. Receipts remain under
`../deep-client-shared/artifacts/dr0176-closed-operations-20261028-04/` and `-05/`.
The dependent `artifacts/dr0176-cli-20261028-04/terminal.json` passed the same
29 cases with build/native exits 0, zero warnings/errors, 2131 build-source and
2289 source/binary inputs unchanged. No case was excluded to qualify the fixture.

Baseline07 and candidate04 each completed 141/141 rows with native exits 0 and
unchanged helper hashes. Receipts are
`artifacts/p1-storage-benchmark-20261028-baseline07/baseline07.terminal.json` and
`artifacts/p1-storage-benchmark-20261028-candidate04/candidate04.terminal.json`.
Fresh candidate publication used `--no-restore`; its `publish01/terminal.json`
records native exit 0 and 2129 unchanged source inputs. Benchmark capture records
2163 unchanged source/runtime inputs and 32 files. All nine candidate medians
remain above the matched aggregate; the capacity-1024 single read is nearly equal,
without an established improvement. Times are aggregate → manifest in milliseconds:

| Capacity | Single read | Batch read | Atomic cycle |
| ---: | ---: | ---: | ---: |
| 16 | 0.307 → 1.607 | 0.299 → 1.917 | 15.683 → 125.001 |
| 256 | 0.910 → 4.196 | 0.760 → 4.126 | 21.979 → 144.395 |
| 1024 | 3.576 → 3.585 | 2.861 → 4.278 | 51.393 → 158.285 |

Read bytes and native counts are unchanged from candidate03: warm reads use one
Unprotect, two manifest reads and one/two selected objects; atomic cycles use
eight Unprotect, 49 manifest reads and 29 objects. Candidate allocated bytes for
single/batch/atomic are 125944/154696/2489832 at capacity 16,
368776/397528/6387424 at 256, and 1087816/1116528/19251140 at 1024. Small-inventory
allocation and write latency remain worse than the aggregate. Separate costs:

| Capacity | Seed ms | First cold admission ms | Median cold reopen ms |
| ---: | ---: | ---: | ---: |
| 16 | 11.129 → 280.382 | 10.183 → 9.675 | 7.274 → 5.441 |
| 256 | 4.364 → 3109.239 | 10.746 → 67.538 | 7.900 → 52.429 |
| 1024 | 11.711 → 13800.897 | 10.318 → 208.247 | 9.335 → 197.273 |

The full comparison is
`artifacts/p1-storage-benchmark-20261028-candidate04/comparison-baseline07-candidate04.json`.
These improvements over the previous candidate do not change the rejected
aggregate performance comparison or imply delivery/p95 acceptance.

The owner's explicit same-three-profile request and DR-0176's diagnostic exception
then authorized local enrollment and one planned three-message round. The immutable
software was `artifacts/p1-storage-candidate-20261028-04/runtime/`. Evidence lives
under `artifacts/retained-storage-diagnostic-20261028-01/`. The exact local Docker
project had nine healthy services and the same three previously recorded node
images; no Docker mutation occurred. The initial unscoped inventory included six
older containers and was rejected by the coordinator's global count assumption;
both `docker-preflight.json` and corrected project-scoped `docker-preflight02.json`
are preserved. This does not repair the earlier upgrade mount-qualification gap.

`enrollment01/receipt.json` records all 412/438/386 logical slots and every logical
byte preserved, plus exact native file-family byte preservation for all three
profiles. Before snapshots stayed only in RAM under command/storage locks; those
locks were released before each standalone enrollment child and reacquired for
post-checks. Full DSS2 audits, complete membership/value comparisons and native
byte comparisons passed. Snapshots were zeroed in `finally`. Native file-family
counts include zero-byte lock files; file-length-only SQL counts remain 7/8/8.
Enrollment wall observations include post-audit verification and are not delivery
times. Its source/runtime capture had 2170 unchanged inputs and native exit 0.

`preflight01/receipt.json` confirmed 180 events/60 local commands per role,
revision 11, Active epoch 2, three members and the same retained consent. All six
routes were expired without retained faults, so RouteExpired/native exit 1 is
preserved. Authorized normal ConnectionCycle resumed the original state.
In `maintenance01/receipt.json`, role 1 publication succeeded in 51018 ms
(CPU 15656 ms); role 2 failed with business exit 6 after 40889 ms (CPU 13281 ms).
The complete maintenance process took 98446 ms, native exit 1. These are
maintenance measurements. Role 1 success and role 2 pending state remain retained.

`maintenance01/failure-4.json` maps to `VerifyServiceTransition` IL 375, the final
exact signed-predecessor guard, after identity/policy and both signature checks.
Read-only `prekey-relation03.json` uniquely joins the original phase-1 pending
intent to its committed predecessor using the existing derivation. Committed XPS
generation is 5, staged tip is 7, expected direct successor is 6. Both direct-next
generation and exact-predecessor hash tests fail; identity/policy and monotonic
validity comparisons pass. Protected generation 6 links the exact committed 5,
and 7 links 6. The pending entry has no bound XPS bundle, threshold records or
issuance head. A protected chain does not supply historical AccountProof authority.
Earlier read-only selector rejections remain in `prekey-relation01.json`/`02.json`;
the final reader used no storage admission/recovery or business command, exported
only scalar relations and verified the protected manifest bytes unchanged.

`blocked01.terminal.json` records three planned messages, zero authored, no round
execution and next cursor 60; visibility/ACK timing remains unobserved. All 2170
initial-to-final source/runtime/helper inputs stayed unchanged, sessions closed,
native processes drained and the lease released. Metadata-only pre/post receipts
retain protected-file, object and native-file sizes without content or traffic
claims. No reset, replacement operation, blind retry or reauthoring followed the
failure. These checkpoint edits were made after terminal/freeze release and are
not retroactively part of the captured inputs. The same-three-profile diagnostic
remains blocked on the precise contact/prekey lifecycle mismatch.
