# Private storage adapter and disposable benchmark

[DR-0176](../../../docs/survival-program/decisions/DR-0176-bounded-protected-storage-inventory.md)
owns the format, enrollment, atomic commit and cleanup contract. This checkpoint
records only CLI composition and engineering evidence. No retained account has
been enrolled, and no storage performance or release claim is accepted here.

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
