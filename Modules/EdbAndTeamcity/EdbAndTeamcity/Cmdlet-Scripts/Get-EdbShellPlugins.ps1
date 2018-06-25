Function Get-EdbShellPlugins{
<#
.SYNOPSIS
Fetches ShellPlugin definitions from EDB
 
.DESCRIPTION
Fetches ShellPlugin definitions from EDB
 
.PARAMETER Server
The EDB server hostname or IP address

.EXAMPLE
PS C:\> Get-EdbShellPlugins

.EXAMPLE
PS C:\> Get-EdbShellPlugins -server edb.cityindex.co.uk
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

		$edbURL = "http`://$Server/ApplicationData.svc/ShellPlugins"
		$result = Invoke-RestMethod -Credential $Global:EDBAndTeamcityCredential -Uri $edbURL -Headers @{ "Accept" = "application/json" }
		return $result.value
	}
}