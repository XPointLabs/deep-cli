[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$scenario = Join-Path $PSScriptRoot 'Invoke-AttachmentE2E.ps1'
$tokens = $null; $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($scenario, [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw 'Attachment scenario has parser errors.' }
# Load the actual pure selector and identity function, not the scenario body:
# these tests run no CLI, account operation, network or fixture authority.
foreach ($name in @('Select-AcceptedAttachmentConversation','Operation')) {
    $definition = $ast.Find({ param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq $name
    }, $false)
    if ($null -eq $definition) { throw 'Scenario helper missing.' }
    . ([scriptblock]::Create($definition.Extent.Text))
}
function Contact([string]$conversation, [string]$state) { [pscustomobject]@{conversation=$conversation;state=$state} }
$ab = 'a' * 64; $ac = 'b' * 64; $bc = 'c' * 64
$left = [pscustomobject]@{contacts=@((Contact $ab 'PeerAcceptanceRetained'), (Contact $ac 'PeerAcceptanceRetained'))}
$right = [pscustomobject]@{contacts=@((Contact $bc 'LocalAcceptanceRetained'), (Contact $ab 'LocalAcceptanceRetained'))}
if ((Select-AcceptedAttachmentConversation $left $right) -cne $ab) { throw 'Additional contacts changed selected pair.' }
if ((Select-AcceptedAttachmentConversation $right $left) -cne $ab) { throw 'Pair orientation incorrectly constrained.' }
$upper = $ab.ToUpperInvariant()
if ((Select-AcceptedAttachmentConversation ([pscustomobject]@{contacts=@((Contact $upper 'PeerAcceptanceRetained'))}) `
    ([pscustomobject]@{contacts=@((Contact $upper 'LocalAcceptanceRetained'))})) -cne $upper) { throw 'Actual CLI uppercase selector rejected.' }
$badPairs = @(
    @([pscustomobject]@{contacts=@()}, $right),
    @([pscustomobject]@{contacts=@((Contact $ac 'PeerAcceptanceRetained'))}, $right),
    @([pscustomobject]@{contacts=@((Contact $ab 'LocalAcceptanceRetained'))}, $right),
    @([pscustomobject]@{contacts=@((Contact $ab 'PeerAcceptanceRetained'),(Contact $ab 'PeerAcceptanceRetained'))}, $right),
    @($left, [pscustomobject]@{contacts=@((Contact $ab 'LocalAcceptanceRetained'),(Contact $ac 'LocalAcceptanceRetained'))}),
    @([pscustomobject]@{contacts=@((Contact $ab 'Pending'))}, $right),
    @([pscustomobject]@{contacts=@((Contact 'invalid' 'PeerAcceptanceRetained'))}, [pscustomobject]@{contacts=@((Contact 'invalid' 'LocalAcceptanceRetained'))}),
    @([pscustomobject]@{contacts=@((Contact ($ab+"`n") 'PeerAcceptanceRetained'))}, [pscustomobject]@{contacts=@((Contact ($ab+"`n") 'LocalAcceptanceRetained'))})
)
foreach ($pair in $badPairs) {
    $rejected = $false
    try { [void](Select-AcceptedAttachmentConversation $pair[0] $pair[1]) } catch { $rejected = $true }
    if (-not $rejected) { throw 'Ambiguous or unaccepted pair was selected.' }
}
$network = '1' * 32; $AliceProfile = 'unit-left'; $BobProfile = 'unit-right'; $AssetRevision = 0
$purpose = 'file-alice-to-bob/asset'
$expected = [Convert]::ToHexStringLower([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes(
    'Deep/CLI/AttachmentQA/20261018/'+$network+'/'+$AliceProfile+'/'+$BobProfile+'/'+$purpose)))
if ((Operation $purpose) -cne $expected) { throw 'Original operation identity changed.' }
$AssetRevision = 1; $next = Operation $purpose
if ($next -ceq $expected -or $next -cne (Operation $purpose)) { throw 'New explicit asset revision is not stable and distinct.' }
$run = Join-Path (Split-Path $PSScriptRoot -Parent) ('artifacts/unused-attachment-guard-' + [Guid]::NewGuid().ToString('N'))
$rejected = $false
try {
    & $scenario -BootstrapDirectory 'must-never-be-opened' -RegistryOrigin 'https://localhost:1/' `
        -RunDirectory $run -ExecutablePath (Join-Path $PSScriptRoot 'deep.exe')
} catch {
    if ($_.Exception.Message -cne 'Published executable must be an existing deep.exe inside this CLI repository artifacts directory.') { throw }
    $rejected = $true
}
if (-not $rejected -or (Test-Path -LiteralPath $run)) { throw 'Invalid runtime was not rejected before I/O.' }
[pscustomobject]@{passed=15;failed=0;cliProcesses=0;networkUsed=$false} | ConvertTo-Json -Compress
