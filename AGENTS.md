# Deep CLI

The workspace `../AGENTS.md` applies. This repository owns only console/platform
adapters, isolated profiles and black-box CLI scenarios. Current sprint order
and acceptance belong to `../docs/architecture/IMPLEMENTATION-PLAN-V1.md`.

- Use `Deep.Client.Shared.Production.csproj` and current Protocol, not MAUI or
  the retired Shared project graph. Do not duplicate business orchestration.
- No fake proofs, in-memory storage, permissive TLS, fixture authority or direct
  private node storage access for client E2E.
- Keep CLI state under its own namespace; never open/reset device/prod profiles.
- Never emit recovery phrases, keys, raw exceptions, credentials or private paths.
  Public addresses are returned only by explicit account creation/address commands.
- Windows is the initial local host. No macOS build until explicitly requested.
- Implement one complete slice, then focused tests; full/package and physical
  Windows/Android qualification remain distinct final gates.

Run `dotnet test Deep.Cli.slnx --configuration Release -m:1` under Windows
PowerShell5.1 / SDK10.0.301. Use the root native test runner for captured receipts.
