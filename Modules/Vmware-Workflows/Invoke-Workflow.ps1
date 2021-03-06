Function Invoke-Workflow{
<#
.SYNOPSIS
Runs vCO Workflow on a vCenter Orchestrator server
 
.DESCRIPTION
Runs vCO Workflow on a vCenter Orchestrator server
 
.PARAMETER Server
The vCO server hostname or IP address
 
.PARAMETER PortNumber
The port to connect on

.PARAMETER VMName
The hostname to be given to the newly created VM

.PARAMETER VmwareGroup
The group to which the resource pool and folder belong. E.g Payment, MetaTrader, CoreDEV, QA
 
.EXAMPLE
PS C:\> Invoke-Workflow -WorkflowId 12345 -VMName PKH-DEV-abc123

.EXAMPLE
PS C:\> Invoke-Workflow -Server 192.168.60.172 -PortNumber 8281 -WorkflowId 12345 -VMName PKH-DEV-abc123 -VmwareGroup Payment
#>
 
[CmdletBinding()]
param(
[Parameter(Position=0,Mandatory=$false,
ValueFromPipeline=$false,ValueFromPipelineByPropertyName=$true)]
[String]
$Server="192.168.152.145",
 
[Parameter(Position=1,Mandatory=$false,
ValueFromPipeline=$false,ValueFromPipelineByPropertyName=$true)]
[ValidateRange(0,65535)] 
[Int]
$PortNumber=8281,

[Parameter(Position=2,Mandatory=$true,
ValueFromPipeline=$false,ValueFromPipelineByPropertyName=$true)]
[String]
$workflowId,

[Parameter(Position=3,Mandatory=$true,
ValueFromPipeline=$false,ValueFromPipelineByPropertyName=$true)]
[String]
$vmName,

[Parameter(Position=4,Mandatory=$true)]
[ValidateSet('Payment','MetaTrader','CoreDEV','QA','WebDEV')]
[String]
$vmwareGroup
)
 
process 
{
	if (!($Global:VmwareWorkflowsCredential))
	{
		$cred = Get-Credential -Message "Please supply domain credential for Vmware"
		Set-Variable -Name "VmwareWorkflowsCredential" -Value $cred -Scope Global
	}
	 
	# Craft our URL and encoded details note we escape the colons with a backtick.
	$vCoURL = "https`://$Server`:$PortNumber/vco/api/workflows/$workflowId/executions"
	 
	# Ignore SSL warning
	[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

	$vmoIds = 
	@{
		Payment = @{ ResourcePool='resgroup-985'; Folder='group-v324' }
		MetaTrader = @{ ResourcePool='resgroup-983'; Folder='group-v224' }
		CoreDEV = @{ ResourcePool='resgroup-979'; Folder='group-v81' }
		QA = @{ ResourcePool='resgroup-988'; Folder='group-v185' }
		WebDEV = @{ ResourcePool='resgroup-990'; Folder='group-v82' }
	}

	# to find object ids
	# $vmo = New-WebServiceProxy -Uri "https`://$Server`:$PortNumber/vco/vmware-vmo-webcontrol/webservice?WSDL"
	# $user = $credential.GetNetworkCredential().UserName
	# $pass = $credential.GetNetworkCredential().Password
	# $vmo.find("VC:ResourcePool","xpath:name='MetaTrader'",$user,$pass)

	$resourcePool = $vmoIds[$vmwareGroup]['ResourcePool']
	$folder = $vmoIds[$vmwareGroup]['Folder']
	$postData = @"
	{ 
		"parameters": [
		{
			"name": "name", 
			"type": "string", 
			"scope": "local", 
			"value": {
				"string": { "value": "$vmName" }
			}
		},
		{
			"name": "RequestedMemory", 
			"type": "number", 
			"scope": "local", 
			"value": {
				"number": { "value": "8192" }
			}
		},
		{
			"name": "ResourcePool",
			"type": "VC:ResourcePool",
			"scope": "local",
			"value": {
				"sdk-object": { 
					"type": "VC:ResourcePool",
					"id": "pkh-srv-vc02/$resourcePool"
				}
			}
		},
		{
			"name": "Folder",
			"type": "VC:VmFolder",
			"scope": "local",
			"value": {
				"sdk-object": { 
					"type": "VC:VmFolder",
					"id": "pkh-srv-vc02/$folder"
				}
			}
		}]
	}
"@
	Write-Verbose "posturl = $vcoURL"
	Write-Verbose "postdata = $postData"
	[Microsoft.PowerShell.Commands.WebResponseObject]$result = try { 
	Invoke-WebRequest $vCoURL -Credential $Global:VmwareWorkflowsCredential -Method Post -Body $postData -ContentType "application/json"
	[System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null
	} 
	catch 
	{
		Write-Error $_.Exception
	}
	if($result.StatusCode -eq 202)
	{
		$location = $result.Headers.Get_Item("Location")
		$uri = [System.Uri]$location
		$executionId = $uri.Segments[-1].Trim('/')
		Write-Host "Workflow started successfully for VM $vmName with execution id $executionId" 
		return $executionId
	}
	return ""
}
}