# Real CLI remote file/image slice

Owner: Mr. X. Scope: local `deep-dev-current`, two retained accepted CLI accounts;
no device UI, production update, Release publication or group acceptance.
Normative allocation: root DR-0141 / `blob-chunk-v1.registry.json`.

## Source and actual transfer

Shared owns prepare/queue/send/download and native receive custody. CLI owns only
isolated profiles, source/output files and process scheduling. Blob requests go
through the existing masked three-hop ONION transport to two verified signed
Blob nodes. Nodes receive ciphertext/public commitments, not DAM1/object keys or
plaintext metadata. Independent authenticated received DMC2 history selects the
manifest before download; key-free SQL/UI projections are selectors only.
All chunks, AEAD tags, complete geometry and current owned receive custody pass
before any plaintext is written. CLI staging never overwrites a destination.

`artifacts/cli-files-groups-20261018/e2e-01` remains FAIL/native1. Initial
orchestration incorrectly used retry-only preparation for an uncreated offer;
the owner correctly refused to author caller-selected work. No object/account
or key was replaced. The fix splits owner-generated queue from exact retry and
adds protected pending/retained operation projections.

`e2e-02/receipt.json` passed/native0:28 cold processes,0 unexpected failures.
The two expected nonzero exits are explicit overwrite-refusal checks, not waived
failed transfers. Started2026-10-18T03:53:22Z, finished04:11:18Z.

| Direction | Fixture | Plaintext bytes | Complete remote SHA256 |
| --- | --- | ---: | --- |
| Alice→Bob | generated document,3 chunks | 524325 | `28d74fa5755c48ed29abc801895d72119129c7e3a37be3aee13116e689f551e5` |
| Bob→Alice | valid PNG,1 chunk | 68 | `1e8f472d1b58b5c8b29fd9d3ec58f5e34451f05d1ff114748e136d8442b13308` |

Both actual independently downloaded output files match their source hash.
The PNG fixture also decoded through the native Windows image decoder (1×1).
Cold identical prepare retains object/expiry; exact send and repeated mailbox
sync do not create duplicate offers. The existing output hash is unchanged after
overwrite refusal. No partial staging remains. Store is verified but is never
described as recipient delivery until the other account's download/hash passes.

Runtime SHA256 `a019618617e803898532443c9917bbbc6e786431efdb40a290f266d11d147e5d`;
scenario SHA256 `b39ef54a05fc487987502762f62a733065a1ea5eab201e56d29c86e698a59bc6`.
The adjacent `local-runtime.json` binds9 actual image digests to supported local
activation `deploy-01`. Both Build/Up native exits0 preserved55 mounts, no reset.

## Corrections after the first connected run

The first successful replay unnecessarily uploaded already confirmed chunks.
Shared now validates the requested original manifest and original verified Store
before returning a retained result, including still-retained working Stored
rows. It does not trust a projection flag or recreate expired/missing evidence.
The hostile payload case and unchanged exact replay are separate fixture tests.

Node descriptor publication is now staged/fsynced/atomic. Closed unpublished
staging is removable on cold open; corrupted published custody and unknown names
remain fail-closed. The retained chunk store and node identities are unchanged.
`deploy-02` Build/Up passed with9 services,55 identical mounts and no reset.

The final-binary cold continuation `e2e-03` passed/native0:24 cold processes,
0 unexpected failures, both original remote hashes/metadata exact, repeated
Store/receive/dedup and both overwrite refusals passed. It reuses the same
objects/operations after the supported node restart, not a fresh account/contact/
create experiment. Started2026-10-18T04:14:23Z, finished04:20:11Z.
Runtime SHA256 `f8033f1815299b295c0e8d2d1ef6396ec2bd2de3d02dc482df0fca92de7fa48c`;
scenario SHA256 `0b3c212713a744f1436ff0c367e91d0080a060c781f0b46feebb0de93d6f59eb`.
The adjacent actual-image receipt binds supported `deploy-02`. Document send
replay fell from164s in02 to25s in03; this is an observation, not an SLO/benchmark.

## Focused source closure

All receipts use fresh directories below `cli-files-groups-20261018` in the
respective repository; .NET children ran under explicit Windows PowerShell5.1.

| Owner / receipt | Result |
| --- | --- |
| CLI focused05 | 37 PASS/native0/0skip |
| Shared focused04 | 78 PASS/native0/0skip |
| Protocol focused06 | 270 PASS/native0/0skip |
| Node integration focused03 | 4 PASS/native0/0skip |
| Node core focused06 | 65 PASS/native0/0skip |
| Protocol graph04 | normal Debug+Release builds and exact-three actual assembly/API/resource graph PASS/native0 |
| Protocol registry01 | strict source/resolved/schema/magic/source-anchor gate PASS/native0 |

Original failures are retained: Shared's test helper argument mismatch, old
terminal/API inventories before DR-0141, old retired-frame diagnostic names and
pre-cutover API snapshots. The snapshots now bind the current source closure,
not a newly accepted package or independent security review. Node core's stale
pre-key-store fixture now supplies distinct synthetic node ID and verification
key; it does not make production identifiers equal signing keys.

These are focused source/connected receipts, **not** canonical unfiltered full
source/package, sustained recovery, release-contract or device qualification.

## Still open

- Durable partial-download progress, cancel/materialization-driven retention,
  expired-object GC, full quota/expiry/churn/handover and large-file throughput.
- Image/document/voice/video/avatar UI and physical Windows/Android evidence.
- Current DID2 governed groups: authoring, semantic consumer, protected state,
  current control authority/quorum and durable fanout are not composed. Old
  GroupV1 structures/fixtures cannot authorize a group or count as group E2E.
- Full/package/dependency/evidence/security/ops/release acceptance.

No group text was disguised as an ordinary direct message; no SessionId adapter,
fake authority, direct file-server fallback or plaintext private storage access
was used for these CLI claims. S10/S11 and the release remain unaccepted.
