[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$BootstrapDirectory,
    [Parameter(Mandatory)][string]$RegistryOrigin,
    [Parameter(Mandatory)][string]$RunDirectory,
    [Parameter(Mandatory)][string]$GroupName,
    [Parameter(Mandatory)][string[]]$Profiles
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($Profiles.Count -ne 3 -or @($Profiles|Select-Object -Unique).Count -ne 3 -or
    @($Profiles|Where-Object {$_ -cnotmatch '^[a-z][a-z0-9-]{0,31}$'}).Count -ne 0) { throw 'Three distinct CLI profiles required.' }
$repo=Split-Path $PSScriptRoot -Parent
$run=[IO.Path]::GetFullPath($RunDirectory)
$artifactRoot=[IO.Path]::GetFullPath((Join-Path $repo 'artifacts'))+[IO.Path]::DirectorySeparatorChar
if(-not $run.StartsWith($artifactRoot,[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $run)) { throw 'Fresh repository-owned receipt directory required.' }
$binaryRoot=Join-Path $repo 'src/Deep.Cli/bin/Release/net10.0-windows'
$exe=Join-Path $binaryRoot 'deep.exe'
foreach($path in @($run,$binaryRoot,$BootstrapDirectory)) {
    for($cursor=[IO.Path]::GetFullPath($path);$cursor;$cursor=[IO.Path]::GetDirectoryName($cursor)) {
        if((Test-Path -LiteralPath $cursor) -and ((Get-Item -LiteralPath $cursor).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Reparse path rejected.' }
    }
}
function Runtime-Hash {
    $items=@(Get-ChildItem -LiteralPath $binaryRoot -Recurse -Force|Sort-Object FullName -CaseSensitive)
    if(@($items|Where-Object {$_.Attributes -band [IO.FileAttributes]::ReparsePoint}).Count) { throw 'Runtime reparse rejected.' }
    $files=@($items|Where-Object {-not $_.PSIsContainer})
    if($files.Count -lt 3 -or $files.Count -gt 2048) { throw 'Runtime inventory bound.' }
    $rows=@($files|ForEach-Object {$_.FullName.Substring($binaryRoot.Length)+'|'+(Get-FileHash -LiteralPath $_.FullName).Hash})
    [Convert]::ToHexStringLower([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes(($rows -join "`n"))))
}
$runtimeHash=Runtime-Hash
$scriptHash=(Get-FileHash -LiteralPath $PSCommandPath).Hash
$modulePath=Join-Path $PSScriptRoot 'CliSession.psm1'
$moduleHash=(Get-FileHash -LiteralPath $modulePath).Hash
Import-Module $modulePath -Force
$network=(Get-Content -LiteralPath (Join-Path $BootstrapDirectory 'deep-dev.json') -Raw|ConvertFrom-Json).networkIdHex.ToLowerInvariant()
if($network -cnotmatch '^[0-9a-f]{32}$') { throw 'Explicit network required.' }
$networkArgs=@('--bootstrap',$BootstrapDirectory,'--registry',$RegistryOrigin)
[void](New-Item -ItemType Directory -Path $run)
Copy-Item -LiteralPath $PSCommandPath -Destination (Join-Path $run 'scenario.ps1')
Copy-Item -LiteralPath $modulePath -Destination (Join-Path $run 'CliSession.psm1')
Compress-Archive -LiteralPath $binaryRoot -DestinationPath (Join-Path $run 'runtime.zip') -CompressionLevel Fastest
$steps=[Collections.Generic.List[object]]::new();$session=$null;$passed=$false
function Invoke-Measured([int]$actor,[string]$phase,[string[]]$Command) {
    if((Runtime-Hash) -cne $runtimeHash -or (Get-FileHash -LiteralPath $PSCommandPath).Hash -cne $scriptHash -or
        (Get-FileHash -LiteralPath $modulePath).Hash -cne $moduleHash) { throw 'Measurement inputs changed.' }
    $argsNative=$Command+@('--profile',$Profiles[$actor],'--network',$network)
    $watch=[Diagnostics.Stopwatch]::StartNew();$process=$null
    try {
        if($session) { $response=Invoke-CliSession $session $argsNative 330000 }
        else {
            $start=[Diagnostics.ProcessStartInfo]::new($exe);$start.UseShellExecute=$false;$start.CreateNoWindow=$true
            $start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
            foreach($arg in $argsNative) { [void]$start.ArgumentList.Add($arg) }
            $process=[Diagnostics.Process]::new();$process.StartInfo=$start
            if(-not $process.Start()) { throw 'CLI not started.' }
            $stdout=$process.StandardOutput.ReadToEndAsync();$stderr=$process.StandardError.ReadToEndAsync()
            if(-not $process.WaitForExit(330000)) { $process.Kill($true);throw 'CLI deadline; no retry.' }
            $out=$stdout.GetAwaiter().GetResult();$err=$stderr.GetAwaiter().GetResult()
            if($out.Length+$err.Length -gt 1048576) { throw 'CLI output bound.' }
            $json=$(if($process.ExitCode -eq 0){$out}else{$err})|ConvertFrom-Json
            $response=[pscustomobject]@{ExitCode=$process.ExitCode;Result=$json;ProcessorMilliseconds=[long]$process.TotalProcessorTime.TotalMilliseconds}
        }
        $row=[pscustomobject]@{actor=$actor;phase=$phase;exit=$response.ExitCode;milliseconds=$watch.ElapsedMilliseconds;processorMilliseconds=$response.ProcessorMilliseconds}
        foreach($field in @('networkWork','sessionWork')) {
            if($response.Result.PSObject.Properties.Name -contains $field) { $row|Add-Member $field $response.Result.$field }
        }
        $steps.Add($row);Write-Host ($row|ConvertTo-Json -Depth 8 -Compress)
        if($response.ExitCode -ne 0) { throw 'Measured command failed; no retry or replacement.' }
        if((Runtime-Hash) -cne $runtimeHash) { throw 'Runtime changed during command.' }
        return $response.Result
    } finally { if($process) { $process.Dispose() } }
}
try {
    $ownerContacts=Invoke-Measured 0 'setup-contacts' @('contact','list')
    $expectedGroup=$null;$expectedEpoch=$null
    foreach($actor in 0..2) {
        $heads=Invoke-Measured $actor 'setup-native-head' @('group','list')
        $head=@($heads.items|Where-Object {$_.Name -ceq $GroupName})
        if($head.Count -ne 1 -or $head[0].State -cne 'Active' -or $head[0].Members -ne 3) { throw 'Exact active three-member group required.' }
        if($actor -eq 0) { $expectedGroup=$head[0].Group;$expectedEpoch=$head[0].Epoch }
        elseif($head[0].Group -cne $expectedGroup -or $head[0].Epoch -ne $expectedEpoch) { throw 'Different native group head.' }
        if($actor -eq 0) { $command=@('group','publish','--group',$expectedGroup)+$networkArgs }
        else {
            $contacts=Invoke-Measured $actor 'setup-contacts' @('contact','list')
            $pair=@($contacts.contacts|Where-Object {$_.conversation -in @($ownerContacts.contacts|ForEach-Object conversation)})
            if($pair.Count -ne 1) { throw 'Exact owner contact required.' }
            $command=@('group','sync','--group',$expectedGroup,'--conversation',$pair[0].conversation)+$networkArgs
        }
        $cold=Invoke-Measured $actor 'cold-control' $command
        $session=New-CliSession $exe $Profiles[$actor] $network $BootstrapDirectory $RegistryOrigin
        [void](Invoke-Measured $actor 'separate-authority-refresh' (@('network','refresh')+$networkArgs))
        foreach($sample in 1..2) {
            $warm=Invoke-Measured $actor ('working-control-'+$sample) $command
            if($warm.status -cne $cold.status -or $warm.completed -ne $cold.completed -or $warm.completed -ne 0) { throw 'Control replay changed protected progress.' }
        }
        Close-CliSession $session;$session=$null
    }
    $passed=$true
} finally {
    if($session) { try { Close-CliSession $session } catch { $passed=$false } }
    [ordered]@{kind='three-cli-control-latency-only';passed=$passed;runtimeSha256=$runtimeHash;scenarioSha256=$scriptHash;sessionModuleSha256=$moduleHash;
        attemptsPerCommand=1;steps=@($steps.ToArray());newMessages=0;deviceQualified=$false;releaseQualified=$false}|ConvertTo-Json -Depth 12|
        Set-Content -LiteralPath (Join-Path $run 'receipt.json') -Encoding utf8
    Write-Host ([pscustomobject]@{passed=$passed;commands=$steps.Count}|ConvertTo-Json -Compress)
}
