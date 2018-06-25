Function Get-EdbWinServices{
<#
.SYNOPSIS
Fetches WindowsServices from EDB
 
.DESCRIPTION
Fetches WindowsServices from EDB
 
.PARAMETER Server
The EDB server hostname or IP address

.EXAMPLE
PS C:\> Get-EdbWinServices

.EXAMPLE
PS C:\> Get-EdbWinServices -server edb.cityindex.co.uk

.EXAMPLE
PS C:\> Get-EdbWinServices -server edb.cityindex.co.uk | ft -Property Id,Name,PackageName
#>
 
[CmdletBinding()]
param(
[Parameter(Position=0,Mandatory=$false,HelpMessage="Specify EDB Server.",
ValueFromPipeline=$false,ValueFromPipelineByPropertyName=$true)]
[String]
$Server="edb.cityindex.co.uk"
) 
	process 
	{
		if (!($Global:EDBAndTeamcityCredential))
		{
			$cred = Get-Credential -Message "Please supply domain credential for EDB/Teamcity"
			Set-Variable -Name "EDBAndTeamcityCredential" -Value $cred -Scope Global
		}

		$edbURL = "http`://$Server/ApplicationData.svc/WindowsServices"
		$result = Invoke-RestMethod -Credential $Global:EDBAndTeamcityCredential -Uri $edbURL -Headers @{ "Accept" = "application/json" }
		return $result.value
	}
}