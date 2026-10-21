# Retained NTS quorum and ACK — 2026-10-21

Continues the [grant attribution checkpoint](cli-fanout-grant-attribution-2026-10-21.md).
Same three CLI profiles and group, retained node volumes/keys/history. No reset,
rekey, replaced floor, production change or Windows/Android UI work.

## Cause and bounded repair

The installed signed policy has exactly two sources in two independent families,
requiring both. Correlated Registry diagnostics identify lost authenticated UDP
observations, not a failed TLS pin, changed identity or relaxed time boundary.
An established-session timeout previously entered the ten-second KE backoff,
longer than the signed ten-second sample age. A normal three-second polling wait
after the failed acquisition further delayed recovery.

The observer now retains that same negotiated session after a UDP timeout and
allows the next ordinary poll after two seconds. It still makes at most two
two-second UDP attempts per source per poll. Timeout neither increments nor
resets KE backoff; authentication/session-discard failures still discard the
session and retain exponential KE backoff. Only an authenticated NTP success
resets that history. Registry uses a two-second next-poll delay after a missing
observation quorum; healthy polling and the ten-second process-restart delay
remain unchanged. Missing packets never become time evidence. TLS/hostname/SPKI,
NTS authentication, two-family quorum, signed ages/radii and protected floors
remain mandatory.

This reduces avoidable recovery delay; it cannot guarantee availability during
an outage of either provider in the current two-of-two deployment.

## Source redundancy is authored, not activated

[DR-0160](../../../docs/survival-program/decisions/DR-0160-offline-additive-time-source-succession.md)
adds explicit offline additive source input to the existing same-key renewal.
Every old source tuple is retained; roots, thresholds, ages, radii, genesis and
wire grammar are unchanged. The old signed source list authenticates ceremony
time. Closed input/signer mutation and source-family tests cover this authoring.

The current mailbox-enabled contour intentionally rejects the older operational
preparation/activation ceremony. Coordinated isolated role-volume, issuer-journal
and node-floor rollover is not implemented here. That guard was not bypassed.
No root key was mounted online, no candidate was activated and the installed
source policy still contains TWO entries. Synthetic four-source tests are not
live redundancy evidence.

## Qualification

Captured native Windows PowerShell5.1 / SDK10.0.301 unless stated otherwise:

- Observer: eight actual uncached Go tests PASS; Windows ARM64 helper build
  PASS/native0 in the pinned official Go container.
- Protocol authoring: 29/29 focused PASS, zero skipped/native0.
- Dev offline tool: 118 printed checks PASS/native0; synthetic signed ceremonies,
  not activation of this contour.
- DevOps script contracts: 32/32 PASS/native0. CLI scope contracts: eight
  checks PASS/native0 in PowerShell7.6.5, including the explicit published-path
  boundary and unchanged delivery-only/full qualification distinction.
- Registry NTS/image cases: 53/53 focused PASS, zero skipped/native0. Its local
  cutover test assembly name is `Deep.Protocol.Tests`; the actual project is
  Registry. The first build failed on a compiler-held output; the serial build
  with shared compilation disabled passed. Original failure log is retained.
- CLI: 67/67 PASS, zero skipped/native0; ordinary build and explicit ARM64
  ReadyToRun publish have zero compiler warnings/errors. The CLI, Shared and
  Protocol published PE files have actual ARM64 ReadyToRun headers.
- Supported retained `Up` and `Verify`: native0. New Registry image
  `sha256:ebee47ca9860e88fb74f4ace75e1de36ca2a9f17e851ce9e6e80bba8c922e23a`.
  All three nodes remain on the prior image
  `sha256:e3704142b27bc0ab5b7e8779fdf89303950def1888ac82cb6f70d49950191850`.

These focused gates do not qualify the full source/package/device/release lanes.
Native logs are under superproject `artifacts/cli-nts-ack-20261021/`; actual TRX
files are under each owning repository's matching artifacts directory.

## Strict retained round34

Full46/46 PASS/native0, 12:13:22.932–12:21:13.501 UTC. Every command attempt1;
zero Store/mailbox resumes, lease waits, HTTP non-success or session-close
failure. All three senders and six actual receive/ACK commands, exact cold
history, full original-batch replay, empty mailbox, deduplication and GSR control
checks pass. Each account has105 messages /35 original local commands,
Active3/epoch2. This is a real first-attempt retained round, not recovery of33.

| Operation | Individual wall seconds | Mean seconds | Total ONION |
| --- | --- | ---: | ---: |
| Two-recipient fanout | 50.425 /58.273 /60.116 | 56.271 | 12 |
| Receive + durable ACK | 31.691 /26.198 /24.786 /23.070 /32.828 /17.129 | 25.950 | 17 |
| Cold original-batch verification | 33.174 /32.917 /28.722 | 31.604 | 0 |

Active command total464.413s, CLI process CPU227.844s, driver wall470.569s.
One recipient session was sampled for three minutes; profiler overhead is
included, not subtracted. The ordinary shipping CLI is unchanged from33.
Cold grant acquisitions differ from the earlier warm-authority round33, so
these times do not establish an ACK speedup or regression caused by this patch.

## ACK profile and explicit publish experiment

The nonempty receive/ACK trace also contains that session's following group-send
work. Excluding identifiable waits reveals repeated native SQL preparation and
SQLCipher checks, PBKDF2 in the pre-key connection helper, signature verification
and DPAPI calls. Thread sampling is not kernel CPU attribution or an isolated
ACK benchmark. It does not justify deleting fresh database, floor or signature
checks or extending a private-key cache across owner lifetimes.

The explicit CLI `Latency` publish profile instead precompiles the same Release
graph with ReadyToRun. No trimming, single-file/native-source build, authority
cache or second business stack is added. It targets this CLI host only. The E2E
driver can explicitly select a published `deep.exe` inside its own artifacts
directory and still archives/hashes every actual runtime input. Ordinary build
selection and all full-scenario assertions remain the default.

An initial unsupported profiler mode failed before collection; another startup
probe failed canonical CLI parsing. Neither is ACK evidence. The successful cold
empty-mailbox trace is also kept separate from actual nonempty round34 sampling.
Raw traces, arguments, private paths, payloads and identifiers are not committed.

Local receipts: CLI `artifacts/cli-nts-ack-20261021/steady-34/receipt.json`
and the separately recorded published-runtime round35.

## Published-runtime strict round35

Full46/46 PASS/native0, 12:24:15.910–12:30:12.154 UTC. No profiler, retries,
automatic Store/mailbox resumes, lease waits, HTTP non-success or abnormal
session close. All six receive/ACKs process the real new envelopes. Cold
history/replay/empty-mailbox/deduplication and GSR control checks all pass.
The SAME accounts now each contain108 messages /36 original commands,
Active3/epoch2. Neither failed32/33 receipt is overwritten or relabelled.

| Operation | Round33 completed recovery | Round34 ordinary + sampling | Round35 published |
| --- | ---: | ---: | ---: |
| Mean two-recipient fanout, s | 39.407 | 56.271 | 32.610 |
| Fanout ONION total | 6 | 12 | 6 |
| Mean actual receive + ACK, s | 21.889 | 25.950 | 19.807 |
| Receive/ACK ONION total | 12 | 17 | 12 |
| Mean cold original-batch verification, s | not comparable: includes recovery | 31.604 | 32.211 |

Round35 fanouts:32.424/32.140/33.265s. Receive/ACK:
21.473/18.848/15.856/19.193/18.896/24.573s. Cold original-batch checks:
32.025/32.038/32.569s, zero ONION. Empty-mailbox checks:
4.849/7.860/5.285s. Owner control reverification1.434s; two empty GSR cursor
checks4.296/3.219s. Active353.443s, process CPU191.844s, driver wall356.244s.

Compared with33's completed operations, fanout is17.2% lower and ACK9.5% lower
at the same ONION counts. Compared with the earlier first-attempt full30, ACK
is8.6% lower (21.671→19.807s, both12 ONION). These are successive retained
histories, not identical-state ABBA measurements: publication, grant lifecycle,
host scheduling and runtime compilation differ. A universal or exclusively
ReadyToRun-caused speedup is NOT established. The first sampled34 receive
reports3.581s JIT versus2.093s for35; runtime compiler counters alone do not
attribute end-to-end improvement. Cold full-batch verification did NOT improve.

The new Registry's closed logs from its12:12:35.020 UTC start through
12:31:19.983 UTC contain zero observation-quorum misses and zero query timeouts.
Thus both first-attempt runs pass, but this live window does not reproduce a
provider outage or qualify sustained two-provider availability. Scheduling fault
behavior is covered by focused tests; four-source activation remains unfinished.
The1–2s delivery objective, sustained soak, full package and device acceptance
remain open. No security check was traded for these measurements.

Runtime SHA256:
`9d658a3e8e556ed33974ef0db8cd03a9ad039f56a4ccc9fe62159a377e744b60`.
Scenario SHA256:
`c3ce35ceac8ee4096ff13b69bac795415ba9ec2ce131f47e0407abb80be8d8ff`.
Receipt SHA25634:
`fed7a22d5234d52bb01b4d11e4615f11fd9caefb784ac3660934a3741893496c`;
35:`159ef5bdd5addfb7f791ba5aaebd00ca0fffb8b1f518ad0a58cad30fd97be893`.
