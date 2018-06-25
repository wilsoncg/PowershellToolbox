Function Set-TeamcityBuildToPinned{
<#
.SYNOPSIS
Set teamcity build to pinned
 
.DESCRIPTION
Set teamcity build to pinned

.PARAMETER TeamcityServer
The teamcity server hostname or IP address

.PARAMETER TeamcityBuildId (also known as the teamcity changeset id in EDB)
The teamcity build id

.EXAMPLE
PS C:\> Set-TeamcityBuildToPinned -TeamcityBuildId 1
 
.EXAMPLE
PS C:\> Set-TeamcityBuildToPinned -server teamcity.cityindex.co.uk -TeamcityBuildId 1
#>
 
[CmdletBinding()]
param(
[Parameter(Position=0,Mandatory=$false,HelpMessage="Specify Teamcity Server.",
ValueFromPipeline=$false,ValueFromPipelineByPropertyName=$true)]
[String]
$teamcityServer="teamcity.cityindex.co.uk",

[Parameter(Position=1,Mandatory=$true,HelpMessage="The Teamcity build id.",
ValueFromPipeline=$false,ValueFromPipelineByPropertyName=$true)]
[int]
$buildId
) 
	process 
	{
		if (!($Global:EDBAndTeamcityCredential))
		{
			$cred = Get-Credential -Message "Please supply domain credential for EDB/Teamcity"
			Set-Variable -Name "EDBAndTeamcityCredential" -Value $cred -Scope Global
		}

		$teamcityUrl = "http`://{0}/httpAuth/app/rest/builds/id:{1}/pin"
		$url = [string]::Format($teamcityUrl, $teamcityServer, $buildId)

		try {
			$dateTime = Get-Date
			$message = "Build pinned by $($Global:EDBAndTeamcityCredential.UserName) on $dateTime"
			$result = Invoke-RestMethod -Uri $url -Credential $Global:EDBAndTeamcityCredential -Headers @{ "Accept" = "application/json" } -Method Put -Body $message
			Write-Verbose $message
		}
		catch
		{
			$errorResult = $_.Exception.Response
			if($errorResult.StatusCode -eq [system.net.httpstatuscode]::NotFound) {
				Write-Warning "Teamcity returned 404 HttpStatusCode.NotFound for url $url"
			}

			$errorStream = $errorResult.GetResponseStream()
			$reader = New-Object System.IO.StreamReader($errorStream)
			$reader.BaseStream.Position = 0
			$reader.DiscardBufferedData()
			$body = $reader.ReadToEnd();
			$errorStatus = [int]$errorResult.StatusCode
			Write-Error "Error $errorStatus contacting teamcity - $body"
		}
	}
}

		