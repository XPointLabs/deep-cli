[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$scenario = Join-Path $PSScriptRoot 'Invoke-ThreeClientGsrE2E.ps1'
$tokens = $null; $errors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile($scenario, [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw 'Scenario syntax errors.' }
$round = @($ast.ParamBlock.Parameters | Where-Object { $_.Name.VariablePath.UserPath -ceq 'SteadyStateRound' })
$range = @($round.Attributes | Where-Object { $_.TypeName.Name -ceq 'ValidateRange' })
if ($round.Count -ne 1 -or $range.Count -ne 1 -or
    $range[0].PositionalArguments[0].SafeGetValue() -ne 0 -or
    $range[0].PositionalArguments[1].SafeGetValue() -ne 63) { throw 'Retained diagnostic round range changed.' }
$parameter = @($ast.ParamBlock.Parameters | Where-Object { $_.Name.VariablePath.UserPath -ceq 'DeliveryOnly' })
if ($parameter.Count -ne 1 -or $null -ne $parameter[0].DefaultValue -or
    $parameter[0].StaticType -ne [Management.Automation.SwitchParameter]) { throw 'Delivery-only must remain explicit and disabled by default.' }
$source = Get-Content -LiteralPath $scenario -Raw
if (-not $source.Contains('deliveryLatencyQualified=($passed -and $DeliveryOnly -and -not $RecoverIncompleteSteadyRound)') -or
    -not $source.Contains('recoveryDeliveryQualified=($passed -and $RecoverIncompleteSteadyRound -and $DeliveryOnly)') -or
    -not $source.Contains('steadyStateQualified=($passed -and $SteadyStateRound -gt 0 -and -not $RecoverIncompleteSteadyRound -and -not $DeliveryOnly)')) {
    throw 'Delivery-only cannot qualify the full steady-state lane.'
}
$expected = 'Delivery-only requires retained steady accounts; recovery is never first-attempt or full qualification.'
$cases = @(
    @{SteadyStateRound=0; ReusePublishedAccounts=$true},
    @{SteadyStateRound=0; ReusePublishedAccounts=$true; RequireFirstAttempt=$true}
)
foreach ($case in $cases) {
    $failure = $null
    try {
        & $scenario -DeliveryOnly @case -BootstrapDirectory '__scope_test_missing_bootstrap__' -RegistryOrigin 'https://localhost/' -RunDirectory '__scope_test_never_create__'
    } catch { $failure = $_.Exception.Message }
    if ($failure -cne $expected) { throw 'Invalid scope did not reject before bootstrap/profile access.' }
}
$failure = $null
try {
    & $scenario -DeliveryOnly -RecoverIncompleteSteadyRound -SteadyStateRound 1 -ReusePublishedAccounts `
        -BootstrapDirectory '__scope_test_missing_bootstrap__' -RegistryOrigin 'https://localhost/' -RunDirectory '__scope_test_never_create__'
} catch { $failure = $_.Exception.Message }
if ($failure -cne 'Fresh artifact directory and distinct isolated profiles required.') {
    throw 'Explicit delivery recovery did not reach the artifact guard before bootstrap/profile access.'
}
$published = @($ast.ParamBlock.Parameters | Where-Object { $_.Name.VariablePath.UserPath -ceq 'ExecutablePath' })
if ($published.Count -ne 1 -or $null -ne $published[0].DefaultValue) { throw 'Published runtime selection must remain explicit.' }
$failure = $null
try {
    & $scenario -ExecutablePath (Join-Path $PSScriptRoot '../src/Deep.Cli/bin/Release/net10.0-windows/deep.exe') `
        -BootstrapDirectory '__scope_test_missing_bootstrap__' -RegistryOrigin 'https://localhost/' `
        -RunDirectory (Join-Path $PSScriptRoot '../artifacts/__scope_test_never_create__')
} catch { $failure = $_.Exception.Message }
if ($failure -cne 'Published executable must be an existing deep.exe inside this CLI repository artifacts directory.') {
    throw 'Explicit published executable escaped the artifacts boundary or accessed bootstrap.'
}
$repair = Join-Path $PSScriptRoot 'Invoke-ContactRouteRepair.ps1'
$failure = $null
try {
    & $repair -ExecutablePath (Join-Path $PSScriptRoot '../src/Deep.Cli/bin/Release/net10.0-windows/deep.exe') `
        -BootstrapDirectory '__scope_test_missing_bootstrap__' -RegistryOrigin 'https://localhost/' `
        -RunDirectory (Join-Path $PSScriptRoot '../artifacts/__scope_test_never_create__') `
        -PublisherProfile 'cli-scope-a' -RecipientProfiles 'cli-scope-b'
} catch { $failure = $_.Exception.Message }
if ($failure -cne 'Published repair executable must be an existing deep.exe inside this CLI repository artifacts directory.') {
    throw 'Explicit repair executable escaped artifacts or accessed bootstrap/profile state.'
}
[pscustomobject]@{passed=$true;scopeChecks=9;edition=$PSVersionTable.PSEdition;version=$PSVersionTable.PSVersion.ToString()} | ConvertTo-Json -Compress
