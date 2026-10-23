# Retained CLI55 recovery and idle authority scheduling

Date:2026-10-23. Same three retained CLI profiles and local three-node contour;
no reset, rekey, production deployment, Windows/Android app operation or release.

## Implemented slice

[DR-0173](../../../docs/survival-program/decisions/DR-0173-idle-authority-scheduling.md)
removes the complete authority borrow from the idle *due check*. An absent memo
is acquired on business demand, not speculatively after independent ACK. Current
far-from-deadline scheduling does no protected/network read. Due refresh keeps
the full producer; every business borrow still joins actual account, protected
history/fork, issuer, freshness and clock. Captured loans, replay counters and
original requests/deadlines are unchanged. No private key/read cache is added.

In recovery54-02, cumulative idle maintenance reached77–203s on some sessions,
and local history queries took29–46s. This establishes unnecessary background
work and contention, not a complete attribution of transport latency. CLI error
receipts now include the existing closed persistence/session counters as well
as network/protection counters; exception messages and private paths stay closed.

Acquisition lifecycle and original46 were already completed in the
[acquisition checkpoint](cli-acquisition-lifecycle-2026-10-22.md). That round is
not repeated or re-authored. The current retained pending cursor was55.

## Source and runtime verification

- Shared focused13/13 PASS, skipped0, native0: working/independent scope and
  idle scheduling; real protected storage reads counted, absent/current memo,
  due refresh, on-demand acquisition, fork, cancellation and clock rollback.
- CLI70/70 PASS, skipped0, native0. Publish succeeds using the existing Latency
  profile, explicit win-arm64, ReadyToRun, no trim or single-file changes.
- Fresh receipts: `artifacts/cli-idle-scheduling-20261023/` in each changed repo;
  root captured native logs use the same prefix. Focused tests are NOT canonical
  unfiltered full, package, physical or release qualification.

Published runtime fingerprint:
`d70f2a5b56bfc0fa17f2fcfab12eb7c2c18bb8c18bee06d5a35e131531403e75`.
Scenario remains:
`4c33e9d224361d0705293351fb738375422955ffd3cf62ac2a010b03f5695475`.

## Original55 recovery

`recovery-55-01/receipt.json`:43/43 PASS, native0,
03:35:10.583–03:41:34.768Z. A's original pending command56 resumes exactly once;
B/C author their previously absent original command56. No replacement command
or account reset. Each cold native history contains168 messages /56 original
local commands, exact semantic copies once, Active3/epoch2. All six recipient
receives have independently durable ACK, followed by empty mailbox and dedup
checks after cold reopen. Automatic Store/mailbox resumes0, lease waits0.

`recoveryDeliveryQualified=true`; `deliveryLatencyQualified=false` and
`recoveryQualified=false`: this is delivery recovery, NOT full historical Store
audit or new-round first-attempt latency. Full/archive54 remains failed in its
original immutable receipt; no result is overwritten.

| Operation |Count |Mean seconds |Total seconds |
|---|---:|---:|---:|
| Original pending resume |1 |39.327 |39.327 |
| Remaining new fanout |2 |66.708 |133.416 |
| Receive plus independent ACK |6 |26.333 |157.999 |
| Empty mailbox |3 |7.489 |22.467 |
| Cold native history |3 |1.157 |3.472 |
| Deduplicated history |3 |0.960 |2.880 |
| ALL active commands |43 |— |380.191 |
| Scenario wall |— |— |384.184 |
| CLI CPU |— |— |184.048 |

All reported session maintenance milliseconds and failures are0. Sub-millisecond
scheduling work is rounded by the existing integer counter; this is not a claim
of no CPU work or a controlled performance A/B. A new round56 on the identical
runtime is measured separately below.

## New56 first-attempt delivery

`delivery-56/receipt.json`:40/40 PASS, native0,
03:42:05.205–03:47:21.836Z. Same runtime/scenario/profile/group inputs as recovery55.
All commands use attempt1, automatic Store/mailbox resumes0, lease waits0,
network failed0/nonSuccess0, maintenance failures0/reported milliseconds0.
`deliveryLatencyQualified=true`, `firstAttemptRequired=true`; no full/archive
or release qualification. Each cold native history has171 messages /57 original
local commands, exact current-round copies once. Empty mailboxes and duplicate
checks pass after cold reopen. Next retained cursor57; never re-author55/56.

Fanout samples:54.699 /46.130 /47.281s. ACK includes Retrieve, native receive,
materialization and independent durable tombstone, not only an ACK round trip.

| Comparable measured operation |Clean53 |New56 |Time change |
|---|---:|---:|---:|
| Two-recipient fanout, mean3 |51.299s |49.370s |−3.8% |
| Receive plus ACK, mean6 |24.541s |19.736s |−19.6% |
| Empty mailbox, mean3 |9.269s |7.569s |−18.3% |
| ALL active commands |350.329s |315.769s |−9.9% |
| Scenario wall |353.798s |316.631s |−10.5% |
| CLI CPU |168.954s |180.735s |+7.0% |

Baseline is the separately captured clean53 in the
[floor checkpoint](cli-node-floor-read-batching-2026-10-23.md), not failed55's
199.632s or differently scoped recovery54/55. These are observed timings, not a
controlled causal A/B: authority windows, warmth and retained history differ.
Fanout now performs7 ONION/9 directory proof requests versus6/8 in53; ACK has12
ONION/30 proofs versus12/30. Removed idle work does not remove a security check.

Full56 operation table:

| Phase |Count |Mean seconds |Total seconds |
|---|---:|---:|---:|
| Cold account status |3 |0.404 |1.213 |
| Pair left contact list |3 |1.608 |4.824 |
| Pair right contact list |3 |2.413 |7.240 |
| Retained owner head |1 |0.272 |0.272 |
| Command preflight |3 |0.213 |0.638 |
| History preflight |3 |0.967 |2.902 |
| Exact active owner head |1 |0.249 |0.249 |
| Exact active recipient head |2 |0.188 |0.375 |
| Original-command counter |3 |0.211 |0.633 |
| New two-recipient fanout |3 |49.370 |148.110 |
| Receive plus independent ACK |6 |19.736 |118.414 |
| Cold native history |3 |1.154 |3.463 |
| Empty mailbox |3 |7.569 |22.707 |
| Deduplicated history |3 |1.576 |4.729 |
| ALL active commands |40 |— |315.769 |

Remaining work is material: fanout ONION aggregate58.040s plus directory8.995s,
6657 actual protected reads/19.809s storage-load aggregate and185 application
opens. Receive/ACK ONION50.399s, directory20.348s,3606 protected reads/11.642s
storage aggregate. Nested phase timings overlap and must not be added as a
wall-time decomposition. No1–2s or Signal-parity claim is made.

Local services remain9/9 healthy; no node rebuild/configuration/rollout was
needed for this Shared/CLI-only change. Full/archive54, canonical full/package,
operational rehearsal, device and release blockers remain open. No GitHub
Release or main merge was performed.
