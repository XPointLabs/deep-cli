[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$scenario = Join-Path $PSScriptRoot 'Invoke-ContactTextE2E.ps1'
$tokens = $null; $errors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($scenario, [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw 'Contact/text scenario has parser errors.' }
foreach ($switches in @(@{}, @{ReusePublishedAccounts=$true}, @{ResumeContact=$true})) {
    $run = Join-Path (Split-Path $PSScriptRoot -Parent) ('artifacts/unused-scenario-guard-' + [Guid]::NewGuid().ToString('N'))
    $rejected = $false
    try {
        & $scenario -BootstrapDirectory 'must-never-be-opened' -RegistryOrigin 'https://localhost:1/' `
            -RunDirectory $run -TextRevision 1 @switches
    } catch {
        if ($_.Exception.Message -cne 'New regression texts require the already accepted retained pair.') { throw }
        $rejected = $true
    }
    if (-not $rejected -or (Test-Path -LiteralPath $run)) { throw 'Unsafe regression scheduling was not rejected before I/O.' }
}
[pscustomobject]@{passed=4;failed=0;cliProcesses=0;networkUsed=$false} | ConvertTo-Json -Compress
