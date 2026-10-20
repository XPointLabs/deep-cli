# CLI authority/native latency — 2026-10-20

Scope: existing local`deep-dev-current`, same three retained CLI profiles and
active three-member group epoch2. No Windows/Android device or production work,
account/key/volume reset, new wire/schema/crypto or client runtime change.
Prior complete evidence and all older FAIL receipts remain in
[route renewal checkpoint](cli-route-renewal-2026-10-20.md).

## Cause and correction

The prior final round12 (`cli-route-20261020/steady-05`) passed46/46, but B's
161.890s fanout required one original Store continuation and one lease wait.
Bounded, read-only node logs located the pre-dispatch refusal at
`DeepIdV2NetworkPlacementRuntime.ReadNetworkAsync`, IL424, called by
`ReadPublicationAuthorityAsync`: no acquired observation was available. This
was not a native terminal Store failure; no terminal-incomplete log occurred
in that slice. No raw logs, exception payloads or identifiers are retained here.

The receive observer now returns **false** for the code-owned missing-observation
case. The existing ONION binding owner then performs a genuine independently
verified acquisition before returning the binding in that same request.
Observation cannot mint authority. Publication/effect checks still reject the
missing observation; corrupt custody, clock failures, stopped sources and
cancellation are not converted into valid authority. Unavailable fresh proof
still rejects and leaves custody unchanged. No retry budget/window is enlarged.

## Bounded pure work reduction

The public NCP2 frame was about1.66MB. Native per-effect checks repeatedly read
and parsed it, and re-parsed public ADH1 grammar after authenticating every native
head file. Existing numeric diagnostics separated these costs: across21
rate-limited slow samples, source-file work ranged361–964ms and proof-observation
work471–1387ms per sampled terminal. These nested timings are not additive to
outer authority/lease totals and are not a full-RPC census.

One exact public frame up to4MiB now retains only pure decoded framing. Every
use still rereads actual file bytes/EOF; a byte change takes the complete parser.
Consumers own independent buffers. Larger valid frames keep the original path.
Already verified public ADH1 bytes reuse canonical grammar only after the actual
native record is reread and unprotected. All header, chain, signature-authority,
anchor/index, floor, clock and effect checks remain. No file metadata, decrypted
private state, accepted native floor or currentness result is cached.

## Verification ledger

- Node `cli-native-20261020/focused-01`:118 PASS/11 FAIL. Nine assertions expected
  the old exact base exception for missing observation; two new fixture cases
  requested a refresh interval outside the existing maximum. Original FAIL
  retained. No acceptance predicate changed to satisfy it.
- `focused-02`:129 PASS/native0. Includes real signed runtime/custody paths,
  actual binding-owner reacquisition in the same call, unavailable proof refusal,
  pure grammar counters, independent disposed buffers, changed/malformed source,
  native tamper/link/missing-floor/rollback/clock/expiry and mailbox admission.
  Exception assertions now require the precise missing-observation subtype.
- The same shipping CLI runtime is used as before:
  `c4b8fbd72311ed29af93607fe0605fc177d1bad69aa4790851522a69271626bc`.
- Supported local`node-build-01`, `node-up-01` and`smoke-01` exited0. Node image
  `sha256:5c6b6943f277daf8cd835b2f3664df67f888b609014f850e6ed21228c248a068`
  replaced only the three node containers. All nine services healthy; all mounts
  and CPU settings preserved. The other six containers/images were unchanged.
  Registry remains
  `sha256:33bd279ae4f03d9eabb6a5a3c463df490b5f038fc650427cba14e0023198f685`.

Full source/package, retention/scale, physical device and release qualification
remain separate. Focused tests and one steady-state round do not close those.

## Connected result and complete timing

`cli-native-20261020/steady-01`, strict round13: **46/46 PASS**, all driver
attempts1, **Store resume0 / ACK resume0 / lease wait0**, no observed client HTTP
non-success and normal session close. All three profiles have42 messages /
14 local commands. Six durable receives/ACKs, complete original batches36/29/29,
cold dedup, empty mailboxes and empty GSR/control replay passed. No message was
replaced or manually repeated. Next new strict cursor is14, not13.

| Operation family (sum, seconds) | Before | Final |
|---|---:|---:|
| `account-cold-status` ×3 | 1.774 | 1.945 |
| `cold-control-cursor-empty-replay` ×2 | 13.993 | 11.092 |
| `cold-original-full-batch-replay` ×3 | 99.462 | 86.322 |
| `exact-three-active-owner-head` ×1 | 0.218 | 0.218 |
| `exact-three-active-recipient-head` ×2 | 0.496 | 0.397 |
| `fanout-recipient-native-receive-ack` ×6 | 206.301 | 228.696 |
| `one-command-two-recipient-fanout` ×3 | 366.048 | 320.881 |
| `owner-cold-control-receipt-reverification` ×1 | 3.360 | 4.098 |
| `pair-left-cold-list` ×3 | 6.777 | 6.434 |
| `pair-right-cold-list` ×3 | 24.348 | 25.908 |
| `post-replay-deduplicated-history` ×3 | 7.685 | 6.956 |
| `post-replay-empty-mailbox` ×3 | 24.805 | 21.943 |
| `retained-steady-owner-head` ×1 | 0.262 | 0.237 |
| `sender-original-command-count` ×3 | 0.697 | 0.596 |
| `steady-native-command-preflight` ×3 | 0.705 | 0.697 |
| `steady-native-history-preflight` ×3 | 8.309 | 7.842 |
| `three-way-cold-native-history` ×3 | 6.710 | 6.589 |
| **All 46 commands** | **771.950** | **730.851** |

Active771.950→730.851s (-5.3%); client CPU377.078→335.892s (-10.9%);
three fanouts366.048→320.881s (-12.3%). B161.890→103.950s without its former
Store continuation; A93.572→105.112s and C110.586→111.819s did not improve.
Six receive/ACK206.301→228.696s **regressed10.9%**. Fanout ONION RPC sum
156.234→177.435s and ACK ONION sum97.108→118.385s also regressed. Thus removing
the uncertain operation did not make each network request faster. The older
632.739s baseline remains faster overall; this is not instant-delivery parity.

Read-only final diagnostics`node-work-01` and`authority-work-01` contain only
numbers/closed reasons, no raw logs. Both compared rounds yielded21 rate-limited
slow samples, with2758→2788 lease checks. Weighted per-check authority-source
work23.673→21.976ms (-7.2%); native operation work19.063→17.931ms (-5.9%).
Source-file sample range361–964→152–631ms. Pure framing work is reduced; tests
also prove no repeated grammar decode for identical bytes.

There is **no demonstrated proof-observation/native-join speedup**: proof sample
range471–1387→543–1423ms; native join per-check7.443→7.908ms, and maximum lease
work11.251→11.351s. Those costs, actual protected-file I/O and extra ONION queries
remain next profiling targets. They were not skipped or hidden by a larger lease.
The new run has no terminal-incomplete entries in its bounded log slice.

These are single operational rounds, not an isolated causal benchmark. History
grew39/13→42/14, full batches34/27/27→36/29/29, grant/acquisition states differ,
and the node update made the server runtime cold. The same CLI runtime remained
frozen; no builds/tests/profile operations or source changes ran during timing.
Existing uncertainty/recovery support remains mandatory for real network loss;
one zero-resume round is not a universal no-retry guarantee.
