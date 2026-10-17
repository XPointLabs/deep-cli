[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$BootstrapDirectory,
    [Parameter(Mandatory)][string]$RegistryOrigin,
    [Parameter(Mandatory)][string]$RunDirectory,
    [switch]$ReusePublishedAccounts,
    [switch]$ResumeContact,
    [switch]$RetryExactTransient,
    [ValidateRange(0,100)][int]$IntentRevision = 0,
    [ValidatePattern('^[a-z][a-z0-9-]{0,31}$')][string]$AliceProfile = 'cli-e2e-alice',
    [ValidatePattern('^[a-z][a-z0-9-]{0,31}$')][string]$BobProfile = 'cli-e2e-bob'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$exe = Join-Path $repo 'src/Deep.Cli/bin/Release/net10.0-windows/deep.exe'
$run = [IO.Path]::GetFullPath($RunDirectory)
$artifactRoot = [IO.Path]::GetFullPath((Join-Path $repo 'artifacts')) + [IO.Path]::DirectorySeparatorChar
if (-not $run.StartsWith($artifactRoot, [StringComparison]::OrdinalIgnoreCase) -or
    (Test-Path -LiteralPath $run) -or $AliceProfile -ceq $BobProfile) { throw 'Fresh repo artifact directory and distinct profiles required.' }
foreach ($path in @($run, $BootstrapDirectory, $exe)) {
    for ($cursor = [IO.Path]::GetFullPath($path); $cursor; $cursor = [IO.Path]::GetDirectoryName($cursor)) {
        if ((Test-Path -LiteralPath $cursor) -and ((Get-Item -LiteralPath $cursor).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw 'Reparse path rejected.'
        }
    }
}
$manifest = Get-Content -LiteralPath (Join-Path $BootstrapDirectory 'deep-dev.json') -Raw | ConvertFrom-Json
$network = $manifest.networkIdHex.ToLowerInvariant()
if ($network -cnotmatch '^[0-9a-f]{32}$') { throw 'Public network binding rejected.' }
$exeHash = (Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash
function Get-RuntimeInputFingerprint {
    $binaryRoot = [IO.Path]::GetDirectoryName($exe) + [IO.Path]::DirectorySeparatorChar
    $entries = @(Get-ChildItem -LiteralPath $binaryRoot -Recurse -Force)
    if (@($entries | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }).Count -ne 0) {
        throw 'Runtime input reparse path rejected.'
    }
    $files = @($entries | Where-Object { -not $_.PSIsContainer } | Sort-Object FullName -CaseSensitive)
    if ($files.Count -lt 3 -or $files.Count -gt 2048) { throw 'Runtime input inventory exceeds its bound.' }
    $rows = @($files | ForEach-Object {
        $_.FullName.Substring($binaryRoot.Length).Replace('\','/') + '|' + (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
    })
    # The apphost EXE alone does not identify managed code. Include the complete
    # bounded output tree: CLI/Shared/Protocol, native providers and config.
    $bytes = [Text.Encoding]::UTF8.GetBytes(($rows -join "`n"))
    return [Convert]::ToHexStringLower([Security.Cryptography.SHA256]::HashData($bytes))
}
$runtimeFingerprint = Get-RuntimeInputFingerprint
[void](New-Item -ItemType Directory -Path $run)
$steps = [Collections.Generic.List[object]]::new()
$started = [DateTime]::UtcNow
$networkArgs = @('--bootstrap', $BootstrapDirectory, '--registry', $RegistryOrigin)

function Invoke-Client([string]$Phase, [string]$ClientProfile, [string[]]$Command, [int]$Attempt = 1) {
    if ((Get-RuntimeInputFingerprint) -cne $runtimeFingerprint) { throw 'CLI runtime inputs changed during scenario.' }
    $start = [Diagnostics.ProcessStartInfo]::new($exe)
    $start.UseShellExecute = $false; $start.CreateNoWindow = $true
    $start.RedirectStandardOutput = $true; $start.RedirectStandardError = $true
    foreach ($arg in ($Command + @('--profile', $ClientProfile, '--network', $network))) { [void]$start.ArgumentList.Add($arg) }
    $process = [Diagnostics.Process]::new(); $process.StartInfo = $start
    $watch = [Diagnostics.Stopwatch]::StartNew()
    try {
        if (-not $process.Start()) { throw 'CLI process not started.' }
        $stdout = $process.StandardOutput.ReadToEndAsync(); $stderr = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit(330000)) {
            $process.Kill($true)
            $steps.Add([pscustomobject]@{phase=$Phase;exit=-1;milliseconds=$watch.ElapsedMilliseconds;outcome='unknown'})
            throw 'CLI process deadline; retained work must not be reminted.'
        }
        $out = $stdout.GetAwaiter().GetResult(); $err = $stderr.GetAwaiter().GetResult()
        if ((Get-RuntimeInputFingerprint) -cne $runtimeFingerprint) { throw 'CLI runtime inputs changed during command.' }
        if ($out.Length + $err.Length -gt 1048576) { throw 'CLI output exceeded bound.' }
        $parsed = if ($process.ExitCode -eq 0) { $out | ConvertFrom-Json } else { $err | ConvertFrom-Json }
        $work = $null
        if ($parsed.PSObject.Properties.Name -contains 'protectionWork') {
            $w = $parsed.protectionWork
            $work = [ordered]@{nativeProtects=[long]$w.nativeProtects;nativeUnprotects=[long]$w.nativeUnprotects;
                nativeProtectionMilliseconds=[long]$w.nativeProtectionMilliseconds}
        }
        $networkWork = if ($parsed.PSObject.Properties.Name -contains 'networkWork') { $parsed.networkWork } else { $null }
        $step = [pscustomobject]@{phase=$Phase;exit=$process.ExitCode;milliseconds=$watch.ElapsedMilliseconds;protectionWork=$work;networkWork=$networkWork}
        $steps.Add($step)
        Write-Host ($step | ConvertTo-Json -Compress)
        if ($process.ExitCode -ne 0) {
            # The CLI error grammar emits only closed category/owned-method/IL
            # metadata. Never write stdout, command args, payload or identity.
            $failure = $parsed
            if ($failure.code -eq 'business-operation-failed') {
                [pscustomobject]@{phase=$Phase;diagnostic=$failure.diagnostic} |
                    ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $run ('failure-'+$steps.Count+'.json')) -Encoding utf8
                Write-Host ($failure.diagnostic | ConvertTo-Json -Depth 8 -Compress)
                # Scenario scheduling only, not authority or proof of noncommit.
                # At most ONE new process repeats the IDENTICAL owned command.
                # Never repeat account creation or non-idempotent text queueing.
                $eligible = $Phase -in @('alice-verify','bob-verify','contact-request','contact-accept','bob-receive-request',
                    'alice-receive-accept','alice-text-send','bob-text-send','bob-receive-text','alice-receive-text','dedup-poll')
                $transient = @($failure.diagnostic.causes | Where-Object {
                    $_.category -in @('OutcomeUnknown','Cancelled','IngressRetryableBeforeForward') -or $_.check -ceq 'ClaimOutcomeUnknown'
                }).Count -gt 0
                if ($RetryExactTransient -and $Attempt -eq 1 -and $eligible -and $transient) {
                    return Invoke-Client ($Phase+'-exact-retry') $ClientProfile $Command 2
                }
            }
            throw 'CLI operation failed; exact account and pending operations retained.'
        }
        return $parsed
    } finally { $process.Dispose() }
}
function Operation([string]$Purpose) {
    if ($IntentRevision -gt 0) { $Purpose = 'explicit-new-intent-' + $IntentRevision + '/' + $Purpose }
    $hash = [Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes('Deep/CLI/QA/20261017/' + $network + '/' + $Purpose))
    return [Convert]::ToHexStringLower($hash)
}
function Require([bool]$Condition, [string]$Label) { if (-not $Condition) { throw $Label } }
function Send-Text([string]$ClientProfile, [string]$Conversation, [string]$Text, [string]$Label) {
    $history = Invoke-Client ($Label+'-before') $ClientProfile @('message','list','--conversation',$Conversation)
    $matching = @($history.items | Where-Object { $_.local -and $_.text -ceq $Text })
    Require ($matching.Count -le 1) 'Duplicate local semantic text.'
    $pending = Invoke-Client ($Label+'-pending') $ClientProfile @('message','pending')
    $work = @($pending.items | Where-Object { $_.conversation -ceq $Conversation -and $_.text -ceq $Text })
    Require ($work.Count -le 1) 'Ambiguous original text operation.'
    if ($work.Count -eq 1) { $op = $work[0].operation }
    elseif ($matching.Count -eq 0) {
        $queued = Invoke-Client ($Label+'-queue') $ClientProfile (@('message','queue','--conversation',$Conversation,'--text',$Text)+$networkArgs)
        $op = $queued.operation
    } else { return }
    [void](Invoke-Client ($Label+'-send') $ClientProfile (@('message','send','--conversation',$Conversation,'--operation',$op,'--text',$Text)+$networkArgs))
}
$passed = $false
try {
    foreach ($p in @($AliceProfile,$BobProfile)) {
        $label = if ($p -ceq $AliceProfile) { 'alice' } else { 'bob' }
        $status = Invoke-Client ($label+'-status') $p @('account','status')
        if (-not $status.accountPresent) {
            Require (-not $ReusePublishedAccounts) 'Resume requires both retained accounts.'
            [void](Invoke-Client ($label+'-create') $p @('account','create','--name',('CLI QA '+$label)))
        }
        # Workflow resume only. Every subsequent business command still opens
        # the real independently current account/source/route/grant boundary.
        # This never fabricates a verification result or skips runtime gates.
        if (-not $ReusePublishedAccounts) { [void](Invoke-Client ($label+'-verify') $p (@('network','verify')+$networkArgs)) }
    }
    $alice = Invoke-Client 'alice-address' $AliceProfile @('account','address')
    $bob = Invoke-Client 'bob-address' $BobProfile @('account','address')
    Require ($alice.address -cne $bob.address) 'Profiles share identity.'
    # A deterministic caller logical intent permits exact scenario restart;
    # protocol nonces/keys/grants are exclusively authored by their real owners.
    $resumeAccepted = $false
    if ($ResumeContact) {
        $existingAlice = Invoke-Client 'alice-retained-contact' $AliceProfile @('contact','list')
        $existingBob = Invoke-Client 'bob-retained-contact' $BobProfile @('contact','list')
        Require (@($existingAlice.contacts).Count -eq 1 -and @($existingBob.contacts).Count -eq 1) 'Resume requires two unique retained contacts.'
        Require ($existingAlice.contacts[0].conversation -ceq $existingBob.contacts[0].conversation -and
            $existingAlice.contacts[0].initiator -and -not $existingBob.contacts[0].initiator) 'Retained contacts do not form one exact pair.'
        $resumeAccepted = $existingAlice.contacts[0].state -ceq 'PeerAcceptanceRetained' -and
            $existingBob.contacts[0].state -ceq 'LocalAcceptanceRetained'
    } else {
        [void](Invoke-Client 'contact-request' $AliceProfile (@('contact','request','--address',$bob.address,'--operation',(Operation ('request/'+$bob.address)))+$networkArgs))
        [void](Invoke-Client 'bob-receive-request' $BobProfile (@('mailbox','sync')+$networkArgs))
    }
    $bc = Invoke-Client 'bob-contact' $BobProfile @('contact','list')
    Require (@($bc.contacts).Count -eq 1) 'Bob has no unique received contact.'
    $bConversation = $bc.contacts[0].conversation
    # Continuation scheduling only. QueueText/RetryText still independently
    # verify actual native and protected acceptance through Shared's owner.
    # Do not resend an already confirmed control event just to reach text.
    if (-not $resumeAccepted) {
        [void](Invoke-Client 'contact-accept' $BobProfile (@('contact','accept','--conversation',$bConversation,'--operation',(Operation ('accept/'+$bConversation)))+$networkArgs))
        [void](Invoke-Client 'alice-receive-accept' $AliceProfile (@('mailbox','sync')+$networkArgs))
    }
    $ac = Invoke-Client 'alice-contact' $AliceProfile @('contact','list')
    Require (@($ac.contacts).Count -eq 1 -and $ac.contacts[0].state -ceq 'PeerAcceptanceRetained') 'Alice lacks explicit retained peer acceptance.'
    $aConversation = $ac.contacts[0].conversation
    $textA = 'CLI E2E Alice to Bob 20261017'
    $textB = 'CLI E2E Bob to Alice 20261017'
    Send-Text $AliceProfile $aConversation $textA 'alice-text'
    [void](Invoke-Client 'bob-receive-text' $BobProfile (@('mailbox','sync')+$networkArgs))
    Send-Text $BobProfile $bConversation $textB 'bob-text'
    [void](Invoke-Client 'alice-receive-text' $AliceProfile (@('mailbox','sync')+$networkArgs))
    foreach ($pair in @(@($AliceProfile,$aConversation),@($BobProfile,$bConversation))) {
        [void](Invoke-Client 'dedup-poll' $pair[0] (@('mailbox','sync')+$networkArgs))
        $messages = Invoke-Client 'cold-history' $pair[0] @('message','list','--conversation',$pair[1])
        $localText = if ($pair[0] -ceq $AliceProfile) { $textA } else { $textB }
        $remoteText = if ($pair[0] -ceq $AliceProfile) { $textB } else { $textA }
        Require (@($messages.items | Where-Object { $_.local -and $_.text -ceq $localText }).Count -eq 1) 'Local text not materialized exactly once.'
        Require (@($messages.items | Where-Object { -not $_.local -and $_.text -ceq $remoteText }).Count -eq 1) 'Remote text not received exactly once.'
    }
    $passed = $true
} finally {
    [ordered]@{scope=$(if($ResumeContact){'cli-retained-contact-bidirectional-text'}else{'cli-real-contact-bidirectional-text'});passed=$passed;reusedPublishedAccounts=[bool]$ReusePublishedAccounts;resumedContact=[bool]$ResumeContact;maximumExactAttempts=$(if($RetryExactTransient){2}else{1});intentRevision=$IntentRevision;startedUtc=$started.ToString('o');finishedUtc=[DateTime]::UtcNow.ToString('o');
        executableSha256=$exeHash.ToLowerInvariant();runtimeInputSha256=$runtimeFingerprint;deviceAcceptance=$false;steps=$steps.ToArray()} |
        ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $run 'receipt.json') -Encoding utf8
}
