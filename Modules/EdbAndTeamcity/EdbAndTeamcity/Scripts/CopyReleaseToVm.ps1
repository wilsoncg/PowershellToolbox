<#
.DESCRIPTION
Fetch release ticket information from EDB, download artifacts from teamcity, extract and copy to VM.

.PARAMETER ChangeRequests
Comma seperated list of ChangeRequests in EDB

.PARAMETER VmHostName
VM machine name

.PARAMETER forLiveEdb
For switching to live EDB (defaults to staging EDB instance for QAT/PPE)

.PARAMETER Debug
Provide debug switch for more information while script is running

.EXAMPLE
PS> .\CopyReleaseToVm.ps1 -ChangeRequests RELEASE-12038_Services,RELEASE-12038_Plugins -VmHostName pkh-dev-cw01.cityindex.co.uk -Debug

#>
Param(
    [Parameter(Mandatory=$true)]
  	[string] $VmHostName,
	[Parameter(Mandatory=$true)]
	[string[]] $changeRequests,

	[switch] $forLiveEdb = $false
)
#Requires -Modules EdbAndTeamcity

# Stops annoying confirmation popup when using Write-Debug and -Debug
If ($PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
}

Enum ArtifactType
{
	Webservice = 1
	Plugin = 2
}

$tempPath = "$env:LOCALAPPDATA\Temp"
$edbServer = 'edb-stg.cityindex.co.uk'
if($forLiveEdb -eq $true)
{
	$edbServer = 'edb.cityindex.co.uk'
}

function getWebservicesFromEdb($server)
{
	Write-Debug "Getting WebServices from EDB $server"
	$webServices = 
		Get-EdbWebServices -Server $server |
		Select-Object -Property Id, PackageName, Website
	return $webServices
}

function getShellPluginsFromEdb($server)
{
	Write-Debug "Getting ShellPlugins from EDB $server"
	$plugins = 
		Get-EdbShellPlugins -Server $server |
		Select-Object -Property Id, Name
	return $plugins
}

function getShellPluginNameFromId($plugins, $id)
{
	$plugin = 
		$plugins | 
		Where-Object { $_.Id -eq $id } | 
		Select -First 1	
	Write-Debug "Got PluginName $($plugin.Name) from $id"
	return $plugin.Name
}

function getWebservicePackageNameFromId($services, $id)
{
	$service = 
		$services | 
		Where-Object { $_.Id -eq $id } | 
		Select -First 1
	Write-Debug "Got PackageName $($service.PackageName) from $id"
	return $service.PackageName
}

function getWebserviceNameFromId($services, $id)
{
	$service = 
		$services | 
		Where-Object { $_.Id -eq $id } | 
		Select -First 1
	Write-Debug "Got Website $($service.Website) from $id"
	return $service.Website
}

function getArtifactName($cr, $services, $plugins)
{
	if(!([string]::IsNullOrEmpty($cr.WindowsServiceDeploymentStep_WebService))) {
		return getWebservicePackageNameFromId $services $cr.WindowsServiceDeploymentStep_WebService
	}

	if(!([string]::IsNullOrEmpty($cr.DeploymentStep_ShellPlugin))) {
		return getShellPluginNameFromId $plugins $cr.DeploymentStep_ShellPlugin
	}
}

function getWebsiteName($cr, $services, $plugins)
{
	if(!([string]::IsNullOrEmpty($cr.WindowsServiceDeploymentStep_WebService))) {
		return getWebserviceNameFromId $services $cr.WindowsServiceDeploymentStep_WebService
	}

	return ""
}

function getArtifactType($cr, $services, $plugins)
{
	if(!([string]::IsNullOrEmpty($cr.WindowsServiceDeploymentStep_WebService))) {
		return $([ArtifactType]::Webservice)
	}

	if(!([string]::IsNullOrEmpty($cr.DeploymentStep_ShellPlugin))) {
		return $([ArtifactType]::Plugin)
	}
}

function getCRDetailsFromEdb($server, $CRs)
{
	$services = getWebservicesFromEdb $server
	$plugins = getShellPluginsFromEdb $server
	
	$crDetails = @()
	ForEach ($CR in $CRs.GetEnumerator())
	{
		Write-Host "Getting $CR details from EDB $server"
		$details = 
			Get-EdbChangeRequestDetails -server $server -CRNumber $CR |
			Select-Object -Property SequenceId, WindowsServiceDeploymentStep_WebService, DeploymentStep_ShellPlugin, TeamCityChangeSet, Version, IncludePattern |
			Sort-Object -Property SequenceId |
			Add-Member NoteProperty -Name CRNumber -Value $CR -PassThru |
			% {
				$artifactName = getArtifactName $_ $services $plugins
				$artifact = Get-TeamcityArtifactDownloadUrl -ChangesetId $_.TeamCityChangeSet
				$artifactType = getArtifactType $_ $services $plugins
				$websiteName = getWebsiteName $_ $services $plugins
				$_ | 
				Add-Member -MemberType NoteProperty -Name TeamcityDownloadUrl -Value $artifact.DownloadUrl -PassThru |
				Add-Member -MemberType NoteProperty -Name TeamcityFile -Value $artifact.TeamcityFile -PassThru |
				Add-Member -MemberType NoteProperty -Name ArtifactName -Value $artifactName -PassThru |
				Add-Member -MemberType NoteProperty -Name ArtifactType -Value $artifactType -PassThru |
				Add-Member -MemberType NoteProperty -Name WebsiteName -Value $websiteName -PassThru
			}
		$crDetails += $details
	}
	return $crDetails
}

function createFolder([string]$folder)
{
	if(!(Test-Path $folder))
	{
		Write-Debug "Creating directory $folder"
		New-Item -ItemType Directory -Path $folder | out-null
	}
}

function downloadFromTeamcity($cr, $tempPath)
{
	try {
		$crOutFolder = "$tempPath\$($cr.CRNumber)"
		createFolder $crOutFolder

		$outFile = "$crOutFolder\$($cr.TeamcityFile)"
		Write-Host "Downloading from $($cr.TeamcityDownloadUrl) to $outFile"
		$result = wget -Uri $cr.TeamcityDownloadUrl -Credential $Global:EDBAndTeamcityCredential -OutFile $outFile
	}
	catch
	{
		Write-Error "$_.Exception.Message"
		return $cr
	}
	return $cr
}

function cleanExtract($cr, $tempPath)
{
	$folder = "$tempPath\$($cr.CRNumber)\$($cr.ArtifactName)-$($cr.Version)"
	if(Test-Path $folder)
	{
		Write-Debug "Removing directory $folder"
		Remove-Item -Path $folder -Recurse
	}
	return $cr
}

function extractArtifact($cr, $tempPath)
{	
	$zipPath = "$tempPath\$($cr.CRNumber)\$($cr.TeamcityFile)"
	Write-Debug "Extracting $($cr.TeamcityFile) to $tempPath\$($cr.CRNumber)"
	Expand-Archive -LiteralPath $zipPath -DestinationPath "$tempPath\$($cr.CRNumber)\$($cr.ArtifactName)-$($cr.Version)"
	return $cr
}

function deploy( 
    [string]$src,
    [string]$dest,
    [string[]]$exclude = @())
{
	Write-Debug "Copying from $src to $dest"
    # copy items in src
    Copy-Item $src $dest -Exclude $exclude
    # remove items not in src
    $dFiles = Get-ChildItem $dest
    $sFiles = Get-ChildItem $src
    $dFiles | 
		Where-Object {$_.Name -inotin ($sFiles|%{$_.Name}) } | 
		%{
			Write-Warning "Removing item $($_.FullName)"
			Remove-Item $_.FullName
		}
}

function copyToVm($cr, $from, $vmName)
{
	$zipExtract = "$from\$($cr.CRNumber)\$($cr.ArtifactName)-$($cr.Version)"

	if($cr.ArtifactType -eq [ArtifactType]::Webservice)
	{
		Write-Host "Deploying $($cr.ArtifactName)-$($cr.Version) to $vmName"
		deploy "$zipExtract\Websites\$($cr.ArtifactName)\bin\*" "\\$vmName\D\Websites\$($cr.WebsiteName)\bin"
	}

	if($cr.ArtifactType -eq [ArtifactType]::Plugin)
	{
		Write-Host "Deploying $($cr.ArtifactName)-$($cr.Version) to $vmName"
		$cr.IncludePattern -split "," |
			% { deploy "$zipExtract\$_" "\\$vmName\D\Websites\Download64.cityindex.co.uk\$_" }
	}
}

getCRDetailsFromEdb $edbServer $changeRequests | 
	% { downloadFromTeamcity $_ $tempPath } |
	% { cleanExtract $_ $tempPath } |
	% { extractArtifact $_ $tempPath } |
	% { copyToVm $_ $tempPath $VmHostName }