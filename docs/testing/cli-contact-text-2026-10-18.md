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

Fresh-pair run34 exercises account creation/publication, request/accept and
both text directions on this unchanged CLI/runtime candidate. Its eventual
receipt, not this checkpoint, determines that separate acceptance.

No production/device test, first-attempt reliability, full source gate,
package qualification or release readiness is claimed here.
