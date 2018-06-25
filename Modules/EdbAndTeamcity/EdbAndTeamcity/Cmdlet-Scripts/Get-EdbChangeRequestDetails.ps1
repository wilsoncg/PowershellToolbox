Function Get-EdbChangeRequestDetails{
<#
.SYNOPSIS
Fetches ChangeRequest details from EDB
 
.DESCRIPTION
Fetches ChangeRequest details from EDB
 
.PARAMETER Server
The EDB server hostname or IP address

.PARAMETER CRNumber
Specified as RELEASE-XXXX or as XXXX (for pre JIRA releases). Basically, the CRNumber field as it's set in EDB.

.EXAMPLE
PS C:\> Get-EdbChangeRequestDetails

.EXAMPLE
PS C:\> Get-EdbChangeRequestDetails -server edb.cityindex.co.uk -CRNumber RELEASE-1000
#>
 
[CmdletBinding()]
param(
	[Parameter(Position=0,Mandatory=$false,HelpMessage="Specify EDB Server.",
	ValueFromPipeline=$false,ValueFromPipelineByPropertyName=$true)]
	[String]
	$Server="edb.cityindex.co.uk",
	[Parameter(Mandatory=$true,HelpMessage="CRNumber")]
	[String]
	$CRNumber
) 
	process 
	{
		if (!($Global:EDBAndTeamcityCredential))
		{
			$cred = Get-Credential -Message "Please supply domain credential for EDB/Teamcity"
			Set-Variable -Name "EDBAndTeamcityCredential" -Value $cred -Scope Global
		}

		function edbGetData($url)
		{
			$result = Invoke-RestMethod -Credential $Global:EDBAndTeamcityCredential -Uri $url -Headers @{ "Accept" = "application/json" }
			return $result.value
		}
		
		$crsCollection = edbGetData "http`://$Server/ApplicationData.svc/ChangeRequests"
		
		$crId =
			$crsCollection | 
			Select-Object -Property CRNumber, Id |
			Where-Object { $_.CRNumber -like $CRNumber } |
			Select -First 1 |
			Select-Object -ExpandProperty Id

		$crDetails = edbGetData "http`://$Server/ApplicationData.svc/ChangeRequests($crId)/DeploymentSteps"
		return $crDetails
	}
}