Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Private redirected stdio only. Callers own the serial request order and must
# dispose every host. Neither arguments nor raw response frames are logged here.
function New-CliSession {
    param([string]$Executable,[string]$Profile,[string]$Network,[string]$Bootstrap,[string]$Registry)
    $start = [Diagnostics.ProcessStartInfo]::new($Executable)
    $start.UseShellExecute=$false; $start.CreateNoWindow=$true
    $start.RedirectStandardInput=$true; $start.RedirectStandardOutput=$true; $start.RedirectStandardError=$true
    foreach($arg in @('session','run','--profile',$Profile,'--network',$Network,'--bootstrap',$Bootstrap,'--registry',$Registry)) { [void]$start.ArgumentList.Add($arg) }
    $process=[Diagnostics.Process]::new(); $process.StartInfo=$start
    try {
        if(-not $process.Start()) { throw 'Session host not started.' }
        return [pscustomobject]@{Process=$process;ErrorDrain=$process.StandardError.ReadToEndAsync()}
    } catch { $process.Dispose(); throw }
}

function Invoke-CliSession {
    param($Session,[string[]]$Arguments,[int]$BudgetMilliseconds)
    $process=$Session.Process
    if($process.HasExited) { throw 'Session host exited; no implicit restart or retry.' }
    $before=$process.TotalProcessorTime.TotalMilliseconds
    $frame=ConvertTo-Json -InputObject @($Arguments) -Compress
    if($frame.Length -gt 65536) { throw 'Session command exceeds frame bound.' }
    $process.StandardInput.WriteLine($frame); $process.StandardInput.Flush()
    $read=$process.StandardOutput.ReadLineAsync()
    if(-not $read.Wait($BudgetMilliseconds)) { $process.Kill($true); throw 'Session command deadline; original work retained.' }
    $raw=$read.GetAwaiter().GetResult()
    if($null -eq $raw -or $raw.Length -gt 1048576) { throw 'Session response missing or oversized.' }
    $response=$raw|ConvertFrom-Json
    $process.Refresh()
    return [pscustomobject]@{ExitCode=[int]$response.exitCode;Result=$response.result;ProcessorMilliseconds=[long]($process.TotalProcessorTime.TotalMilliseconds-$before)}
}

function Close-CliSession {
    param($Session)
    $process=$Session.Process
    try {
        if(-not $process.HasExited) {
            $process.StandardInput.Close()
            if(-not $process.WaitForExit(10000)) { $process.Kill($true); throw 'Idle session did not stop after EOF.' }
        }
        if($process.ExitCode -ne 0 -or $Session.ErrorDrain.GetAwaiter().GetResult().Length -ne 0) { throw 'Session host closed abnormally.' }
    } finally { $process.Dispose() }
}

Export-ModuleMember -Function New-CliSession,Invoke-CliSession,Close-CliSession
