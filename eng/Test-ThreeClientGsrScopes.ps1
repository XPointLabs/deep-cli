[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$scenario = Join-Path $PSScriptRoot 'Invoke-ThreeClientGsrE2E.ps1'
$tokens = $null; $errors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile($scenario, [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw 'Scenario syntax errors.' }
$parameter = @($ast.ParamBlock.Parameters | Where-Object { $_.Name.VariablePath.UserPath -ceq 'DeliveryOnly' })
if ($parameter.Count -ne 1 -or $null -ne $parameter[0].DefaultValue -or
    $parameter[0].StaticType -ne [Management.Automation.SwitchParameter]) { throw 'Delivery-only must remain explicit and disabled by default.' }
$source = Get-Content -LiteralPath $scenario -Raw
if (-not $source.Contains('deliveryLatencyQualified=($passed -and $DeliveryOnly)') -or
    -not $source.Contains('steadyStateQualified=($passed -and $SteadyStateRound -gt 0 -and -not $RecoverIncompleteSteadyRound -and -not $DeliveryOnly)')) {
    throw 'Delivery-only cannot qualify the full steady-state lane.'
}
$expected = 'Delivery-only requires a new retained steady round; recovery and full lifecycle qualification remain separate.'
$cases = @(
    @{SteadyStateRound=0; ReusePublishedAccounts=$true},
    @{SteadyStateRound=1; ReusePublishedAccounts=$true; RecoverIncompleteSteadyRound=$true},
    @{SteadyStateRound=0; ReusePublishedAccounts=$true; RequireFirstAttempt=$true}
)
foreach ($case in $cases) {
    $failure = $null
    try {
        & $scenario -DeliveryOnly @case -BootstrapDirectory '__scope_test_missing_bootstrap__' -RegistryOrigin 'https://localhost/' -RunDirectory '__scope_test_never_create__'
    } catch { $failure = $_.Exception.Message }
    if ($failure -cne $expected) { throw 'Invalid scope did not reject before bootstrap/profile access.' }
}
[pscustomobject]@{passed=$true;scopeChecks=5;edition=$PSVersionTable.PSEdition;version=$PSVersionTable.PSVersion.ToString()} | ConvertTo-Json -Compress
