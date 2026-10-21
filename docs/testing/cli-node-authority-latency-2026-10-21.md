# Retained three-CLI ONION/authority checkpoint — 2026-10-21

Scope: the SAME three CLI profiles and three-member group/epoch2 as the
[pre-key checkpoint](cli-prekey-open-latency-2026-10-21.md). No account, consent,
ratchet, keys, database, native history or volume reset; no production or
Windows/Android work. CLI/Shared/Protocol shipping binaries are unchanged.
This is focused source/local-connected evidence, not full/package/device or
release qualification.

## Measured owner and bounded corrections

A real retained A-to-C direct text completed Store, native receive/ACK, exactly
one history entry and an empty subsequent poll under server EventPipe sampling.
The diagnostic driver used `ExternalProfiling`, not the final benchmark lane.
Store26.190s (ONION20.142s), receive/ACK37.828s (two ONION requests24.956s total).
All nine commands succeeded with no owned recovery or non-success HTTP.

Each of the three Linux ARM64 nodes produced a private150-second trace. In-node
Speedscope conversion exhausted the profiler's memory; trace collection itself
completed and host conversion of the first trace succeeded. This is not a fully
successful in-container profiling gate. Nodes remained healthy; raw traces and
private data are not published. Node1 non-wait sampled thread time attributed
to the nearest own method included path validation1.277s, bounded file reads
1.012s, protected record read0.995s, closure file read0.865s and repeated closure
digest computation0.613s. These are sampled thread intervals, NOT exact CPU or
end-to-end request durations. Existing numeric server diagnostics separately
showed roughly94–227 lease checks per mailbox operation, actual protected
proof observation0.748–1.754s and authority-source work1.285–2.942s.

Two node-only corrections remove pure repeated work, not verification:

- The atomic PUBLIC bundle's same closed group/count/length SHA256 digest is
  computed with framing once and reused only after a FULL new bounded file/EOF
  read and exact byte comparison. Returned groups and digest are independent
  copies; consumer disposal/backing-array mutation cannot poison the memo.
  Changed bytes recompute; malformed bytes reject. The existing4MiB memo resource
  bound stays unchanged; larger valid bundles still use the full path.
- Fresh attributes check each actual path entry through the custody root.
  On Unix, .NET10 maps the actual symlink mode to `ReparsePoint`, including
  dangling links; repeated `LinkTarget`/`readlink` per ancestor is redundant.
  Missing entries, links and wrong entry types still reject. See the primary
  [.NET10 implementation](https://github.com/dotnet/runtime/blob/v10.0.0/src/libraries/System.Private.CoreLib/src/System/IO/FileStatus.Unix.cs).

Actual protected-file reads/MACs, permissions, anchor/index/chain equality,
authority signatures, both floor checks, current proof/monotonic clock,
revocation, grants, native sequence/replay joins and all effect-boundary lease
checks remain. No signed TTL/skew/window/lease is extended, no ACK permission
is shared with receive, and no uncertainty is converted to success. Wire,
crypto suite, protocols, persistence and TLS policy are unchanged.

## Gates and deployment scope

- Windows PowerShell5.1 / SDK10.0.301 native runner:57/57 PASS, native0 for
  `DeepIdV2NetworkPlacementRuntimeTests` and
  `FileDeepIdV2DirectoryProtectedHeadStoreTests`. Actual tampering, live/dangling
  link refusal, authority binding, floor/index loss and original deadline checks
  remain covered; digest isolation/changed-frame behavior is added to the
  existing exact-bundle test.
- The SAME57 tests execute on actual Linux ARM64 in the documented
  `node-authority-tests` Docker target:57 PASS,0 skipped, native0.
- Changed Docker target contract:1 PASS, native0.
- Supported `deep-dev.ps1 Build -BuildService node-1`, then retained `Up` and
  separate `test-env.ps1 -Suite smoke -BackendMode deep-dev
  -DeepDevProjectName deep-dev-current`: real Registry proof and all3 ONION
  nodes ready. All nodes run image
  `sha256:948226898c4d30d913b8b1adca2daa2b4e6698308bd05efe089cf690b8c08dde`.
  The auxiliary whole-Mounts JSON equality assertion did not match after
  recreation; it is NOT a passing custody-digest gate. Separate inspection
  confirms the expected nine retained mount bindings per node, including the
  existing named state/key/custody volumes. No reset/provision action was used.

Source/build receipts are under `xnode/artifacts/cli-onion-ack-20261021/`;
the profiled direct driver and strict group round are under
`deep-cli/artifacts/cli-onion-ack-20261021/`. No unfiltered source/package,
carrier rehearsal, scale, physical device or release PASS is claimed.

## Connected measurements

Cursor19 (`steady-01`) terminates46/46 PASS, `steadyStateQualified=true`,
`firstAttemptRequired=true`, `noOwnedUnknownRecovery=true`. Every attempt1;
Store/mailbox resumes, lease waits, HTTP non-success and session-close failures0.
All three original sends reach both peers, all six native receive/ACKs finish,
complete original-batch cold audit/replay remains deduplicated, and ordinary
mailbox/GSR cursors end empty. The same profiles now contain60 messages /
20 local commands each, Active3/epoch2. No reset or replacement logical send.

Runtime SHA256 remains
`7881ea90805cf732db00128521b1694c307a07fa7eeca07eb8f283f87768f036`;
scenario SHA256 remains
`360c082c9dd4f02570a8095d49a4f2622a53fe3b09bedbe397cbfcd6d2707215`.
Only node binaries changed for this comparison. Sequential samples have larger
retained histories and different request counts; they are not an isolated
causal estimate or a statistical performance guarantee.

### All operations, seconds (phase totals)

| Operation | Count | Cursor18 before | Cursor19 after |
| --- | ---: | ---: | ---: |
| Account cold status |3|1.678|1.831|
| Pair left cold list |3|3.709|3.111|
| Pair right cold list |3|5.546|5.479|
| Retained owner head |1|0.325|0.246|
| Native command preflight |3|0.739|0.738|
| Native history preflight |3|2.384|2.358|
| Exact active owner head |1|0.223|0.239|
| Exact active recipient heads |2|0.367|0.410|
| Original sender command count |3|0.743|0.693|
| Two-recipient fanout |3|164.206|149.057|
| Recipient native receive/ACK |6|184.138|198.860|
| Cold native history |3|3.425|3.633|
| Cold original full-batch audit/replay |3|93.223|96.914|
| Post-replay empty mailbox |3|22.925|22.581|
| Post-replay deduplicated history |3|2.218|2.393|
| Cold owner control receipt audit |1|1.752|3.773|
| Cold empty control cursor |2|7.000|7.060|
| All46 active commands |46|494.601|499.376|
| Whole run wall time |1|501.885|506.619|

Individual fanouts A/B/C:61.750/57.046/45.410 →49.339/42.455/57.263s.
Individual receive/ACKs in scenario order:
35.011/31.560/34.833/27.782/27.270/27.682 →
29.624/38.979/31.661/31.956/33.228/33.412s.

| Actual workload | Cursor18 | Cursor19 |
| --- | ---: | ---: |
| Fanout process CPU, s |65.000|61.907|
| Receive/ACK process CPU, s |46.782|50.250|
| All46 process CPU, s |228.999|230.453|
| Fanout ONION HTTP requests |10|8|
| Receive/ACK ONION HTTP requests |13|14|
| Fanout ONION HTTP duration, s |89.116|83.142|
| Receive/ACK ONION HTTP duration, s |85.907|95.987|
| Fanout all HTTP duration, s |100.344|91.990|
| Receive/ACK all HTTP duration, s |140.447|152.592|

Mean fanout54.735→49.686s (**9.2% lower**), but request count also falls10→8.
Mean receive/ACK30.690→33.143s (**8.0% higher**); all46 active commands are
**1.0% slower**. This does NOT demonstrate overall delivery or ACK acceleration.
Do not call the main ONION/authority latency issue fixed or claim Signal-like
speed. These are complete sequential command times, not simultaneous
sender-to-visible-message instrumentation; CPU and HTTP durations can overlap.

## Still open — same S05 priority

The sampled pure repeated work is removed and both native platforms reject the
tested hostile changes. Its end-to-end benefit is not established by this round.
Authority/native checks remain numerous, and encrypted ONION aggregates do not
identify the inner terminal or maintenance purpose. The next optimization must
attribute critical-path acquisition, forwarding, native durable work and
independent ACK work before changing scheduling. Do not remove actual floor/
MAC/effect fences, stretch leases, skip original replay auditing or hide slow
samples behind retries. The1–2-second target and principal ACK latency remain
OPEN, along with the existing full/package/retention/device/release gates.
