[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$BootstrapDirectory,
    [Parameter(Mandatory)][string]$RegistryOrigin,
    [Parameter(Mandatory)][string]$RunDirectory,
    [Parameter(Mandatory)][ValidatePattern('^[a-z][a-z0-9-]{0,31}$')][string]$PublisherProfile,
    [Parameter(Mandatory)][ValidateCount(1,8)][string[]]$RecipientProfiles
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$exe=Join-Path $repo 'src/Deep.Cli/bin/Release/net10.0-windows/deep.exe'
$run=[IO.Path]::GetFullPath($RunDirectory)
$artifactRoot=[IO.Path]::GetFullPath((Join-Path $repo 'artifacts'))+[IO.Path]::DirectorySeparatorChar
if(-not $run.StartsWith($artifactRoot,[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $run) -or
    @($RecipientProfiles|Where-Object {$_ -cnotmatch '^[a-z][a-z0-9-]{0,31}$' -or $_ -ceq $PublisherProfile}).Count -or
    @($RecipientProfiles|Select-Object -Unique).Count -ne $RecipientProfiles.Count){throw 'Fresh owned artifact directory and distinct isolated profiles required.'}
foreach($path in @($run,$exe,$BootstrapDirectory)){
    for($cursor=[IO.Path]::GetFullPath($path);$cursor;$cursor=[IO.Path]::GetDirectoryName($cursor)){
        if((Test-Path -LiteralPath $cursor) -and ((Get-Item -LiteralPath $cursor).Attributes -band [IO.FileAttributes]::ReparsePoint)){throw 'Linked path rejected.'}
    }
}
$network=(Get-Content -LiteralPath (Join-Path $BootstrapDirectory 'deep-dev.json') -Raw|ConvertFrom-Json).networkIdHex.ToLowerInvariant()
if($network -cnotmatch '^[0-9a-f]{32}$'){throw 'Exact public network required.'}
$scenarioHash=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
$module=Join-Path $PSScriptRoot 'CliSession.psm1';$moduleHash=(Get-FileHash -LiteralPath $module -Algorithm SHA256).Hash
function RuntimeHash {
    $root=[IO.Path]::GetDirectoryName($exe)+[IO.Path]::DirectorySeparatorChar
    $items=@(Get-ChildItem -LiteralPath $root -Recurse -Force)
    if(@($items|Where-Object {$_.Attributes -band [IO.FileAttributes]::ReparsePoint}).Count){throw 'Linked runtime rejected.'}
    $files=@($items|Where-Object {-not $_.PSIsContainer}|Sort-Object FullName -CaseSensitive)
    if($files.Count -lt 3 -or $files.Count -gt 2048){throw 'Runtime inventory bound.'}
    $rows=@($files|ForEach-Object {$_.FullName.Substring($root.Length).Replace('\','/')+'|'+(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash})
    [Convert]::ToHexStringLower([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes(($rows -join [char]10))))
}
$runtimeHash=RuntimeHash
[void](New-Item -ItemType Directory -Path $run)
Copy-Item -LiteralPath $PSCommandPath -Destination (Join-Path $run 'scenario.ps1')
Copy-Item -LiteralPath $module -Destination (Join-Path $run 'CliSession.psm1')
Compress-Archive -LiteralPath ([IO.Path]::GetDirectoryName($exe)) -DestinationPath (Join-Path $run 'runtime.zip') -CompressionLevel Fastest
Import-Module $module -Force
$steps=[Collections.Generic.List[object]]::new();$sessions=@{};$passed=$false;$closeFailed=$false
function Call([string]$phase,[string]$profile,[string[]]$arguments){
    if((RuntimeHash) -cne $runtimeHash -or (Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash -cne $scenarioHash -or
        (Get-FileHash -LiteralPath $module -Algorithm SHA256).Hash -cne $moduleHash){throw 'Repair inputs changed.'}
    if(-not $sessions.ContainsKey($profile)){$sessions[$profile]=New-CliSession $exe $profile $network $BootstrapDirectory $RegistryOrigin}
    $watch=[Diagnostics.Stopwatch]::StartNew()
    $result=Invoke-CliSession $sessions[$profile] ($arguments+@('--profile',$profile,'--network',$network)) 330000
    $row=[ordered]@{phase=$phase;exit=$result.ExitCode;milliseconds=$watch.ElapsedMilliseconds;processorMilliseconds=$result.ProcessorMilliseconds;attempt=1}
    foreach($field in @('networkWork','runtimeWork','recoveryWork')){if($result.Result.PSObject.Properties.Name -contains $field){$row[$field]=$result.Result.$field}}
    $steps.Add([pscustomobject]$row);[pscustomobject]$row|ConvertTo-Json -Depth 6 -Compress|Write-Host
    if($result.ExitCode -ne 0){$result.Result.diagnostic|ConvertTo-Json -Depth 10|Set-Content -LiteralPath (Join-Path $run ('failure-'+$steps.Count+'.json')) -Encoding utf8;throw 'Owned repair failed; original state retained.'}
    return $result.Result
}
$net=@('--bootstrap',$BootstrapDirectory,'--registry',$RegistryOrigin)
try{
    $publisher=Call 'publisher-native-contacts' $PublisherProfile @('contact','list')
    foreach($recipient in $RecipientProfiles){
        $peer=Call 'recipient-native-contacts' $recipient @('contact','list')
        $common=@($publisher.contacts|Where-Object {$_.conversation -in @($peer.contacts|ForEach-Object conversation)})
        if($common.Count -ne 1){throw 'One exact retained pair required; no contact creation.'}
        $conversation=$common[0].conversation
        $repair=Call 'publish-owned-successor-through-live-reverse-route' $PublisherProfile (@('contact','refresh-route','--conversation',$conversation)+$net)
        if($repair.completed -notin @(0,1)){throw 'Unexpected maintenance result.'}
        $page=Call 'recipient-native-control-receive-ack' $recipient (@('mailbox','sync')+$net)
        if($page.hasMore -or $page.processed -ne $page.tombstones){throw 'Control receive/ACK incomplete; no implicit retry.'}
        $health=Call 'recipient-retained-route-interval-check' $recipient (@('contact','route-health','--conversation',$conversation)+$net)
        if(-not $health.health.AdvertisementIntervalCoversNow -or $health.health.RouteFaultRetained){throw 'Peer advertisement remains expired/faulted.'}
        $again=Call 'exact-maintenance-no-new-control' $PublisherProfile (@('contact','refresh-route','--conversation',$conversation)+$net)
        if($again.completed -ne 0){throw 'Maintenance created duplicate work.'}
    }
    $passed=$true
}finally{
    foreach($session in @($sessions.Values)){try{Close-CliSession $session}catch{$closeFailed=$true;$passed=$false}}
    if((RuntimeHash) -cne $runtimeHash){$passed=$false}
    [ordered]@{passed=$passed;runtimeSha256=$runtimeHash;scenarioSha256=$scenarioHash.ToLowerInvariant();sessionModuleSha256=$moduleHash.ToLowerInvariant();
        recipientCount=$RecipientProfiles.Count;sessionCloseFailed=$closeFailed;steps=$steps.ToArray();releaseQualified=$false}|ConvertTo-Json -Depth 12|
        Set-Content -LiteralPath (Join-Path $run 'receipt.json') -Encoding utf8
    Write-Host ([pscustomobject]@{passed=$passed;commands=$steps.Count}|ConvertTo-Json -Compress)
    if($closeFailed){throw 'Repair session did not close normally.'}
}
