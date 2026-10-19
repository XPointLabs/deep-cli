# Three-CLI GSR1 performance checkpoint

Owner: Mr. X. Date: 2026-10-19. CLI-first local Docker qualification only;
Windows, Android and production are unchanged. This supplements the
[previous functional checkpoint](cli-gsr-groups-2026-10-18.md), not a wire change
or release acceptance.

## Implementation and security boundary

[Shared](../../../deep-client-shared/docs/architecture/owned-connected-groups.md)
uses an explicit, disposable group-command child to borrow already verified
public endpoint capabilities. It shares the actual acquisition gate and custody
owners, not an ambient/process/persistent cache. Each use still checks actual
protected floors, monotonic boot/time, signed lifetimes, coherent directory/view
bindings and mailbox authority. Nested group calls borrow the same scope;
closing the root clears its references. A captured request cannot silently
receive a replacement authority. Ordinary mailbox APIs are unchanged.

[Node](../../../xnode/docs/operator.md) remembers only a hash and length of
fully authenticated document grammar under the reference-identical native
operation lease. Every read still parses fresh bytes, reads/hashes the real file
after callbacks and checks its native commitment. Changed bytes and every save
receive full structural validation. No mutable document, replay/currentness
decision or native admission is cached. Second-read same/different-length
tampering remains rejected before mutation or HTTP.

No TLS/signature checks, authority windows, deadlines, node CPU quotas, keys or
volumes were relaxed. No protocol, schema or journal generation was introduced.

## Focused checks

Each path below is relative to its repository's
`artifacts/cli-gsr-perf-20261019/` directory. Gates ran serially, separately from
connected E2E; these are not unfiltered/package/scale/device gates.

| Repository / receipt | Result |
| --- | --- |
| Shared `focused-01` | 17 PASS/native0/no skip; initial scope and actual native/group/receive/ACK coverage |
| Shared `focused-02` | Interrupted/native-1 while compilation stalled; no TRX, not PASS |
| Shared `focused-03` | 10 PASS/native0/no skip on final source, including 7 scope cases and actual mixed-view/captured-owner cases; shared compilation disabled |
| CLI `build-01`, `unit-01` | Build native0, no warnings/errors; 49 PASS/native0/no skip |
| Node `node-01` integration | 27 PASS/native0/no skip, including four post-read tamper cases, real peer TLS/H2, ACK/Store and custody recovery fences |
| DevOps `node-build-01`, `node-up-01` | Supported build/activation native0 on all three existing nodes |

Shared focused receipts overlap; their counts must not be summed as unique
tests. Node image is
`sha256:61f9c63631d1784572dff2ae93fe96d49c45a616afc7d4fce1a79f3891ea4de4`.
Each node retains its one-CPU budget; Registry's existing two-CPU budget and
image are unchanged. No identities or native journals were reset.

## Connected result and timing

The original scenario is unchanged. All runs retain the same three CLI profiles
and group revision1; unknown operations are resumed from their original durable
batches, never replaced with new semantic sends. Each run retains its original
receipt, scenario and runtime archive under the CLI artifacts prefix. Failed
attempts are included in timing, not hidden by the final recovery result.

Final `e2e-05`: **PASS/native0**,50 cold commands,1 failed attempt recovered
by the exact original batch retry. Across01–05:159 commands,11 failed attempts,
all preserved. No unknown send was reissued as a new message. The chain proves
mutual contacts, create/invite/accept,3 active members/epoch2 on all three heads,
independent GSR catch-up with empty ordinary mailboxes, one message from each
participant to both peers, exact three-message native histories (one local each),
all original Store batch replays, no duplicates, empty mailboxes, cold owner GSR
receipt verification and both empty recipient control cursors.

Runtime SHA256:
`a329f8cd796e9fa72a2f038d2d09943620a08166bf32badc5ea1be48c75e75be`.
Scenario SHA256:
`eee94d8c07b91e0b45e26c6d63ad8f6d7575a6d8c2cb0f90f36b3bcbae262783`.

| Run | Outcome | Commands | Failed attempts | Receipt SHA256 |
| --- | --- | ---: | ---: | --- |
| e2e-01 | FAIL (preserved) | 35 | 6 | `85c46b7dabfba91d7712003ec723d993a011d607cddf657821d6b2fd7200ae21` |
| e2e-02 | FAIL (preserved) | 17 | 2 | `50f8608cf9e517c392257bb9a0f679bc0db2924072e2d7958cd228510a824d95` |
| e2e-03 | FAIL (preserved) | 31 | 1 | `f0b555d51a5f4e5c359c2d4fb4f46400ff0b718d9ff1517627094ad9f0ed8799` |
| e2e-04 | FAIL (preserved) | 26 | 1 | `c795f6bbb210707d8fa47a23fee07872c0edb015aef098e3d7fe3ebf0a91165e` |
| e2e-05 | PASS | 50 | 1 | `9fdda4dbd5c5ddbb8cc4422b38204bba6d8e879f199c21126e88fdd034f5c30a` |

The original first send by A returned unknown after107.346s; original-batch
recovery completed in39.271s: **146.617s total command time**, compared with the
previous successful227.858s command (35.7% lower, but not a first-attempt PASS).
B returned unknown after97.524s and recovered in65.990s failed +39.440s successful
flush: **202.954s total**, versus227.826s (10.9% lower; also not first-attempt).
C's new send passed its first attempt in **136.355s**. Previous C evidence was
already recovery, so it is not a clean first-attempt baseline.

Each new semantic fanout uses **3 directory proof acquisitions and2 network
closure requests**, versus28–29 proofs and12–13 closures in the old A/B samples.
Independent currentness checks remain. Both successor activations passed in
17.909/30.228s, versus previous97.164/176.528s.

Run01 used the new Shared scope with the previous node image. Node's grammar
fingerprint optimization was installed before02 without resetting state.
The subsequent original pending invitation ACK completed in96.984s, including
14.973s ONION rather than a25s timeout; prior unknown attempts had already made
progress, so this is not a controlled causal benchmark. Native/ONION latency
and first-attempt reliability remain open; do not claim an end-to-end SLO.

### All operation timings

Totals include **every command attempt in01–05**, failed attempts, exact retries,
repeated cold state checks and empty polls. They are sums of recorded CLI command
wall times, **not** a single clean first-run latency. Build/test/engineering pauses
between runs are excluded. Min/max are individual command durations. Restoring
published accounts and contacts does not create fresh ones.

| Operation | Attempts | Failed | Total seconds | Min–max seconds |
| --- | ---: | ---: | ---: | ---: |
| GSR catch-up | 3 | 0 | 67.012 | 18.783–28.453 |
| Аккаунт: холодное открытие | 15 | 0 | 9.385 | 0.445–1.878 |
| Активация / публикация GSR | 2 | 0 | 48.137 | 17.909–30.228 |
| Восстановление acceptance | 1 | 0 | 45.225 | 45.225–45.225 |
| Восстановление fanout | 3 | 1 | 144.701 | 39.271–65.990 |
| История после replay | 3 | 0 | 6.167 | 0.808–3.337 |
| Локальные списки / heads | 47 | 0 | 27.938 | 0.514–0.701 |
| Отправка fanout | 3 | 2 | 341.225 | 97.524–136.355 |
| Полный replay Store | 3 | 0 | 90.896 | 24.131–38.417 |
| Приглашения | 4 | 2 | 373.513 | 16.266–189.979 |
| Приём приглашений / ACK | 6 | 3 | 555.445 | 34.024–130.861 |
| Приём сообщений / ACK | 8 | 0 | 395.864 | 13.461–75.660 |
| Принятие приглашений | 4 | 3 | 253.209 | 41.213–85.153 |
| Проверка пустого ordinary mailbox | 3 | 0 | 50.030 | 12.887–19.993 |
| Проверка сети / публикация | 3 | 0 | 84.702 | 24.910–30.595 |
| Пустой GSR cursor | 2 | 0 | 43.340 | 21.024–22.316 |
| Пустой mailbox после replay | 3 | 0 | 47.819 | 12.659–19.711 |
| Согласие у владельца / ACK | 2 | 0 | 133.013 | 63.308–69.705 |
| Создание группы | 1 | 0 | 15.997 | 15.997–15.997 |
| Сохранённые контакты | 30 | 0 | 66.585 | 0.952–3.794 |
| Холодная native history | 12 | 0 | 17.471 | 0.527–3.241 |
| Холодная проверка GSR receipts | 1 | 0 | 18.293 | 18.293–18.293 |
| **All CLI operations** | **159** | **11** | **2835.967** | — |

Final05 run wall time:772.487s. The sum of run wall times is2860.246s;
CLI command time is2835.967s (47m15.967s). Archive/startup/scenario work accounts
for the difference, not hidden failed commands.

## Still excluded

Subsequent timeout fixes and strict first-attempt candidate measurements are
tracked in the [next checkpoint](cli-gsr-first-attempt-2026-10-19.md). This
historical recovery baseline and its original failures remain unchanged.

Expired prepared ACK / unknown GSR-write recovery, descriptor rotation/handover,
400-day retention, remove/rekey/device/history policies, scale/soak, full/package
qualification and device/release acceptance remain open. Earlier rejected
candidates and evidence are preserved separately.
