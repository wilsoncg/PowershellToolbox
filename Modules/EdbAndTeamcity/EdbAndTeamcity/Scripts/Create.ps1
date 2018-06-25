<#
  .SYNOPSIS
  Synopsis.
  .DESCRIPTION
  Description

  .EXAMPLE
  PS > .\Create.ps1  
  
#>
Param(
    [Parameter(Mandatory=$false)]
  	[string] $VmHostName
)
#Requires -Modules EdbAndTeamcity
#Requires -Modules 7Zip4Powershell

# Stops annoying confirmation popup when using Write-Debug and -Debug
If ($PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
}

Enum DownloadType
{
	Teamcity = 1
	Ostaging = 2
	PpeRefresh = 3
	QatRefresh = 4
}

# by EDB packageName,Website
$genesisWebApps = 
@{ 
	"AccountOperator" = $null;
	"Audit" = $null;
	"Authentication" = $null;
	"BackOffice" = $null;
	"ClientAccountWatchlist"= $null;
	"ClientDocuments"= $null;
	"ClientMaintenance"= $null;
	"ClientManagement"= $null;
	"Concentration"= $null;
	"DealerTools"= $null;
	"FinancialSettings"= $null;
	"Funding"= $null;
	"IDTService"= $null;
	"InstructionProcessor"= $null;
	"LockService"= $null;
	"Margin"= $null;
	"Payment"= $null;
	"RebatesWebService"= $null;
	"RebateSplit"= $null;
	"RiskGroups"= $null;
	"RolloversExpiries"= $null;
	"SecurityManagement"= $null;
	"SubscriptionViewer"= $null;
	"TradingAdvisor"= $null;
	"TransactionReporting"= $null;
	"UtilityManagement"= $null;
	"FundingWebUi"= $null;
	"NetBanxAsiaFundingWeb"= $null;
	"MetaTraderWebService"= $null;
	"MessageTranslation"= $null;
	"Scheme"= $null;
	"TradingApi" = "CI WEBSERVICE";
	#"Htmlfunding" = "LoginandTrade"; # no version in EDB!!
}

$genesisWinservices = 
@{
	"AutoHedgeService" = $null;
	"CansWinService" = $null;
	"CaptureService" = $null;
	"CentralisedLoggingService" = $null;
	"EODDataCapturer" = $null;
	"AccountInformationGateway" = $null;
	"AuthenticationGateway" = $null;
	"CiConnectGateway" = $null;
	"ClientPreferenceGateway" = $null;
	"HedgeGateway" = $null;
	"InstructionProcessorGateway" = $null;
	"MarketSearchGateway" = $null;
	"MessageGateway" = $null;
	"NewsGateway" = $null;
	"OrderGateway" = $null;
	"PriceHistoryGateway" = $null;
	"SimulationGateway" = $null;
	"TradingAdvisorGateway" = $null;
	"VersionInformationGateway" = $null;
	"WatchlistGateway" = $null;
	"LchFixInitiatorService" = $null;
	"PostingAdministrationService" = $null;
	"MarginEventProcessorService" = $null;
	"MarginSnapshotService" = $null;
	"marketservice" = $null;
	"OrderBookManagementService" = $null;
	"OrderService" = $null;
	"QuoteExpiryService" = $null;
	"RebatesService" = $null;
	"ExpiriesRolloversService" = $null;
	"ScheduledValuesService" = $null;
	"SchedulerService" = $null;
	"SMAService" = $null;
	"SubscriptionProcessorService" = $null;
}

$ppeRefreshWebsitesFolder = "\\srv-nol02\ReleaseBuilds\ROCReleases\RefreshWebServices\PPE\{0}-{1}.7z"
$ppeRefreshWinservicesFolder = "\\srv-nol02\ReleaseBuilds\ROCReleases\RefreshWindowsServices\PPE\{0}-{1}.7z"
$qatRefreshWebsitesFolder = "\\srv-nol02\ReleaseBuilds\ROCReleases\RefreshWebServices\QAT\{0}-{1}.7z"
$qatRefreshWinservicesFolder = "\\srv-nol02\ReleaseBuilds\ROCReleases\RefreshWindowsServices\QAT\{0}-{1}.7z"
$stagingAreaFolder = "\\fs01\Staging Area\QA\{0}-{1}.7z"

$webPaths = @{ 
	"ppeRefresh" = $ppeRefreshWebsitesFolder;
	"qatRefresh" = $qatRefreshWebsitesFolder;
	"staging" = $stagingAreaFolder;
	}
$winPaths = @{ 
	"ppeRefresh" = $ppeRefreshWinservicesFolder;
	"qatRefresh" = $qatRefreshWinservicesFolder;
	"staging" = $stagingAreaFolder;
	}

#powershell script port of https://github.com/maxhauser/semver/
function toSemVer($version){    
	$versionPattern = "^([0-9]+).([0-9]+).([0-9]+).([0-9]+)?"	
	$major, $minor, $patch, $build = ([regex]$versionPattern).matches($version) |
										  foreach {$_.Groups } | 
										  Select-Object -Skip 1
    return New-Object PSObject -Property @{ 
        Major = $major.Value
        Minor = $minor.Value
        Patch = $patch.Value
		Build = $build.Value
        VersionString = $version
        }
}

function addSemver($obj, $semver)
{
	Add-Member -InputObject $obj -MemberType NoteProperty -Name SemverMajor -Value $semver.Major
	Add-Member -InputObject $obj -MemberType NoteProperty -Name SemverMinor -Value $semver.Minor
	Add-Member -InputObject $obj -MemberType NoteProperty -Name SemverPatch -Value $semver.Patch
	Add-Member -InputObject $obj -MemberType NoteProperty -Name SemverBuild -Value $semver.Build
	Add-Member -InputObject $obj -MemberType NoteProperty -Name VersionString -Value $semver.VersionString
	return $obj
}

function rankSemvers([object[]]$objs)
{
	$highest = $objs | Sort-Object -Property @{ Expression={$_.SemverMajor}; Descending = $true }, @{ Expression={$_.Semver.Minor}; Descending = $true }, @{ Expression={$_.Semver.Patch}; Descending = $true }, @{ Expression={$_.Semver.Build}; Descending = $true } | Select -First 1
	return $highest
}

function filterEdbWebsite($webservice, $nameProperty, $websiteProperty)
{
	if(([string]::IsNullOrEmpty($websiteProperty)) -and $webservice.PackageName -eq $nameProperty)
	{
		return $webservice
	}
	if(!([string]::IsNullOrEmpty($websiteProperty)) -and ($webservice.PackageName -eq $nameProperty) -and ($webservice.Website -eq $websiteProperty))
	{ 
		return $webservice
	}
}

function filterEdbWinservice($winservice, $nameProperty)
{
	if($winservice.PackageName -eq $nameProperty)
	{ 
		return $winservice
	}
}

function addChangeset($servicesWithSemVers, $service)
{
	Write-Debug "Ranking semvers for $($service.PackageName)"
	$highestVersion = rankSemvers $servicesWithSemvers

	Write-Debug "Found $($highestVersion.VersionString) with teamcity build id $($highestVersion.ChangeSet)"
	Add-Member -InputObject $service -MemberType NoteProperty -Name Version -Value $($highestVersion.VersionString)

	if($($highestVersion.ChangeSet) -ne $null) {
		Add-Member -InputObject $service -MemberType NoteProperty -Name ChangeSet -Value $($highestVersion.ChangeSet) 
	}
	return $service
}

function getWebsites($apps)
{
	$appWithInfo = @()

	$services = Get-EdbWebServices | Select-Object -Property PackageName, Id, BinaryPath, Website
	ForEach ($app in $apps.GetEnumerator())
	{
		$service = $services | Where-Object { filterEdbWebsite $_ $app.Key $app.Value }
		Write-Debug "Attempting to determine Teamcity version/changeset for $($service.PackageName)"
		$serviceWithSemvers = Get-EdbWebServiceServerDeployedOn -WebServiceId $service.Id | 
			Where-Object { $_.Version -ne $null } | 
				foreach { 
					$_
					$semver = toSemVer($_.Version) 
					addSemver $_ $semver
				}		
		$appWithInfo += addChangeset $serviceWithSemvers $service
	}
	return $appWithInfo
}

function getWinservices($apps)
{
	$appWithInfo = @()

	$services = Get-EdbWinServices | Select-Object -Property PackageName, Id, BinaryPath
	ForEach ($app in $apps.GetEnumerator())
	{
		$service = $services | Where-Object { filterEdbWinservice $_ $app.Key }
		Write-Debug "Attempting to determine Teamcity version/changeset for $($service.PackageName)"
		$serviceWithSemvers = Get-EdbWinServicesServerDeployedOn -WinServiceId $service.Id | 
			Where-Object { $_.Version -ne $null } | 
				foreach { 
					$_
					$semver = toSemVer($_.Version) 
					addSemver $_ $semver
				}		
		$appWithInfo += addChangeset $serviceWithSemvers $service
	}
	return $appWithInfo
}

function testPath($app, $paths)
{
	ForEach ($path in $paths.GetEnumerator())
	{
		$testpath = [string]::Format($($path.Value), $app.PackageName, $app.Version)
		Write-Debug "Testing path $testPath"
		$exists = Test-Path $testPath
		if($exists -eq $True -and ($($path.Key) -eq "ppeRefresh"))
		{
			Add-Member -InputObject $app -MemberType NoteProperty -Name DownloadUrl -Value $testpath
			Add-Member -InputObject $app -MemberType NoteProperty -Name DownloadType -Value $([DownloadType]::PpeRefresh)
			break
		}
		Elseif($exists -eq $True -and ($($path.Key) -eq "qatRefresh"))
		{
			Add-Member -InputObject $app -MemberType NoteProperty -Name DownloadUrl -Value $testpath
			Add-Member -InputObject $app -MemberType NoteProperty -Name DownloadType -Value $([DownloadType]::QatRefresh)
			break
		}
		Elseif($exists -eq $True -and ($($path.Key) -eq "staging"))
		{
			Add-Member -InputObject $app -MemberType NoteProperty -Name DownloadUrl -Value $testpath
			Add-Member -InputObject $app -MemberType NoteProperty -Name DownloadType -Value $([DownloadType]::Ostaging)
			break
		}
	}
	return $app
}

function getDownloadPath($app, $stagingPaths)
{
	# try teamcity
	if($app.Changeset -ne $null) {
		$teamcityArtifact = Get-TeamcityArtifactDownloadUrl -ChangesetId $app.Changeset
		if(!($teamcityArtifact.DownloadUrl))
		{
			return testPath $app $stagingPaths
		}

		Add-Member -InputObject $app -MemberType NoteProperty -Name DownloadUrl -Value $teamcityArtifact.DownloadUrl
		Add-Member -InputObject $app -MemberType NoteProperty -Name TeamcityFile -Value $teamcityArtifact.TeamcityFile
		Add-Member -InputObject $app -MemberType NoteProperty -Name DownloadType -Value $([DownloadType]::Teamcity)
		return $app
	}
	# try staging areas
	if($app.Changeset -eq $null)
	{
		return testPath $app $stagingPaths
	}
}

function createFolder([string]$folder)
{
	if(!(Test-Path $folder))
	{
		New-Item -ItemType Directory -Path $folder
	}
}

function gatherForFullPackage($app)
{
	$working = (Resolve-Path .\).Path + "\working"
	createFolder "$working\FullPackage"

	if($app.DownloadType -eq [DownloadType]::Teamcity)
	{
		try {
			$result = wget -Uri $app.DownloadUrl -Credential $Global:EDBAndTeamcityCredential -OutFile "$working\FullPackage\$($app.TeamcityFile)"
		}
		catch
		{
			Write-Error "$_.Exception.Message"
		}
	}
	if(($app.DownloadType -eq [DownloadType]::Ostaging) -or
		($app.DownloadType -eq [DownloadType]::PpeRefresh) -or
		($app.DownloadType -eq [DownloadType]::QatRefresh))
	{
		Copy-Item -Path $app.DownloadUrl -Destination "$working\FullPackage"
	}
	if($app.DownloadUrl -eq $null)
	{
		Write-Warning "Missing from teamcity and staging areas: $($app.PackageName)"
	}
}

$webApps = getWebsites $genesisWebApps | % { getDownloadPath $_ $webPaths } | % { gatherForFullPackage $_ }
$winApps = getWinservices $genesisWinservices | % { getDownloadPath $_ $winPaths } | % { gatherForFullPackage $_ }
