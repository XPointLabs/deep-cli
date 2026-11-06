[CmdletBinding()]
param(
 [Parameter(Mandatory)][string]$ExecutablePath,
 [Parameter(Mandatory)][string]$BootstrapDirectory,
 [Parameter(Mandatory)][string]$RegistryOrigin,
 [Parameter(Mandatory)][string]$RunDirectory,
 [ValidateRange(1,8)][int]$DirectRounds=4,
 [ValidateRange(1,16)][int]$GroupRounds=8,
 [ValidateRange(1000,330000)][int]$SampleBudgetMilliseconds=120000,
 [ValidateRange(0,2)][int]$RecoveryAttempts=1,
 [ValidateRange(0,900)][int]$IdleSeconds=180,
 [ValidateRange(60,1800)][int]$ReadinessBudgetSeconds=1800
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$root=[IO.Path]::GetFullPath((Join-Path $repo 'artifacts'))+[IO.Path]::DirectorySeparatorChar
$exe=[IO.Path]::GetFullPath($ExecutablePath);$run=[IO.Path]::GetFullPath($RunDirectory)
if(-not $run.StartsWith($root,[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $run) -or
 -not $exe.StartsWith($root,[StringComparison]::OrdinalIgnoreCase) -or [IO.Path]::GetFileName($exe) -cne 'deep.exe') {throw 'Fresh owned artifacts and archived runtime required.'}
foreach($path in @($run,$exe,$BootstrapDirectory)) {for($cursor=[IO.Path]::GetFullPath($path);$cursor;$cursor=[IO.Path]::GetDirectoryName($cursor)) {
 if((Test-Path -LiteralPath $cursor) -and ((Get-Item -LiteralPath $cursor).Attributes -band [IO.FileAttributes]::ReparsePoint)){throw 'Linked input rejected.'}
}}
$profiles=@('cli-latency-a2','cli-gsr4-bob','cli-latency-c')
$network=(Get-Content -LiteralPath (Join-Path $BootstrapDirectory 'deep-dev.json') -Raw|ConvertFrom-Json).networkIdHex.ToLowerInvariant()
if($network -cnotmatch '^[0-9a-f]{32}$'){throw 'Exact public network required.'}
$net=@('--bootstrap',$BootstrapDirectory,'--registry',$RegistryOrigin)
$inputs=@($PSCommandPath,(Join-Path $PSScriptRoot 'CliSession.psm1'),(Join-Path $PSScriptRoot 'DeliveryMeasurement.cs'),(Join-Path $PSScriptRoot 'GsrCohort.psm1'))
$sourceHashes=@($inputs|ForEach-Object {(Get-FileHash -LiteralPath $_).Hash})
$runtimeRoot=[IO.Path]::GetDirectoryName($exe)
$runtimeFiles=@(Get-ChildItem -LiteralPath $runtimeRoot -File -Recurse|Sort-Object FullName)
if($runtimeFiles.Count -lt 3 -or $runtimeFiles.Count -gt 2048){throw 'Runtime inventory rejected.'}
$runtimeHashes=@($runtimeFiles|ForEach-Object {(Get-FileHash -LiteralPath $_.FullName).Hash})
function Inputs {for($i=0;$i -lt $inputs.Count;$i++){if((Get-FileHash -LiteralPath $inputs[$i]).Hash -cne $sourceHashes[$i]){throw 'Frozen source changed.'}}
 if(@(Get-ChildItem -LiteralPath $runtimeRoot -Recurse -Force|Where-Object {$_.Attributes -band [IO.FileAttributes]::ReparsePoint}).Count -ne 0 -or @(Get-ChildItem -LiteralPath $runtimeRoot -File -Recurse).Count -ne $runtimeFiles.Count){throw 'Frozen runtime inventory changed.'}
 for($i=0;$i -lt $runtimeFiles.Count;$i++){if((Get-FileHash -LiteralPath $runtimeFiles[$i].FullName).Hash -cne $runtimeHashes[$i]){throw 'Frozen runtime changed.'}}}
[void][IO.Directory]::CreateDirectory($run)
foreach($path in $inputs){Copy-Item -LiteralPath $path -Destination $run}
Import-Module (Join-Path $PSScriptRoot 'CliSession.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'GsrCohort.psm1') -Force
# The denominator and original asymmetric cursors exist before opening a host.
# B64 is retained. No balancing message or replacement command is authored.
$population=[Collections.Generic.List[object]]::new()
foreach($kind in @('Direct','Group')){
 $rounds=if($kind -ceq 'Direct'){$DirectRounds}else{$GroupRounds}
 foreach($round in 0..$rounds){foreach($sender in 1..3){
  $recipients=if($kind -ceq 'Direct'){@(1..3|Where-Object {$_ -ne $sender})}else{@(0)}
  foreach($recipient in $recipients){$population.Add([pscustomobject]@{kind=$kind;round=$round;warmup=($round -eq 0);sender=$sender;recipient=$recipient;sequence=$(if($kind -ceq 'Group'){@(63,64,63)[$sender-1]+$round+1}else{$round});submitted=$false;command=0L;dispatch=0L;outcome='NotSubmitted';recovery=$false;recovered=$false;ack=$false;readWithoutOwnedAckPage=$false;duplicatesChecked=$false;reads=@();externalReadMilliseconds=@()})}
 }}
}
$population.ToArray()|ConvertTo-Json -Depth 4|Set-Content -LiteralPath (Join-Path $run 'population.json') -Encoding utf8
[ordered]@{schema='deep.cli.balanced-plan.v1';directMeasured=6*$DirectRounds;groupMeasured=3*$GroupRounds;warmup=9;startHistory=190;startLocal=@(63,64,63);firstAttemptOnly=$true;sampleBudgetMilliseconds=$SampleBudgetMilliseconds;recoveryAttempts=$RecoveryAttempts;idleSeconds=$IdleSeconds;readinessBudgetSeconds=$ReadinessBudgetSeconds;releaseQualified=$false;sourceHashes=$sourceHashes;runtimeHashes=$runtimeHashes}|ConvertTo-Json -Depth 4|Set-Content -LiteralPath (Join-Path $run 'plan.json') -Encoding utf8
$controller=New-DeliveryEventController -MaximumEvents 100000
$sessions=@{};$contacts=@{};$addresses=@{};$books=@{};$pairs=@{};$pending=@{};$blocked=@{};$group=$null;$beforeGenerations=@{};$generationProof=[Collections.Generic.List[object]]::new()
$steps=[Collections.Generic.List[object]]::new();$initial=[Collections.Generic.List[object]]::new();$final=[Collections.Generic.List[object]]::new();$originals=[Collections.Generic.List[object]]::new()
$script:safety=$false;$setup=$false;$closed=$true;$unchanged=$true;$integrity=$true;$phase='setup';$started=[DateTime]::UtcNow
function Require([bool]$ok){if(-not $ok){throw 'Closed scenario assertion rejected.'}}
function Pair([int]$a,[int]$b){(@($a,$b)|Sort-Object)-join ':'}
function Start([int]$role,[string]$stage,[string[]]$arguments){
 if($pending.ContainsKey($role) -or $blocked.ContainsKey('host'+$role)){throw 'Host unavailable or already active.'}
 $h=Start-CliSessionCommand $sessions[$role] ($arguments+@('--profile',$profiles[$role-1],'--network',$network))
 $pending[$role]=[pscustomobject]@{handle=$h;stage=$stage;watch=[Diagnostics.Stopwatch]::StartNew()};$h
}
function Finish([int]$role){
 $p=$pending[$role]
 try{$r=Complete-CliSessionCommand $sessions[$role] $p.handle ([Math]::Max(1,1830000-[int]$p.watch.ElapsedMilliseconds))}
 catch{$blocked['host'+$role]=$true;throw 'Host transport failed; original custody retained.'}
 finally{$pending.Remove($role)}
 $row=[ordered]@{role=$role;phase=$p.stage;command=$r.CommandOrdinal;exit=$r.ExitCode;milliseconds=$p.watch.ElapsedMilliseconds;cpuMilliseconds=$r.ProcessorMilliseconds}
 foreach($name in @('recoveryWork','sessionWork','networkWork','nativeStorageWork','processed','tombstones','hasMore','completed','maintenance')){if($r.Result.PSObject.Properties.Name -contains $name){$row[$name]=$r.Result.$name}}
 if($r.Result.PSObject.Properties.Name -contains 'health'){$row['routeHealth']=[pscustomobject]@{AdvertisementIntervalCoversNow=$r.Result.health.AdvertisementIntervalCoversNow;UpdateIntervalCoversNow=$r.Result.health.UpdateIntervalCoversNow;RouteFaultRetained=$r.Result.health.RouteFaultRetained;UpdateGeneration=$(if($r.Result.health.PSObject.Properties.Name -contains 'UpdateGeneration'){$r.Result.health.UpdateGeneration}else{$null})}}
 if($r.ExitCode -ne 0){
  $row['code']='Unclassified';if($r.Result.PSObject.Properties.Name -contains 'code' -and $r.Result.code -cin @('business-operation-failed','cancelled','protected-state-rejected','invalid-arguments','storage-unavailable-or-busy','operation-failed')){$row.code=$r.Result.code}
  if($row.code -ceq 'protected-state-rejected'){$script:safety=$true}
  # Only closed product categories/check names, never arbitrary error text.
  if($r.Result.PSObject.Properties.Name -contains 'diagnostic'){$row['causes']=@($r.Result.diagnostic.causes|ForEach-Object {[pscustomobject]@{category=$_.category;check=$_.check}})}
 }
 $steps.Add([pscustomobject]$row)
 [pscustomobject]$row|ConvertTo-Json -Depth 6 -Compress|Add-Content -LiteralPath (Join-Path $run 'steps.jsonl') -Encoding utf8
 return $r
}
function Call([int]$role,[string]$stage,[string[]]$arguments){[void](Start $role $stage $arguments);Finish $role}
function Must([int]$role,[string]$stage,[string[]]$arguments){$r=Call $role $stage $arguments;Require ($r.ExitCode -eq 0);$r.Result}
function RecoveryWork($result){
 if($result.PSObject.Properties.Name -notcontains 'recoveryWork'){return $false}
 $w=$result.recoveryWork
 return $w.storeResumes -gt 0 -or $w.mailboxResumes -gt 0 -or $w.leaseWaits -gt 0
}
function Recent($sample,[int]$recipient,[string]$conversation){
 if($sample.kind -ceq 'Group'){return @('group','recent','--group',$group,'--limit','20')}
 return @('message','recent','--conversation',$conversation,'--limit','20')
}
function Present($result,$sample,[string]$text,[bool]$local=$false){
 $copies=@($result.items|Where-Object {$_.text -ceq $text})
 if($copies.Count -gt 1){$script:safety=$true;throw 'Duplicate original detected.'}
 if($copies.Count -eq 0){return $false}
 Require ([bool]$copies[0].local -eq $local)
 if($sample.kind -ceq 'Group'){Require ($copies[0].sequence -eq $sample.sequence)}
 return $true
}
function Census([string]$stage){
 $histories=@{};$heads=@{};$pendings=@{}
 foreach($role in 1..3){
  $h=Select-GsrGroupHead (Must $role ($stage+'-head') @('group','list')).items 'GSR CLI QA 11'
  Require ($h.Epoch -eq 2 -and $h.Members -eq 3 -and $h.State -ceq 'Active')
  if($null -eq $script:group){$script:group=$h.Group}else{Require ($h.Group -ceq $script:group)}
  $history=Must $role ($stage+'-history') @('group','messages','--group',$group)
  $old=@($history.items|Where-Object sequence -le 63).Count
  $b64=@($history.items|Where-Object {$_.sequence -eq 64 -and $_.text -ceq 'CLI engineering sequence 64 role 2'}).Count
  $p=Must $role ($stage+'-pending') @('message','pending')
  Require ($old -eq 189 -and $b64 -eq 1)
  $histories[$role]=$history;$heads[$role]=$h;$pendings[$role]=$p
  $row=[pscustomobject]@{role=$role;history=@($history.items).Count;originalPrefix=$old;B64Copies=$b64;local=[int]$h.LocalMessageCommands;pending=@($p.items).Count}
  if($stage -ceq 'initial'){Require ($row.history -eq 190 -and $row.local -eq @(63,64,63)[$role-1] -and $row.pending -eq 0);$initial.Add($row)}else{$final.Add($row)}
 }
 if($stage -cne 'initial'){
  $authored=@(foreach($original in $originals){
   $copies=@($histories[$original.sender].items|Where-Object {$_.text -ceq $original.text})
   Require ($copies.Count -le 1)
   if($copies.Count -eq 1){Require ($copies[0].local -eq $true -and $copies[0].sequence -eq $original.sequence);$original}
  })
  foreach($row in $final){
   $expected=190+$authored.Count;$local=@(63,64,63)[$row.role-1]+@($authored|Where-Object sender -eq $row.role).Count
   $exact=$row.history -eq $expected -and $row.local -eq $local -and $row.pending -eq 0
   foreach($original in $authored){$copies=@($histories[$row.role].items|Where-Object {$_.text -ceq $original.text -and $_.sequence -eq $original.sequence});if($copies.Count -ne 1 -or [bool]$copies[0].local -ne ($row.role -eq $original.sender)){$exact=$false}}
   $row|Add-Member -NotePropertyName expectedHistory -NotePropertyValue $expected
   $row|Add-Member -NotePropertyName expectedLocal -NotePropertyValue $local
   $row|Add-Member -NotePropertyName exactConverged -NotePropertyValue $exact
  }
 }
}
function SaveProgress {
 $population.ToArray()|Select-Object kind,round,warmup,sender,recipient,sequence,submitted,command,dispatch,outcome,recovery,recovered,ack,readWithoutOwnedAckPage,duplicatesChecked,reads,externalReadMilliseconds|ConvertTo-Json -Depth 7|Set-Content -LiteralPath (Join-Path $run 'progress.json') -Encoding utf8
}
function Wait-QuietMaintenance([int]$role,[long]$completed){
 while($readiness.Elapsed.TotalSeconds -lt $ReadinessBudgetSeconds){
  $summary=@($controller.MaintenanceSummary())
  $summary|ConvertTo-Json -Depth 4|Set-Content -LiteralPath (Join-Path $run 'maintenance-progress.json') -Encoding utf8
  if($controller.Rejected -or $script:safety){return $false}
  $state=@($summary|Where-Object role -eq $role)[0]
  if($state.completed -ge $completed -and -not $state.active -and $readiness.Elapsed.TotalSeconds -ge $IdleSeconds){return $true}
  Start-Sleep -Seconds 1
 }
 return $false
}
try{
 Inputs
 foreach($role in 1..3){$sessions[$role]=New-CliSession $exe $profiles[$role-1] $network $BootstrapDirectory $RegistryOrigin -DeliveryController $controller -ControllerRole $role}
 Census 'initial'
 foreach($role in 1..3){$contacts[$role]=(Must $role 'known-consent' @('contact','list')).contacts;$addresses[$role]=(Must $role 'known-owner-address' @('account','address')).address;Require (-not [string]::IsNullOrWhiteSpace($addresses[$role]))}
 foreach($a in 1..2){foreach($b in ($a+1)..3){$c=Select-GsrRetainedConversation $contacts[$a] $contacts[$b];Require ($null -ne $c);$pairs[(Pair $a $b)]=$c}}
 foreach($role in 1..3){$entries=@(foreach($peer in 1..3|Where-Object {$_ -ne $role}){[pscustomobject]@{conversation=$pairs[(Pair $role $peer)];address=$addresses[$peer]}});$books[$role]=ConvertTo-Json -InputObject $entries -Depth 3 -Compress}
 $addresses.Clear()
 # Diagnostic reads do not activate contact maintenance. Capture actual native
 # generation before connect; a denied diagnostic is recorded, never repaired
 # with a foreground publication or route-control operation.
 foreach($role in 1..3){foreach($peer in 1..3|Where-Object {$_ -ne $role}){
  $r=Call $role 'initial-route-health' (@('contact','route-health','--conversation',$pairs[(Pair $role $peer)])+$net)
  $beforeGenerations[($role.ToString()+':'+$peer)]=$(if($r.ExitCode -eq 0 -and $r.Result.health.PSObject.Properties.Name -contains 'UpdateGeneration'){$r.Result.health.UpdateGeneration}else{$null})
 }}
 # The seed-only normal entry point persists the real user-known address book
 # through private stdio. It performs no foreground route-control operation.
 foreach($role in 1..3){$seed=Must $role 'connection-seed-only' (@('network','connect','--known-contacts',$books[$role])+$net);Require ($seed.status -ceq 'connected' -and $seed.networkConnected -eq $true -and $seed.backgroundMaintenanceScheduled -eq $true)}
 # Observe scheduler telemetry in RAM, without preempting the real composite
 # publication/control/receive work. A probe waits for two completed cycles per
 # role, and only submits each diagnostic when that role's cycle is inactive.
 $readiness=[Diagnostics.Stopwatch]::StartNew();$nextCompleted=@{1=2L;2=2L;3=2L};$ready=$false
 while($readiness.Elapsed.TotalSeconds -lt $ReadinessBudgetSeconds){
  $ready=$true;$generationProof.Clear()
  foreach($role in 1..3){foreach($peer in 1..3|Where-Object {$_ -ne $role}){
   if(-not (Wait-QuietMaintenance $role $nextCompleted[$role])){$ready=$false;break}
   $r=Call $role 'background-readiness-health' (@('contact','route-health','--conversation',$pairs[(Pair $role $peer)])+$net)
   $current=$false;$after=$null
   if($r.ExitCode -eq 0){$h=$r.Result.health;$after=$(if($h.PSObject.Properties.Name -contains 'UpdateGeneration'){$h.UpdateGeneration}else{$null});$current=$h.AdvertisementIntervalCoversNow -eq $true -and $h.UpdateIntervalCoversNow -eq $true -and $h.RouteFaultRetained -eq $false -and $null -ne $after -and $after -ge 1}
   if(-not $current){$ready=$false}
   $before=$beforeGenerations[($role.ToString()+':'+$peer)];$generationProof.Add([pscustomobject]@{role=$role;peer=$peer;before=$before;after=$after;advanced=($null -ne $before -and $null -ne $after -and $after -gt $before);current=$current})
  }}
  if($ready -or $script:safety){break}
  foreach($state in @($controller.MaintenanceSummary())){$nextCompleted[$state.role]=[long]$state.completed+2L}
 }
 Require ($ready -and -not $script:safety)
 foreach($role in 1..3){foreach($peer in 1..3|Where-Object {$_ -ne $role}){$v=Must $role 'ready-route' (@('contact','route-verify','--conversation',$pairs[(Pair $role $peer)])+$net);Require ($v.routeVerified -eq $true)}}
 $setup=$true
 foreach($sample in $population){
  if($script:safety){$sample.outcome='SafetyNotSubmitted';continue}
  $sender=$sample.sender;$recipients=@(if($sample.kind -ceq 'Direct'){$sample.recipient}else{1..3|Where-Object {$_ -ne $sender}})
  $conversation=$pairs[(Pair $sender $recipients[0])]
  $dependencies=@(foreach($peer in $recipients){'Pair:'+(Pair $sender $peer)})
  if($sample.kind -ceq 'Group'){$dependencies+=@('Group:'+$sender)}
  if(@($dependencies|Where-Object {$blocked.ContainsKey($_)}).Count -gt 0 -or @(@($sender)+$recipients|Where-Object {$blocked.ContainsKey('host'+$_)}).Count){$sample.outcome='DependencyNotSubmitted';continue}
  Inputs;$phase='sample';$text='Balanced delivery '+[Guid]::NewGuid().ToString('N');$operation=$null;$bad=$false;$sendComplete=$false
  if($sample.kind -ceq 'Group'){$originals.Add([pscustomobject]@{sender=$sender;sequence=$sample.sequence;text=$text})} # RAM only.
  $watch=[Diagnostics.Stopwatch]::StartNew();$states=@{}
  try{
   $sample.submitted=$true;$sample.outcome='Incomplete'
   if($sample.kind -ceq 'Direct'){
    $h=Start $sender 'queue' (@('message','queue','--conversation',$conversation,'--text',$text)+$net);$sample.command=$h.CommandOrdinal
    $queued=Finish $sender
    if($queued.ExitCode -ne 0){throw 'Original queue failed.'}
    $sample.recovery=RecoveryWork $queued.Result;$operation=$queued.Result.operation;Require ($operation -cmatch '^[0-9a-f]{64}$')
    $h=Start $sender 'send' (@('message','send','--conversation',$conversation,'--operation',$operation,'--text',$text)+$net);$sample.dispatch=$h.CommandOrdinal
    $controller.BindDirectDispatch($sender,$sample.command,$sample.dispatch)
   }else{$h=Start $sender 'send' (@('group','send','--group',$group,'--conversation',$conversation,'--text',$text)+$net);$sample.command=$h.CommandOrdinal;$sample.dispatch=$h.CommandOrdinal}
   foreach($role in $recipients){$states[$role]=[pscustomobject]@{phase='receive';page=0;read=$false;ack=$false;checked=$false;requests=0};[void](Start $role 'receive' (@('mailbox','receive')+$net))}
   # The receive/read deadline is distinct from the bounded post-read ACK.
   # Finishing ACK after t1 must not inflate the admission-to-history sample.
   while($watch.ElapsedMilliseconds -lt ($SampleBudgetMilliseconds+330000)){
    if($watch.ElapsedMilliseconds -ge $SampleBudgetMilliseconds -and @($recipients|Where-Object {-not $states[$_].read}).Count -ne 0){break}
    foreach($role in @($pending.Keys)){
     if(-not $pending[$role].handle.Read.IsCompleted){continue}
     $stage=$pending[$role].stage;$ordinal=$pending[$role].handle.CommandOrdinal;$r=Finish $role
     if($r.ExitCode -ne 0){$bad=$true;continue}
     if(RecoveryWork $r.Result){$sample.recovery=$true}
     if($role -eq $sender){$sendComplete=$true;Require ($(if($sample.kind -ceq 'Direct'){$r.Result.status -ceq 'stored'}else{$r.Result.completed -eq 2}));continue}
     $state=$states[$role]
     if($stage -ceq 'receive'){
      Require ($r.Result.status -ceq 'received' -and $r.Result.processed -ge 0);$state.page=[int]$r.Result.processed;$state.requests++
      $state.phase='read'
     }elseif($stage -ceq 'read'){
      if(Present $r.Result $sample $text){
       $state.read=$true;$sample.reads+=@([pscustomobject]@{recipient=$role;command=$ordinal});$sample.externalReadMilliseconds+=@($watch.ElapsedMilliseconds);$controller.RecordHistoryRead($sender,$sample.command,$role,$ordinal)
       if($watch.ElapsedMilliseconds -ge $SampleBudgetMilliseconds){$bad=$true}
       if($state.page -eq 0){$sample.readWithoutOwnedAckPage=$true;$bad=$true}
      }
      $state.phase=$(if($state.page -gt 0){'ack'}else{'receive'})
     }elseif($stage -ceq 'ack'){
      Require ($r.Result.processed -eq $state.page -and $r.Result.tombstones -eq $state.page);$state.ack=$true;$state.phase=$(if($state.read){'check'}else{'receive'})
     }elseif($stage -ceq 'check'){Require (Present $r.Result $sample $text);$state.checked=$true;$state.phase='done'}
    }
    if($bad){break}
    foreach($role in $recipients){if(-not $pending.ContainsKey($role)){
     $state=$states[$role];if($state.phase -ceq 'done'){continue};Require ($state.requests -le 32)
     $args=if($state.phase -ceq 'receive'){@('mailbox','receive')+$net}elseif($state.phase -ceq 'ack'){@('mailbox','sync')+$net}else{Recent $sample $role $conversation}
     [void](Start $role $state.phase $args)
    }}
    if($sendComplete -and @($recipients|Where-Object {-not $states[$_].checked}).Count -eq 0){$sample.outcome='Success';$sample.ack=$true;$sample.duplicatesChecked=$true;break}
    Start-Sleep -Milliseconds 25
   }
  }catch{$bad=$true;$sample.outcome='CommandOrAssertionFailure'}
  # Complete every already-admitted command before any exact-original recovery.
  foreach($role in @($pending.Keys)){try{[void](Finish $role)}catch{$bad=$true}}
  if($sample.outcome -cne 'Success'){
   $sample.outcome=$(if($watch.ElapsedMilliseconds -ge $SampleBudgetMilliseconds){'Deadline'}else{'FirstAttemptFailure'})
   foreach($attempt in 1..$RecoveryAttempts){if($RecoveryAttempts -eq 0 -or $script:safety -or $sample.recovered){break}
    try{
     $sample.recovery=$true
     # An uncertain queue is discovered by its exact retained text; it is never
     # repeated. A group failure is resumed, never sent as a new command.
     if($sample.kind -ceq 'Direct'){
      $p=Must $sender 'recover-pending' @('message','pending');$original=@($p.items|Where-Object {$_.conversation -ceq $conversation -and $_.text -ceq $text})
      Require ($original.Count -le 1)
      if($original.Count -eq 1){[void](Must $sender 'recover-original-store' (@('message','send','--conversation',$conversation,'--operation',$original[0].operation,'--text',$original[0].text)+$net))}
     }else{[void](Must $sender 'recover-original-group' (@('group','resume','--group',$group,'--conversation',$conversation)+$net))}
     foreach($role in $recipients){
      $page=Must $role 'recover-receive' (@('mailbox','receive')+$net)
      $read=Call $role 'recover-read' (Recent $sample $role $conversation);Require ($read.ExitCode -eq 0 -and (Present $read.Result $sample $text))
      if(@($sample.reads|Where-Object recipient -eq $role).Count -eq 0){$sample.reads+=@([pscustomobject]@{recipient=$role;command=$read.CommandOrdinal});$sample.externalReadMilliseconds+=@($watch.ElapsedMilliseconds);$controller.RecordHistoryRead($sender,$sample.command,$role,$read.CommandOrdinal)}
      if($page.processed -gt 0){$ack=Must $role 'recover-ack' (@('mailbox','sync')+$net);Require ($ack.processed -eq $page.processed -and $ack.tombstones -eq $page.processed)}
      Require (Present (Must $role 'recover-duplicate-check' (Recent $sample $role $conversation)) $sample $text)
     }
     $sample.recovered=$true
    }catch{ }
   }
   if(-not $sample.recovered){foreach($dependency in $dependencies){$blocked[$dependency]=$true}}
  }
  SaveProgress
  Write-Host ([pscustomobject]@{kind=$sample.kind;round=$sample.round;sender=$sender;recipient=$sample.recipient;warmup=$sample.warmup;outcome=$sample.outcome;recovery=$sample.recovery;recovered=$sample.recovered}|ConvertTo-Json -Compress)
 }
 Census 'final'
}catch{$phase='SetupOrSafetyFailure';$integrity=$false}
finally{
 foreach($role in @($pending.Keys)){try{[void](Finish $role)}catch{$closed=$false}}
 foreach($s in $sessions.Values){try{Close-CliSession $s}catch{$closed=$false}}
 try{Inputs}catch{$unchanged=$false}
 $samples=@(foreach($sample in $population){
  $recipients=[int[]]@(if($sample.kind -ceq 'Direct'){$sample.recipient}else{1..3|Where-Object {$_ -ne $sample.sender}})
  $timings=@(foreach($recipient in $recipients){$ms=$controller.ValidatedHistoryReadMilliseconds($sample.sender,$sample.command,$recipient);$observed=$controller.ObservedValidatedHistoryReadMilliseconds($sample.sender,$sample.command,$recipient);[pscustomobject]@{recipient=$recipient;milliseconds=$(if([double]::IsFinite($ms)){$ms}else{$null});positiveInfinity=(-not [double]::IsFinite($ms));observedMilliseconds=$(if([double]::IsFinite($observed)){$observed}else{$null});observedPositiveInfinity=(-not [double]::IsFinite($observed))}})
  $finite=$sample.outcome -ceq 'Success' -and -not $sample.recovery -and $sample.ack -and $sample.duplicatesChecked -and $closed -and $unchanged -and $integrity -and -not $script:safety -and -not $controller.Rejected -and @($timings|Where-Object positiveInfinity).Count -eq 0
  $observedFinite=$closed -and $unchanged -and @($timings|Where-Object observedPositiveInfinity).Count -eq 0
  [pscustomobject]@{kind=$sample.kind;round=$sample.round;warmup=$sample.warmup;sender=$sample.sender;recipient=$sample.recipient;sequence=$sample.sequence;submitted=$sample.submitted;admitted=$controller.HasCommandAdmission($sample.sender,$sample.command);outcome=$sample.outcome;recovery=$sample.recovery;recovered=$sample.recovered;ack=$sample.ack;readWithoutOwnedAckPage=$sample.readWithoutOwnedAckPage;duplicatesChecked=$sample.duplicatesChecked;positiveInfinity=(-not $finite);milliseconds=$(if($finite){($timings.milliseconds|Measure-Object -Maximum).Maximum}else{$null});observedPositiveInfinity=(-not $observedFinite);observedMilliseconds=$(if($observedFinite){($timings.observedMilliseconds|Measure-Object -Maximum).Maximum}else{$null});observedExternalReadMilliseconds=$sample.externalReadMilliseconds;recipients=$timings}
 })
 $stats=@(foreach($kind in @('Direct','Group')){
  $cohort=@($samples|Where-Object {$_.kind -ceq $kind -and -not $_.warmup});$values=[double[]]@($cohort|ForEach-Object {if($_.positiveInfinity){[double]::PositiveInfinity}else{[double]$_.milliseconds}})
  $p95=[Deep.Cli.Measurement.DeliveryEventController]::NearestRank($values,.95)
  $observedValues=[double[]]@($cohort|ForEach-Object {if($_.observedPositiveInfinity){[double]::PositiveInfinity}else{[double]$_.observedMilliseconds}});$observedP95=[Deep.Cli.Measurement.DeliveryEventController]::NearestRank($observedValues,.95)
  [pscustomobject]@{kind=$kind;n=$cohort.Count;rank=[int][Math]::Ceiling(.95*$cohort.Count);submitted=@($cohort|Where-Object submitted).Count;admitted=@($cohort|Where-Object admitted).Count;notSubmitted=@($cohort|Where-Object {-not $_.submitted}).Count;deadlines=@($cohort|Where-Object outcome -eq 'Deadline').Count;errors=@($cohort|Where-Object outcome -eq 'FirstAttemptFailure').Count;withRecovery=@($cohort|Where-Object recovery).Count;finite=@($cohort|Where-Object {-not $_.positiveInfinity}).Count;missingOrFailed=@($cohort|Where-Object positiveInfinity).Count;p95Milliseconds=$(if([double]::IsFinite($p95)){$p95}else{$null});positiveInfinity=[double]::IsPositiveInfinity($p95);observedFinite=@($cohort|Where-Object {-not $_.observedPositiveInfinity}).Count;observedMissing=@($cohort|Where-Object observedPositiveInfinity).Count;observedP95Milliseconds=$(if([double]::IsFinite($observedP95)){$observedP95}else{$null});observedPositiveInfinity=[double]::IsPositiveInfinity($observedP95);observedIncludesRecovery=$true}
 })
 $pairsStats=@(foreach($kind in @('Direct','Group')){foreach($sender in 1..3){foreach($recipient in 1..3|Where-Object {$_ -ne $sender}){
  $cohort=@($samples|Where-Object {$_.kind -ceq $kind -and -not $_.warmup -and $_.sender -eq $sender -and ($kind -ceq 'Group' -or $_.recipient -eq $recipient)})
  $values=[double[]]@(foreach($sample in $cohort){if($sample.positiveInfinity){[double]::PositiveInfinity}else{[double](@($sample.recipients|Where-Object recipient -eq $recipient)[0].milliseconds)}})
  $p95=[Deep.Cli.Measurement.DeliveryEventController]::NearestRank($values,.95)
  $observedValues=[double[]]@(foreach($sample in $cohort){$pair=@($sample.recipients|Where-Object recipient -eq $recipient)[0];if($pair.observedPositiveInfinity){[double]::PositiveInfinity}else{[double]$pair.observedMilliseconds}});$observedP95=[Deep.Cli.Measurement.DeliveryEventController]::NearestRank($observedValues,.95)
  [pscustomobject]@{kind=$kind;sender=$sender;recipient=$recipient;n=$cohort.Count;rank=[int][Math]::Ceiling(.95*$cohort.Count);finite=@($values|Where-Object {[double]::IsFinite($_)}).Count;p95Milliseconds=$(if([double]::IsFinite($p95)){$p95}else{$null});positiveInfinity=[double]::IsPositiveInfinity($p95);observedFinite=@($observedValues|Where-Object {[double]::IsFinite($_)}).Count;observedP95Milliseconds=$(if([double]::IsFinite($observedP95)){$observedP95}else{$null});observedPositiveInfinity=[double]::IsPositiveInfinity($observedP95)}
 }}})
 $roleStats=@(foreach($sender in 1..3){$cohort=@($samples|Where-Object {$_.kind -ceq 'Group' -and -not $_.warmup -and $_.sender -eq $sender});$values=[double[]]@($cohort|ForEach-Object {if($_.positiveInfinity){[double]::PositiveInfinity}else{[double]$_.milliseconds}});$p95=[Deep.Cli.Measurement.DeliveryEventController]::NearestRank($values,.95);$observedValues=[double[]]@($cohort|ForEach-Object {if($_.observedPositiveInfinity){[double]::PositiveInfinity}else{[double]$_.observedMilliseconds}});$observedP95=[Deep.Cli.Measurement.DeliveryEventController]::NearestRank($observedValues,.95);[pscustomobject]@{sender=$sender;n=$cohort.Count;rank=[int][Math]::Ceiling(.95*$cohort.Count);finite=@($values|Where-Object {[double]::IsFinite($_)}).Count;p95Milliseconds=$(if([double]::IsFinite($p95)){$p95}else{$null});positiveInfinity=[double]::IsPositiveInfinity($p95);observedFinite=@($observedValues|Where-Object {[double]::IsFinite($_)}).Count;observedP95Milliseconds=$(if([double]::IsFinite($observedP95)){$observedP95}else{$null});observedPositiveInfinity=[double]::IsPositiveInfinity($observedP95)}})
 [ordered]@{schema='deep.cli.retained-balanced-delivery.v1';startedUtc=$started;finishedUtc=[DateTime]::UtcNow;setup=$setup;terminalPhase=$phase;safetyStopped=$script:safety;cohortIntegrity=$integrity;inputsUnchanged=$unchanged;cleanClosure=$closed;controllerRejected=$controller.Rejected;idleSeconds=$IdleSeconds;backgroundGenerationProof=$generationProof.ToArray();maintenance=$controller.MaintenanceSummary();initial=$initial.ToArray();final=$final.ToArray();statistics=$stats;perDirectedPair=$pairsStats;perGroupSender=$roleStats;samples=$samples;streams=$controller.StreamSummary();releaseQualified=$false;warmLatencyQualified=$false}|ConvertTo-Json -Depth 12|Set-Content -LiteralPath (Join-Path $run 'receipt.json') -Encoding utf8
 SaveProgress
}
