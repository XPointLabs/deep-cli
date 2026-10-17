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

## Next, in order

The authoritative sprint/acceptance plan is
[CLI-first in XPointLabs](../docs/architecture/IMPLEMENTATION-PLAN-V1.md#cli-first--первый-приоритет-внутри-s05):
shared headless composition → network/contact/consent → bidirectional text and
recovery → files/images → groups. Network commands are **not implemented yet**.
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
