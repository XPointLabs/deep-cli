Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Private redirected stdio only. Callers own the serial request order and must
# dispose every host. Neither arguments nor raw response frames are logged here.
function New-CliSession {
    param([string]$Executable,[string]$Profile,[string]$Network,[string]$Bootstrap,[string]$Registry,
        $DeliveryController,[ValidateRange(0,3)][int]$ControllerRole=0)
    if(($null -eq $DeliveryController) -ne ($ControllerRole -eq 0)){throw 'Delivery controller and distinct role must be supplied together.'}
    $start = [Diagnostics.ProcessStartInfo]::new($Executable)
    $start.UseShellExecute=$false; $start.CreateNoWindow=$true
    $start.RedirectStandardInput=$true; $start.RedirectStandardOutput=$true; $start.RedirectStandardError=$true
    foreach($arg in @('session','run','--profile',$Profile,'--network',$Network,'--bootstrap',$Bootstrap,'--registry',$Registry)) { [void]$start.ArgumentList.Add($arg) }
    if($null -ne $DeliveryController){[void]$start.ArgumentList.Add('--delivery-events');[void]$start.ArgumentList.Add('true')}
    $process=[Diagnostics.Process]::new(); $process.StartInfo=$start
    try {
        if(-not $process.Start()) { throw 'Session host not started.' }
        $drain=if($null -ne $DeliveryController){$DeliveryController.Attach($ControllerRole,$process.StandardError)}else{$process.StandardError.ReadToEndAsync()}
        return [pscustomobject]@{Process=$process;ErrorDrain=$drain;DeliveryController=$DeliveryController;ControllerRole=$ControllerRole;Pending=$null}
    } catch {
        try { if($process.Id -and -not $process.HasExited){$process.Kill($true)} } catch { }
        $process.Dispose(); throw
    }
}

function Invoke-CliSession {
    param($Session,[string[]]$Arguments,[int]$BudgetMilliseconds)
    $pending=Start-CliSessionCommand $Session $Arguments
    return Complete-CliSessionCommand $Session $pending $BudgetMilliseconds
}

# Start is deliberately separate from completion so three existing processes
# can execute their Shared send/receive operations concurrently. No polling,
# retry or business scheduler is implemented by this adapter.
function Start-CliSessionCommand {
    param($Session,[string[]]$Arguments)
    if($null -ne $Session.Pending){throw 'One outstanding command per session is required.'}
    $process=$Session.Process
    if($process.HasExited) { throw 'Session host exited; no implicit restart or retry.' }
    $before=$process.TotalProcessorTime.TotalMilliseconds
    $frame=ConvertTo-Json -InputObject @($Arguments) -Compress
    if($frame.Length -gt 65536) { throw 'Session command exceeds frame bound.' }
    $ordinal=if($null -ne $Session.DeliveryController){$Session.DeliveryController.BeginCommand($Session.ControllerRole)}else{0}
    try {$process.StandardInput.WriteLine($frame); $process.StandardInput.Flush()}
    catch {
        if($null -ne $Session.DeliveryController){$Session.DeliveryController.CompleteCommand($Session.ControllerRole,$ordinal,1)}
        throw
    }
    $pending=[pscustomobject]@{Read=$process.StandardOutput.ReadLineAsync();Before=$before;CommandOrdinal=$ordinal}
    $Session.Pending=$pending
    return $pending
}

function Complete-CliSessionCommand {
    param($Session,$Pending,[int]$BudgetMilliseconds)
    if(-not [object]::ReferenceEquals($Session.Pending,$Pending) -or $BudgetMilliseconds -le 0){throw 'Exact pending command and positive budget required.'}
    $process=$Session.Process;$read=$Pending.Read
    try {
        if(-not $read.Wait($BudgetMilliseconds)) { $process.Kill($true); throw 'Session command deadline; original work retained.' }
        $raw=$read.GetAwaiter().GetResult()
        if($null -eq $raw -or $raw.Length -gt 1048576) { throw 'Session response missing or oversized.' }
        $response=$raw|ConvertFrom-Json
        $responseNames=@($response.PSObject.Properties.Name)
        if($responseNames.Count -ne 2 -or $responseNames -cnotcontains 'exitCode' -or $responseNames -cnotcontains 'result' -or
            ($response.exitCode -isnot [int] -and $response.exitCode -isnot [long]) -or $response.exitCode -lt 0 -or $response.exitCode -gt 255 -or $null -eq $response.result){throw 'Current closed session response required.'}
    }catch{
        if($null -ne $Session.DeliveryController){$Session.DeliveryController.CompleteCommand($Session.ControllerRole,$Pending.CommandOrdinal,1)}
        throw
    }
    if($null -ne $Session.DeliveryController){$Session.DeliveryController.CompleteCommand($Session.ControllerRole,$Pending.CommandOrdinal,[int]$response.exitCode)}
    $Session.Pending=$null
    $process.Refresh()
    return [pscustomobject]@{ExitCode=[int]$response.exitCode;Result=$response.result;CommandOrdinal=$Pending.CommandOrdinal;ProcessorMilliseconds=[long]($process.TotalProcessorTime.TotalMilliseconds-$Pending.Before)}
}

function Close-CliSession {
    param($Session)
    $process=$Session.Process
    try {
        if(-not $process.HasExited) {
            $process.StandardInput.Close()
            if(-not $process.WaitForExit(10000)) { $process.Kill($true); throw 'Idle session did not stop after EOF.' }
        }
        if($null -ne $Session.DeliveryController){
            [void]$Session.ErrorDrain.GetAwaiter().GetResult()
            if($Session.DeliveryController.Rejected){throw 'Delivery event stream rejected; no latency qualification.'}
        }elseif($Session.ErrorDrain.GetAwaiter().GetResult().Length -ne 0){throw 'Session host closed abnormally.'}
        if($process.ExitCode -ne 0){throw 'Session host closed abnormally.'}
    } finally { $process.Dispose() }
}

function New-DeliveryEventController {
    if(-not ('Deep.Cli.Measurement.DeliveryEventController' -as [type])){
        Add-Type -Path (Join-Path $PSScriptRoot 'DeliveryMeasurement.cs')
    }
    return [Deep.Cli.Measurement.DeliveryEventController]::new()
}

Export-ModuleMember -Function New-CliSession,Invoke-CliSession,Start-CliSessionCommand,Complete-CliSessionCommand,Close-CliSession,New-DeliveryEventController
