[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$BootstrapDirectory,
    [Parameter(Mandatory)][string]$RegistryOrigin,
    [Parameter(Mandatory)][string]$RunDirectory,
    [Parameter(Mandatory)][ValidatePattern('^[a-z][a-z0-9-]{0,31}$')][string]$SenderProfile,
    [Parameter(Mandatory)][ValidatePattern('^[a-z][a-z0-9-]{0,31}$')][string]$ReceiverProfile,
    [string]$PrivateTraceDirectory,
    [string]$Executable,
    [switch]$ExternalProfiling
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$run=[IO.Path]::GetFullPath($RunDirectory)
$artifactRoot=[IO.Path]::GetFullPath((Join-Path $repo 'artifacts'))+[IO.Path]::DirectorySeparatorChar
if(-not $run.StartsWith($artifactRoot,[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $run) -or $SenderProfile -ceq $ReceiverProfile){throw 'Fresh local artifact and distinct retained profiles required'}
$exe=if($Executable){[IO.Path]::GetFullPath($Executable)}else{Join-Path $repo 'src/Deep.Cli/bin/Release/net10.0-windows/deep.exe'}
if($Executable -and (-not $exe.StartsWith($artifactRoot,[StringComparison]::OrdinalIgnoreCase) -or [IO.Path]::GetFileName($exe) -cne 'deep.exe')){throw 'Only an archived repo-owned CLI runtime is accepted'}
$network=(Get-Content (Join-Path $BootstrapDirectory 'deep-dev.json') -Raw|ConvertFrom-Json).networkIdHex.ToLowerInvariant()
if($network -cnotmatch '^[0-9a-f]{32}$'){throw 'Exact public network binding required'}
if($PrivateTraceDirectory){
    $traceRoot=[IO.Path]::GetFullPath('C:/Work/DeepSession/secrets/dev/')
    $PrivateTraceDirectory=[IO.Path]::GetFullPath($PrivateTraceDirectory)
    if(-not $PrivateTraceDirectory.StartsWith($traceRoot,[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $PrivateTraceDirectory)){throw 'Fresh private dev trace directory required'}
}
foreach($path in @($run,$exe,$BootstrapDirectory,$PrivateTraceDirectory)|Where-Object {$_}){
    for($cursor=[IO.Path]::GetFullPath($path);$cursor;$cursor=[IO.Path]::GetDirectoryName($cursor)){
        if((Test-Path -LiteralPath $cursor) -and ((Get-Item -LiteralPath $cursor).Attributes -band [IO.FileAttributes]::ReparsePoint)){throw 'Linked probe input rejected'}
    }
}
if($PrivateTraceDirectory){[void](New-Item -ItemType Directory -Path $PrivateTraceDirectory)}
[void](New-Item -ItemType Directory -Path $run)
Import-Module (Join-Path $PSScriptRoot 'CliSession.psm1') -Force
$sessions=@{};$steps=[Collections.Generic.List[object]]::new();$passed=$false;$closeFailed=$false;$trace=$null
$net=@('--bootstrap',$BootstrapDirectory,'--registry',$RegistryOrigin)
$runtimeHash=(Get-FileHash -LiteralPath (Join-Path (Split-Path $exe) 'Deep.Client.Shared.dll') -Algorithm SHA256).Hash
$protocolHash=(Get-FileHash -LiteralPath (Join-Path (Split-Path $exe) 'Deep.Protocol.dll') -Algorithm SHA256).Hash
$scriptHash=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
Copy-Item -LiteralPath $PSCommandPath -Destination (Join-Path $run 'scenario.ps1')
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'CliSession.psm1') -Destination (Join-Path $run 'CliSession.psm1')
function Call([string]$phase,[string]$profile,[string[]]$arguments){
    if(-not $sessions.ContainsKey($profile)){$sessions[$profile]=New-CliSession $exe $profile $network $BootstrapDirectory $RegistryOrigin}
    $watch=[Diagnostics.Stopwatch]::StartNew()
    $result=Invoke-CliSession $sessions[$profile] ($arguments+@('--profile',$profile,'--network',$network)) 330000
    $row=[ordered]@{Phase=$phase;Exit=$result.ExitCode;Milliseconds=$watch.ElapsedMilliseconds;CpuMilliseconds=$result.ProcessorMilliseconds}
    foreach($field in @('networkWork','protectionWork','recoveryWork','processed','tombstones','hasMore')){if($result.Result.PSObject.Properties.Name -contains $field){$row[$field]=$result.Result.$field}}
    $steps.Add([pscustomobject]$row);[pscustomobject]$row|ConvertTo-Json -Depth 8 -Compress|Write-Host
    if($result.ExitCode -ne 0){$result.Result.diagnostic|ConvertTo-Json -Depth 12|Set-Content (Join-Path $run 'failure.json') -Encoding utf8;throw 'Original probe operation failed; no implicit retry or account reset'}
    return $result.Result
}
try{
    $left=Call 'sender-contacts' $SenderProfile @('contact','list')
    $right=Call 'receiver-contacts' $ReceiverProfile @('contact','list')
    $common=@($left.contacts|Where-Object {$_.conversation -in @($right.contacts|ForEach-Object conversation)})
    if($common.Count -ne 1){throw 'Exactly one existing conversation required'}
    $conversation=$common[0].conversation
    [void](Call 'sender-warm-network' $SenderProfile (@('network','verify')+$net))
    [void](Call 'receiver-warm-network' $ReceiverProfile (@('network','verify')+$net))
    if($PrivateTraceDirectory){
        $start=[Diagnostics.ProcessStartInfo]::new((Get-Command dotnet-trace).Source)
        $start.UseShellExecute=$false;$start.CreateNoWindow=$true;$start.RedirectStandardInput=$true;$start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
        foreach($arg in @('collect','--process-id',[string]$sessions[$SenderProfile].Process.Id,'--providers','Microsoft-DotNETCore-SampleProfiler','--duration','00:01:30','--output',(Join-Path $PrivateTraceDirectory 'sender.nettrace'),'--buffersize','32')){[void]$start.ArgumentList.Add($arg)}
        $trace=[Diagnostics.Process]::Start($start);$traceOut=$trace.StandardOutput.ReadToEndAsync();$traceErr=$trace.StandardError.ReadToEndAsync()
        Start-Sleep -Seconds 2
        if($trace.HasExited){throw 'Sampling attachment failed'}
    }
    $text='Direct latency '+[Guid]::NewGuid().ToString('N')
    $queue=Call 'sender-queue' $SenderProfile (@('message','queue','--conversation',$conversation,'--text',$text)+$net)
    [void](Call 'sender-store' $SenderProfile (@('message','send','--conversation',$conversation,'--text',$text,'--operation',$queue.operation)+$net))
    if($trace){
        if(-not $trace.WaitForExit(100000)){throw 'Sampling did not stop'}
        if($trace.ExitCode -ne 0){throw 'Sampling failed'}
        [void]$traceOut.GetAwaiter().GetResult();[void]$traceErr.GetAwaiter().GetResult();$trace.Dispose();$trace=$null
    }
    $page=Call 'receiver-native-receive-ack' $ReceiverProfile (@('mailbox','sync')+$net)
    if($page.hasMore -or $page.processed -ne $page.tombstones -or $page.processed -lt 1){throw 'Probe receive/ACK incomplete'}
    $history=Call 'receiver-native-history' $ReceiverProfile @('message','list','--conversation',$conversation)
    if(@($history.items|Where-Object {$_.text -ceq $text -and -not $_.local}).Count -ne 1){throw 'Exact received probe missing/duplicated'}
    $empty=Call 'receiver-empty-sync' $ReceiverProfile (@('mailbox','sync')+$net)
    if($empty.processed -ne 0 -or $empty.tombstones -ne 0 -or $empty.hasMore){throw 'Native mailbox not empty'}
    $passed=$true
}finally{
    if($trace){try{$trace.StandardInput.WriteLine();$trace.StandardInput.Flush();if(-not $trace.WaitForExit(30000)){$trace.Kill($true)}}finally{$trace.Dispose()}}
    foreach($session in $sessions.Values){try{Close-CliSession $session}catch{$closeFailed=$true;$passed=$false}}
    if((Get-FileHash -LiteralPath (Join-Path (Split-Path $exe) 'Deep.Client.Shared.dll') -Algorithm SHA256).Hash -cne $runtimeHash){$passed=$false}
    if((Get-FileHash -LiteralPath (Join-Path (Split-Path $exe) 'Deep.Protocol.dll') -Algorithm SHA256).Hash -cne $protocolHash -or (Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash -cne $scriptHash){$passed=$false}
    [ordered]@{Passed=$passed;Profiled=[bool]($PrivateTraceDirectory -or $ExternalProfiling);OriginalMessages=1;SharedAssemblySha256=$runtimeHash.ToLowerInvariant();ProtocolAssemblySha256=$protocolHash.ToLowerInvariant();ScenarioSha256=$scriptHash.ToLowerInvariant();CloseFailed=$closeFailed;Steps=$steps.ToArray();ReleaseQualified=$false}|ConvertTo-Json -Depth 12|Set-Content (Join-Path $run 'receipt.json') -Encoding utf8
    Write-Host ([pscustomobject]@{Passed=$passed;Commands=$steps.Count}|ConvertTo-Json -Compress)
    if(-not $passed){throw 'Direct probe failed; original state preserved'}
}
