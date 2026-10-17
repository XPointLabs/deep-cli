# Deep CLI

Headless client for the current DID2 stack. Uses
`deep-client-shared/Deep.Client.Shared.Production.csproj` and current Protocol;
no MAUI workloads, emulator or device deployment for the inner development loop.
Place this repository beside `deep-client-shared` and `deep-protocol`, as in the
XPointLabs workspace. Requires Windows and .NET SDK10.0.301 initially.

## Available now

```powershell
dotnet build Deep.Cli.slnx --configuration Release
dotnet run --project src/Deep.Cli --no-build --configuration Release -- --help
```

Account commands:

```text
deep account create --profile alice --network <32 lowercase hex network ID> --name Alice
deep account status --profile alice --network <same network ID>
deep account address --profile alice --network <same network ID>
```

`create` generates the real Shared DID2 account and device state; it does not
register/publish on the network. `status` does not emit identity. `address` and
`create` explicitly return the public resolver address. JSON goes to stdout;
closed errors to stderr with nonzero exit. Ctrl+C cancels the operation.
Recovery phrases/keys/raw exceptions are never printed. There is no reset,
recovery export, arbitrary storage-path or raw-RPC command.

Profiles live only in the current user's local application-data directory under
`XPointLabs/DeepCli/<network>/<profile>`. Each has a private Windows ACL, current-user
DPAPI aggregate protection and the same Shared SQLCipher/account owner. Commands
hold an exclusive per-profile lease; no MAUI, Android or production state is opened.
Keep QA profiles for restart/recovery testing instead of resetting after failures.

Every aggregate decryption uses native DPAPI; no plaintext decryption cache is
retained by the adapter. Numeric `protectionWork` reports native call counts/time
only. `networkWork` groups public HTTP by a closed endpoint category;
it contains counts/status totals/durations, never URLs, bodies or identifiers.

## Real network and business commands

The initial network adapter consumes the existing **public** `deep-dev-current`
bundle (`deep-dev.json`, genesis XNA1/DTS1/ADH1 and public `dev-ca.crt`). It reads
no operator/node/signer secrets. Pass its directory as `--bootstrap` and an
explicit canonical HTTPS origin as `--registry`; the bundle network must equal
`--network`. The CA is app-scoped, with hostname/EKU/current-chain/revocation
checks unchanged. No global trust import or TLS bypass.

Alongside `--profile` and `--network`, commands accept:

| Command | Additional options |
| --- | --- |
| `network verify` | `--bootstrap`, `--registry` |
| `contact request` | network options, `--address`, `--operation` |
| `contact accept` | network options, `--conversation`, `--operation` |
| `contact stop` | network options, `--operation` |
| `contact list`, `contact operations` | none; protected local projections only |
| `mailbox sync` | network options; one actual page/materialization/ACK |
| `message queue` | network options, `--conversation`, `--text` |
| `message send` | network options, `--conversation`, `--operation`, `--text` |
| `message list` | `--conversation`; explicitly returns message history |
| `message pending` | none; returns existing exact pending text commands |

Logical operation IDs are nonzero **32 bytes /64 lowercase hex**; conversation
IDs are32 bytes /64 hex. `queue` durably authors one message and returns its
operation. `send` retries that exact operation/text, never queues a replacement.
`stored` means verified mailbox storage, not recipient acceptance/delivery.
`stop` uses the existing account-owned cancellation path, not remote recall or
proof of noncommit. Unknown outcome remains retained. Commands have a120s
whole-operation budget; neither protocol windows nor peer deadlines are extended.
Failures emit only closed phase/category/check and owned method/IL metadata.

`eng/Invoke-ContactTextE2E.ps1` launches separate real CLI processes for two
persistent profiles: publication → request → mailbox receive → consent → text
both ways → cold history/duplicate checks. Arguments/results containing addresses,
operation IDs and plaintext remain in memory, never in its evidence receipts.
Use a fresh `-RunDirectory` beneath this repository's ignored `artifacts/`.
The driver fingerprints the complete bounded runtime output tree before/after
commands, including managed assemblies, native providers and configuration.
An apphost EXE hash alone does not identify .NET application code. The receipt
contains the combined digest, not runtime paths or profile state.
`-ReusePublishedAccounts` resumes already initialized profiles without repeating
setup; it supplies no authority and all business/currentness checks still run.
`-IntentRevision` is an explicit separate QA command, not automatic retry: never
advance it to overwrite or silently evade an unresolved original intent.
`-ResumeContact` continues two already materialized, unique contacts only if
their exact conversation IDs and opposite initiator roles match. It still sends
the same owned acceptance operation and requires actual peer acceptance before
text. Its receipt is explicitly a **retained-contact continuation**, not evidence
of a new Initial publication/store in that run; qualify the earlier receive
separately and use the full scenario for final fresh-cycle acceptance.
`-RetryExactTransient` tests one bounded cold-process retry of an identical
idempotent business command after an uncertain/cancelled or retryable-before-
forward result. It never repeats account creation/text queueing, changes an
operation ID, or extends authority. Both attempts and every failure diagnostic
remain in the receipt; all delivery/history checks must still pass.

Closed failure diagnostics distinguish the known ingress control classes
MalformedFrame/WrongOrigin/Saturated/Unavailable from arbitrary exception text.
This does not authorize automatic retries or imply end-to-end noncommit.

## Next, in order

The authoritative sprint/acceptance plan is
[CLI-first in XPointLabs](../docs/architecture/IMPLEMENTATION-PLAN-V1.md#cli-first--первый-приоритет-внутри-s05):
shared headless composition → network/contact/consent → bidirectional text and
recovery → files/images → groups. Network commands are implemented; connected
contact/text acceptance is still being debugged, not claimed complete.
Do not interpret local account creation as network, message or device E2E PASS.
Two CLI profiles will use the real local Registry/three-node Docker topology,
existing TLS/authority/native crypto and persistent storage. No mock-success path.

Run `dotnet test Deep.Cli.slnx --configuration Release -m:1` for the focused CLI
suite. Full source/package gates and subsequent Windows/Android physical E2E
remain required for release. This repository publishes no release automatically.

## Initial account-slice evidence (2026-10-17)

`artifacts/cli-account-20261017/focused-02`:12PASS/native0/0skip, no compiler
warnings/errors, Windows PowerShell5.1 / SDK10.0.301. Includes real DPAPI tamper
refusal and native DID2/account/device persistence, strict arguments, cancellation
and refusal to overwrite an existing account. Initial `focused-01` failed before
account creation because CLI incorrectly expected a32-byte network ID; current
CLI uses the existing16-byte DID2 network ID. The failed receipt is retained.

`process-01/receipt.json`: separately launched actual `deep.exe` processes created
two distinct accounts, reopened the same public address, rejected duplicate
creation without changing the original, and omitted the address from status.
All six checks passed/native0. Output captured only in memory; the receipt has
booleans and executable SHA256, no account addresses, keys or private paths.
This qualifies **local account behavior only**, not network/contact/device E2E.
