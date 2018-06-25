function Get-ScriptDirectory {
    #Split-Path -Parent $PSCommandPath
	Split-Path -Parent $script:MyInvocation.MyCommand.Definition
}
$wmdir = Get-ScriptDirectory
Write-Output $wmdir
$commandPath = [Environment]::GetEnvironmentVariable('java_home') | Join-Path -ChildPath java.exe
$wiremockArgs = "-cp $wmdir\wiremock-body-transformer-1.1.5.jar;$wmdir\wiremock-2.5.0-standalone.jar;$wmdir\slf4j-simple-1.7.16.jar com.github.tomakehurst.wiremock.standalone.WireMockServerRunner --verbose --extensions com.opentable.extension.BodyTransformer --root-dir $wmdir > c:\logs\wiremock.log"

Write-Output "Wiremock running on http://localhost:8080 (default)"
Write-Output "View mappings using swagger http://localhost:8080/__admin/swagger-ui/"
Write-Output "View wiremock log in c:\logs\wiremock.log"

Write-Host "Starting..."
Start-Process $commandPath -WorkingDirectory $wmdir -ArgumentList "$wiremockArgs"
