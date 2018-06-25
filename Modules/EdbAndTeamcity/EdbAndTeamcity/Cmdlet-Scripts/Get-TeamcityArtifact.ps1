#
# Get_TeamcityArtifact.ps1
#
Function Get-TeamcityArtifact{
<#
.SYNOPSIS
Fetches artifact from teamcity
 
.DESCRIPTION
Fetches artifact from teamcity

.PARAMETER TeamcityServer
The teamcity server hostname or IP address

.PARAMETER ChangesetId
The teamcity changeset id

.EXAMPLE
PS C:\> Get-TeamcityArtifact -ChangesetId 1
 
.EXAMPLE
PS C:\> Get-TeamcityArtifact -server teamcity.cityindex.co.uk -ChangesetId 1
#>
 
[CmdletBinding()]
param(
[Parameter(Position=0,Mandatory=$false,HelpMessage="Specify Teamcity Server.",
ValueFromPipeline=$false,ValueFromPipelineByPropertyName=$true)]
[String]
$teamcityServer="teamcity.cityindex.co.uk",

[Parameter(Position=1,Mandatory=$true,HelpMessage="The Teamcity changeset id.",
ValueFromPipeline=$false,ValueFromPipelineByPropertyName=$true)]
[int]
$changesetId
) 
	process 
	{
		if (!($Global:EDBAndTeamcityCredential))
		{
			$cred = Get-Credential -Message "Please supply domain credential for EDB/Teamcity"
			Set-Variable -Name "EDBAndTeamcityCredential" -Value $cred -Scope Global
		}

		$teamcityUrl = "http`://{0}/httpAuth/app/rest/builds/id:{1}/artifacts/children"
		$url = [string]::Format($teamcityUrl, $teamcityServer, $changesetId)
		$returnObj = @{}
		$returnObj.DownloadUrl = $null
		$returnObj.TeamcityFile = $null

		try {
			$result = Invoke-RestMethod -Uri $url -Credential $Global:EDBAndTeamcityCredential -Headers @{ "Accept" = "application/json" }
			if($result.Count -eq 0)	{				
				return $returnObj
			}
			else {
				$url = "http`://$teamcityServer" + $result.file.content.href
				Write-Debug "Got teamcity download url $url"
				$returnObj.DownloadUrl = $url
				$returnObj.TeamcityFile = $result.file.name
			}
		}
		catch
		{
			$errorResult = $_.Exception.Response
			if($errorResult.StatusCode -eq [system.net.httpstatuscode]::NotFound) {
				Write-Debug "Teamcity returned 404 HttpStatusCode.NotFound for url $url"
				return $returnObj
			}

			$errorStream = $errorResult.GetResponseStream()
			$reader = New-Object System.IO.StreamReader($errorStream)
			$reader.BaseStream.Position = 0
			$reader.DiscardBufferedData()
			$body = $reader.ReadToEnd();
			$errorStatus = [int]$errorResult.StatusCode
			Write-Error "Error $errorStatus contacting teamcity - $body"
		}
		return $returnObj
	}
}		