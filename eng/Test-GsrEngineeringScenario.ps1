[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'GsrCohort.psm1') -Force
$scenario=Join-Path $PSScriptRoot 'Invoke-ThreeClientDeliveryEngineering.ps1'
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($scenario,[ref]$tokens,[ref]$errors)
if($errors.Count){throw 'Engineering driver syntax rejected.'}
$checks=0
function Require([bool]$value,[string]$label){if(-not $value){throw $label};$script:checks++}
function Reject([scriptblock]$action){$rejected=$false;try{& $action}catch{$rejected=$true};Require $rejected 'Expected bounded metadata rejection.'}
$rounds=@($ast.ParamBlock.Parameters|Where-Object {$_.Name.VariablePath.UserPath -ceq 'Rounds'})[0]
Require ($rounds.DefaultValue.SafeGetValue() -eq 4) 'Balanced four-round engineering default required.'
$range=@($rounds.Attributes|Where-Object {$_.TypeName.Name -ceq 'ValidateRange'})[0]
Require ($range.PositionalArguments[0].SafeGetValue() -eq 1 -and $range.PositionalArguments[1].SafeGetValue() -eq 4) 'Engineering cannot enable qualification-sized runs.'
$population=@(New-GsrEngineeringPopulation)
Require ($population.Count -eq 12) 'Predeclared twelve authored samples required.'
foreach($role in 1..3){
    $items=@($population|Where-Object {$_.SenderRole -eq $role})
    Require ($items.Count -eq 4 -and $items[0].Sequence -eq 61 -and $items[-1].Sequence -eq 64) 'Balanced retained per-role cursor required.'
    Require (@($items|Where-Object {$_.Submitted -or $_.Outcome -cne 'NotSubmitted' -or $_.CommandOrdinal -ne 0}).Count -eq 0) 'Population cannot contain inferred successes.'
}
Reject {New-GsrEngineeringPopulation -Rounds 200}
Reject {New-GsrEngineeringPopulation -Cursor -1}
$direct=@(New-DirectEngineeringPopulation -Rounds 2)
Require ($direct.Count -eq 12) 'Two direct rounds require twelve planned originals.'
foreach($sender in 1..3){foreach($recipient in @(1..3|Where-Object {$_ -ne $sender})){
    Require (@($direct|Where-Object {$_.SenderRole -eq $sender -and $_.RecipientRole -eq $recipient}).Count -eq 2) 'Every direct pair must have its full fixed denominator.'
}}
Reject {New-DirectEngineeringPopulation -Rounds 200}
Reject {& $scenario -MessageKind Direct -SingleDirectSample -DirectSenderRole 2 -DirectRecipientRole 2 -BootstrapDirectory '__never_read__' -RegistryOrigin 'https://localhost/' -RunDirectory '__never_create__'}
$head=[pscustomobject]@{Name='GSR CLI QA 11';Group=('a'*64)}
Require ((Select-GsrGroupHead @($head) 'GSR CLI QA 11').Group -ceq $head.Group) 'Exact group selector changed.'
Reject {Select-GsrGroupHead @($head,$head) 'GSR CLI QA 11'}
Reject {Select-GsrGroupHead @($head) 'other'}
$left=[pscustomobject]@{conversation=('a'*64);state='PeerAcceptanceRetained'}
$right=[pscustomobject]@{conversation=('a'*64);state='LocalAcceptanceRetained'}
Require ((Select-GsrRetainedConversation @($left) @($right)) -ceq $left.conversation) 'Retained complementary consent required.'
Require ((Select-GsrRetainedConversation @($right) @($left)) -ceq $left.conversation) 'Retained reverse orientation required.'
Require ($null -eq (Select-GsrRetainedConversation @($left) @($left))) 'Matching selectors without mutual consent cannot admit a cohort.'
Reject {Select-GsrRetainedConversation @($left,$left) @($right)}
Reject {Select-GsrRetainedConversation @($left) @($right,$right)}
Reject {& $scenario -Rounds 200 -BootstrapDirectory '__never_read__' -RegistryOrigin 'https://localhost/' -RunDirectory '__never_create__'}
$failure=$null
try{& $scenario -AliceProfile 'same' -BobProfile 'same' -CarolProfile 'other' -BootstrapDirectory '__never_read__' -RegistryOrigin 'https://localhost/' -RunDirectory '__never_create__'}catch{$failure=$_.Exception.Message}
Require ($failure -ceq 'Fresh artifact directory and distinct retained profiles required.') 'Invalid cohort must reject before bootstrap/profile access.'
$recoveryParser=@($ast.FindAll({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq 'Read-RecoveryWork'},$true))
Require ($recoveryParser.Count -eq 1) 'One actual closed recovery parser required.'
. ([scriptblock]::Create($recoveryParser[0].Extent.Text))
$zero=[pscustomobject]@{recoveryWork=[pscustomobject]@{storeResumes=0L;mailboxResumes=0L;leaseWaits=0L}}
Require ((Read-RecoveryWork $zero $true).storeResumes -eq 0) 'Actual recovery parser rejected valid unsigned counters.'
Require ($null -eq (Read-RecoveryWork ([pscustomobject]@{accountPresent=$true}) $false)) 'Account status may omit recovery counters.'
Reject {Read-RecoveryWork ([pscustomobject]@{status='stored'}) $true}
foreach($bad in @(-1L,'0',0.0,$null)){
    Reject {Read-RecoveryWork ([pscustomobject]@{recoveryWork=[pscustomobject]@{storeResumes=$bad;mailboxResumes=0L;leaseWaits=0L}}) $true}
}
Reject {Read-RecoveryWork ([pscustomobject]@{recoveryWork=[pscustomobject]@{storeResumes=0L;mailboxResumes=0L}}) $true}
foreach($name in @('Read-ClosedFailure','Require-CorrelatedHistory','Test-DirectHistory','Sample-Recipients')){
    $function=@($ast.FindAll({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq $name},$true))
    Require ($function.Count -eq 1) 'One actual evidence adapter required.'
    . ([scriptblock]::Create($function[0].Extent.Text))
}
$directMessage=[pscustomobject]@{text='actual original direct text';local=$false}
Require (Test-DirectHistory ([pscustomobject]@{status='ok';items=@($directMessage)}) $directMessage.text) 'Exact direct text requires ordinary remote history.'
Require (-not (Test-DirectHistory ([pscustomobject]@{status='ok';items=@()}) $directMessage.text)) 'Missing original direct text must remain unobserved.'
Reject {Test-DirectHistory ([pscustomobject]@{status='ok';items=@($directMessage,$directMessage)}) $directMessage.text}
Reject {Test-DirectHistory ([pscustomobject]@{status='ok';items=@([pscustomobject]@{text=$directMessage.text;local='false'})}) $directMessage.text}
Reject {Test-DirectHistory ([pscustomobject]@{status='ok';items=@([pscustomobject]@{text=$directMessage.text;local=$true})}) $directMessage.text}
& {
    $MessageKind='Direct';$roles=@(Sample-Recipients $direct[0])
    Require ($roles.Count -eq 1 -and $roles[0] -eq 2) 'Direct observation must bind exactly its planned recipient.'
    $MessageKind='Group';$roles=@(Sample-Recipients ([pscustomobject]@{SenderRole=1}))
    Require ($roles.Count -eq 2 -and $roles[0] -eq 2 -and $roles[1] -eq 3) 'Group observation must preserve both other recipients.'
}
& {
    # Exercise the production pending assignment with the real JSON empty and
    # nonempty result shapes. PS strict array member enumeration rejects .items
    # on a wrapper containing one object whose items array is empty.
    $assignment=@($ast.FindAll({param($node) $node -is [Management.Automation.Language.AssignmentStatementAst] -and $node.Left.Extent.Text -ceq '$directPending[$role]'},$true))
    Require ($assignment.Count -eq 1) 'One actual direct-pending projection required.'
    $role=1;$directPending=@{};$pendingResult='{"status":"ok","items":[]}'|ConvertFrom-Json
    . ([scriptblock]::Create($assignment[0].Extent.Text))
    Require ($directPending[1].Count -eq 0) 'Empty ordinary pending result must admit the selected conversation.'
    $pendingResult='{"status":"ok","items":[{"conversation":"selected","operation":"private","text":"private"}]}'|ConvertFrom-Json
    . ([scriptblock]::Create($assignment[0].Extent.Text))
    Require ($directPending[1].Count -eq 1 -and $directPending[1][0].conversation -ceq 'selected') 'Nonempty ordinary pending custody must remain available for the selected-pair guard.'
}
$message=[pscustomobject]@{text='correlated test message';sequence=61L;local=$false}
Require-CorrelatedHistory ([pscustomobject]@{status='ok';items=@($message)}) 61L $message.text
foreach($defect in @('missing','duplicate','mixed-duplicate','text','sequence','local','untyped-local','untyped-sequence','status')){
    $item=[pscustomobject]@{text=$message.text;sequence=61L;local=$false}
    switch($defect){
        'text'{$item.text='different'} 'sequence'{$item.sequence=62L} 'local'{$item.local=$true}
        'untyped-local'{$item.local='false'} 'untyped-sequence'{$item.sequence='61'}
    }
    $items=@($item);if($defect -ceq 'missing'){$items=@()};if($defect -ceq 'duplicate'){$items=@($item,$item)}
    if($defect -ceq 'mixed-duplicate'){$items=@($item,[pscustomobject]@{text=$message.text;sequence=61L;local=$true})}
    $status='ok';if($defect -ceq 'status'){$status=@('ok')}
    Reject {Require-CorrelatedHistory ([pscustomobject]@{status=$status;items=$items}) 61L $message.text}
}
$closed=Read-ClosedFailure ([pscustomobject]@{code='business-operation-failed';payload='never-export';diagnostic=[pscustomobject]@{
    phase='MailboxSync';secret='never-export';causes=@([pscustomobject]@{category='OutcomeUnknown';check='IngressUnavailable';
        method='Deep.Client.Shared.Services.Test+<Read>d__1.MoveNext';il=42;message='never-export';trail=@([pscustomobject]@{method='private-path';il=9999999;payload='never-export'})})}})
Require ($closed.code -ceq 'business-operation-failed' -and $closed.diagnostic.phase -ceq 'MailboxSync' -and
    $closed.diagnostic.causes[0].category -ceq 'OutcomeUnknown' -and $closed.diagnostic.causes[0].il -eq 42) 'Closed owned diagnostic fields must survive.'
Require ($closed.diagnostic.causes[0].trail[0].method -ceq 'Unavailable' -and $closed.diagnostic.causes[0].trail[0].il -eq -1 -and
    -not ($closed|ConvertTo-Json -Depth 8 -Compress).Contains('never-export')) 'Payloads, messages and private paths cannot escape.'
$unknown=Read-ClosedFailure ([pscustomobject]@{code='never-export';diagnostic=[pscustomobject]@{phase='never-export';causes=@([pscustomobject]@{category='never-export';check='never-export';method='never-export';il=-2})}})
Require ($unknown.code -ceq 'Unclassified' -and $unknown.diagnostic.phase -ceq 'Unclassified' -and
    $unknown.diagnostic.causes[0].category -ceq 'Other' -and $unknown.diagnostic.causes[0].check -ceq 'Unclassified') 'Unknown diagnostic values require closed replacements.'
foreach($reason in @('FutureCreation','ExpiredAnnouncement','CreationOutsideSignedRoute')){
    $historyFailure=Read-ClosedFailure ([pscustomobject]@{code='business-operation-failed';payload='never-export';diagnostic=[pscustomobject]@{
        phase='ContactRouteVerification';causes=@([pscustomobject]@{category='ProtectedState';check=('HistoryAnnouncement'+$reason);message='never-export'})}})
    Require ($historyFailure.diagnostic.causes[0].check -ceq ('HistoryAnnouncement'+$reason) -and
        -not ($historyFailure|ConvertTo-Json -Depth 8 -Compress).Contains('never-export')) 'Closed current-history reasons must survive the frame consumer without payload or exception text.'
}
foreach($reason in @('NetworkAuthority','RecipientNetwork','ViewAuthority','HeadAuthority','DirectoryAuthority','TimeAuthority','DirectoryWitnessPolicy','TimeWitnessPolicy','DirectoryHead','ViewHash','ViewGeneration','ClockBoot','ClockRegression','ObservationExpiry')){
    $contextFailure=Read-ClosedFailure ([pscustomobject]@{code='business-operation-failed';diagnostic=[pscustomobject]@{
        phase='ContactRouteVerification';causes=@([pscustomobject]@{category='ProtectedState';check=('RouteContext'+$reason);message='never-export';record='never-export'})}})
    Require ($contextFailure.diagnostic.causes[0].check -ceq ('RouteContext'+$reason) -and
        -not ($contextFailure|ConvertTo-Json -Depth 8 -Compress).Contains('never-export')) 'Closed typed route-context reason must survive without record values or exception text.'
}
foreach($reason in @('RouteContext999','RouteContextDO-NOT-EXPORT','DirectoryHead')){
    $unknownContext=Read-ClosedFailure ([pscustomobject]@{code='business-operation-failed';diagnostic=[pscustomobject]@{
        phase='ContactRouteVerification';causes=@([pscustomobject]@{category='ProtectedState';check=$reason;message='never-export'})}})
    Require ($unknownContext.diagnostic.causes[0].check -ceq 'Unclassified') 'Unknown route-context fields cannot escape through the harness.'
}
$many=[pscustomobject]@{category='Other';check='Unclassified';method='Unavailable';il=-1;trail=@(1..12|ForEach-Object {[pscustomobject]@{method='Unavailable';il=-1}})}
$bounded=Read-ClosedFailure ([pscustomobject]@{code='business-operation-failed';diagnostic=[pscustomobject]@{phase='MailboxSync';causes=@(1..12|ForEach-Object {$many})}})
Require ($bounded.diagnostic.causes.Count -eq 8 -and $bounded.diagnostic.causes[0].trail.Count -eq 8) 'Diagnostic cause/trail bounds must remain eight.'
$compiler='Deep.Client.Shared.Persistence.Owner+<>c__DisplayClass1_0+<<Run>g__Guard|0_1>d.MoveNext'
$compilerClosed=Read-ClosedFailure ([pscustomobject]@{code='business-operation-failed';diagnostic=[pscustomobject]@{phase='MailboxSync';causes=@([pscustomobject]@{category='Other';check='Unclassified';method=$compiler;il=10})}})
Require ($compilerClosed.diagnostic.causes[0].method -ceq $compiler) 'Bounded code-owned compiler local-function frames must survive.'
foreach($method in @('Deep.Client.Shared.Services.Guard|0.MoveNext','Deep.Protocol.<Run>g__Guard|secret.MoveNext','Other.<Run>g__Guard|0.MoveNext')){
    $invalid=Read-ClosedFailure ([pscustomobject]@{code='business-operation-failed';diagnostic=[pscustomobject]@{phase='MailboxSync';causes=@([pscustomobject]@{category='Other';check='Unclassified';method=$method;il=10})}})
    Require ($invalid.diagnostic.causes[0].method -ceq 'Unavailable') 'A pipe requires a numeric compiler local-function suffix in an owned namespace.'
}
$source=Get-Content -LiteralPath $scenario -Raw
Require ($source.Contains("@('contact','route-verify'") -and
    $source.IndexOf("@('contact','route-verify'") -lt $source.IndexOf('$cohortValidated=$true')) 'Strict current route verification must precede cohort admission.'
$historicalGates=@($ast.FindAll({param($node) $node -is [Management.Automation.Language.CommandAst] -and
    $node.GetCommandName() -ceq 'Require' -and $node.Extent.Text.Contains('UpdateIntervalCoversNow')},$true))
Require ($historicalGates.Count -eq 0) 'Historical XUR intervals cannot qualify current route admission.'
Require ($source.Contains('Start-Command $sender') -and $source.Contains("Start-Command `$role 'receive-ack'")) 'Sender and recipient submissions must be independent.'
Require ($source.Contains('$watch.ElapsedMilliseconds -lt $SampleBudgetMilliseconds') -and $source.Contains('$pages[$role] -ge $MaximumReceivePages')) 'Receive scheduling requires both time and work bounds.'
$cadence=@($ast.ParamBlock.Parameters|Where-Object {$_.Name.VariablePath.UserPath -ceq 'EmptyPollIntervalMilliseconds'})[0]
Require ($cadence.DefaultValue.SafeGetValue() -eq 100) 'Explicit empty-only cadence required.'
Require ($source.Contains('$nextEmptyPoll[$role]=$watch.ElapsedMilliseconds+$EmptyPollIntervalMilliseconds') -and
    $source.Contains('Ceiling($SampleBudgetMilliseconds/$EmptyPollIntervalMilliseconds)+$MaximumReceivePages+1')) 'Fast empty polls must cover the full bounded sample window.'
Require ($source.Contains('failurePhase=$script:failurePhase;failureCode=$script:failureCode') -and -not $source.Contains('$_.Exception.Message')) 'Failures require closed phase/code, never raw exception messages.'
Require ($source.Contains('$eventBudget -gt 100000') -and $source.Contains('New-DeliveryEventController -MaximumEvents ([int]$eventBudget)') -and
    $source.IndexOf('$eventBudget -gt 100000') -lt $source.IndexOf('New-CliSession $exe')) 'Declared diagnostic budget must reject before profiles open.'
Require ($source.Contains('$observed=$metric.Complete -and -not $closeFailed -and $inputsUnchanged') -and
    $source.Contains('observed=$observedBlock') -and $source.Contains('$finite=$sample.Outcome -ceq')) 'ACK failure must preserve raw closed observation separately from qualification.'
Require (-not $source.Contains("@('group','resume'") -and -not $source.Contains("@('group','create'") -and -not $source.Contains("@('contact','request'")) 'Engineering driver cannot repair or reauthor retained setup.'
Require ($source.Contains('positiveInfinity=(-not $finite)') -and $source.Contains('perDirectedPair=$pairStats.ToArray()')) 'Complete population and directed-pair reporting required.'
Require ($source.Contains("Start-Command `$role 'history-read' @('group','messages','--group',`$group)") -and
    $source.Contains('Require-CorrelatedHistory $result $sample.Sequence $text') -and $source.Contains('$controller.RecordHistoryRead(')) 'Read-result evidence must use the ordinary exact correlated history command.'
Require ($source.Contains("`$row['failure']=Read-ClosedFailure `$result") -and $source.Contains('historyReadPositiveInfinity=(-not $readFinite)') -and
    $source.Contains('historyReadP95Milliseconds=') -and $source.Contains('observed=$observedBlock')) 'Closed failures and distinct complete read/projection populations are mandatory.'
$legacy=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Invoke-ThreeClientGsrE2E.ps1') -Raw
Require ($legacy.Contains('Select-GsrGroupHead') -and $legacy.Contains('Select-GsrRetainedConversation') -and $legacy.Contains('cohortModuleSha256=')) 'Both GSR drivers must use the captured pure selectors.'
& {
    foreach($name in @('Record-Failure','Start-Command','Complete-Command','Collect-AdmittedCommands')){
        $fn=@($ast.FindAll({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq $name},$true))
        Require ($fn.Count -eq 1) 'One production pending-command owner required.'
        . ([scriptblock]::Create($fn[0].Extent.Text))
    }
    $pending=@{};$sessions=@{1=[pscustomobject]@{Role=1};2=[pscustomobject]@{Role=2}}
    $steps=[Collections.Generic.List[object]]::new();$lateDispositions=[Collections.Generic.List[object]]::new()
    $profiles=@('unit-left','unit-right');$network='unit-network'
    $MessageKind='Group';$ObserveRecovery=$false
    $script:submittedHandles=0;$script:collectedBudgets=[Collections.Generic.List[int]]::new()
    $script:commandFailed=$false;$script:measurementRejected=$false;$script:failureCode='None';$script:failurePhase='None'
    function Start-CliSessionCommand($session,$arguments){
        $script:submittedHandles++
        [pscustomobject]@{Read=$(if($session.Role -eq 1){[Threading.Tasks.Task]::CompletedTask}else{[Threading.Tasks.Task]::Delay(250)});CommandOrdinal=1}
    }
    function Complete-CliSessionCommand($session,$handle,[int]$budget){
        $script:collectedBudgets.Add($budget)
        if(-not $handle.Read.Wait($budget)){throw 'Original unit handle did not finish within its budget.'}
        [pscustomobject]@{ExitCode=0;CommandOrdinal=1;ProcessorMilliseconds=0;Result=[pscustomobject]@{completed=2;recoveryWork=[pscustomobject]@{storeResumes=0L;mailboxResumes=$(if($session.Role -eq 1){1L}else{0L});leaseWaits=0L}}}
    }
    [void](Start-Command 1 'receive-ack' @('mailbox','sync'))
    [void](Start-Command 2 'send' @('group','send'))
    Require ($pending[1].ProductBudgetMilliseconds -eq 300000 -and $pending[2].ProductBudgetMilliseconds -eq 1800000) 'Original product deadlines must match the submitted command.'
    [void](Complete-Command 1 1000)
    Require ($script:commandFailed -and $script:measurementRejected -and $script:failureCode -ceq 'RecoveryDetected' -and $pending.Count -eq 1) 'Recovered success must stop measurement while its slower sibling remains admitted.'
    Reject {Start-Command 1 'send' @('group','send')}
    Collect-AdmittedCommands
    Require ($script:submittedHandles -eq 2 -and $pending.Count -eq 0 -and $lateDispositions.Count -eq 1 -and $lateDispositions[0].role -eq 2 -and $lateDispositions[0].exit -eq 0) 'Collection must finish only the existing sibling without another send or drain.'
    Require ($script:collectedBudgets[1] -gt 0 -and $script:collectedBudgets[1] -le 1800000 -and $steps[-1].completed -eq 2) 'Late disposition must retain the real response under the remaining original budget.'
    $sample=[pscustomobject]@{Outcome='Success'};$metric=[pscustomobject]@{Complete=$true};$closeFailed=$false;$inputsUnchanged=$true;$recovered=$false
    $finiteAssignment=@($ast.FindAll({param($node) $node -is [Management.Automation.Language.AssignmentStatementAst] -and $node.Left.Extent.Text -ceq '$finite'},$true))
    Require ($finiteAssignment.Count -eq 1) 'One actual qualification predicate required.'
    . ([scriptblock]::Create($finiteAssignment[0].Extent.Text))
    Require (-not $finite -and $script:commandFailed) 'Successful late completion must preserve failed/infinite measurement qualification.'
}
& {
    Import-Module (Join-Path $PSScriptRoot 'CliSession.psm1') -Force
    $controller=New-DeliveryEventController
    $hash='a'*64;$delivery='b'*64
    function Frame([long]$sequence,[long]$command,[string]$phase,[string]$messageHash='',[string]$deliveryHash=''){
        [ordered]@{schema='deep.delivery.v1';sequence=$sequence;command=$command;phase=$phase;messageHash=$messageHash;deliveryHash=$deliveryHash}|ConvertTo-Json -Compress
    }
    function End([long]$sequence){
        [ordered]@{schema='deep.delivery.v1';sequence=$sequence;command=0;phase='StreamClosed';messageHash='';deliveryHash='';dropped=0}|ConvertTo-Json -Compress
    }
    $sender=@((Frame 1 1 'CommandAccepted'),(Frame 2 1 'NativeOutboxDurable' $hash $delivery),(End 3))-join "`n"
    [void]$controller.Attach(1,[IO.StringReader]::new($sender+"`n")).GetAwaiter().GetResult()
    [void]$controller.BeginCommand(1);$controller.CompleteCommand(1,1,6)
    $receiver=@((Frame 1 1 'CommandAccepted'),(Frame 2 1 'RecipientDurableReadable' $hash $delivery),(Frame 3 2 'CommandAccepted'),(End 4))-join "`n"
    [void]$controller.Attach(2,[IO.StringReader]::new($receiver+"`n")).GetAwaiter().GetResult()
    [void]$controller.BeginCommand(2);[void]$controller.BeginCommand(2)
    $controller.CompleteCommand(2,1,6);$controller.CompleteCommand(2,2,0)
    $controller.RecordHistoryRead(1,1,2,2)
    Require (-not $controller.Rejected -and [double]::IsFinite($controller.ObservedHistoryReadMilliseconds(1,1,2))) 'Closed ordinary read must survive a failed sender/ACK as diagnostic evidence.'
    Require ([double]::IsPositiveInfinity($controller.HistoryReadMilliseconds(1,1,[int[]]@(2),2))) 'Diagnostic read cannot qualify a failed original send.'
    $queued=New-DeliveryEventController
    $sender=@((Frame 1 1 'CommandAccepted'),(Frame 2 2 'CommandAccepted'),(Frame 3 2 'NativeOutboxDurable' $hash $delivery),(Frame 4 2 'StoreQuorum' $hash $delivery),(End 5))-join "`n"
    [void]$queued.Attach(1,[IO.StringReader]::new($sender+"`n")).GetAwaiter().GetResult()
    [void]$queued.BeginCommand(1);$queued.CompleteCommand(1,1,0)
    [void]$queued.BeginCommand(1);$queued.BindDirectDispatch(1,1,2);$queued.CompleteCommand(1,2,0)
    [void]$queued.Attach(2,[IO.StringReader]::new($receiver+"`n")).GetAwaiter().GetResult()
    [void]$queued.BeginCommand(2);[void]$queued.BeginCommand(2)
    $queued.CompleteCommand(2,1,0);$queued.CompleteCommand(2,2,0);$queued.RecordHistoryRead(1,1,2,2)
    Require ($queued.HasRecipientObservation(1,1,2) -and $queued.Sample(1,1,[int[]]@(2)).Complete -and [double]::IsFinite($queued.HistoryReadMilliseconds(1,1,[int[]]@(2),2))) 'Original queue admission must correlate its distinct later dispatch and ordinary read.'
    Require ([double]::IsPositiveInfinity($queued.ObservedHistoryReadMilliseconds(1,2,2))) 'Unbound dispatch has no ordinary queue-read correlation and cannot replace t0.'
}
& {
    foreach($name in @('Recent-Arguments','Test-RecentHistory')){
        $fn=@($ast.FindAll({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq $name},$true))
        Require ($fn.Count -eq 1) 'One actual bounded ordinary recent adapter required.'
        . ([scriptblock]::Create($fn[0].Extent.Text))
    }
    $MessageKind='Direct';$RecentReadLimit=20;$ReceiveBeforeAck=$true
    Require (((Recent-Arguments 'private-conversation' 'private-group') -join ' ') -ceq 'message recent --conversation private-conversation --limit 20') 'Direct recent must remain an ordinary bounded public read.'
    $MessageKind='Group'
    Require (((Recent-Arguments 'private-conversation' 'private-group') -join ' ') -ceq 'group recent --group private-group --limit 20') 'Group recent must remain an ordinary bounded public read.'
    $MessageKind='Direct'
    $completion=@($ast.FindAll({param($node) $node -is [Management.Automation.Language.ForEachStatementAst] -and
        $node.Extent.Text.StartsWith('foreach($role in @($pending.Keys))') -and $node.Extent.Text.Contains("`$phase -ceq 'history-validation'")},$true))
    Require ($completion.Count -eq 1) 'One actual candidate completion state machine required.'
    $watch=[Diagnostics.Stopwatch]::StartNew();$SampleBudgetMilliseconds=120000
    $pending=@{};$sender=1;$sample=[pscustomobject]@{Sequence=1;CommandOrdinal=10};$text='original direct payload'
    $awaitingAck=@{2=$false};$readBeforeAck=@{2=$false};$receivedPending=@{2=0};$historyRead=@{2=$false};$historyValidated=@{2=$false}
    $more=@{2=$false};$nextEmptyPoll=@{2=0};$pages=@{2=0};$script:unitReadRecords=0
    $controller=[pscustomobject]@{}
    $controller|Add-Member ScriptMethod RecordHistoryRead {param($senderRole,$sendOrdinal,$recipientRole,$readOrdinal) $script:unitReadRecords++}
    $controller|Add-Member ScriptMethod HasRecipientObservation {param($senderRole,$sendOrdinal,$recipientRole) return $true}
    $scheduler=@($ast.FindAll({param($node) $node -is [Management.Automation.Language.ForEachStatementAst] -and
        $node.Variable.Extent.Text -ceq '$role' -and $node.Condition.Extent.Text -ceq '$recipients' -and $node.Extent.Text.Contains('$watch.ElapsedMilliseconds -ge $nextEmptyPoll[$role]')},$true))
    Require ($scheduler.Count -eq 1) 'One actual candidate receiver scheduler required.'
    $recipients=@(2);$conversation='private-conversation';$group='private-group';$networkArgs=@('--bootstrap','unit','--registry','unit');$script:unitPhases=[Collections.Generic.List[string]]::new()
    function Start-Command($role,$phase,$arguments){$script:unitPhases.Add($phase);$pending[$role]=[pscustomobject]@{Phase=$phase}}
    function Complete-Command($role,$budget){$pending.Remove($role);return $script:unitResult}
    function Complete-Phase([string]$phase,$result){
        $script:unitResult=$result
        $pending[2]=[pscustomobject]@{Phase=$phase;Handle=[pscustomobject]@{Read=[Threading.Tasks.Task]::CompletedTask;CommandOrdinal=20}}
        . ([scriptblock]::Create($completion[0].Extent.Text))
    }
    Complete-Phase 'receive' ([pscustomobject]@{status='received';processed=1;hasMore=$false;acknowledgementPending=$true})
    Require ($awaitingAck[2] -and -not $readBeforeAck[2] -and $receivedPending[2] -eq 1 -and $pages[2] -eq 1) 'Ordinary receive must retain its exact page for read before ACK.'
    . ([scriptblock]::Create($scheduler[0].Extent.Text))
    Require ($script:unitPhases[-1] -ceq 'history-read') 'Deferred receive must schedule ordinary recent before sync.'
    $history=[pscustomobject]@{status='ok';items=@([pscustomobject]@{text=$text;local=$false})}
    Complete-Phase 'history-read' $history
    Require ($historyRead[2] -and $readBeforeAck[2] -and $awaitingAck[2] -and $script:unitReadRecords -eq 1) 'Ordinary first recent result must be timed before ACK.'
    . ([scriptblock]::Create($scheduler[0].Extent.Text))
    Require ($script:unitPhases[-1] -ceq 'ack-drain') 'First ordinary read must schedule the real exact page ACK.'
    Complete-Phase 'ack-drain' ([pscustomobject]@{status='ok';processed=1;tombstones=1;hasMore=$false})
    Require (-not $awaitingAck[2] -and -not $historyValidated[2]) 'Exact sync drain must not substitute for post-ACK content validation.'
    . ([scriptblock]::Create($scheduler[0].Extent.Text))
    Require ($script:unitPhases[-1] -ceq 'history-validation') 'Successful ACK must schedule ordinary content validation.'
    Complete-Phase 'history-validation' $history
    Require ($historyValidated[2] -and $script:unitReadRecords -eq 1) 'Duplicate-free second ordinary read must preserve the first read timestamp.'
    Reject {Complete-Phase 'ack-drain' ([pscustomobject]@{status='ok';processed=2;tombstones=2;hasMore=$false})}
    Reject {Complete-Phase 'history-validation' ([pscustomobject]@{status='ok';items=@($history.items[0],$history.items[0])})}
    $historyRead[2]=$false;$readBeforeAck[2]=$false
    Complete-Phase 'history-read' ([pscustomobject]@{status='ok';items=@()})
    Require (-not $historyRead[2] -and $readBeforeAck[2] -and $script:unitReadRecords -eq 1) 'A prior mailbox page without the target may drain but cannot create a timing sample.'
    $MessageKind='Group';$historyRead[2]=$false;$readBeforeAck[2]=$false;$historyValidated[2]=$false
    Complete-Phase 'receive' ([pscustomobject]@{status='received';processed=1;hasMore=$false;acknowledgementPending=$true})
    $groupHistory=[pscustomobject]@{status='ok';items=@([pscustomobject]@{text=$text;sequence=1L;local=$false})}
    Complete-Phase 'history-read' $groupHistory
    Complete-Phase 'ack-drain' ([pscustomobject]@{status='ok';processed=1;tombstones=1;hasMore=$false})
    Complete-Phase 'history-validation' $groupHistory
    Require ($historyRead[2] -and $historyValidated[2] -and $script:unitReadRecords -eq 2) 'Group receive/read/ACK must preserve exact text/sequence/remote identity.'
    Reject {Test-RecentHistory ([pscustomobject]@{status='ok';items=@([pscustomobject]@{text=$text;sequence=2L;local=$false})}) 1L $text}
}
[pscustomobject]@{passed=$true;checks=$checks;edition=$PSVersionTable.PSEdition;version=$PSVersionTable.PSVersion.ToString();profilesOpened=0;networkCalls=0}|ConvertTo-Json -Compress
