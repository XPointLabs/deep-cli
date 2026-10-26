[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('aggregate','manifest')][string]$Provider,
    [Parameter(Mandatory)][string]$RuntimeDirectory,
    [Parameter(Mandatory)][string]$RunDirectory
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if(-not $IsWindows -or $PSVersionTable.PSVersion.ToString() -cne '7.6.5' -or [Environment]::Version.Major -ne 10){
    throw 'A fresh Windows PowerShell7.6.5/.NET10 process is required.'
}
if(@([AppDomain]::CurrentDomain.GetAssemblies()|Where-Object {$_.GetName().Name -eq 'Deep.Client.Shared'}).Count){
    throw 'Start a fresh process for each exact provider runtime.'
}
$repo=Split-Path $PSScriptRoot -Parent
$artifacts=[IO.Path]::GetFullPath((Join-Path $repo 'artifacts'))+[IO.Path]::DirectorySeparatorChar
$runtime=[IO.Path]::GetFullPath($RuntimeDirectory).TrimEnd([IO.Path]::DirectorySeparatorChar)
$run=[IO.Path]::GetFullPath($RunDirectory)
if(-not $runtime.StartsWith($artifacts,[StringComparison]::OrdinalIgnoreCase) -or
   -not $run.StartsWith($artifacts,[StringComparison]::OrdinalIgnoreCase) -or
   -not(Test-Path -LiteralPath $runtime -PathType Container) -or (Test-Path -LiteralPath $run)){
    throw 'Existing archived runtime and fresh receipt must remain inside CLI artifacts.'
}
function Require-Ordinary([string]$path){
    for($cursor=$path;$cursor;$cursor=[IO.Path]::GetDirectoryName($cursor)){
        if((Test-Path -LiteralPath $cursor) -and ((Get-Item -LiteralPath $cursor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)){
            throw 'Linked benchmark input rejected.'
        }
    }
}
Require-Ordinary $runtime;Require-Ordinary $run
$helper=Join-Path $PSScriptRoot 'SecureStorageProviderBenchmark.cs'
$sourcePaths=@($PSCommandPath,$helper)
$sourceHashes=@($sourcePaths|ForEach-Object {(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash})
function Runtime-Inventory {
    $pending=[Collections.Generic.Stack[string]]::new();$pending.Push($runtime)
    $files=[Collections.Generic.List[object]]::new()
    while($pending.Count){foreach($entry in (Get-Item -LiteralPath $pending.Pop() -Force).EnumerateFileSystemInfos()){
        if($entry.Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Linked runtime entry rejected.'}
        if($entry.Attributes -band [IO.FileAttributes]::Directory){$pending.Push($entry.FullName)}
        else{$files.Add($entry);if($files.Count -gt 2048){throw 'Runtime inventory exceeds its bound.'}}
    }}
    if($files.Count -lt 3){throw 'Complete runtime inventory required.'}
    @($files|Sort-Object FullName -CaseSensitive|ForEach-Object {
        [pscustomobject]@{path=$_.FullName.Substring($runtime.Length+1).Replace('\','/');sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash}
    })
}
$before=@(Runtime-Inventory)
foreach($name in @('deep.dll','Deep.Client.Shared.dll')){
    if(-not(Test-Path -LiteralPath (Join-Path $runtime $name) -PathType Leaf)){throw 'Exact managed runtime is incomplete.'}
}
[void][IO.Directory]::CreateDirectory($run)
foreach($path in $sourcePaths){Copy-Item -LiteralPath $path -Destination (Join-Path $run ([IO.Path]::GetFileName($path)))}
$before|ConvertTo-Json -Depth 4|Set-Content -LiteralPath (Join-Path $run 'runtime.before.json') -Encoding utf8
$temporary=Join-Path ([IO.Path]::GetTempPath()) ('deep-storage-provider-'+[Guid]::NewGuid().ToString('N'))
$passed=$false;$failure='None';$inputsUnchanged=$false;$phase='Compilation';$compilationFailure=$null
try{
    $shared=Join-Path $runtime 'Deep.Client.Shared.dll'
    [void][Reflection.Assembly]::LoadFrom($shared)
    # Add-Type needs reference assemblies rather than mixing runtime type
    # forwarders from the hosting process's trusted-platform inventory.
    $references=@((Get-ChildItem -LiteralPath (Join-Path $PSHOME 'ref') -Filter '*.dll' -File).FullName)+@($shared)
    Add-Type -Path $helper -ReferencedAssemblies $references -CompilerOptions @('/nullable:enable','/langversion:latest')
    $phase='ProviderExecution'
    $json=[Deep.Cli.Engineering.SecureStorageProviderBenchmark]::RunAsync($Provider,$runtime,$temporary).GetAwaiter().GetResult()
    $result=$json|ConvertFrom-Json
    $json|Set-Content -LiteralPath (Join-Path $run 'measurements.json') -Encoding utf8
    $passed=[bool]$result.passed -and $result.completedRows -eq $result.plannedRows -and $result.plannedRows -eq 141
    if(-not $passed){$failure='ProviderBenchmarkRejected'}
}catch{
    $failure=if($phase -ceq 'Compilation'){'CompilationRejected'}else{'ProviderExecutionRejected'}
    if($phase -ceq 'Compilation'){$compilationFailure=$_}
}
finally{
    try{
        $after=@(Runtime-Inventory)
        $after|ConvertTo-Json -Depth 4|Set-Content -LiteralPath (Join-Path $run 'runtime.after.json') -Encoding utf8
        $inputsUnchanged=($before|ConvertTo-Json -Depth 4 -Compress) -ceq ($after|ConvertTo-Json -Depth 4 -Compress)
        for($i=0;$i -lt $sourcePaths.Count;$i++){
            if((Get-FileHash -LiteralPath $sourcePaths[$i] -Algorithm SHA256).Hash -cne $sourceHashes[$i]){$inputsUnchanged=$false}
        }
    }catch{$inputsUnchanged=$false}
    $passed=$passed -and $inputsUnchanged
    [ordered]@{schema='deep.cli.storage-provider-benchmark-terminal.v1';provider=$Provider;passed=$passed;failureCode=$failure;
        interpreter=$PSVersionTable.PSVersion.ToString();dotnet=[Environment]::Version.ToString();sourceHashes=$sourceHashes;
        inputsUnchanged=$inputsUnchanged;runtimeFiles=$before.Count;retainedProfilesOpened=$false;
        physicalDiskTrafficMeasured=$false;gateAccepted=$false;providerComparisonQualified=$false;latencyQualified=$false;releaseQualified=$false}|ConvertTo-Json -Depth 4|
        Set-Content -LiteralPath (Join-Path $run 'terminal.json') -Encoding utf8
    Write-Host ([pscustomobject]@{provider=$Provider;passed=$passed;inputsUnchanged=$inputsUnchanged}|ConvertTo-Json -Compress)
}
if($null -ne $compilationFailure){throw $compilationFailure}
if(-not $passed){throw 'Storage provider benchmark rejected; preserve its exact receipt.'}
