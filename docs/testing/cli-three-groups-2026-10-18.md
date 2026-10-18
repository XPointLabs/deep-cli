# Three-CLI group candidate checkpoint

Owner: Mr. X. Date: 2026-10-18. Qualification is recorded per receipt, not
inferred from compilation. No Windows/Android or production deployment.

Normative allocation: [DR-0144](../../../docs/survival-program/decisions/DR-0144-multi-account-group-batches.md).
Shared custody and remaining GSR1 composition belong to
[the owner mapping](../../../deep-client-shared/docs/architecture/owned-connected-groups.md).

## Implemented slice

- Multiple accounts, sequential accepted-invite successors and complete exact
  predecessor delivery. Own membership requires actual local consent; observing
  another member's activation does not join this account.
- A complete target snapshot and one identical semantic DGM1 are durably captured
  before dispatch. Independent operations/ordinary sequences per pairwise scope,
  ordered draining within each scope and bounded concurrency across scopes.
- Missing/ambiguous targets reject before capture; semantic history deduplicates
  local fanout copies while every native operation remains independently checked.
- Missing member DID2 is only a query candidate. Current proof acquisition borrows
  the actual held SQL/marker backend without a recursive account/source lock.
  The scoped reader never owns the common transports; foreign/disposed leases
  reject. Current network, directory, time and authenticated floor CAS still apply.
- Historical invitation/consent/proposal windows are checked at signed commit
  time. New membership still requires unexpired consent now. Current directory/
  device checks and valid signatures are unchanged.

The group journal is generation2 only. Earlier QA profiles/receipts are retained;
no legacy reader, migration, reset or replacement intent was added. Current
device enrollment and the final large-fanout scale gate remain unqualified.

## Source checks

Paths below are under each repository's `artifacts/cli-owned-groups-20261018/`:

| Repository / receipt | Observed result |
| --- | --- |
| Protocol `multi-focused-01` | 26 PASS, native0, no skips; three-member reducer and identical semantic copies |
| Protocol `multi-focused-04` | 27 PASS, native0, no skips; historical expiry, expired new-author/late-commit refusal and wrong package-length chunk rejection |
| Shared `multi-native-03` | 2 PASS, native0; actual held-directory borrow and native two-way/cold/replay group regression |
| Shared `multi-final-focused-01` | 94 PASS, native0, no skips; focused persistence/account/ordinary/native/ACK/recovery union before the historical Protocol correction |
| Shared `multi-native-05` | 2 PASS, native0; corrected Protocol, malformed protected chunk rejected without changing storage |
| CLI `multi-build-03`, `multi-unit-02` | build: zero warnings/errors; 45 unit cases PASS, native0, no skips |
| Shared `multi-native-06` | 2 PASS/native0 after consent-before-endpoint-capture correction; still native fixture, not connected transport evidence |
| CLI `multi-build-04`, `multi-unit-03` | build: zero warnings/errors; 46 unit cases PASS/native0, no skips |
| Protocol `multi-graph-02` | normal Release/Debug: zero warnings/errors and exact-three actual assembly/resource/API/source graph PASS |
| Shared `multi-ack-01` | 11 PASS, native0, no skips; common-own ACK snapshot, publication/expired-page/lost-ACK/native/Braid recovery |
| Protocol `cli-multi-groups-20261018/registry-01` | strict generated/source/anchor registry PASS/native0 |

Protocol `multi-focused-02` retained one failure: the earlier time-order test
observed the expiry rejection first. Predicate ordering was corrected without
relaxing either check; `multi-focused-03` is the fresh passing receipt. Shared
`multi-native-01` retained the premature-send error-type regression; the original
business refusal was restored and later receipts pass. No failed receipt changed.

These are focused/source checks, not unfiltered full/package/release acceptance.

## Connected receipts

`eng/Invoke-ThreeClientGroupE2E.ps1` uses three isolated real CLI processes over
the retained `deep-dev-current` signed TLS/ONION/native/replicated-mailbox contour.
It establishes three accepted pairwise contacts, activates two successive joins,
sends from every member to both others, checks cold native histories and replays
original batches. Counts/hashes/closed phases and bounded resource metrics only
are retained; no payloads, credentials, capabilities or account/group selectors.

Under `deep-cli/artifacts/cli-multi-groups-20261018/`:

- `e2e-01`: publication refused `RouteTimePMS2NotBefore`; original account kept.
- `e2e-02`: all accounts published, first pair accepted, second request Stored;
  retained-read result verification stopped the receive. Original work kept.
- `e2e-03`: three accepted pairs and group creation/invitation/acceptance; owner
  sync stopped at an endpoint authority fence. 36 cold commands; not group PASS.
- `e2e-04`: Bob activation/receive/ACK passed after one exact retry. Carol's
  original invitation batch was retained, but a sibling worker exhausted the
  account file-lock wait. No three-member PASS; exact scenario archived by hash.
- `e2e-05`: FAIL/native1,52 cold commands on the same accounts/group. All three
  independently adopted epoch2/members3; Alice and Bob each Stored both message
  copies and both recipients completed receive/ACK. Carol's send stopped before
  group intent capture at `VerifyForOwnMessagingAsync` IL1481. Exact assembly
  metadata identifies the unchanged network-custody fence; a later per-target
  consent mint had advanced custody after an earlier endpoint snapshot.
- `e2e-06`: FAIL/native1,43 cold commands. Corrected authority capture passed;
  Carol's one command was captured, then a Store returned `OutcomeUnknown`.
  This is not evidence of non-delivery and no new send is authored to retry it.
- `e2e-07`: PASS/native0,59 cold commands, zero failed steps, with the same04
  runtime/accounts/group/original commands. All three clients independently show
  epoch2/members3, exactly three native-backed messages (one local/two incoming),
  exact plaintext/sequence matches and no duplicates. Every full original batch
  replay passed; post-replay mailboxes were empty. This qualifies recovery of
  the retained scenario, not a fresh first-attempt reliability run.
  Already received semantic copies can avoid an extra early batch replay only
  after every member's actual native history proves the exact message. Final
  full original Store verification remains unconditional.
- `continuation-01`: FAIL/native1,13 commands. Bob Stored both second-round
  copies; Carol captured its command, then mailbox-grant transport returned
  `OutcomeUnknown`. Original commands were retained, not reauthored.
- `continuation-02`: PASS/native0,23 commands, preserving those same commands.
  Both full batches resumed successfully. Bob and Carol each sent to both other
  members before any receive, exercising Alice's two-peer-scope native receive/
  ACK. One initial ACK exceeded its bounded native verification scope; the exact
  cold retry passed. Every profile then showed exactly five native-backed
  messages, with one local for Alice/two for Bob and Carol, exact author
  sequences1/2 and empty post-ACK mailbox. No first-attempt ACK latency claim.

The07 runtime SHA256 is
`3b099ea0443366156d590ffd4ab266de5da3e3568d015567b07f018d3332d806`;
its archived scenario SHA256 is
`02bd5d915723715efd5dd5bab96dbc64d88a4bb3c9039d740594511965b514d1`.
The continuation uses the same exact runtime. The archived scenario and receipt
retain its independent hash. Do not rerun the first-round driver against this
now-five-message group as if it were a fresh three-message scenario.

The current ACK capture uses one current own/network snapshot for all peer
lookups. Previously a final additional own mint could advance protected network
custody after endpoint capture and correctly invalidate that mixed set. The
strict fence remains. Target workers now queue account operations before taking
the existing lock/authority loan; this prevents sibling lock-wait timeouts but
is not parallel wire-loan qualification. The actual saved scenario and a
profile-free runtime ZIP are archived for new runs; receipts still contain only
closed metadata and hashes, not command output or private profile state.
The successful ordinary-mailbox owner-head phase in the archived05 scenario was
named `owner-publish-complete-head`; it is not GSR1 publish-complete evidence.
The current scenario uses `owner-mailbox-batch-stored-head`.

Only idempotent commands may retry once with a new cold process and new verified
proofs after a closed transient/currentness refusal. New `send`/`create` never
retry as fresh intent. Changed membership, invalid signatures or fork state
still reject normally; a diagnostic category grants no authority.

## Remaining GSR1/release boundary

Cold throughput is not qualified even at three accounts. In05, Alice's first
two-target send took553262ms (4895 native DPAPI unprotects/242718ms protection
work,38 DirectoryProof and23 NetworkClosure requests); Bob's took278710ms
(3561 unprotects/38185ms protection work). These are measured candidate costs,
not transport deadlines. Normal sends currently reverify every retained old
group batch; the full replay gate is useful evidence but not an acceptable
steady-state scheduler. Reducing repeat custody opens/lookups must retain actual
native/receipt authority and preserve unknown original work, not cache a Stored
boolean as proof or remove final fences.
The multi-scope ACK first attempt also exhausted the30-second scope during final
native reconciliation. Recovery passed without extending that budget. Repeated
semantic/source opens across callback fences remain a performance blocker; this
checkpoint does not claim that cost has been optimized away.

Ordinary group delivery is not GSR1. The dormant server opaque/CAS service does
not supply current DID2 placement, an E2EE descriptor/key carrier, protected
recipient control custody or verified client GSS1 quorum/recovery. Those paths
remain unfinished and the host boundary remains unavailable. The historical
expiry correction is necessary, but not sufficient, for long-offline recovery;
historical device/directory changes and the complete retention/handover gates
remain separate. S11 and release are not accepted.
