[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$BootstrapDirectory,
    [Parameter(Mandatory)][string]$RegistryOrigin,
    [Parameter(Mandatory)][string]$RunDirectory,
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
function Conversation([string]$left,[string]$right) { $pairConversations[(Pair-Key $left $right)] }
$passed = $false
try {
    $lists = @{}; $group = $null
    foreach ($profile in $profiles) {
        $present = Invoke-Client 'retained-account-cold-status' $profile @('account','status')
        Require ([bool]$present.accountPresent) 'Retained published account required.'
        $lists[$profile] = Invoke-Client 'retained-contact-consent-list' $profile @('contact','list')
        $head = Group-Head 'retained-three-member-head' $profile
        Require ($head.State -ceq 'Active' -and $head.Epoch -eq 2 -and $head.Members -eq 3) 'Complete retained three-member head required.'
        if ($null -eq $group) { $group = $head.Group } else { Require ($head.Group -ceq $group) 'Profiles disagree on exact group.' }
    }
    foreach ($pair in @(@($AliceProfile,$BobProfile),@($AliceProfile,$CarolProfile),@($BobProfile,$CarolProfile))) {
        $left = $lists[$pair[0]]; $right = $lists[$pair[1]]
        $common = @($left.contacts | Where-Object { $_.conversation -in @($right.contacts | ForEach-Object conversation) })
        Require ($common.Count -eq 1) 'One exact retained pair session required.'
        $conversation = $common[0].conversation
        foreach ($list in @($left,$right)) {
            $contact = @($list.contacts | Where-Object { $_.conversation -ceq $conversation })[0]
            $expected = if ($contact.initiator) { 'PeerAcceptanceRetained' } else { 'LocalAcceptanceRetained' }
            Require ($contact.state -ceq $expected) 'Actual retained contact consent required.'
        }
        $pairConversations[(Pair-Key $pair[0] $pair[1])] = $conversation
    }
    # Two non-owner senders finish both independent Store copies before any
    # recipient runs. The owner's fresh page must cover two distinct native peer
    # scopes; do not repeat its already qualified large control-batch replay here.
    $senders = @($BobProfile,$CarolProfile)
    foreach ($sender in $senders) {
        $peer = if ($sender -ceq $AliceProfile) { $BobProfile } else { $AliceProfile }
        $head = Group-Head 'second-round-original-command-count' $sender
        Require ($head.LocalMessageCommands -in @(1,2)) 'Unexpected semantic command count; never replace pending work.'
        $argsGroup = @('--group',$group,'--conversation',(Conversation $sender $peer))+$networkArgs
        if ($head.LocalMessageCommands -eq 1) { [void](Invoke-Client 'second-round-two-target-store' $sender (@('group','send','--text',('Three CLI second round '+$sender))+$argsGroup)) }
        else { [void](Invoke-Client 'second-round-original-full-batch-resume' $sender (@('group','flush')+$argsGroup)) }
    }
    foreach ($recipient in $profiles) {
        $sync = Sync 'two-peer-scope-native-receive-and-ack' $recipient
        $expectedReceives = if ($recipient -ceq $AliceProfile) { 2 } else { 1 }
        Require ($sync.processed -eq $expectedReceives -or $sync.processed -eq 0) 'Unexpected continuation page; preserve original work.'
        # Zero is allowed only for an exact resumed already-ACKed round. The
        # independent native histories below must still prove every new receive.
        $messages = Invoke-Client 'five-message-cold-native-history' $recipient @('group','messages','--group',$group)
        $expectedLocal = if ($recipient -ceq $AliceProfile) { 1 } else { 2 }
        Require (@($messages.items).Count -eq 5 -and @($messages.items | Where-Object local).Count -eq $expectedLocal) 'Both rounds of native history required.'
        foreach ($sender in $profiles) {
            Require (@($messages.items | Where-Object { $_.text -ceq ('Three CLI '+$sender) -and $_.sequence -eq 1 }).Count -eq 1) 'First-round history changed.'
        }
        foreach ($sender in $senders) {
            Require (@($messages.items | Where-Object { $_.text -ceq ('Three CLI second round '+$sender) -and $_.sequence -eq 2 }).Count -eq 1) 'Second-round history missing or duplicated.'
        }
        $empty = Sync 'post-multi-scope-ack-empty-poll' $recipient
        Require ($empty.processed -eq 0) 'Durably acknowledged events reappeared.'
    }
    $passed = $true
} finally {
    [ordered]@{schema='deep.cli.connected-group-e2e.v1';passed=$passed;startedUtc=$started;finishedUtc=[DateTime]::UtcNow;
        runtimeSha256=$runtimeHash;scenarioSha256=$scenarioHash.ToLowerInvariant();steps=@($steps.ToArray());
        candidateAccounts=3;devicesPerAccount=1;groupRevision=$GroupRevision;retainedGroupContinuation=$true;
        targetMessagesPerAccount=5;secondRoundSenders=2;maximumExactAttempts=2;gsr1RetentionQualified=$false;devicesQualified=$false;releaseQualified=$false} |
        ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $run 'receipt.json') -Encoding utf8
    Write-Host ([pscustomobject]@{passed=$passed;commands=$steps.Count} | ConvertTo-Json -Compress)
}
