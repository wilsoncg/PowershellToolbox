$path = Split-Path ((Get-Variable MyInvocation).Value).MyCommand.Path 
$stdTraceFile = "$path\build-withtrace.ps1"
$stdTraceLog  = Join-Path $path build.log

$SParguments = "-NoProfile -file `"$stdTracefile`""
Start-Process 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -ArgumentList $SParguments -RedirectStandardOutput $stdTracelog