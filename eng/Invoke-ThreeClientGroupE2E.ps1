[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$BootstrapDirectory,
    [Parameter(Mandatory)][string]$RegistryOrigin,
    [Parameter(Mandatory)][string]$RunDirectory,
    [switch]$ReusePublishedAccounts,
    [ValidateRange(0,31)][int]$GroupRevision = 0,
    [ValidatePattern('^[a-z][a-z0-9-]{0,31}$')][string]$AliceProfile = 'cli-multi-alice',
    [ValidatePattern('^[a-z][a-z0-9-]{0,31}$')][string]$BobProfile = 'cli-multi-bob',
    [ValidatePattern('^[a-z][a-z0-9-]{0,31}$')][string]$CarolProfile = 'cli-multi-carol'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$exe = Join-Path $repo 'src/Deep.Cli/bin/Release/net10.0-windows/deep.exe'
$run = [IO.Path]::GetFullPath($RunDirectory)
$artifactRoot = [IO.Path]::GetFullPath((Join-Path $repo 'artifacts')) + [IO.Path]::DirectorySeparatorChar
if (-not $run.StartsWith($artifactRoot, [StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $run) -or @($AliceProfile,$BobProfile,$CarolProfile | Select-Object -Unique).Count -ne 3) { throw 'Fresh artifact directory and distinct isolated profiles required.' }
foreach ($path in @($run, $BootstrapDirectory, $exe)) {
    for ($cursor = [IO.Path]::GetFullPath($path); $cursor; $cursor = [IO.Path]::GetDirectoryName($cursor)) {
        if ((Test-Path -LiteralPath $cursor) -and ((Get-Item -LiteralPath $cursor).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Reparse path rejected.' }
    }
}
$network = (Get-Content -LiteralPath (Join-Path $BootstrapDirectory 'deep-dev.json') -Raw | ConvertFrom-Json).networkIdHex.ToLowerInvariant()
if ($network -cnotmatch '^[0-9a-f]{32}$') { throw 'Explicit public network binding required.' }
$scenarioPath = $PSCommandPath
$scenarioHash = (Get-FileHash -LiteralPath $scenarioPath -Algorithm SHA256).Hash
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
if ((Get-FileHash -LiteralPath (Join-Path $run 'scenario.ps1') -Algorithm SHA256).Hash -cne $scenarioHash) { throw 'Scenario archive differs.' }
Compress-Archive -LiteralPath ([IO.Path]::GetDirectoryName($exe)) -DestinationPath (Join-Path $run 'runtime.zip') -CompressionLevel Fastest
if ((Runtime-Fingerprint) -cne $runtimeHash) { throw 'Runtime changed during archive.' }
$started = [DateTime]::UtcNow
$steps = [Collections.Generic.List[object]]::new()
$networkArgs = @('--bootstrap', $BootstrapDirectory, '--registry', $RegistryOrigin)
$groupName = 'Three CLI QA '+$GroupRevision
function Require([bool]$ok, [string]$label) { if (-not $ok) { throw $label } }
function Invoke-Client([string]$phase, [string]$profile, [string[]]$command, [int]$attempt = 1) {
    Require ((Runtime-Fingerprint) -ceq $runtimeHash -and (Get-FileHash -LiteralPath $scenarioPath -Algorithm SHA256).Hash -ceq $scenarioHash) 'Scenario inputs changed.'
    $start = [Diagnostics.ProcessStartInfo]::new($exe)
    $start.UseShellExecute = $false; $start.CreateNoWindow = $true
    $start.RedirectStandardOutput = $true; $start.RedirectStandardError = $true
    foreach ($arg in ($command + @('--profile',$profile,'--network',$network))) { [void]$start.ArgumentList.Add($arg) }
    $process = [Diagnostics.Process]::new(); $process.StartInfo = $start
    $watch = [Diagnostics.Stopwatch]::StartNew()
    try {
        if (-not $process.Start()) { throw 'CLI child not started.' }
        $stdout = $process.StandardOutput.ReadToEndAsync(); $stderr = $process.StandardError.ReadToEndAsync()
        $budget = if ($command[0] -ceq 'group' -and $command[1] -in @('invite','accept','advance','send','flush')) { 1830000 } else { 330000 }
        if (-not $process.WaitForExit($budget)) { $process.Kill($true); throw 'CLI deadline; original work retained.' }
        $out = $stdout.GetAwaiter().GetResult(); $err = $stderr.GetAwaiter().GetResult()
        Require ($out.Length + $err.Length -le 1048576) 'CLI output bound.'
        Require ((Runtime-Fingerprint) -ceq $runtimeHash -and (Get-FileHash -LiteralPath $scenarioPath -Algorithm SHA256).Hash -ceq $scenarioHash) 'Scenario inputs changed during child.'
        $row = [pscustomobject]@{phase=$phase;exit=$process.ExitCode;milliseconds=$watch.ElapsedMilliseconds;attempt=$attempt}
        if ($process.ExitCode -eq 0) {
            $metrics = $out | ConvertFrom-Json
            if ($metrics.PSObject.Properties.Name -contains 'networkWork') { $row | Add-Member networkWork @($metrics.networkWork) }
            if ($metrics.PSObject.Properties.Name -contains 'protectionWork') { $row | Add-Member protectionWork $metrics.protectionWork }
        }
        $steps.Add($row); Write-Host ($row | ConvertTo-Json -Depth 8 -Compress)
        if ($process.ExitCode -ne 0) {
            $failure = $err | ConvertFrom-Json
            if ($failure.code -ceq 'business-operation-failed') {
                $failure.diagnostic | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $run ('failure-'+$steps.Count+'.json')) -Encoding utf8
                Write-Host ($failure.diagnostic | ConvertTo-Json -Depth 8 -Compress)
                $eligible = (($command[0] -in @('network','mailbox','contact')) -and ($command[1] -notin @('queue','create'))) -or
                    (($command[0] -ceq 'group') -and ($command[1] -in @('flush','invite','accept','advance')))
                $transient = @($failure.diagnostic.causes | Where-Object { $_.category -in @('OutcomeUnknown','Cancelled','IngressRetryableBeforeForward') -or $_.check -in @('ClaimOutcomeUnknown','EndpointPairNetworkChanged','EndpointPairDirectoryExpired','EndpointPairDirectoryFloorAdvanced','EndpointPairDirectoryExpiredBeforeHandoff') }).Count -gt 0
                if ($attempt -eq 1 -and $eligible -and $transient) { return Invoke-Client ($phase+'-exact-retry') $profile $command 2 }
            }
            throw 'CLI operation failed; retain original accounts and pending group batch.'
        }
        return ($out | ConvertFrom-Json)
    } finally { $process.Dispose() }
}
function Operation([string]$purpose) { [Convert]::ToHexStringLower([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes('Deep/CLI/GroupQA/20261018/'+$network+'/'+$AliceProfile+'/'+$BobProfile+'/'+$CarolProfile+'/'+$purpose))) }
function Group-Head([string]$phase, [string]$profile) {
    $list = Invoke-Client $phase $profile @('group','list')
    $heads = @($list.items | Where-Object { $_.Name -ceq $groupName })
    Require ($heads.Count -eq 1) 'One exact named candidate group required; never silently select another group.'
    return $heads[0]
}
function Sync([string]$phase, [string]$profile) {
    $result = Invoke-Client $phase $profile (@('mailbox','sync')+$networkArgs)
    Require ($result.processed -eq $result.tombstones) 'Every received event requires independently qualified durable ACK.'
    return $result
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
    $groups = Invoke-Client 'owner-initial-group-list' $AliceProfile @('group','list')
    $matching = @($groups.items | Where-Object { $_.Name -ceq $groupName }); Require ($matching.Count -le 1) 'Ambiguous group.'
    if ($matching.Count -eq 0) { $group = (Invoke-Client 'owner-create-group' $AliceProfile (@('group','create','--name',$groupName)+$networkArgs)).group }
    else { $group = $matching[0].Group }
    $memberCount = 1
    foreach ($invitee in @($BobProfile,$CarolProfile)) {
        $memberCount++
        $beforeOwner = Group-Head 'retained-owner-membership-head' $AliceProfile
        $recipientGroups = Invoke-Client 'retained-invitee-head-selection' $invitee @('group','list')
        $recipientHead = @($recipientGroups.items | Where-Object { $_.Name -ceq $groupName })
        Require ($recipientHead.Count -le 1) 'Ambiguous retained invitee group.'
        if ($recipientHead.Count -eq 1 -and $beforeOwner.State -ceq 'Active' -and $beforeOwner.Epoch -ge ($memberCount-1) -and
            $recipientHead[0].State -ceq 'Active' -and $recipientHead[0].Group -ceq $group -and $recipientHead[0].Epoch -eq $beforeOwner.Epoch -and $recipientHead[0].Members -eq $beforeOwner.Members) {
            # Actual protected adoption already happened in an earlier receipt.
            # The final original-batch replay still independently checks Stores.
            continue
        }
        $conversation = Peer-Conversation $AliceProfile $invitee
        $argsGroup = @('--group',$group,'--conversation',$conversation)+$networkArgs
        [void](Invoke-Client 'owner-invite-original-batch' $AliceProfile (@('group','invite')+$argsGroup))
        [void](Sync 'invitee-complete-lineage-invitation-ack' $invitee)
        [void](Invoke-Client 'invitee-explicit-accept-original' $invitee (@('group','accept')+$argsGroup))
        [void](Sync 'owner-consent-ack' $AliceProfile)
        [void](Invoke-Client 'owner-successor-complete-fanout' $AliceProfile (@('group','advance')+$argsGroup))
        $ownerHead = Group-Head 'owner-mailbox-batch-stored-head' $AliceProfile
        foreach ($profile in $profiles[1..($memberCount-1)]) { [void](Sync 'successor-fanout-receive-ack' $profile) }
        foreach ($profile in $profiles[0..($memberCount-1)]) {
            $head = Group-Head 'exact-protected-successor-head' $profile
            Require ($head.Group -ceq $group -and $head.State -ceq 'Active' -and $head.Epoch -eq $ownerHead.Epoch -and $head.Members -eq $ownerHead.Members -and $head.Members -ge $memberCount) 'Exact membership head mismatch.'
        }
    }
    foreach ($sender in $profiles) {
        $peer = if ($sender -ceq $AliceProfile) { $BobProfile } else { $AliceProfile }
        $argsGroup = @('--group',$group,'--conversation',(Peer-Conversation $sender $peer))+$networkArgs
        $head = Group-Head 'sender-original-command-count' $sender
        Require ($head.LocalMessageCommands -le 1) 'Unexpected retained semantic commands.'
        if ($head.LocalMessageCommands -eq 0) { [void](Invoke-Client 'one-command-two-recipient-fanout' $sender (@('group','send','--text',('Three CLI '+$sender))+$argsGroup)) }
        else {
            # A resumed command may already have been received by every member.
            # Avoid verifying its entire historical batch twice in one run only
            # when every actual native history proves that exact semantic copy.
            # The unconditional final full-batch replay still qualifies all Stores.
            $receivedByAll = $true
            foreach ($profile in $profiles) {
                $history = Invoke-Client 'retained-semantic-copy-native-history' $profile @('group','messages','--group',$group)
                $copies = @($history.items | Where-Object { $_.text -ceq ('Three CLI '+$sender) -and $_.sequence -eq 1 })
                Require ($copies.Count -le 1) 'Retained semantic history duplicated.'
                if ($copies.Count -ne 1) { $receivedByAll = $false }
            }
            if (-not $receivedByAll) { [void](Invoke-Client 'resume-original-two-target-batch' $sender (@('group','flush')+$argsGroup)) }
        }
        foreach ($recipient in $profiles | Where-Object { $_ -cne $sender }) { [void](Sync 'fanout-recipient-native-receive-ack' $recipient) }
    }
    foreach ($profile in $profiles) {
        $messages = Invoke-Client 'three-way-cold-native-history' $profile @('group','messages','--group',$group)
        Require (@($messages.items).Count -eq 3 -and @($messages.items | Where-Object local).Count -eq 1) 'Three-way semantic history missing or duplicated.'
        foreach ($sender in $profiles) { Require (@($messages.items | Where-Object { $_.text -ceq ('Three CLI '+$sender) }).Count -eq 1) 'Exact fanout plaintext mismatch.' }
        $peer = if ($profile -ceq $AliceProfile) { $BobProfile } else { $AliceProfile }
        [void](Invoke-Client 'cold-original-full-batch-replay' $profile (@('group','flush','--group',$group,'--conversation',(Peer-Conversation $profile $peer))+$networkArgs))
        $empty = Sync 'post-replay-empty-mailbox' $profile
        Require ($empty.processed -eq 0) 'Durably ACKed fanout reappeared.'
        $again = Invoke-Client 'post-replay-deduplicated-history' $profile @('group','messages','--group',$group)
        Require (@($again.items).Count -eq 3) 'Fanout replay duplicated history.'
    }
    $passed = $true
} finally {
    [ordered]@{schema='deep.cli.connected-group-e2e.v1';passed=$passed;startedUtc=$started;finishedUtc=[DateTime]::UtcNow;
        runtimeSha256=$runtimeHash;scenarioSha256=$scenarioHash.ToLowerInvariant();steps=@($steps.ToArray());
        candidateAccounts=3;devicesPerAccount=1;groupRevision=$GroupRevision;reusedPublishedAccounts=[bool]$ReusePublishedAccounts;maximumExactAttempts=2;gsr1RetentionQualified=$false;devicesQualified=$false;releaseQualified=$false} |
        ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $run 'receipt.json') -Encoding utf8
    Write-Host ([pscustomobject]@{passed=$passed;commands=$steps.Count} | ConvertTo-Json -Compress)
}
