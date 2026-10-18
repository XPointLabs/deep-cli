[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$BootstrapDirectory,
    [Parameter(Mandatory)][string]$RegistryOrigin,
    [Parameter(Mandatory)][string]$RunDirectory,
    [ValidatePattern('^[a-z][a-z0-9-]{0,31}$')][string]$AliceProfile = 'cli-current-alice',
    [ValidatePattern('^[a-z][a-z0-9-]{0,31}$')][string]$BobProfile = 'cli-current-bob'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$exe = Join-Path $repo 'src/Deep.Cli/bin/Release/net10.0-windows/deep.exe'
$run = [IO.Path]::GetFullPath($RunDirectory)
$artifactRoot = [IO.Path]::GetFullPath((Join-Path $repo 'artifacts')) + [IO.Path]::DirectorySeparatorChar
if (-not $run.StartsWith($artifactRoot, [StringComparison]::OrdinalIgnoreCase) -or
    (Test-Path -LiteralPath $run) -or $AliceProfile -ceq $BobProfile) { throw 'Fresh artifact directory and distinct retained profiles required.' }
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
$files = [Collections.Generic.List[object]]::new()
$networkArgs = @('--bootstrap', $BootstrapDirectory, '--registry', $RegistryOrigin)
function Require([bool]$ok, [string]$label) { if (-not $ok) { throw $label } }
function Invoke-Client([string]$phase, [string]$profile, [string[]]$command, [switch]$ExpectRefusal) {
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
        if (-not $process.WaitForExit(330000)) { $process.Kill($true); throw 'CLI deadline; original work retained, never reminted.' }
        $out = $stdout.GetAwaiter().GetResult(); $err = $stderr.GetAwaiter().GetResult()
        Require ($out.Length + $err.Length -le 1048576) 'CLI output bound.'
        Require ((Runtime-Fingerprint) -ceq $runtimeHash -and (Get-FileHash -LiteralPath $scenarioPath -Algorithm SHA256).Hash -ceq $scenarioHash) 'Scenario inputs changed during child.'
        $row = [pscustomobject]@{phase=$phase;exit=$process.ExitCode;milliseconds=$watch.ElapsedMilliseconds;expectedRefusal=[bool]$ExpectRefusal}
        $steps.Add($row); Write-Host ($row | ConvertTo-Json -Compress)
        if ($ExpectRefusal) { Require ($process.ExitCode -ne 0) 'Expected refusal did not happen.'; return }
        if ($process.ExitCode -ne 0) {
            $failure = $err | ConvertFrom-Json
            if ($failure.code -ceq 'business-operation-failed') {
                # Only the CLI's closed diagnostic schema, never stdout/arguments/identities/payload.
                $failure.diagnostic | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $run ('failure-'+$steps.Count+'.json')) -Encoding utf8
                Write-Host ($failure.diagnostic | ConvertTo-Json -Depth 8 -Compress)
            }
            throw 'CLI operation failed; preserve account, manifest and exact pending offer.'
        }
        return ($out | ConvertFrom-Json)
    } finally { $process.Dispose() }
}
function Operation([string]$purpose) {
    [Convert]::ToHexStringLower([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes('Deep/CLI/AttachmentQA/20261018/'+$network+'/'+$AliceProfile+'/'+$BobProfile+'/'+$purpose)))
}
function Transfer([string]$label, [string]$sender, [string]$receiver, [string]$conversation, [byte[]]$content, [string]$name, [string]$media) {
    $input = Join-Path $run $name
    [IO.File]::WriteAllBytes($input, $content) # Generated harmless QA fixture, not application custody.
    $hash = [Convert]::ToHexStringLower([Security.Cryptography.SHA256]::HashData($content))
    $asset = Operation ($label+'/asset')
    $prepare = @('attachment','prepare','--file',$input,'--media',$media,'--operation',$asset)+$networkArgs
    $prepared = Invoke-Client ($label+'-prepare') $sender $prepare
    Require ($prepared.status -ceq 'prepared' -and $prepared.PlaintextSha256 -ceq $hash -and $prepared.Bytes -eq $content.Length) 'Prepared object differs from source.'
    $reopened = Invoke-Client ($label+'-prepare-reopen') $sender $prepare
    Require ($prepared.ObjectId -ceq $reopened.ObjectId -and $prepared.ExpiresAtUnixSeconds -eq $reopened.ExpiresAtUnixSeconds) 'Prepare retry replaced original object or expiry.'
    $pending = Invoke-Client ($label+'-operations') $sender @('attachment','operations')
    $work = @($pending.items | Where-Object { $_.ConversationId -ceq $conversation -and $_.ObjectId -ceq $prepared.ObjectId })
    Require ($work.Count -le 1) 'Ambiguous original attachment offer.'
    Require (@($work | Where-Object WorkStopped).Count -eq 0) 'Stopped attachment work cannot be recreated.'
    if ($work.Count -eq 1) { $offer = $work[0].Operation }
    else {
        $prior = Invoke-Client ($label+'-own-list') $sender @('attachment','list','--conversation',$conversation)
        Require (@($prior.items | Where-Object { $_.IsLocalAuthor -and $_.ObjectId -ceq $prepared.ObjectId }).Count -eq 0) 'Previously completed offer needs its original receipt; do not create a replacement.'
        $offer = (Invoke-Client ($label+'-queue') $sender (@('attachment','queue','--conversation',$conversation,'--asset',$asset)+$networkArgs)).operation
    }
    $send = @('attachment','send','--conversation',$conversation,'--asset',$asset,'--operation',$offer)+$networkArgs
    Require ((Invoke-Client ($label+'-send') $sender $send).status -ceq 'stored') 'No authenticated Store.'
    [void](Invoke-Client ($label+'-receive') $receiver (@('mailbox','sync')+$networkArgs))
    $list = Invoke-Client ($label+'-list') $receiver @('attachment','list','--conversation',$conversation)
    $matching = @($list.items | Where-Object { -not $_.IsLocalAuthor -and $_.ObjectId -ceq $prepared.ObjectId })
    Require ($matching.Count -eq 1) 'No unique independently received authenticated offer.'
    $item = $matching[0]
    Require ($item.Bytes -eq $content.Length -and $item.Filename -ceq $name -and $item.MediaType -ceq $media) 'Received metadata differs.'
    $output = Join-Path $run ('received-'+$name)
    $download = @('attachment','download','--conversation',$conversation,'--logical',$item.LogicalId,'--device',$item.AuthorDeviceId,'--output',$output)+$networkArgs
    $downloaded = Invoke-Client ($label+'-cold-download') $receiver $download
    Require ($downloaded.status -ceq 'downloaded' -and $downloaded.PlaintextSha256 -ceq $hash -and $downloaded.Bytes -eq $content.Length) 'Download response differs.'
    Require ((Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash.ToLowerInvariant() -ceq $hash) 'Independent complete output hash differs.'
    Invoke-Client ($label+'-refuse-overwrite') $receiver $download -ExpectRefusal
    Require ((Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash.ToLowerInvariant() -ceq $hash) 'Refused overwrite changed output.'
    Require ((Invoke-Client ($label+'-send-reopen') $sender $send).status -ceq 'stored') 'Exact retained Store retry failed.'
    [void](Invoke-Client ($label+'-dedup-sync') $receiver (@('mailbox','sync')+$networkArgs))
    $list = Invoke-Client ($label+'-dedup-list') $receiver @('attachment','list','--conversation',$conversation)
    Require (@($list.items | Where-Object { -not $_.IsLocalAuthor -and $_.ObjectId -ceq $prepared.ObjectId }).Count -eq 1) 'Duplicate attachment materialized.'
    $files.Add([pscustomobject]@{direction=$label;bytes=$content.Length;sha256=$hash;completeRemoteHashVerified=$true;coldPrepareReusedObject=$true;retainedStoreReplay=$true;duplicateOffers=0;overwriteRefused=$true})
}
$passed = $false
try {
    $a = Invoke-Client 'alice-retained-contact' $AliceProfile @('contact','list')
    $b = Invoke-Client 'bob-retained-contact' $BobProfile @('contact','list')
    Require (@($a.contacts).Count -eq 1 -and @($b.contacts).Count -eq 1) 'Exactly one retained contact per client required.'
    Require ($a.contacts[0].conversation -ceq $b.contacts[0].conversation -and $a.contacts[0].state -ceq 'PeerAcceptanceRetained' -and $b.contacts[0].state -ceq 'LocalAcceptanceRetained') 'Retained pair is not explicitly accepted.'
    $data = [byte[]]::new(524325)
    for ($i = 0; $i -lt $data.Length; $i++) { $data[$i] = [byte](($i * 17 + 31) % 251) }
    Transfer 'file-alice-to-bob' $AliceProfile $BobProfile $a.contacts[0].conversation $data 'qa-document.bin' 'application/octet-stream'
    $png = [Convert]::FromBase64String('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aE1sAAAAASUVORK5CYII=')
    Transfer 'png-bob-to-alice' $BobProfile $AliceProfile $a.contacts[0].conversation $png 'qa-image.png' 'image/png'
    Require (@(Get-ChildItem -LiteralPath $run -Filter '.deep-verified-download-*').Count -eq 0) 'Download staging file leaked.'
    $passed = $true
} finally {
    $receipt = [ordered]@{schema='deep.cli.attachment-e2e.v1';passed=$passed;startedUtc=$started;finishedUtc=[DateTime]::UtcNow;
        runtimeSha256=$runtimeHash;scenarioSha256=$scenarioHash.ToLowerInvariant();steps=@($steps.ToArray());files=@($files.ToArray());
        groupsQualified=$false;devicesQualified=$false;releaseQualified=$false}
    $receipt | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $run 'receipt.json') -Encoding utf8
    Write-Host ([pscustomobject]@{passed=$passed;commands=$steps.Count;remoteFiles=$files.Count} | ConvertTo-Json -Compress)
}
