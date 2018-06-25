Function Get-EdbWinServicesServerDeployedOn{
<#
.SYNOPSIS
Fetches WinServices info from EDB
 
.DESCRIPTION
Fetches WinServices info from EDB
 
.PARAMETER Server
The EDB server hostname or IP address

.PARAMETER WebServiceId
The EDB Id corresponding to a particular Genesis windows service

.EXAMPLE
PS C:\> Get-EdbWinServicesServerDeployedOn -WinServiceId 1
 
.EXAMPLE
PS C:\> Get-EdbWinServicesServerDeployedOn -server edb.cityindex.co.uk -WinServiceId 1
#>
 
[CmdletBinding()]
param(
[Parameter(Position=0,Mandatory=$false,HelpMessage="Specify EDB Server.",
ValueFromPipeline=$false,ValueFromPipelineByPropertyName=$true)]
[String]
$Server="edb.cityindex.co.uk",

[Parameter(Position=1,Mandatory=$true,HelpMessage="The EDB Id corresponding to a particular Genesis win service.",
ValueFromPipeline=$false,ValueFromPipelineByPropertyName=$true)]
[int]
$winServiceId
) 
	process 
	{
		if (!($Global:EDBAndTeamcityCredential))
		{
			$cred = Get-Credential -Message "Please supply domain credential for EDB/Teamcity"
			Set-Variable -Name "EDBAndTeamcityCredential" -Value $cred -Scope Global
		}

		$edbURL = "http`://$Server/ApplicationData.svc/WindowsServices($winServiceId)/ServerWindowsServices"
		$result = Invoke-RestMethod -Credential $Global:EDBAndTeamcityCredential -Uri $edbURL -Headers @{ "Accept" = "application/json" }
		return $result.value
	}
}
