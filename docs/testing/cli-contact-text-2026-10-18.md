# Real CLI contact/text evidence

Source/architecture owner: root S05 CLI-first slice and DR-0140. No second
business stack or fake authority is used by this adapter.

`artifacts/cli-contact-text-20261017/e2e-32/receipt.json` was diagnostic:
bidirectional cold history and duplicate polls verified, but both Store outcomes
remained unknown. It records24 steps,5 failed attempts, `passed=false` and
unsettledStoreCount2. It must not be counted as complete CLI acceptance.

## Strict retained continuation

`e2e-33/receipt.json` passed with actual process exit0:

- 24 real cold CLI process steps against local Docker Registry/XNode.
- Both original semantic text operations obtained verified Store receipts.
- Both cold histories contain exactly one own and one peer text.
- Repeated mailbox polls completed without duplicate materialization.
- `observeUnknownStore=false`, unsettledStoreCount0, historyVerified true.
- 4 transient failures are retained; each recovered with one identical cold
  retry. No replacement logical message or reset was used.

Runtime input SHA256:
`76918ebd46026be3aa099942007faecac918a45afb0ec2d138002ec9e7019ae1`.
Started2026-10-17T20:25:36Z, finished20:39:14Z. The original request/accept
cycle was exercised in earlier retained runs;33 is explicitly not evidence of
a fresh Initial/contact creation in a single unchanged-runtime scenario.

CLI matching focused16 passed35/native0/0skip without compiler diagnostics.
Shared's matching attempt-key focused07/08 passed4+12/native0/0skip. Node's
memory-transition focused27/28 passed31+5/native0/0skip. Supported local
activation deploy19 Build/Up exited0 and preserved9 services/54 mounts.

## Complete contact/text continuation on the fresh pair

Run34 created and published two genuinely new accounts on the same CLI build,
but both original Initial Store attempts exhausted the native deadline. Its
receipt remains FAIL/native1. After byte-identical public inputs moved from
Windows bind reads to the supported Linux public-output volume, run35 resumed
those exact accounts and contact intent without reset or replacement.

Run35 passed/native0:24 cold process steps,0 failed attempts, both consent
sides retained, verified text Store and receive/ACK in both directions, both
cold histories exactly once, duplicate polls passed, unsettledStoreCount0.
Started2026-10-17T21:09:32Z, finished21:23:16Z. CLI runtime SHA256 remains
`76918ebd46026be3aa099942007faecac918a45afb0ec2d138002ec9e7019ae1`.
The separate local-runtime receipt records the actual image digests; all three
nodes match supported deploy19 and source52045ee. Public-output activation01
retained9 services and all50 non-public-output mounts; no private state changed.
This is the complete fresh-pair contact/text path across34→35, not a claim
that the earlier failed first Initial attempts were successful.

The independently found Node-ID/descriptor-key correction passed67 source
tests and supported deploy21 Build/Up0 with9 services/55 unchanged mounts.
Run36 sent an explicitly NEW synthetic text pair on those upgraded
nodes, not a replacement for any unknown send: original35 passed first, and
the driver verifies retained consent, no prior pending text and both original
histories. Its own source SHA256 and numeric text revision are captured.
Scenario scheduling guards passed4/native0 without CLI processes or network.
Run36 passed/native0:26 cold process steps,0 failed attempts, verified Store
and receive/ACK in both directions, duplicate polls and cold histories passed,
unsettledStoreCount0. Started21:24:53Z, finished21:31:35Z. Its actual node image
digests match supported deploy21/source de53e06. CLI runtime input SHA256 is
unchanged; the executed scenario SHA256 is
`73e40ce92e78490208c20cd4837bd885630b772dbac984b59a4a1aba90ee4be5`.
A separate post-upgrade cold check found exactly2 own+2 received texts and0
pending on EACH client: both original and new pairs survived, exactly once.
Final CLI focused17 passed35/native0/0skip without compiler diagnostics.
Supported local smoke01 separately verified Registry proof and3 ONION nodes
after bounded32s readiness recovery; this is not uninterrupted availability.

No production/device test, first-attempt reliability, full source gate,
package qualification or release readiness is claimed here.
