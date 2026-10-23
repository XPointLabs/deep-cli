[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$BootstrapDirectory,
    [Parameter(Mandatory)][string]$RegistryOrigin,
    [Parameter(Mandatory)][string]$RunDirectory,
    [string]$ExecutablePath,
    [Parameter(Mandatory)][ValidatePattern('^[a-z][a-z0-9-]{0,31}$')][string]$PublisherProfile,
    [Parameter(Mandatory)][ValidateCount(1,8)][string[]]$RecipientProfiles,
    [switch]$Reintroduce,
    [switch]$ConnectionCycle
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($ConnectionCycle -and $Reintroduce){throw 'Connection cycle cannot import a re-introduction address.'}
$repo=Split-Path $PSScriptRoot -Parent
$exe=Join-Path $repo 'src/Deep.Cli/bin/Release/net10.0-windows/deep.exe'
$run=[IO.Path]::GetFullPath($RunDirectory)
$artifactRoot=[IO.Path]::GetFullPath((Join-Path $repo 'artifacts'))+[IO.Path]::DirectorySeparatorChar
if($PSBoundParameters.ContainsKey('ExecutablePath')) {
    $exe=[IO.Path]::GetFullPath($ExecutablePath)
    if(-not $exe.StartsWith($artifactRoot,[StringComparison]::OrdinalIgnoreCase) -or
        [IO.Path]::GetFileName($exe) -cne 'deep.exe' -or -not(Test-Path -LiteralPath $exe -PathType Leaf)) {
        throw 'Published repair executable must be an existing deep.exe inside this CLI repository artifacts directory.'
    }
}
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
    $budget=if($arguments[0] -ceq 'network' -and $arguments[1] -cin @('maintain','verify','publish')){1830000}else{330000}
    $result=Invoke-CliSession $sessions[$profile] ($arguments+@('--profile',$profile,'--network',$network)) $budget
    $row=[ordered]@{phase=$phase;exit=$result.ExitCode;milliseconds=$watch.ElapsedMilliseconds;processorMilliseconds=$result.ProcessorMilliseconds;attempt=1}
    foreach($field in @('networkWork','runtimeWork','recoveryWork','persistenceWork','sessionWork')){if($result.Result.PSObject.Properties.Name -contains $field){$row[$field]=$result.Result.$field}}
    if($result.Result.PSObject.Properties.Name -contains 'maintenance'){$row['contactMaintenance']=$result.Result.maintenance}
    $steps.Add([pscustomobject]$row);[pscustomobject]$row|ConvertTo-Json -Depth 6 -Compress|Write-Host
    if($result.ExitCode -ne 0){$result.Result.diagnostic|ConvertTo-Json -Depth 10|Set-Content -LiteralPath (Join-Path $run ('failure-'+$steps.Count+'.json')) -Encoding utf8;throw 'Owned repair failed; original state retained.'}
    return $result.Result
}
function Require-ConnectionCycleResult($result,[int]$contacts,[bool]$quiescent=$false,[bool]$activation=$false,[int]$allowedDeferred=0){
    $m=$result.maintenance
    $statuses=if($activation){@('ok')}else{@('maintained','partial')}
    if($result.status -cnotin $statuses -or $m.AcceptedContacts -ne $contacts -or
        $m.ControlsStored -lt 0 -or $m.ControlsStored -gt $contacts -or
        $m.DeferredContacts -lt 0 -or $m.DeferredContacts -gt $contacts -or
        $m.Reintroductions -lt 0 -or $m.Reintroductions -gt $m.ControlsStored -or
        $m.ControlsStored+$m.DeferredContacts-$m.Reintroductions -gt $contacts -or
        $m.ProcessedEnvelopes -lt 0 -or $m.ProcessedEnvelopes -ne $m.DurableTombstones -or $m.HasMore){
        throw 'Connection cycle did not complete its bounded owned work.'
    }
    if($activation -and (-not $result.networkVerified -or -not $result.contactPublished)){
        throw 'Connection activation did not verify its own admission/publication.'
    }
    if(-not $activation -and (($result.status -ceq 'maintained') -ne ($m.DeferredContacts -eq 0))){
        throw 'Connection cycle status disagrees with deferred contacts.'
    }
    if($quiescent -and ($result.status -cnotin @('maintained','partial') -or $m.ControlsStored -ne 0 -or
        $m.Reintroductions -ne 0 -or $m.DeferredContacts -gt $allowedDeferred -or $m.ProcessedEnvelopes -ne 0)){
        throw 'Connection cycle is not quiescent; no implicit repair or retry.'
    }
}
$net=@('--bootstrap',$BootstrapDirectory,'--registry',$RegistryOrigin)
try{
    if($ConnectionCycle){
        $profiles=@($PublisherProfile)+@($RecipientProfiles)
        $lists=@{};$addresses=@{};$books=@{}
        foreach($profile in $profiles){
            $published=Call 'connection-own-publication-bootstrap' $profile (@('network','publish')+$net)
            if($published.status -cne 'published' -or -not $published.networkVerified -or -not $published.contactPublished){throw 'Own publication bootstrap failed.'}
            $lists[$profile]=Call 'connection-initial-native-contacts' $profile @('contact','list')
            # Ordinary user-known descriptors from the actual owners. Private
            # stdio/RAM only; never emitted in rows, files or process arguments.
            $own=Call 'existing-profile-public-descriptor' $profile @('account','address')
            if(-not $own.accountPresent -or [string]::IsNullOrWhiteSpace($own.address)){throw 'Existing descriptor unavailable; no account creation.'}
            $addresses[$profile]=$own.address;$own=$null
        }
        foreach($profile in $profiles){
            $entries=@(foreach($other in $profiles|Where-Object {$_ -cne $profile}){
                $common=@($lists[$profile].contacts|Where-Object {$_.conversation -cin @($lists[$other].contacts.conversation)})
                if($common.Count -ne 1 -or $common[0].state -cnotin @('PeerAcceptanceRetained','LocalAcceptanceRetained')){throw 'One accepted retained pair required.'}
                [pscustomobject]@{conversation=$common[0].conversation;address=$addresses[$other]}
            })
            $books[$profile]=[pscustomobject]@{arguments=($entries|ConvertTo-Json -Depth 3 -Compress -AsArray);selectors=@($entries.conversation)}
        }
        $addresses.Clear()
        # Two planned convergence passes, not retries of failed commands. Every
        # API invocation renews its own publication and targets ALL own contacts;
        # no script selects a peer address or invokes refresh/reintroduce-route.
        foreach($pass in 1..2){foreach($profile in $profiles){
            $verb=if($pass -eq 1){'verify'}else{'maintain'}
            $cycle=Call ('connection-maintenance-pass-'+$pass) $profile (@('network',$verb,'--known-contacts',$books[$profile].arguments)+$net)
            $lists[$profile]=Call 'connection-cycle-native-contacts' $profile @('contact','list')
            $accepted=@($lists[$profile].contacts|Where-Object {$_.state -cin @('PeerAcceptanceRetained','LocalAcceptanceRetained')}).Count
            Require-ConnectionCycleResult $cycle $accepted $false ($pass -eq 1)
        }}
        foreach($profile in $profiles){
            $cycle=Call 'connection-maintenance-quiescent-replay' $profile (@('network','maintain','--known-contacts',$books[$profile].arguments)+$net)
            $lists[$profile]=Call 'maintenance-retained-native-contacts' $profile @('contact','list')
            $accepted=@($lists[$profile].contacts|Where-Object {$_.state -cin @('PeerAcceptanceRetained','LocalAcceptanceRetained')})
            $outside=@($accepted|Where-Object {$_.conversation -cnotin $books[$profile].selectors}).Count
            Require-ConnectionCycleResult $cycle $accepted.Count $true $false $outside
        }
        for($left=0;$left -lt $profiles.Count;$left++){for($right=$left+1;$right -lt $profiles.Count;$right++){
            $common=@($lists[$profiles[$left]].contacts|Where-Object {$_.conversation -cin @($lists[$profiles[$right]].contacts.conversation)})
            if($common.Count -ne 1){throw 'One exact retained pair required; no contact creation.'}
            foreach($profile in @($profiles[$left],$profiles[$right])){
                $health=Call 'post-cycle-retained-route-interval-check' $profile (@('contact','route-health','--conversation',$common[0].conversation)+$net)
                if(-not $health.health.AdvertisementIntervalCoversNow -or $health.health.RouteFaultRetained){throw 'Connection cycle left an expired/faulted route.'}
            }
        }}
        $books.Clear()
    }else{
    $publisher=Call 'publisher-native-contacts' $PublisherProfile @('contact','list')
    foreach($recipient in $RecipientProfiles){
        $peer=Call 'recipient-native-contacts' $recipient @('contact','list')
        $common=@($publisher.contacts|Where-Object {$_.conversation -in @($peer.contacts|ForEach-Object conversation)})
        if($common.Count -ne 1){throw 'One exact retained pair required; no contact creation.'}
        $conversation=$common[0].conversation
        if($Reintroduce){
            [void](Call 'recipient-current-own-publication-maintenance' $recipient (@('network','publish')+$net))
            # Read only the peer's explicitly requested public address through
            # its real CLI. It remains in RAM and is never logged or archived.
            $address=Call 'read-existing-peer-public-address' $recipient @('account','address')
            if(-not $address.accountPresent -or [string]::IsNullOrWhiteSpace($address.address)){throw 'Existing peer address unavailable; no account creation.'}
            $repair=Call 'current-same-peer-reintroduction-native-control-store' $PublisherProfile (@('contact','reintroduce-route','--conversation',$conversation,'--address',$address.address)+$net)
            $address=$null
        }else{
            $repair=Call 'publish-owned-successor-through-live-reverse-route' $PublisherProfile (@('contact','refresh-route','--conversation',$conversation)+$net)
        }
        if($repair.completed -notin @(0,1)){throw 'Unexpected maintenance result.'}
        $page=Call 'recipient-native-control-receive-ack' $recipient (@('mailbox','sync')+$net)
        if($page.hasMore -or $page.processed -ne $page.tombstones){throw 'Control receive/ACK incomplete; no implicit retry.'}
        $health=Call 'recipient-retained-route-interval-check' $recipient (@('contact','route-health','--conversation',$conversation)+$net)
        if(-not $health.health.AdvertisementIntervalCoversNow -or $health.health.RouteFaultRetained){throw 'Peer advertisement remains expired/faulted.'}
        if($Reintroduce){
            $reverse=Call 'ordinary-reverse-native-route-maintenance' $recipient (@('contact','refresh-route','--conversation',$conversation)+$net)
            if($reverse.completed -notin @(0,1)){throw 'Unexpected reverse maintenance result.'}
            $back=Call 'publisher-native-control-receive-ack' $PublisherProfile (@('mailbox','sync')+$net)
            if($back.hasMore -or $back.processed -ne $back.tombstones){throw 'Reverse receive/ACK incomplete; no implicit retry.'}
            $reverseHealth=Call 'publisher-retained-route-interval-check' $PublisherProfile (@('contact','route-health','--conversation',$conversation)+$net)
            if(-not $reverseHealth.health.AdvertisementIntervalCoversNow -or $reverseHealth.health.RouteFaultRetained){throw 'Reverse advertisement remains expired/faulted.'}
        }
        $again=Call 'exact-maintenance-no-new-control' $PublisherProfile (@('contact','refresh-route','--conversation',$conversation)+$net)
        if($again.completed -ne 0){throw 'Maintenance created duplicate work.'}
    }
    }
    $passed=$true
}finally{
    foreach($session in @($sessions.Values)){try{Close-CliSession $session}catch{$closeFailed=$true;$passed=$false}}
    if((RuntimeHash) -cne $runtimeHash){$passed=$false}
    [ordered]@{passed=$passed;runtimeSha256=$runtimeHash;scenarioSha256=$scenarioHash.ToLowerInvariant();sessionModuleSha256=$moduleHash.ToLowerInvariant();
        recipientCount=$RecipientProfiles.Count;reintroduction=[bool]$Reintroduce;connectionCycle=[bool]$ConnectionCycle;
        connectionCycleQualified=($passed -and $ConnectionCycle);periodicLifecycleQualified=$false;
        sessionCloseFailed=$closeFailed;steps=$steps.ToArray();releaseQualified=$false}|ConvertTo-Json -Depth 12|
        Set-Content -LiteralPath (Join-Path $run 'receipt.json') -Encoding utf8
    Write-Host ([pscustomobject]@{passed=$passed;commands=$steps.Count}|ConvertTo-Json -Compress)
    if($closeFailed){throw 'Repair session did not close normally.'}
}
