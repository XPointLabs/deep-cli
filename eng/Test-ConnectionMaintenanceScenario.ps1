[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$scenario=Join-Path $PSScriptRoot 'Invoke-ContactRouteRepair.ps1'
$tokens=$null;$errors=$null
$ast=[System.Management.Automation.Language.Parser]::ParseFile($scenario,[ref]$tokens,[ref]$errors)
if($errors.Count){throw 'Maintenance scenario parser errors.'}
$passed=1
$definition=$ast.Find({param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
    $node.Name -ceq 'Require-ConnectionCycleResult'},$false)
if($null -eq $definition){throw 'Actual cycle-result guard missing.'}
. ([scriptblock]::Create($definition.Extent.Text))
function Result([string]$status='maintained',[int]$accepted=2,[int]$stored=0,[int]$deferred=0,
    [int]$processed=0,[int]$tombstones=0,[bool]$more=$false,[int]$reintroductions=0){
    [pscustomobject]@{status=$status;maintenance=[pscustomobject]@{AcceptedContacts=$accepted;ControlsStored=$stored;
        DeferredContacts=$deferred;ProcessedEnvelopes=$processed;DurableTombstones=$tombstones;HasMore=$more;Reintroductions=$reintroductions}}
}
Require-ConnectionCycleResult (Result) 2 $true;$passed++
Require-ConnectionCycleResult (Result -status partial -stored 1 -deferred 1 -processed 2 -tombstones 2) 2;$passed++
Require-ConnectionCycleResult (Result -status partial -stored 1 -deferred 2 -reintroductions 1) 2;$passed++
Require-ConnectionCycleResult (Result -status partial -accepted 4 -deferred 2) 4 $true $false 2;$passed++
$activation=Result -status ok
$activation|Add-Member networkVerified $true;$activation|Add-Member contactPublished $true
Require-ConnectionCycleResult $activation 2 $false $true;$passed++
$activation.contactPublished=$false
$rejected=$false;try{Require-ConnectionCycleResult $activation 2 $false $true}catch{$rejected=$true}
if(-not $rejected){throw 'Unverified own publication was accepted.'};$passed++
$bad=@((Result -stored -1),(Result -stored 3),(Result -deferred 3),(Result -stored 2 -deferred 1),(Result -reintroductions 1),(Result -reintroductions -1),(Result -processed 1),(Result -more $true),(Result -accepted 1),(Result -status unknown))
foreach($item in $bad){$rejected=$false;try{Require-ConnectionCycleResult $item 2}catch{$rejected=$true};if(-not $rejected){throw 'Invalid owned-cycle counts accepted.'};$passed++}
foreach($item in @((Result -status partial),(Result -stored 1),(Result -deferred 1),(Result -processed 1 -tombstones 1))){
    $rejected=$false;try{Require-ConnectionCycleResult $item 2 $true}catch{$rejected=$true};if(-not $rejected){throw 'Active work labelled quiescent.'};$passed++
}
$run=Join-Path (Split-Path $PSScriptRoot -Parent) ('artifacts/unused-maintenance-guard-'+[Guid]::NewGuid().ToString('N'))
$rejected=$false
try{& $scenario -BootstrapDirectory must-never-be-opened -RegistryOrigin https://localhost:1/ -RunDirectory $run `
    -PublisherProfile unit-left -RecipientProfiles unit-right -ConnectionCycle -Reintroduce}catch{
    if($_.Exception.Message -cne 'Connection cycle cannot import a re-introduction address.'){throw};$rejected=$true
}
if(-not $rejected -or (Test-Path -LiteralPath $run)){throw 'Incompatible cycle mode was not rejected before I/O.'};$passed++
[pscustomobject]@{passed=$passed;failed=0;cliProcesses=0;networkUsed=$false}|ConvertTo-Json -Compress
