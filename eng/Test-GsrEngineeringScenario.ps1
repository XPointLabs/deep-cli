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
$legacy=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Invoke-ThreeClientGsrE2E.ps1') -Raw
Require ($legacy.Contains('Select-GsrGroupHead') -and $legacy.Contains('Select-GsrRetainedConversation') -and $legacy.Contains('cohortModuleSha256=')) 'Both GSR drivers must use the captured pure selectors.'
[pscustomobject]@{passed=$true;checks=$checks;edition=$PSVersionTable.PSEdition;version=$PSVersionTable.PSVersion.ToString();profilesOpened=0;networkCalls=0}|ConvertTo-Json -Compress
