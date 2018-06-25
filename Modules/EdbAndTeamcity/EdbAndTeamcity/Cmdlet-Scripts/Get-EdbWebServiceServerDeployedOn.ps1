Function Get-EdbWebServiceServerDeployedOn{
<#
.SYNOPSIS
Fetches WebServices from EDB
 
.DESCRIPTION
Fetches WebServices from EDB
 
.PARAMETER Server
The EDB server hostname or IP address

.PARAMETER WebServiceId
The EDB Id corresponding to a particular Genesis web service

.EXAMPLE
PS C:\> Get-EdbWebServiceServerDeployedOn -WebServiceId 1

.EXAMPLE
PS C:\> Get-EdbWebServiceServerDeployedOn -server edb.cityindex.co.uk -WebServiceId 1
#>
 
[CmdletBinding()]
param(
[Parameter(Position=0,Mandatory=$false,HelpMessage="Specify EDB Server.",
ValueFromPipeline=$false,ValueFromPipelineByPropertyName=$true)]
[String]
$Server="edb.cityindex.co.uk",

[Parameter(Position=1,Mandatory=$true,HelpMessage="The EDB Id corresponding to a particular Genesis web service.",
ValueFromPipeline=$false,ValueFromPipelineByPropertyName=$true)]
[int]
$webServiceId
) 
	process 
	{
		if (!($Global:EDBAndTeamcityCredential))
		{
			$cred = Get-Credential -Message "Please supply domain credential for EDB/Teamcity"
			$Global:EDBAndTeamcityCredential = $cred
		}

		$edbURL = "http`://$Server/ApplicationData.svc/WebServices($webServiceId)/ServerWebServices"
		$result = Invoke-RestMethod -Credential $Global:EDBAndTeamcityCredential -Uri $edbURL -Headers @{ "Accept" = "application/json" }
		return $result.value
	}
}