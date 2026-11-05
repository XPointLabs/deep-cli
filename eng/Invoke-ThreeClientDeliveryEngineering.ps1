[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$BootstrapDirectory,
    [Parameter(Mandatory)][string]$RegistryOrigin,
    [Parameter(Mandatory)][string]$RunDirectory,
    [string]$ExecutablePath,
    [ValidateRange(1,4)][int]$Rounds=4,
    [ValidateRange(0,10000)][int]$ExpectedCursor=60,
    [ValidateRange(0,31)][int]$GroupRevision=11,
    [ValidateRange(1000,330000)][int]$SampleBudgetMilliseconds=120000,
    [ValidateRange(1,32)][int]$MaximumReceivePages=16,
    [ValidateRange(100,1000)][int]$EmptyPollIntervalMilliseconds=100,
    [ValidatePattern('^[a-z][a-z0-9-]{0,31}$')][string]$AliceProfile='cli-latency-a2',
    [ValidatePattern('^[a-z][a-z0-9-]{0,31}$')][string]$BobProfile='cli-gsr4-bob',
    [ValidatePattern('^[a-z][a-z0-9-]{0,31}$')][string]$CarolProfile='cli-latency-c'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$run=[IO.Path]::GetFullPath($RunDirectory)
$artifactRoot=[IO.Path]::GetFullPath((Join-Path $repo 'artifacts'))+[IO.Path]::DirectorySeparatorChar
$profiles=@($AliceProfile,$BobProfile,$CarolProfile)
if(-not $run.StartsWith($artifactRoot,[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $run) -or
    @($profiles|Select-Object -Unique).Count -ne 3){throw 'Fresh artifact directory and distinct retained profiles required.'}
$exe=Join-Path $repo 'src/Deep.Cli/bin/Release/net10.0-windows/deep.exe'
if($PSBoundParameters.ContainsKey('ExecutablePath')){
    $exe=[IO.Path]::GetFullPath($ExecutablePath)
    if(-not $exe.StartsWith($artifactRoot,[StringComparison]::OrdinalIgnoreCase) -or [IO.Path]::GetFileName($exe) -cne 'deep.exe' -or
        -not (Test-Path -LiteralPath $exe -PathType Leaf)){throw 'Archived repo-owned deep.exe required.'}
}
foreach($path in @($run,$BootstrapDirectory,$exe)){
    for($cursor=[IO.Path]::GetFullPath($path);$cursor;$cursor=[IO.Path]::GetDirectoryName($cursor)){
        if((Test-Path -LiteralPath $cursor) -and ((Get-Item -LiteralPath $cursor).Attributes -band [IO.FileAttributes]::ReparsePoint)){throw 'Reparse path rejected.'}
    }
}
Import-Module (Join-Path $PSScriptRoot 'GsrCohort.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'CliSession.psm1') -Force
$population=@(New-GsrEngineeringPopulation -Rounds $Rounds -Cursor $ExpectedCursor)
$maximumReceiveRequests=[int][Math]::Ceiling($SampleBudgetMilliseconds/$EmptyPollIntervalMilliseconds)+$MaximumReceivePages+1
# Each receive request emits one command admission; each authored sample adds
# sender admission plus two outbox/two Store/two visible events. Bound all
# two ordinary history reads, preflight/round validation and role terminals.
$eventBudget=[long]$population.Count*(2L*$maximumReceiveRequests+9L)+32L+6L*$Rounds
if($eventBudget -gt 100000){throw 'Declared engineering population exceeds the diagnostic event budget.'}
$network=(Get-Content -LiteralPath (Join-Path $BootstrapDirectory 'deep-dev.json') -Raw|ConvertFrom-Json).networkIdHex.ToLowerInvariant()
if($network -cnotmatch '^[0-9a-f]{32}$'){throw 'Explicit public network binding required.'}
$networkArgs=@('--bootstrap',$BootstrapDirectory,'--registry',$RegistryOrigin)
$inputPaths=@($PSCommandPath,(Join-Path $PSScriptRoot 'CliSession.psm1'),(Join-Path $PSScriptRoot 'DeliveryMeasurement.cs'),(Join-Path $PSScriptRoot 'GsrCohort.psm1'))
$inputHashes=@($inputPaths|ForEach-Object {(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash})
function Runtime-Fingerprint {
    $root=[IO.Path]::GetDirectoryName($exe)+[IO.Path]::DirectorySeparatorChar
    $entries=@(Get-ChildItem -LiteralPath $root -Recurse -Force)
    if(@($entries|Where-Object {$_.Attributes -band [IO.FileAttributes]::ReparsePoint}).Count){throw 'Runtime links rejected.'}
    $files=@($entries|Where-Object {-not $_.PSIsContainer}|Sort-Object FullName -CaseSensitive)
    if($files.Count -lt 3 -or $files.Count -gt 2048){throw 'Runtime inventory bound.'}
    $rows=@($files|ForEach-Object {$_.FullName.Substring($root.Length).Replace('\','/')+'|'+(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash})
    [Convert]::ToHexStringLower([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes(($rows -join "`n"))))
}
$runtimeHash=Runtime-Fingerprint
$script:failurePhase='None';$script:failureCode='None';$script:activePhase='input-binding'
function Record-Failure([string]$code,[string]$phase){
    if($script:failureCode -ceq 'None'){$script:failureCode=$code;$script:failurePhase=$phase}
}
function Require-Inputs {
    $script:activePhase='input-binding'
    for($i=0;$i -lt $inputPaths.Count;$i++){if((Get-FileHash -LiteralPath $inputPaths[$i] -Algorithm SHA256).Hash -cne $inputHashes[$i]){Record-Failure 'InputChanged' 'input-binding';throw 'Scenario inputs changed.'}}
    if((Runtime-Fingerprint) -cne $runtimeHash){Record-Failure 'InputChanged' 'input-binding';throw 'Runtime changed.'}
}
[void][IO.Directory]::CreateDirectory($run)
foreach($path in $inputPaths){Copy-Item -LiteralPath $path -Destination (Join-Path $run ([IO.Path]::GetFileName($path)))}
for($i=0;$i -lt $inputPaths.Count;$i++){
    if((Get-FileHash -LiteralPath (Join-Path $run ([IO.Path]::GetFileName($inputPaths[$i]))) -Algorithm SHA256).Hash -cne $inputHashes[$i]){throw 'Scenario archive differs.'}
}
Compress-Archive -LiteralPath ([IO.Path]::GetDirectoryName($exe)) -DestinationPath (Join-Path $run 'runtime.zip') -CompressionLevel Fastest
Require-Inputs
# The population is durable before any client submission. It contains roles and
# ordinals only, never identifiers, descriptors or message text.
$population|ConvertTo-Json -Depth 4|Set-Content -LiteralPath (Join-Path $run 'population.json') -Encoding utf8
$controller=New-DeliveryEventController -MaximumEvents ([int]$eventBudget)
$sessions=@{};$pending=@{};$steps=[Collections.Generic.List[object]]::new();$pairs=@{}
$script:commandFailed=$false;$cohortValidated=$false;$closeFailed=$false;$inputsUnchanged=$true;$started=[DateTime]::UtcNow
function Require([bool]$ok,[string]$message,[string]$code='AssertionRejected'){
    if(-not $ok){Record-Failure $code $script:activePhase;throw $message}
}
function Read-RecoveryWork($result,[bool]$required){
    if($result.PSObject.Properties.Name -notcontains 'recoveryWork'){
        if($required){throw [IO.InvalidDataException]::new('Required recovery counters are absent.')}
        return $null
    }
    $work=$result.recoveryWork
    if($null -eq $work){throw [IO.InvalidDataException]::new('Closed recovery counters required.')}
    $names=@($work.PSObject.Properties.Name)
    if($names.Count -ne 3){throw [IO.InvalidDataException]::new('Closed recovery counters required.')}
    foreach($name in @('storeResumes','mailboxResumes','leaseWaits')){
        if($names -cnotcontains $name -or ($work.$name -isnot [int] -and $work.$name -isnot [long]) -or $work.$name -lt 0){
            throw [IO.InvalidDataException]::new('Unsigned recovery counters required.')
        }
    }
    return [pscustomobject]@{storeResumes=[long]$work.storeResumes;mailboxResumes=[long]$work.mailboxResumes;leaseWaits=[long]$work.leaseWaits}
}
function Pair-Key([int]$left,[int]$right){(@($left,$right)|Sort-Object)-join ':'}
function Require-CorrelatedHistory($result,[ulong]$sequence,[string]$text){
    $matched=@($result.items|Where-Object {$_.text -is [string] -and $_.text -ceq $text -and
        ($_.sequence -is [int] -or $_.sequence -is [long] -or $_.sequence -is [ulong]) -and $_.sequence -eq $sequence})
    Require ($result.status -is [string] -and $result.status -ceq 'ok' -and $matched.Count -eq 1 -and
        $matched[0].local -is [bool] -and -not $matched[0].local) 'Ordinary history must return exactly the correlated remote message.'
}
function Read-ClosedFailure($result){
    # Copy only code-owned closed fields; never serialize the response/exception.
    $codes=@('business-operation-failed','cancelled','invalid-arguments','platform-unavailable','protected-state-rejected','storage-unavailable-or-busy','storage-access-denied','operation-failed','account-missing')
    $closed=[ordered]@{code='Unclassified'}
    if($result.PSObject.Properties.Name -contains 'code' -and $result.code -cin $codes){$closed.code=$result.code}
    if($result.PSObject.Properties.Name -notcontains 'diagnostic' -or $null -eq $result.diagnostic){return [pscustomobject]$closed}
    $diagnostic=$result.diagnostic
    $phases=@('LocalRead','Bootstrap','ContactRouteVerification','ContactRouteMaintenance','ContactRouteReintroduction','NetworkVerify','NetworkRefresh','NetworkMaintain','NetworkPublish','ContactRequest','ContactStop','ContactAccept','MailboxSync','TextQueue','TextSend','AttachmentPrepare','AttachmentSend','AttachmentQueue','AttachmentDownload','GroupWork')
    $categories=@('OutcomeUnknown','ContactRetryExpired','Timeout','ProtectedState','HttpFailure','DirectoryRateLimited','DirectoryUnavailable','IoFailure','InvalidState','Cancelled','OperationRejected','ProtocolRejected','InvalidInput','Other','IngressRetryableBeforeForward','IngressRejectedBeforeForward')
    $checks=@('Unclassified','EndpointPairNetworkChanged','EndpointPairDirectoryExpired','EndpointPairDirectoryFloorAdvanced','EndpointPairDirectoryExpiredBeforeHandoff','IngressMalformedFrame','IngressWrongOrigin','IngressSaturated','IngressUnavailable','PreKeysUnavailable','ClaimExpired','ClaimStaleBundle','ClaimRateLimited','ClaimConflict','ClaimOutcomeUnknown')
    $checks+=@('Expired','RateLimited','StaleView','Conflict','OutcomeUnknown','SizeFailure','RecordTooLarge'|ForEach-Object {'GroupControl'+$_})
    $checks+=@('Lifecycle','Network','Membership','Epoch','Issuer','Generation','IssuerWindow','RouteExpiry','Lifetime','Signature'|ForEach-Object {'Grant'+$_})
    $checks+=@('GrantHorizon','GrantOverlap','RequestInterval','GrantStart','ResponseDeadline','IssuedBeforeRequest','IssuedAfterRequest','IssuedAfterCurrentUpper'|ForEach-Object {'RetainedRead'+$_})
    foreach($artifact in @('XNA1','XNV1','XNH1','ADH1','DeviceCertificate','DCA1','PMT2','XRA1','PMS2','XRC1','XSS1','XIR1V2','XRR1','ThresholdAuthoring','ResolveRequest')){
        foreach($reason in @('InvalidInterval','NotBefore','Expiry')){$checks+='RouteTime'+$artifact+$reason}
    }
    function Location($value){
        $location=[ordered]@{method='Unavailable';il=-1}
        if($null -ne $value -and $value.PSObject.Properties.Name -contains 'method' -and
            $value.method -is [string] -and $value.method.Length -le 240 -and
            $value.method -cmatch '\ADeep\.(Client\.Shared|Protocol)\.(?:[A-Za-z0-9_.+<>`]|g__[A-Za-z0-9_]+\|[0-9]+(?:_[0-9]+)?(?=>|\.|\z))+\z'){$location.method=$value.method}
        if($null -ne $value -and $value.PSObject.Properties.Name -contains 'il' -and
            ($value.il -is [int] -or $value.il -is [long]) -and $value.il -ge -1 -and $value.il -le 1048575){$location.il=$value.il}
        [pscustomobject]$location
    }
    $phase='Unclassified'
    if($diagnostic.PSObject.Properties.Name -contains 'phase' -and $diagnostic.phase -cin $phases){$phase=$diagnostic.phase}
    $causes=@(if($diagnostic.PSObject.Properties.Name -contains 'causes'){
        foreach($cause in @($diagnostic.causes|Select-Object -First 8)){
            if($null -eq $cause){continue}
            $location=Location $cause;$category='Other';$check='Unclassified'
            if($cause.PSObject.Properties.Name -contains 'category' -and $cause.category -cin $categories){$category=$cause.category}
            if($cause.PSObject.Properties.Name -contains 'check' -and $cause.check -cin $checks){$check=$cause.check}
            $trail=@(if($cause.PSObject.Properties.Name -contains 'trail'){foreach($frame in @($cause.trail|Select-Object -First 8)){Location $frame}})
            [pscustomobject]@{category=$category;check=$check;method=$location.method;il=$location.il;trail=$trail}
        }
    })
    $closed['diagnostic']=[pscustomobject]@{phase=$phase;causes=$causes}
    [pscustomobject]$closed
}
function Start-Command([int]$role,[string]$phase,[string[]]$arguments){
    $script:activePhase=$phase
    Require (-not $pending.ContainsKey($role)) 'One outstanding command per role required.'
    try{$handle=Start-CliSessionCommand $sessions[$role] ($arguments+@('--profile',$profiles[$role-1],'--network',$network))}
    catch{Record-Failure 'CommandSubmissionRejected' $phase;throw}
    $pending[$role]=[pscustomobject]@{Handle=$handle;Phase=$phase;Watch=[Diagnostics.Stopwatch]::StartNew()}
    return $handle
}
function Complete-Command([int]$role,[int]$budget){
    $item=$pending[$role]
    $script:activePhase=$item.Phase
    $waiting=-not $item.Handle.Read.IsCompleted;$wait=[Diagnostics.Stopwatch]::StartNew()
    try{
        $response=Complete-CliSessionCommand $sessions[$role] $item.Handle $budget
        $result=$response.Result
        $row=[ordered]@{role=$role;phase=$item.Phase;commandOrdinal=$response.CommandOrdinal;exit=$response.ExitCode;commandMilliseconds=$item.Watch.ElapsedMilliseconds;cpuMilliseconds=$response.ProcessorMilliseconds}
        foreach($field in @('networkWork','runtimeWork','persistenceWork','nativeStorageWork','storageWork','protectionWork','sessionWork')){
            if($result.PSObject.Properties.Name -contains $field){$row[$field]=$result.$field}
        }
        if($response.ExitCode -ne 0){
            $row['failure']=Read-ClosedFailure $result
            Record-Failure $(if($response.ExitCode -eq 130){'CommandTimeout'}else{'CommandError'}) $item.Phase
            $steps.Add([pscustomobject]$row);$script:commandFailed=$true;return $null
        }
        if($item.Phase -ceq 'retained-route-intervals'){
            $row['retainedRouteHealth']=[pscustomobject]@{
                AdvertisementIntervalCoversNow=$result.health.AdvertisementIntervalCoversNow
                UpdateIntervalCoversNow=$result.health.UpdateIntervalCoversNow
                RouteFaultRetained=$result.health.RouteFaultRetained
            }
        }
        $recovery=Read-RecoveryWork $result ($item.Phase -cne 'retained-account')
        if($result.PSObject.Properties.Name -contains 'nativeStorageWork' -and $result.nativeStorageWork.rejected){
            $steps.Add([pscustomobject]$row);Record-Failure 'NativeCounterShapeRejected' $item.Phase;$script:commandFailed=$true;return $null
        }
        $recovered=$null -ne $recovery -and ($recovery.storeResumes -ne 0 -or $recovery.mailboxResumes -ne 0 -or $recovery.leaseWaits -ne 0)
        if($null -ne $recovery){$row['recoveryWork']=$recovery}
        $steps.Add([pscustomobject]$row)
        if($recovered){Record-Failure 'RecoveryDetected' $item.Phase;$script:commandFailed=$true;return $null}
        return $result
    }catch{
        $script:commandFailed=$true
        $code=if($_.Exception -is [IO.InvalidDataException]){'RecoveryShapeRejected'}elseif($waiting -and $wait.ElapsedMilliseconds -ge $budget){'CommandTimeout'}else{'CommandTransportRejected'}
        Record-Failure $code $item.Phase
        $steps.Add([pscustomobject]@{role=$role;phase=$item.Phase;commandOrdinal=$item.Handle.CommandOrdinal;exit=$(if($code -ceq 'CommandTimeout'){130}else{1});failureCode=$code;commandMilliseconds=$item.Watch.ElapsedMilliseconds})
        return $null
    }finally{$pending.Remove($role)}
}
function Call([int]$role,[string]$phase,[string[]]$arguments){
    [void](Start-Command $role $phase $arguments)
    $result=Complete-Command $role 330000
    Require (-not $script:commandFailed) 'Preflight or validation command failed; no repair or retry.'
    return $result
}
function Check-Histories([int]$completedRound){
    foreach($role in 1..3){
        $head=Select-GsrGroupHead (Call $role 'cohort-head' @('group','list')).items ('GSR CLI QA '+$GroupRevision)
        Require ($head.Group -ceq $group -and $head.State -ceq 'Active' -and $head.Epoch -eq 2 -and $head.Members -eq 3 -and
            $head.LocalMessageCommands -eq ($ExpectedCursor+$completedRound)) 'Retained group cursor/head mismatch; no new authoring permitted.' 'CohortRejected'
        $history=Call $role 'semantic-validation' @('group','messages','--group',$group)
        Require (@($history.items).Count -eq 3*($ExpectedCursor+$completedRound) -and @($history.items|Where-Object local).Count -eq ($ExpectedCursor+$completedRound)) 'Retained native history differs.' 'CohortRejected'
        foreach($sample in @($population|Where-Object {$_.Round -le $completedRound})){
            $text='CLI engineering sequence '+$sample.Sequence+' role '+$sample.SenderRole
            $copies=@($history.items|Where-Object {$_.text -ceq $text -and $_.sequence -eq $sample.Sequence})
            Require ($copies.Count -eq 1 -and [bool]$copies[0].local -eq ($role -eq $sample.SenderRole)) 'Exact authored semantic copy missing or duplicated.'
        }
    }
}
try{
    # Arm every independent stderr reader before any command is submitted.
    $script:activePhase='session-open'
    foreach($role in 1..3){$sessions[$role]=New-CliSession $exe $profiles[$role-1] $network $BootstrapDirectory $RegistryOrigin -DeliveryController $controller -ControllerRole $role}
    $contacts=@{};$group=$null
    foreach($role in 1..3){
        Require ([bool](Call $role 'retained-account' @('account','status')).accountPresent) 'Existing retained account required.' 'CohortRejected'
        $contacts[$role]=(Call $role 'retained-consent' @('contact','list')).contacts
        $head=Select-GsrGroupHead (Call $role 'retained-head' @('group','list')).items ('GSR CLI QA '+$GroupRevision)
        if($null -eq $group){$group=$head.Group}else{Require ($head.Group -ceq $group) 'Profiles disagree on exact group.' 'CohortRejected'}
    }
    Check-Histories 0
    foreach($left in 1..2){foreach($right in ($left+1)..3){
        $script:activePhase='retained-consent'
        $conversation=Select-GsrRetainedConversation $contacts[$left] $contacts[$right]
        Require ($null -ne $conversation) 'Existing mutual consent required; no contact setup or repair.' 'CohortRejected'
        $pairs[(Pair-Key $left $right)]=$conversation
        foreach($role in @($left,$right)){
            # Original XUR health is historical information. The strict Shared
            # verifier reads actual current L and retains all live owner guards.
            [void](Call $role 'retained-route-intervals' (@('contact','route-health','--conversation',$conversation)+$networkArgs))
            $verified=Call $role 'current-route-verification' (@('contact','route-verify','--conversation',$conversation)+$networkArgs)
            Require ($verified.routeVerified -ceq $true) 'Current route verification required; no repair.' 'RouteExpiredOrFaulted'
        }
    }}
    $cohortValidated=$true
    foreach($sample in $population){
        if($script:commandFailed){break}
        Require-Inputs
        $sender=$sample.SenderRole;$recipients=@(1..3|Where-Object {$_ -ne $sender});$peer=$recipients[0]
        $text='CLI engineering sequence '+$sample.Sequence+' role '+$sender
        $sample.Submitted=$true;$sample.Outcome='SubmissionUncertain'
        $watch=[Diagnostics.Stopwatch]::StartNew()
        $handle=Start-Command $sender 'send' (@('group','send','--group',$group,'--conversation',$pairs[(Pair-Key $sender $peer)],'--text',$text)+$networkArgs)
        $sample.Submitted=$true;$sample.CommandOrdinal=$handle.CommandOrdinal;$sample.Outcome='Incomplete'
        [pscustomobject]@{round=$sample.Round;senderRole=$sender;sequence=$sample.Sequence;commandOrdinal=$sample.CommandOrdinal}|
            ConvertTo-Json -Compress|Add-Content -LiteralPath (Join-Path $run 'submissions.jsonl') -Encoding utf8
        $pages=@{};$more=@{};$requests=@{};$nextEmptyPoll=@{};$historyRead=@{}
        foreach($role in $recipients){$historyRead[$role]=$false;$pages[$role]=0;$requests[$role]=1;$nextEmptyPoll[$role]=0L;$more[$role]=$false;[void](Start-Command $role 'receive-ack' (@('mailbox','sync')+$networkArgs))}
        # Explicit bounded engineering scheduling of the existing API, not a
        # product background scheduler, business retry or history-based clock.
        while($watch.ElapsedMilliseconds -lt $SampleBudgetMilliseconds){
            if($controller.Rejected){
                Record-Failure 'MeasurementStreamRejected' 'receive-ack';$sample.Outcome='MeasurementRejected';$script:commandFailed=$true;break
            }
            foreach($role in @($pending.Keys)){
                if($pending[$role].Handle.Read.IsCompleted){
                    $phase=$pending[$role].Phase;$ordinal=$pending[$role].Handle.CommandOrdinal
                    $result=Complete-Command $role ([Math]::Max(1,$SampleBudgetMilliseconds-[int]$watch.ElapsedMilliseconds))
                    if($phase -ceq 'history-read' -and $null -ne $result){
                        Require-CorrelatedHistory $result $sample.Sequence $text
                        $controller.RecordHistoryRead($sender,$sample.CommandOrdinal,$role,$ordinal)
                        $historyRead[$role]=$true
                    }elseif($role -ne $sender -and $null -ne $result){
                        Require ($result.processed -ge 0 -and $result.processed -eq $result.tombstones) 'Receive/ACK result incomplete.'
                        Require (-not $result.hasMore -or $result.processed -gt 0) 'Non-final mailbox page made no durable progress.'
                        $more[$role]=[bool]$result.hasMore
                        if($result.processed -eq 0){$nextEmptyPoll[$role]=$watch.ElapsedMilliseconds+$EmptyPollIntervalMilliseconds}
                        else{$pages[$role]++;$nextEmptyPoll[$role]=$watch.ElapsedMilliseconds}
                    }elseif($role -eq $sender -and $null -ne $result){
                        Require ($result.completed -eq 2) 'Fresh send must contain exactly two current target items.'
                    }
                }
            }
            if($script:commandFailed){$sample.Outcome='CommandOrRecoveryFailure';break}
            foreach($role in $recipients){
                if(-not $pending.ContainsKey($role) -and -not $historyRead[$role] -and $controller.HasRecipientObservation($sender,$sample.CommandOrdinal,$role)){
                    # Ordinary same-session read: Sync has returned, including ACK.
                    # Correlate the actual result in RAM; never use ACK as its clock.
                    [void](Start-Command $role 'history-read' @('group','messages','--group',$group))
                    continue
                }
                if(-not $pending.ContainsKey($role) -and $watch.ElapsedMilliseconds -ge $nextEmptyPoll[$role] -and
                    ($more[$role] -or -not $controller.HasRecipientObservation($sender,$sample.CommandOrdinal,$role))){
                    if($pages[$role] -ge $MaximumReceivePages -or $requests[$role] -ge $maximumReceiveRequests){
                        $sample.Outcome='ReceiveBound';Record-Failure 'ReceiveBound' 'receive-ack';$script:commandFailed=$true;break
                    }
                    $requests[$role]++;[void](Start-Command $role 'receive-ack' (@('mailbox','sync')+$networkArgs))
                }
            }
            if($script:commandFailed){break}
            if(-not $pending.Count -and @($recipients|Where-Object {-not $historyRead[$_]}).Count -eq 0){$sample.Outcome='Success';break}
            Start-Sleep -Milliseconds 25
        }
        if($sample.Outcome -ne 'Success'){
            if(-not $script:commandFailed){$sample.Outcome='Deadline';Record-Failure 'CommandTimeout' 'sample-window'}
            $script:commandFailed=$true;break
        }
        if($sender -eq 3){Check-Histories $sample.Round}
    }
}catch{
    $code=if($script:activePhase -ceq 'input-binding'){'InputChanged'}elseif($script:activePhase -in @('retained-account','retained-consent','retained-head','cohort-head')){'CohortRejected'}else{'DriverAssertionRejected'}
    Record-Failure $code $script:activePhase;$script:commandFailed=$true
}
finally{
    # Never restart a failed host or reissue group send. Close retains the
    # original Shared-owned operation; interrupted streams cannot qualify.
    foreach($role in @($sessions.Keys)){try{Close-CliSession $sessions[$role]}catch{Record-Failure 'StreamClosureRejected' 'session-close';$closeFailed=$true}}
    try{Require-Inputs}catch{$inputsUnchanged=$false}
    $samples=[Collections.Generic.List[object]]::new();$roleStats=[Collections.Generic.List[object]]::new();$pairStats=[Collections.Generic.List[object]]::new()
    foreach($sample in $population){
        $recipients=[int[]]@(1..3|Where-Object {$_ -ne $sample.SenderRole})
        $metric=$controller.Sample($sample.SenderRole,$sample.CommandOrdinal,$recipients)
        $observed=$metric.Complete -and -not $closeFailed -and $inputsUnchanged
        $finite=$sample.Outcome -ceq 'Success' -and $metric.Complete -and -not $closeFailed -and $inputsUnchanged
        if(-not $finite -and $sample.Outcome -ceq 'Success'){Record-Failure 'MissingMeasurementObservation' 'measurement-finalization'}
        $recipientSamples=@(foreach($recipient in $recipients){
            $readMilliseconds=$controller.HistoryReadMilliseconds($sample.SenderRole,$sample.CommandOrdinal,$recipients,$recipient)
            $readFinite=$finite -and [double]::IsFinite($readMilliseconds)
            [pscustomobject]@{recipientRole=$recipient;milliseconds=$(if($finite){$controller.RecipientMilliseconds($sample.SenderRole,$sample.CommandOrdinal,$recipients,$recipient)}else{$null});positiveInfinity=(-not $finite);historyReadResultMilliseconds=$(if($readFinite){$readMilliseconds}else{$null});historyReadPositiveInfinity=(-not $readFinite)}
        })
        $readFinite=$finite -and @($recipientSamples|Where-Object historyReadPositiveInfinity).Count -eq 0
        if($finite -and -not $readFinite){Record-Failure 'MissingMeasurementObservation' 'history-read-finalization'}
        $firstRead=$(if($readFinite){($recipientSamples.historyReadResultMilliseconds|Measure-Object -Minimum).Minimum}else{$null})
        $allReads=$(if($readFinite){($recipientSamples.historyReadResultMilliseconds|Measure-Object -Maximum).Maximum}else{$null})
        $observedBlock=[pscustomobject]@{durableVisibleObserved=$observed;firstRecipientMilliseconds=$(if($observed){$metric.FirstRecipientMilliseconds}else{$null});allRecipientsMilliseconds=$(if($observed){$metric.AllRecipientsMilliseconds}else{$null})}
        $samples.Add([pscustomobject]@{round=$sample.Round;senderRole=$sample.SenderRole;sequence=$sample.Sequence;commandOrdinal=$sample.CommandOrdinal;submitted=$sample.Submitted;outcome=$sample.Outcome;positiveInfinity=(-not $finite);observed=$observedBlock;firstRecipientMilliseconds=$(if($finite){$metric.FirstRecipientMilliseconds}else{$null});allRecipientsMilliseconds=$(if($finite){$metric.AllRecipientsMilliseconds}else{$null});historyReadPositiveInfinity=(-not $readFinite);firstHistoryReadResultMilliseconds=$firstRead;allHistoryReadResultMilliseconds=$allReads;nativeOutboxMilliseconds=$(if($finite){$metric.NativeOutboxMilliseconds}else{$null});allStoresMilliseconds=$(if($finite){$metric.AllStoresMilliseconds}else{$null});recipients=$recipientSamples})
    }
    foreach($role in 1..3){
        $values=[double[]]@($samples|Where-Object {$_.senderRole -eq $role}|ForEach-Object {if($_.positiveInfinity){[double]::PositiveInfinity}else{[double]$_.allRecipientsMilliseconds}})
        $p95=[Deep.Cli.Measurement.DeliveryEventController]::NearestRank($values,.95)
        $readValues=[double[]]@($samples|Where-Object {$_.senderRole -eq $role}|ForEach-Object {if($_.historyReadPositiveInfinity){[double]::PositiveInfinity}else{[double]$_.allHistoryReadResultMilliseconds}})
        $readP95=[Deep.Cli.Measurement.DeliveryEventController]::NearestRank($readValues,.95)
        $roleStats.Add([pscustomobject]@{senderRole=$role;population=$values.Count;p95Milliseconds=$(if([double]::IsFinite($p95)){$p95}else{$null});positiveInfinity=[double]::IsPositiveInfinity($p95);historyReadP95Milliseconds=$(if([double]::IsFinite($readP95)){$readP95}else{$null});historyReadPositiveInfinity=[double]::IsPositiveInfinity($readP95)})
        foreach($recipient in @(1..3|Where-Object {$_ -ne $role})){
            $values=[double[]]@($samples|Where-Object {$_.senderRole -eq $role}|ForEach-Object {
                $pair=@($_.recipients|Where-Object {$_.recipientRole -eq $recipient})[0]
                if($pair.positiveInfinity){[double]::PositiveInfinity}else{[double]$pair.milliseconds}
            })
            $p95=[Deep.Cli.Measurement.DeliveryEventController]::NearestRank($values,.95)
            $readValues=[double[]]@($samples|Where-Object {$_.senderRole -eq $role}|ForEach-Object {
                $pair=@($_.recipients|Where-Object {$_.recipientRole -eq $recipient})[0]
                if($pair.historyReadPositiveInfinity){[double]::PositiveInfinity}else{[double]$pair.historyReadResultMilliseconds}
            })
            $readP95=[Deep.Cli.Measurement.DeliveryEventController]::NearestRank($readValues,.95)
            $pairStats.Add([pscustomobject]@{senderRole=$role;recipientRole=$recipient;population=$values.Count;p95Milliseconds=$(if([double]::IsFinite($p95)){$p95}else{$null});positiveInfinity=[double]::IsPositiveInfinity($p95);historyReadP95Milliseconds=$(if([double]::IsFinite($readP95)){$readP95}else{$null});historyReadPositiveInfinity=[double]::IsPositiveInfinity($readP95)})
        }
    }
    $passed=$cohortValidated -and -not $script:commandFailed -and -not $closeFailed -and $inputsUnchanged -and -not $controller.Rejected -and @($samples|Where-Object {$_.positiveInfinity -or $_.historyReadPositiveInfinity}).Count -eq 0
    [ordered]@{schema='deep.cli.delivery-engineering.v1';passed=$passed;failurePhase=$script:failurePhase;failureCode=$script:failureCode;startedUtc=$started;finishedUtc=[DateTime]::UtcNow;plannedSamples=$population.Count;rounds=$Rounds;startingCursor=$ExpectedCursor;expectedFinalCursor=$ExpectedCursor+$Rounds;groupRevision=$GroupRevision;cohortValidated=$cohortValidated;sampleBudgetMilliseconds=$SampleBudgetMilliseconds;emptyPollIntervalMilliseconds=$EmptyPollIntervalMilliseconds;maximumNonemptyReceivePages=$MaximumReceivePages;maximumReceiveRequestsPerSample=$maximumReceiveRequests;diagnosticEventBudget=$eventBudget;streams=$controller.StreamSummary();inputHashes=$inputHashes;runtimeSha256=$runtimeHash;inputsUnchanged=$inputsUnchanged;sessionCloseFailed=$closeFailed;controllerRejected=$controller.Rejected;samples=$samples.ToArray();perRole=$roleStats.ToArray();perDirectedPair=$pairStats.ToArray();steps=$steps.ToArray();tombstoneAckTimingObserved=$false;applicationReceiptTimingObserved=$false;productBackgroundQualified=$false;warmLatencyQualified=$false;releaseQualified=$false}|ConvertTo-Json -Depth 14|Set-Content -LiteralPath (Join-Path $run 'receipt.json') -Encoding utf8
    Write-Host ([pscustomobject]@{passed=$passed;plannedSamples=$population.Count;submittedSamples=@($population|Where-Object Submitted).Count;finiteSamples=@($samples|Where-Object {-not $_.positiveInfinity}).Count}|ConvertTo-Json -Compress)
}
if(-not $passed){throw 'Engineering run failed; retain original submitted work and receipt. No automatic restart or reauthoring.'}
