[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$BootstrapDirectory,
    [Parameter(Mandatory)][string]$RegistryOrigin,
    [Parameter(Mandatory)][string]$RunDirectory,
    [string]$ExecutablePath,
    [switch]$ReusePublishedAccounts,
    [switch]$RequireFirstAttempt,
    [switch]$PersistentSessions,
    [switch]$RecoverIncompleteSteadyRound,
    [switch]$DeliveryOnly,
    [ValidateRange(0,63)][int]$SteadyStateRound = 0,
    [ValidateRange(0,31)][int]$GroupRevision = 0,
    [ValidatePattern('^[a-z][a-z0-9-]{0,31}$')][string]$AliceProfile = 'cli-gsr-alice',
    [ValidatePattern('^[a-z][a-z0-9-]{0,31}$')][string]$BobProfile = 'cli-gsr-bob',
    [ValidatePattern('^[a-z][a-z0-9-]{0,31}$')][string]$CarolProfile = 'cli-gsr-carol'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($SteadyStateRound -gt 0 -and (-not $ReusePublishedAccounts -or $RequireFirstAttempt)) {
    throw 'Steady-state requires retained accounts and is distinct from fresh lifecycle qualification.'
}
if ($RecoverIncompleteSteadyRound -and ($SteadyStateRound -eq 0 -or -not $ReusePublishedAccounts -or $RequireFirstAttempt)) {
    throw 'Recovery requires an explicit incomplete retained steady round; it can never qualify first attempt.'
}
if ($DeliveryOnly -and ($SteadyStateRound -eq 0 -or -not $ReusePublishedAccounts -or $RecoverIncompleteSteadyRound -or $RequireFirstAttempt)) {
    throw 'Delivery-only requires a new retained steady round; recovery and full lifecycle qualification remain separate.'
}
$strictCommands = $RequireFirstAttempt -or $SteadyStateRound -gt 0
$messagePrefix = if ($SteadyStateRound -gt 0) { 'Three CLI round '+($SteadyStateRound+1)+' ' } else { 'Three CLI ' }
$repo = Split-Path $PSScriptRoot -Parent
$exe = Join-Path $repo 'src/Deep.Cli/bin/Release/net10.0-windows/deep.exe'
$run = [IO.Path]::GetFullPath($RunDirectory)
$artifactRoot = [IO.Path]::GetFullPath((Join-Path $repo 'artifacts')) + [IO.Path]::DirectorySeparatorChar
if (-not $run.StartsWith($artifactRoot, [StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $run) -or @($AliceProfile,$BobProfile,$CarolProfile | Select-Object -Unique).Count -ne 3) { throw 'Fresh artifact directory and distinct isolated profiles required.' }
if ($PSBoundParameters.ContainsKey('ExecutablePath')) {
    $exe = [IO.Path]::GetFullPath($ExecutablePath)
    if (-not $exe.StartsWith($artifactRoot, [StringComparison]::OrdinalIgnoreCase) -or
        [IO.Path]::GetFileName($exe) -cne 'deep.exe' -or -not (Test-Path -LiteralPath $exe -PathType Leaf)) {
        throw 'Published executable must be an existing deep.exe inside this CLI repository artifacts directory.'
    }
}
foreach ($path in @($run, $BootstrapDirectory, $exe)) {
    for ($cursor = [IO.Path]::GetFullPath($path); $cursor; $cursor = [IO.Path]::GetDirectoryName($cursor)) {
        if ((Test-Path -LiteralPath $cursor) -and ((Get-Item -LiteralPath $cursor).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Reparse path rejected.' }
    }
}
$network = (Get-Content -LiteralPath (Join-Path $BootstrapDirectory 'deep-dev.json') -Raw | ConvertFrom-Json).networkIdHex.ToLowerInvariant()
if ($network -cnotmatch '^[0-9a-f]{32}$') { throw 'Explicit public network binding required.' }
$scenarioPath = $PSCommandPath
$scenarioHash = (Get-FileHash -LiteralPath $scenarioPath -Algorithm SHA256).Hash
$sessionModulePath = Join-Path $PSScriptRoot 'CliSession.psm1'
$sessionModuleHash = (Get-FileHash -LiteralPath $sessionModulePath -Algorithm SHA256).Hash
function Require-ScenarioInputs {
    if ((Get-FileHash -LiteralPath $scenarioPath -Algorithm SHA256).Hash -cne $scenarioHash -or
        (Get-FileHash -LiteralPath $sessionModulePath -Algorithm SHA256).Hash -cne $sessionModuleHash) { throw 'Scenario inputs changed.' }
}
function Runtime-Fingerprint {
    $root = [IO.Path]::GetDirectoryName($exe) + [IO.Path]::DirectorySeparatorChar
    $entries = @(Get-ChildItem -LiteralPath $root -Recurse -Force)
    if (@($entries | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }).Count) { throw 'Runtime links rejected.' }
    $files = @($entries | Where-Object { -not $_.PSIsContainer } | Sort-Object FullName -CaseSensitive)
    if ($files.Count -lt 3 -or $files.Count -gt 2048) { throw 'Runtime inventory bound.' }
    $rows = @($files | ForEach-Object { $_.FullName.Substring($root.Length).Replace('\','/') + '|' + (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash })
    [Convert]::ToHexStringLower([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes(($rows -join "`n"))))
}
$runtimeHash = Runtime-Fingerprint
[void](New-Item -ItemType Directory -Path $run)
Copy-Item -LiteralPath $scenarioPath -Destination (Join-Path $run 'scenario.ps1')
Copy-Item -LiteralPath $sessionModulePath -Destination (Join-Path $run 'CliSession.psm1')
if ((Get-FileHash -LiteralPath (Join-Path $run 'scenario.ps1') -Algorithm SHA256).Hash -cne $scenarioHash) { throw 'Scenario archive differs.' }
Compress-Archive -LiteralPath ([IO.Path]::GetDirectoryName($exe)) -DestinationPath (Join-Path $run 'runtime.zip') -CompressionLevel Fastest
if ((Runtime-Fingerprint) -cne $runtimeHash) { throw 'Runtime changed during archive.' }
$started = [DateTime]::UtcNow
$steps = [Collections.Generic.List[object]]::new()
$sessions = @{}
Import-Module (Join-Path $PSScriptRoot 'CliSession.psm1') -Force
$networkArgs = @('--bootstrap', $BootstrapDirectory, '--registry', $RegistryOrigin)
$groupName = 'GSR CLI QA '+$GroupRevision
function Require([bool]$ok, [string]$label) { if (-not $ok) { throw $label } }
function Invoke-Client([string]$phase, [string]$profile, [string[]]$command, [int]$attempt = 1) {
    Require-ScenarioInputs
    Require ((Runtime-Fingerprint) -ceq $runtimeHash -and (Get-FileHash -LiteralPath $scenarioPath -Algorithm SHA256).Hash -ceq $scenarioHash) 'Scenario inputs changed.'
    $budget = if ($command[0] -ceq 'group' -and $command[1] -in @('invite','accept','advance','send','flush','sync','publish')) { 1830000 } else { 330000 }
    $watch = [Diagnostics.Stopwatch]::StartNew()
    $process = $null
    try {
    if ($PersistentSessions) {
        if (-not $sessions.ContainsKey($profile)) { $sessions[$profile] = New-CliSession $exe $profile $network $BootstrapDirectory $RegistryOrigin }
        $response = Invoke-CliSession $sessions[$profile] ($command + @('--profile',$profile,'--network',$network)) $budget
        $exitCode=$response.ExitCode; $processorMilliseconds=$response.ProcessorMilliseconds
        $out=''; $err=''
        if($exitCode -eq 0) { $out=$response.Result|ConvertTo-Json -Depth 32 -Compress }
        else { $err=$response.Result|ConvertTo-Json -Depth 32 -Compress }
    } else {
    $start = [Diagnostics.ProcessStartInfo]::new($exe)
    $start.UseShellExecute = $false; $start.CreateNoWindow = $true
    $start.RedirectStandardOutput = $true; $start.RedirectStandardError = $true
    foreach ($arg in ($command + @('--profile',$profile,'--network',$network))) { [void]$start.ArgumentList.Add($arg) }
    $process = [Diagnostics.Process]::new(); $process.StartInfo = $start
        if (-not $process.Start()) { throw 'CLI child not started.' }
        $stdout = $process.StandardOutput.ReadToEndAsync(); $stderr = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit($budget)) { $process.Kill($true); throw 'CLI deadline; original work retained.' }
        $out = $stdout.GetAwaiter().GetResult(); $err = $stderr.GetAwaiter().GetResult()
        $exitCode=$process.ExitCode; $processorMilliseconds=[long]$process.TotalProcessorTime.TotalMilliseconds
    }
        Require ($out.Length + $err.Length -le 1048576) 'CLI output bound.'
        Require-ScenarioInputs
        Require ((Runtime-Fingerprint) -ceq $runtimeHash -and (Get-FileHash -LiteralPath $scenarioPath -Algorithm SHA256).Hash -ceq $scenarioHash) 'Scenario inputs changed during child.'
        $row = [pscustomobject]@{phase=$phase;exit=$exitCode;milliseconds=$watch.ElapsedMilliseconds;processorMilliseconds=$processorMilliseconds;attempt=$attempt}
        $metrics = $(if ($exitCode -eq 0) { $out } else { $err }) | ConvertFrom-Json
        if ($metrics.PSObject.Properties.Name -contains 'networkWork') { $row | Add-Member networkWork @($metrics.networkWork) }
        if ($metrics.PSObject.Properties.Name -contains 'runtimeWork') { $row | Add-Member runtimeWork $metrics.runtimeWork }
        if ($metrics.PSObject.Properties.Name -contains 'persistenceWork') { $row | Add-Member persistenceWork @($metrics.persistenceWork) }
        if ($metrics.PSObject.Properties.Name -contains 'protectionWork') { $row | Add-Member protectionWork $metrics.protectionWork }
        if ($metrics.PSObject.Properties.Name -contains 'sessionWork') { $row | Add-Member sessionWork $metrics.sessionWork }
        if ($metrics.PSObject.Properties.Name -contains 'recoveryWork') { $row | Add-Member recoveryWork $metrics.recoveryWork }
        if ($exitCode -eq 0 -and $command[0] -ceq 'group' -and $command[1] -in @('send','flush')) {
            Require ($metrics.completed -ge 0 -and $metrics.completed -le 512) 'Group work count exceeds its closed batch bound.'
            $row | Add-Member completedBatchItems $metrics.completed
        }
        if ($exitCode -eq 0 -and $command[0] -ceq 'mailbox' -and $command[1] -ceq 'sync') {
            $row | Add-Member processed $metrics.processed
            $row | Add-Member tombstones $metrics.tombstones
            $row | Add-Member hasMore $metrics.hasMore
        }
        $steps.Add($row); Write-Host ($row | ConvertTo-Json -Depth 8 -Compress)
        if ($exitCode -ne 0) {
            $failure = $err | ConvertFrom-Json
            if ($failure.code -ceq 'business-operation-failed') {
                $failure.diagnostic | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $run ('failure-'+$steps.Count+'.json')) -Encoding utf8
                Write-Host ($failure.diagnostic | ConvertTo-Json -Depth 8 -Compress)
                $eligible = (($command[0] -in @('network','mailbox','contact')) -and ($command[1] -notin @('queue','create'))) -or
                    (($command[0] -ceq 'group') -and ($command[1] -in @('flush','invite','accept','advance','sync','publish')))
                $transient = @($failure.diagnostic.causes | Where-Object { $_.category -in @('OutcomeUnknown','Cancelled','IngressRetryableBeforeForward') -or $_.check -in @('ClaimOutcomeUnknown','EndpointPairNetworkChanged','EndpointPairDirectoryExpired','EndpointPairDirectoryFloorAdvanced','EndpointPairDirectoryExpiredBeforeHandoff') }).Count -gt 0
                if (-not $strictCommands -and $attempt -eq 1 -and $eligible -and $transient) { return Invoke-Client ($phase+'-exact-retry') $profile $command 2 }
            }
            throw 'CLI operation failed; retain original accounts and pending group batch.'
        }
        return ($out | ConvertFrom-Json)
    } finally { if($process) { $process.Dispose() } }
}
function Operation([string]$purpose) { [Convert]::ToHexStringLower([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes('Deep/CLI/GroupQA/20261018/'+$network+'/'+$AliceProfile+'/'+$BobProfile+'/'+$CarolProfile+'/'+$purpose))) }
function Group-Head([string]$phase, [string]$profile) {
    $list = Invoke-Client $phase $profile @('group','list')
    $heads = @($list.items | Where-Object { $_.Name -ceq $groupName })
    Require ($heads.Count -eq 1) 'One exact named candidate group required; never silently select another group.'
    return $heads[0]
}
function Sync([string]$phase, [string]$profile) {
    $processed = 0; $tombstones = 0
    foreach ($page in 1..4) {
        $result = Invoke-Client $phase $profile (@('mailbox','sync')+$networkArgs)
        Require ($result.processed -eq $result.tombstones) 'Every received event requires independently qualified durable ACK.'
        $processed += $result.processed; $tombstones += $result.tombstones
        if (-not $result.hasMore) { return [pscustomobject]@{processed=$processed;tombstones=$tombstones;hasMore=$false} }
        Require ($result.processed -gt 0) 'Non-final mailbox page made no durable progress.'
        # Pagination is new work after a successful durable ACK, not a retry of
        # a failed/unknown request. The actual protected owner holds the cursor.
    }
    throw 'Bounded mailbox page drain exhausted; preserve the actual cursor.'
}
$profiles = @($AliceProfile,$BobProfile,$CarolProfile)
$pairConversations = @{}
function Pair-Key([string]$left,[string]$right) { (@($left,$right) | Sort-Object -CaseSensitive) -join ':' }
function Peer-Conversation([string]$left,[string]$right) { $pairConversations[(Pair-Key $left $right)] }
function Ensure-Contact([string]$left,[string]$right) {
    $l = Invoke-Client 'pair-left-cold-list' $left @('contact','list')
    $r = Invoke-Client 'pair-right-cold-list' $right @('contact','list')
    $common = @($l.contacts | Where-Object { $_.conversation -in @($r.contacts | ForEach-Object conversation) })
    Require ($common.Count -le 1) 'Ambiguous exact pair session.'
    if ($common.Count -eq 1 -and $common[0].state -ceq 'PeerAcceptanceRetained' -and
        @($r.contacts | Where-Object { $_.conversation -ceq $common[0].conversation -and $_.state -ceq 'LocalAcceptanceRetained' }).Count -eq 1) {
        # Resume only the actual mutually consented retained pair. Every group
        # operation still independently rechecks current network/native consent.
        $pairConversations[(Pair-Key $left $right)] = $common[0].conversation
        return
    }
    Require ($SteadyStateRound -eq 0) 'Steady-state requires existing mutual contact consent; no setup repair.'
    if ($common.Count -eq 0) {
        $address = (Invoke-Client 'explicit-peer-address' $right @('account','address')).address
        [void](Invoke-Client 'pair-contact-request' $left (@('contact','request','--address',$address,'--operation',(Operation ('contact/'+(Pair-Key $left $right))))+$networkArgs))
    }
    [void](Sync 'pair-contact-receive-ack' $right)
    $l = Invoke-Client 'pair-left-session-list' $left @('contact','list')
    $r = Invoke-Client 'pair-right-session-list' $right @('contact','list')
    $common = @($r.contacts | Where-Object { $_.conversation -in @($l.contacts | ForEach-Object conversation) })
    Require ($common.Count -eq 1) 'Exact pair session absent.'
    $conversation = $common[0].conversation
    if ($common[0].state -cne 'LocalAcceptanceRetained') {
        [void](Invoke-Client 'pair-explicit-contact-accept' $right (@('contact','accept','--conversation',$conversation,'--operation',(Operation ('accept/'+(Pair-Key $left $right))))+$networkArgs))
    }
    [void](Sync 'pair-consent-receive-ack' $left)
    $l = Invoke-Client 'pair-final-contact-consent' $left @('contact','list')
    Require (@($l.contacts | Where-Object { $_.conversation -ceq $conversation -and $_.state -ceq 'PeerAcceptanceRetained' }).Count -eq 1) 'Pair consent missing.'
    $pairConversations[(Pair-Key $left $right)] = $conversation
}
$passed = $false
try {
    foreach ($profile in $profiles) {
        $present = Invoke-Client 'account-cold-status' $profile @('account','status')
        if ($ReusePublishedAccounts) { Require ([bool]$present.accountPresent) 'Reuse requires existing account.'; continue }
        if (-not $present.accountPresent) { [void](Invoke-Client 'isolated-account-create' $profile @('account','create','--name','Three CLI QA')) }
        [void](Invoke-Client 'network-verify-publish' $profile (@('network','verify')+$networkArgs))
    }
    Ensure-Contact $AliceProfile $BobProfile
    Ensure-Contact $AliceProfile $CarolProfile
    Ensure-Contact $BobProfile $CarolProfile
    if ($SteadyStateRound -eq 0) {
    $groups = Invoke-Client 'owner-initial-group-list' $AliceProfile @('group','list')
    $matching = @($groups.items | Where-Object { $_.Name -ceq $groupName }); Require ($matching.Count -le 1) 'Ambiguous group.'
    if ($RequireFirstAttempt) { Require ($matching.Count -eq 0) 'First-attempt qualification requires a new group, not retained recovery.' }
    if ($matching.Count -eq 0) { $group = (Invoke-Client 'owner-create-group' $AliceProfile (@('group','create','--name',$groupName)+$networkArgs)).group }
    else { $group = $matching[0].Group }
    $memberCount = 1
    foreach ($invitee in @($BobProfile,$CarolProfile)) {
        $memberCount++
        $beforeOwner = Group-Head 'retained-owner-membership-head' $AliceProfile
        $recipientGroups = Invoke-Client 'retained-invitee-head-selection' $invitee @('group','list')
        $recipientHead = @($recipientGroups.items | Where-Object { $_.Name -ceq $groupName })
        Require ($recipientHead.Count -le 1) 'Ambiguous retained invitee group.'
        if ($RequireFirstAttempt) { Require ($recipientHead.Count -eq 0) 'First-attempt invitee already has candidate state.' }
        if ($recipientHead.Count -eq 1 -and $beforeOwner.State -ceq 'Active' -and $beforeOwner.Epoch -ge ($memberCount-1) -and
            $recipientHead[0].State -ceq 'Active' -and $recipientHead[0].Group -ceq $group -and $recipientHead[0].Epoch -eq $beforeOwner.Epoch -and $recipientHead[0].Members -eq $beforeOwner.Members) {
            # Actual protected adoption already happened in an earlier receipt.
            # The final original-batch replay still independently checks Stores.
            continue
        }
        $conversation = Peer-Conversation $AliceProfile $invitee
        $argsGroup = @('--group',$group,'--conversation',$conversation)+$networkArgs
        $ownerAlreadyAdvanced = $recipientHead.Count -eq 1 -and $recipientHead[0].Group -ceq $group -and
            $recipientHead[0].State -in @('Accepted','Active') -and $beforeOwner.State -ceq 'Active' -and
            $beforeOwner.Epoch -ge ($memberCount-1) -and $beforeOwner.Members -ge $memberCount
        if (-not $ownerAlreadyAdvanced) {
            $recipientHasInvitation = $recipientHead.Count -eq 1 -and $recipientHead[0].Group -ceq $group -and
                $recipientHead[0].State -in @('Invited','Accepted','Active')
            if (-not $recipientHasInvitation) { [void](Invoke-Client 'owner-invite-original-batch' $AliceProfile (@('group','invite')+$argsGroup)) }
            [void](Sync 'invitee-complete-lineage-invitation-ack' $invitee)
            if ($recipientHasInvitation -and $recipientHead[0].State -in @('Accepted','Active')) {
                [void](Invoke-Client 'resume-invitee-original-consent-batch' $invitee (@('group','flush')+$argsGroup))
            } else { [void](Invoke-Client 'invitee-explicit-accept-original' $invitee (@('group','accept')+$argsGroup)) }
            [void](Sync 'owner-consent-ack' $AliceProfile)
            [void](Invoke-Client 'owner-successor-complete-fanout' $AliceProfile (@('group','advance')+$argsGroup))
        }
        # A retained owner commit is not remote membership. Resume read-only GSR
        # catch-up below; the exact active heads must still independently agree.
        $ownerHead = Group-Head 'owner-mailbox-batch-stored-head' $AliceProfile
        foreach ($profile in $profiles[1..($memberCount-1)]) {
            $received = Sync 'ordinary-mailbox-does-not-carry-new-commit' $profile
            Require ($received.processed -eq 0) 'Current commit unexpectedly used ordinary mailbox delivery.'
            $control = Invoke-Client 'gsr-independent-cold-control-catchup' $profile (@('group','sync','--group',$group,'--conversation',(Peer-Conversation $AliceProfile $profile))+$networkArgs)
            Require ($control.status -ceq 'synced') 'GSR control sync failed.'
        }
        foreach ($profile in $profiles[0..($memberCount-1)]) {
            $head = Group-Head 'exact-protected-successor-head' $profile
            Require ($head.Group -ceq $group -and $head.State -ceq 'Active' -and $head.Epoch -eq $ownerHead.Epoch -and $head.Members -eq $ownerHead.Members -and $head.Members -eq $memberCount) 'Exact membership head mismatch.'
        }
    }
    } else {
        $group = (Group-Head 'retained-steady-owner-head' $AliceProfile).Group
        foreach ($profile in $profiles) {
            $head = Group-Head 'steady-native-command-preflight' $profile
            Require ($head.Group -ceq $group -and ($head.LocalMessageCommands -eq $SteadyStateRound -or
                ($RecoverIncompleteSteadyRound -and $head.LocalMessageCommands -eq ($SteadyStateRound+1)))) 'Steady-state must start before any command, or explicitly recover its original incomplete round.'
            $history = Invoke-Client 'steady-native-history-preflight' $profile @('group','messages','--group',$group)
            if ($RecoverIncompleteSteadyRound) {
                Require (@($history.items).Count -ge 3*$SteadyStateRound -and @($history.items).Count -le 3*($SteadyStateRound+1) -and
                    @($history.items | Where-Object local).Count -eq $head.LocalMessageCommands) 'Incomplete round native history differs.'
                if ($head.LocalMessageCommands -eq ($SteadyStateRound+1)) {
                    Require (@($history.items | Where-Object { $_.local -and $_.text -ceq ($messagePrefix+$profile) -and $_.sequence -eq ($SteadyStateRound+1) }).Count -eq 1) 'Recovery must select the exact original local command.'
                }
            } else {
                Require (@($history.items).Count -eq 3*$SteadyStateRound -and @($history.items | Where-Object local).Count -eq $SteadyStateRound) 'Steady-state native history differs.'
            }
        }
    }
    $finalOwner = Group-Head 'exact-three-active-owner-head' $AliceProfile
    Require ($finalOwner.Group -ceq $group -and $finalOwner.State -ceq 'Active' -and $finalOwner.Members -eq 3) 'Owner must have exactly three active members.'
    foreach ($profile in @($BobProfile,$CarolProfile)) {
        $head = Group-Head 'exact-three-active-recipient-head' $profile
        Require ($head.Group -ceq $group -and $head.State -ceq 'Active' -and $head.Epoch -eq $finalOwner.Epoch -and $head.Members -eq 3) 'Recipient must have the exact same three-member head.'
    }
    foreach ($sender in $profiles) {
        $peer = if ($sender -ceq $AliceProfile) { $BobProfile } else { $AliceProfile }
        $argsGroup = @('--group',$group,'--conversation',(Peer-Conversation $sender $peer))+$networkArgs
        $head = Group-Head 'sender-original-command-count' $sender
        Require ($head.LocalMessageCommands -le ($SteadyStateRound+1)) 'Unexpected retained semantic commands.'
        if ($head.LocalMessageCommands -eq $SteadyStateRound) { [void](Invoke-Client 'one-command-two-recipient-fanout' $sender (@('group','send','--text',($messagePrefix+$sender))+$argsGroup)) }
        else {
            Require ($SteadyStateRound -eq 0 -or $RecoverIncompleteSteadyRound) 'Steady-state cannot resume or replace a failed round.'
            # A resumed command may already have been received by every member.
            # Avoid verifying its entire historical batch twice in one run only
            # when every actual native history proves that exact semantic copy.
            # The unconditional final full-batch replay still qualifies all Stores.
            $receivedByAll = $true
            foreach ($profile in $profiles) {
                $history = Invoke-Client 'retained-semantic-copy-native-history' $profile @('group','messages','--group',$group)
                $copies = @($history.items | Where-Object { $_.text -ceq ($messagePrefix+$sender) -and $_.sequence -eq ($SteadyStateRound+1) })
                Require ($copies.Count -le 1) 'Retained semantic history duplicated.'
                if ($copies.Count -ne 1) { $receivedByAll = $false }
            }
            if (-not $receivedByAll) { [void](Invoke-Client 'resume-original-two-target-batch' $sender (@('group','flush')+$argsGroup)) }
        }
        foreach ($recipient in $profiles | Where-Object { $_ -cne $sender }) { [void](Sync 'fanout-recipient-native-receive-ack' $recipient) }
    }
    foreach ($profile in $profiles) {
        if($sessions.ContainsKey($profile)) { Close-CliSession $sessions[$profile]; $sessions.Remove($profile) }
        $messages = Invoke-Client 'three-way-cold-native-history' $profile @('group','messages','--group',$group)
        Require (@($messages.items).Count -eq 3*($SteadyStateRound+1) -and @($messages.items | Where-Object local).Count -eq ($SteadyStateRound+1)) 'Three-way semantic history missing or duplicated.'
        foreach ($sender in $profiles) { Require (@($messages.items | Where-Object { $_.text -ceq ($messagePrefix+$sender) -and $_.sequence -eq ($SteadyStateRound+1) }).Count -eq 1) 'Exact fanout plaintext mismatch.' }
        $peer = if ($profile -ceq $AliceProfile) { $BobProfile } else { $AliceProfile }
        if (-not $DeliveryOnly) {
            [void](Invoke-Client 'cold-original-full-batch-replay' $profile (@('group','flush','--group',$group,'--conversation',(Peer-Conversation $profile $peer))+$networkArgs))
        }
        $emptyPhase = if ($DeliveryOnly) { 'post-delivery-empty-mailbox' } else { 'post-replay-empty-mailbox' }
        $empty = Sync $emptyPhase $profile
        Require ($empty.processed -eq 0) 'Durably ACKed fanout reappeared.'
        $historyPhase = if ($DeliveryOnly) { 'post-delivery-deduplicated-history' } else { 'post-replay-deduplicated-history' }
        $again = Invoke-Client $historyPhase $profile @('group','messages','--group',$group)
        Require (@($again.items).Count -eq 3*($SteadyStateRound+1)) 'Fanout replay duplicated history.'
    }
    if (-not $DeliveryOnly) {
    [void](Invoke-Client 'owner-cold-control-receipt-reverification' $AliceProfile (@('group','publish','--group',$group)+$networkArgs))
    foreach ($profile in @($BobProfile,$CarolProfile)) {
        $emptyControl = Invoke-Client 'cold-control-cursor-empty-replay' $profile (@('group','sync','--group',$group,'--conversation',(Peer-Conversation $AliceProfile $profile))+$networkArgs)
        Require ($emptyControl.status -ceq 'synced' -and $emptyControl.completed -eq 0) 'Control cursor replay did not remain empty.'
    }
    }
    if ($strictCommands) { Require (@($steps | Where-Object { $_.exit -ne 0 -or $_.attempt -ne 1 }).Count -eq 0) 'First-attempt run contains a retry or failed command.' }
    $passed = $true
} finally {
    $sessionCloseFailed=$false
    foreach($session in @($sessions.Values)) {
        try { Close-CliSession $session } catch { $sessionCloseFailed=$true; $passed=$false }
    }
    $recoveries=@($steps | Where-Object { $_.PSObject.Properties.Name -contains 'recoveryWork' } | ForEach-Object recoveryWork)
    $storeResumes=[long](($recoveries | Measure-Object storeResumes -Sum).Sum)
    $mailboxResumes=[long](($recoveries | Measure-Object mailboxResumes -Sum).Sum)
    $leaseWaits=[long](($recoveries | Measure-Object leaseWaits -Sum).Sum)
    [ordered]@{schema='deep.cli.connected-gsr-e2e.v1';passed=$passed;startedUtc=$started;finishedUtc=[DateTime]::UtcNow;
        automaticStoreResumes=$storeResumes;automaticMailboxResumes=$mailboxResumes;automaticLeaseWaits=$leaseWaits;noOwnedUnknownRecovery=($storeResumes -eq 0 -and $mailboxResumes -eq 0);
        runtimeSha256=$runtimeHash;scenarioSha256=$scenarioHash.ToLowerInvariant();sessionModuleSha256=$sessionModuleHash.ToLowerInvariant();sessionCloseFailed=$sessionCloseFailed;steps=@($steps.ToArray());
        candidateAccounts=3;devicesPerAccount=1;persistentSessions=[bool]$PersistentSessions;groupRevision=$GroupRevision;steadyStateRound=$SteadyStateRound;reusedPublishedAccounts=[bool]$ReusePublishedAccounts;maximumExactAttempts=$(if($strictCommands){1}else{2});firstAttemptRequired=($strictCommands -and -not $RecoverIncompleteSteadyRound);recoveryRequired=[bool]$RecoverIncompleteSteadyRound;recoveryQualified=($passed -and $RecoverIncompleteSteadyRound);deliveryOnly=[bool]$DeliveryOnly;deliveryLatencyQualified=($passed -and $DeliveryOnly);gsr1FunctionalQualified=($passed -and $SteadyStateRound -eq 0);steadyStateQualified=($passed -and $SteadyStateRound -gt 0 -and -not $RecoverIncompleteSteadyRound -and -not $DeliveryOnly);gsr1RetentionQualified=$false;devicesQualified=$false;releaseQualified=$false} |
        ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $run 'receipt.json') -Encoding utf8
    Write-Host ([pscustomobject]@{passed=$passed;commands=$steps.Count} | ConvertTo-Json -Compress)
    if($sessionCloseFailed) { throw 'Session close failed; run remains unqualified.' }
}

