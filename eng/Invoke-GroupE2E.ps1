[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$BootstrapDirectory,
    [Parameter(Mandatory)][string]$RegistryOrigin,
    [Parameter(Mandatory)][string]$RunDirectory,
    [switch]$ReusePublishedAccounts,
    [ValidateRange(0,31)][int]$GroupRevision = 0,
    [ValidatePattern('^[a-z][a-z0-9-]{0,31}$')][string]$AliceProfile = 'cli-groups-alice',
    [ValidatePattern('^[a-z][a-z0-9-]{0,31}$')][string]$BobProfile = 'cli-groups-bob'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$exe = Join-Path $repo 'src/Deep.Cli/bin/Release/net10.0-windows/deep.exe'
$run = [IO.Path]::GetFullPath($RunDirectory)
$artifactRoot = [IO.Path]::GetFullPath((Join-Path $repo 'artifacts')) + [IO.Path]::DirectorySeparatorChar
if (-not $run.StartsWith($artifactRoot, [StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $run) -or $AliceProfile -ceq $BobProfile) { throw 'Fresh artifact directory and distinct isolated profiles required.' }
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
$started = [DateTime]::UtcNow
$steps = [Collections.Generic.List[object]]::new()
$networkArgs = @('--bootstrap', $BootstrapDirectory, '--registry', $RegistryOrigin)
$groupName = if ($GroupRevision -eq 0) { 'Group QA' } else { 'Group QA '+$GroupRevision }
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
        $steps.Add($row); Write-Host ($row | ConvertTo-Json -Compress)
        if ($process.ExitCode -ne 0) {
            $failure = $err | ConvertFrom-Json
            if ($failure.code -ceq 'business-operation-failed') {
                $failure.diagnostic | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $run ('failure-'+$steps.Count+'.json')) -Encoding utf8
                Write-Host ($failure.diagnostic | ConvertTo-Json -Depth 8 -Compress)
                $eligible = (($command[0] -in @('network','mailbox','contact')) -and ($command[1] -notin @('queue','create'))) -or
                    (($command[0] -ceq 'group') -and ($command[1] -in @('flush','invite','accept','advance')))
                $transient = @($failure.diagnostic.causes | Where-Object { $_.category -in @('OutcomeUnknown','Cancelled','IngressRetryableBeforeForward') -or $_.check -ceq 'ClaimOutcomeUnknown' }).Count -gt 0
                if ($attempt -eq 1 -and $eligible -and $transient) { return Invoke-Client ($phase+'-exact-retry') $profile $command 2 }
            }
            throw 'CLI operation failed; retain original accounts and pending group batch.'
        }
        return ($out | ConvertFrom-Json)
    } finally { $process.Dispose() }
}
function Operation([string]$purpose) { [Convert]::ToHexStringLower([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes('Deep/CLI/GroupQA/20261018/'+$network+'/'+$AliceProfile+'/'+$BobProfile+'/'+$purpose))) }
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
$passed = $false
try {
    foreach ($profile in @($AliceProfile,$BobProfile)) {
        $present = Invoke-Client 'account-cold-status' $profile @('account','status')
        if ($ReusePublishedAccounts) { Require ([bool]$present.accountPresent) 'Reuse requires an existing published account.'; continue }
        if (-not $present.accountPresent) { [void](Invoke-Client 'isolated-account-create' $profile @('account','create','--name','Group QA')) }
        [void](Invoke-Client 'network-verify-publish' $profile (@('network','verify')+$networkArgs))
    }
    $a = Invoke-Client 'alice-contact-cold-list' $AliceProfile @('contact','list')
    if (@($a.contacts).Count -eq 0) {
        $address = (Invoke-Client 'bob-explicit-public-address' $BobProfile @('account','address')).address
        [void](Invoke-Client 'alice-contact-request' $AliceProfile (@('contact','request','--address',$address,'--operation',(Operation 'contact'))+$networkArgs))
    }
    [void](Sync 'bob-contact-receive-ack' $BobProfile)
    $b = Invoke-Client 'bob-contact-cold-list' $BobProfile @('contact','list')
    Require (@($b.contacts).Count -eq 1) 'One contact required.'
    $conversation = $b.contacts[0].conversation
    if ($b.contacts[0].state -cne 'LocalAcceptanceRetained') {
        [void](Invoke-Client 'bob-contact-explicit-accept' $BobProfile (@('contact','accept','--conversation',$conversation,'--operation',(Operation 'accept'))+$networkArgs))
    }
    [void](Sync 'alice-contact-consent-receive-ack' $AliceProfile)
    $a = Invoke-Client 'alice-contact-accepted' $AliceProfile @('contact','list')
    Require (@($a.contacts).Count -eq 1 -and $a.contacts[0].state -ceq 'PeerAcceptanceRetained') 'Contact consent missing.'
    $groups = Invoke-Client 'alice-group-cold-list' $AliceProfile @('group','list')
    $matching = @($groups.items | Where-Object { $_.Name -ceq $groupName })
    Require ($matching.Count -le 1) 'Ambiguous candidate group; do not select by position.'
    if ($matching.Count -eq 0) { $group = (Invoke-Client 'owner-create' $AliceProfile (@('group','create','--name',$groupName)+$networkArgs)).group }
    else { $group = $matching[0].Group }
    $argsGroup = @('--group',$group,'--conversation',$conversation)+$networkArgs
    $state = (Group-Head 'owner-head-before-invite' $AliceProfile).State
    if ($state -ceq 'Created') { [void](Invoke-Client 'owner-invite-batch-store' $AliceProfile (@('group','invite')+$argsGroup)) }
    else { [void](Invoke-Client 'owner-invite-original-flush' $AliceProfile (@('group','flush')+$argsGroup)) }
    [void](Sync 'invitee-genesis-invitation-receive-ack' $BobProfile)
    $state = (Group-Head 'invitee-protected-head' $BobProfile).State
    if ($state -ceq 'Invited') { [void](Invoke-Client 'invitee-explicit-accept-store' $BobProfile (@('group','accept')+$argsGroup)) }
    else { [void](Invoke-Client 'invitee-original-flush' $BobProfile (@('group','flush')+$argsGroup)) }
    [void](Sync 'owner-consent-receive-ack' $AliceProfile)
    [void](Invoke-Client 'owner-activation-store' $AliceProfile (@('group','advance')+$argsGroup))
    [void](Sync 'invitee-activation-receive-ack' $BobProfile)
    foreach ($profile in @($AliceProfile,$BobProfile)) {
        $head = Group-Head 'activated-cold-head' $profile
        Require ($head.State -ceq 'Active' -and $head.Epoch -eq 1 -and $head.Group -ceq $group) 'Both exact protected group heads must be activated.'
    }
    foreach ($direction in @(@($AliceProfile,$BobProfile,'A-to-B'),@($BobProfile,$AliceProfile,'B-to-A'))) {
        $before = Invoke-Client 'sender-cold-history' $direction[0] @('group','messages','--group',$group)
        $commands = (Group-Head 'sender-protected-message-commands' $direction[0]).LocalMessageCommands
        Require ($commands -le 1) 'Unrelated group message commands must not be silently replaced.'
        if ($commands -eq 0) { [void](Invoke-Client 'group-text-store' $direction[0] (@('group','send','--text',('Group QA '+$direction[2]))+$argsGroup)) }
        else { [void](Invoke-Client 'group-text-original-flush' $direction[0] (@('group','flush')+$argsGroup)) }
        [void](Sync 'group-text-receive-ack' $direction[1])
    }
    foreach ($profile in @($AliceProfile,$BobProfile)) {
        $messages = Invoke-Client 'two-way-cold-native-history' $profile @('group','messages','--group',$group)
        Require (@($messages.items).Count -eq 2 -and @($messages.items | Where-Object local).Count -eq 1 -and @($messages.items | Where-Object { -not $_.local }).Count -eq 1) 'Both-way native group history missing.'
        Require (@($messages.items | Where-Object { $_.text -ceq 'Group QA A-to-B' }).Count -eq 1 -and @($messages.items | Where-Object { $_.text -ceq 'Group QA B-to-A' }).Count -eq 1) 'Received plaintext differs.'
        [void](Invoke-Client 'original-full-batch-replay' $profile (@('group','flush')+$argsGroup))
        $empty = Sync 'post-ack-empty-mailbox' $profile
        Require ($empty.processed -eq 0) 'Durably ACKed group events reappeared.'
        $again = Invoke-Client 'post-replay-native-history' $profile @('group','messages','--group',$group)
        Require (@($again.items).Count -eq 2) 'Group replay duplicated history.'
    }
    $passed = $true
} finally {
    [ordered]@{schema='deep.cli.connected-group-e2e.v1';passed=$passed;startedUtc=$started;finishedUtc=[DateTime]::UtcNow;
        runtimeSha256=$runtimeHash;scenarioSha256=$scenarioHash.ToLowerInvariant();steps=@($steps.ToArray());
        candidateAccounts=2;devicesPerAccount=1;groupRevision=$GroupRevision;reusedPublishedAccounts=[bool]$ReusePublishedAccounts;maximumExactAttempts=2;gsr1RetentionQualified=$false;devicesQualified=$false;releaseQualified=$false} |
        ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $run 'receipt.json') -Encoding utf8
    Write-Host ([pscustomobject]@{passed=$passed;commands=$steps.Count} | ConvertTo-Json -Compress)
}
