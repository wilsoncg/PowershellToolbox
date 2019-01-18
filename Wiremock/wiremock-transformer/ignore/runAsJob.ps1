function Get-ScriptDirectory {
    Split-Path -Parent $PSCommandPath
}
$cdir = Get-ScriptDirectory
$scriptblock = {
    param($wmdir) 
    & java -cp "$wmdir\wiremock-body-transformer-1.1.5.jar;$wmdir\wiremock-2.5.0-standalone.jar;$wmdir\slf4j-simple-1.7.16.jar" com.github.tomakehurst.wiremock.standalone.WireMockServerRunner --verbose --extensions com.opentable.extension.BodyTransformer --root-dir "$wmdir" > c:\logs\wiremock.log
}
start-job -scriptblock $scriptblock -ArgumentList $cdir
Write-Output "Wiremock running on http://localhost:8080 (default)"
Write-Output "View mappings using swagger http://localhost:8080/__admin/swagger-ui/"
Write-Output "View wiremock log in c:\logs\wiremock.log"