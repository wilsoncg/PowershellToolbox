Function Get-Workflows{
<#
.SYNOPSIS
Fetches vCO Workflow information and details from a vCenter Orchestrator server
 
.DESCRIPTION
Fetches vCO Workflow information and details from a vCenter Orchestrator server
 
.PARAMETER Server
The vCO server hostname or IP address
 
.PARAMETER PortNumber
The port to connect on
 
.EXAMPLE
PS C:\> Get-Workflows -Server 192.168.60.172 -PortNumber 8281
#>
 
[CmdletBinding()]
param(
[Parameter(Position=0,Mandatory=$false,HelpMessage="Specify your vCO Server or hostname.",
ValueFromPipeline=$false,ValueFromPipelineByPropertyName=$true)]
[String]
$Server="pkh-srv-vc02.cityindex.co.uk",
 
[Parameter(Position=1,Mandatory=$false,HelpMessage="Specify your vCO Port.",
ValueFromPipeline=$false,ValueFromPipelineByPropertyName=$true)]
[ValidateRange(0,65535)] 
[Int]
$PortNumber=8281
)
 
process 
{
	if (!($Global:VmwareWorkflowsCredential))
	{
		$cred = Get-Credential -Message "Please supply domain credential for Vmware"
		Set-Variable -Name "VmwareWorkflowsCredential" -Value $cred -Scope Global
	}
	 
	# Craft our URL and encoded details note we escape the colons with a backtick.
	$vCoURL = "https`://$Server`:$PortNumber/vco/api/workflows"
	$Username = $Global:VmwareWorkflowsCredential.GetNetworkCredential().UserName
	$password = $Global:VmwareWorkflowsCredential.GetNetworkCredential().Password
	$UserPassCombined = "$Username`:$Password"
	$EncodedUsernamePassword = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($UserPassCombined))
	
	Write-Verbose "posturl = $vCoURL"
	$result = try { 
		Invoke-RestMethod $vCoURL -Credential $Global:VmwareWorkflowsCredential -Method Get -ContentType "application/json" -Headers @{"Authorization"="Basic $EncodedUsernamePassword"}
		} 
		catch 
		{
			Write-Error $_.Exception
		}
		
		$Report = @() | out-null
 
		foreach ($link in $result.value.link)
		{
			$kvps = $link.attributes
			$HashTable = @{}
			$kvps | foreach { $HashTable[$_.name] = $_.value } 
			$NewPSObject = New-Object PSObject -Property $HashTable 
		 
			$Report += $NewPSObject
		}
		
		return $Report
}
}
