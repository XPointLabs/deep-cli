[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$BootstrapDirectory,
    [Parameter(Mandatory)][string]$RegistryOrigin,
    [Parameter(Mandatory)][string]$RunDirectory,
    [Parameter(Mandatory)][ValidatePattern('^[a-z][a-z0-9-]{0,31}$')][string]$SenderProfile,
    [Parameter(Mandatory)][ValidatePattern('^[a-z][a-z0-9-]{0,31}$')][string]$ReceiverProfile,
    [switch]$ReceiveOnly
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$run=[IO.Path]::GetFullPath($RunDirectory)
$root=[IO.Path]::GetFullPath((Join-Path $repo 'artifacts'))+[IO.Path]::DirectorySeparatorChar
if(-not $run.StartsWith($root,[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $run) -or $SenderProfile -ceq $ReceiverProfile){throw 'Fresh artifact directory and distinct retained profiles required'}
$exe=Join-Path $repo 'src/Deep.Cli/bin/Release/net10.0-windows/deep.exe'
foreach($path in @($run,$exe,$BootstrapDirectory)){
    for($cursor=[IO.Path]::GetFullPath($path);$cursor;$cursor=[IO.Path]::GetDirectoryName($cursor)){
        if((Test-Path -LiteralPath $cursor) -and ((Get-Item -LiteralPath $cursor).Attributes -band [IO.FileAttributes]::ReparsePoint)){throw 'Linked recovery input rejected'}
    }
}
$network=(Get-Content (Join-Path $BootstrapDirectory 'deep-dev.json') -Raw|ConvertFrom-Json).networkIdHex.ToLowerInvariant()
if($network -cnotmatch '^[0-9a-f]{32}$'){throw 'Exact public network binding required'}
[void](New-Item -ItemType Directory -Path $run)
Import-Module (Join-Path $PSScriptRoot 'CliSession.psm1') -Force
$sessions=@{};$steps=[Collections.Generic.List[object]]::new();$passed=$false
$net=@('--bootstrap',$BootstrapDirectory,'--registry',$RegistryOrigin)
$hashes=@{};foreach($name in @('deep.dll','Deep.Client.Shared.dll','Deep.Protocol.dll')){$hashes[$name]=(Get-FileHash (Join-Path (Split-Path $exe) $name) -Algorithm SHA256).Hash}
$scriptHash=(Get-FileHash $PSCommandPath -Algorithm SHA256).Hash
Copy-Item -LiteralPath $PSCommandPath -Destination (Join-Path $run 'scenario.ps1')
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'CliSession.psm1') -Destination (Join-Path $run 'CliSession.psm1')
function Call([string]$phase,[string]$profile,[string[]]$arguments){
    if(-not $sessions.ContainsKey($profile)){$sessions[$profile]=New-CliSession $exe $profile $network $BootstrapDirectory $RegistryOrigin}
    $watch=[Diagnostics.Stopwatch]::StartNew()
    $reply=Invoke-CliSession $sessions[$profile] ($arguments+@('--profile',$profile,'--network',$network)) 330000
    $row=[ordered]@{Phase=$phase;Exit=$reply.ExitCode;Milliseconds=$watch.ElapsedMilliseconds;CpuMilliseconds=$reply.ProcessorMilliseconds}
    foreach($field in @('networkWork','protectionWork','recoveryWork','processed','tombstones','hasMore')){if($reply.Result.PSObject.Properties.Name -contains $field){$row[$field]=$reply.Result.$field}}
    $steps.Add([pscustomobject]$row);[pscustomobject]$row|ConvertTo-Json -Depth 8 -Compress|Write-Host
    if($reply.ExitCode -ne 0){$reply.Result.diagnostic|ConvertTo-Json -Depth 12|Set-Content (Join-Path $run 'failure.json') -Encoding utf8;throw 'Original recovery command failed; no replacement or driver retry'}
    return $reply.Result
}
try{
    $pending=Call 'original-pending' $SenderProfile @('message','pending')
    if($ReceiveOnly){
        if(@($pending.items).Count -ne 0){throw 'Receive-only recovery requires completed sender Store'}
        $left=Call 'sender-contacts' $SenderProfile @('contact','list')
        $right=Call 'receiver-contacts' $ReceiverProfile @('contact','list')
        $common=@($left.contacts|Where-Object {$_.conversation -in @($right.contacts|ForEach-Object conversation)})
        if($common.Count -ne 1){throw 'Exact retained pair conversation required'}
        $history=Call 'sender-original-history' $SenderProfile @('message','list','--conversation',$common[0].conversation)
        $candidates=@($history.items|Where-Object {$_.local -and $_.text -cmatch '^Direct latency [0-9a-f]{32}$'}|Sort-Object createdAt -Descending)
        if($candidates.Count -lt 1){throw 'Original diagnostic message missing'}
        $original=[pscustomobject]@{conversation=$common[0].conversation;text=$candidates[0].text}
    }else{
        if(@($pending.items).Count -ne 1){throw 'Exactly one original pending text command required'}
        $original=$pending.items[0]
    } # Kept only in redirected private stdio/RAM; never exported.
    [void](Call 'sender-current-network' $SenderProfile (@('network','verify')+$net))
    [void](Call 'receiver-current-network' $ReceiverProfile (@('network','verify')+$net))
    if(-not $ReceiveOnly){[void](Call 'original-store' $SenderProfile (@('message','send','--conversation',$original.conversation,'--operation',$original.operation,'--text',$original.text)+$net))}
    $page=Call 'original-receive-ack' $ReceiverProfile (@('mailbox','sync')+$net)
    if($page.hasMore -or (-not $ReceiveOnly -and $page.processed -lt 1) -or $page.processed -ne $page.tombstones){throw 'Original receive/ACK incomplete'}
    $history=Call 'original-history' $ReceiverProfile @('message','list','--conversation',$original.conversation)
    if(@($history.items|Where-Object {$_.text -ceq $original.text -and -not $_.local}).Count -ne 1){throw 'Original received text missing or duplicated'}
    $pending=Call 'sender-pending-empty' $SenderProfile @('message','pending')
    if(@($pending.items).Count -ne 0){throw 'Original Store still pending'}
    $empty=Call 'receiver-empty-sync' $ReceiverProfile (@('mailbox','sync')+$net)
    if($empty.processed -ne 0 -or $empty.tombstones -ne 0 -or $empty.hasMore){throw 'Native mailbox not empty'}
    $passed=$true
}finally{
    foreach($session in $sessions.Values){try{Close-CliSession $session}catch{$passed=$false}}
    foreach($name in $hashes.Keys){if((Get-FileHash (Join-Path (Split-Path $exe) $name) -Algorithm SHA256).Hash -cne $hashes[$name]){$passed=$false}}
    if((Get-FileHash $PSCommandPath -Algorithm SHA256).Hash -cne $scriptHash){$passed=$false}
    [ordered]@{Passed=$passed;Profiled=$false;ReceiveOnly=[bool]$ReceiveOnly;OriginalPendingCommands=$(if($ReceiveOnly){0}else{1});NewQueuedCommands=0;DriverAttempts=1;RuntimeHashes=$hashes;ScenarioSha256=$scriptHash;Steps=$steps.ToArray();ReleaseQualified=$false}|ConvertTo-Json -Depth 12|Set-Content (Join-Path $run 'receipt.json') -Encoding utf8
    if(-not $passed){throw 'Original Store recovery incomplete; original state retained'}
}
