<#
  .SYNOPSIS
  Synopsis.
  .DESCRIPTION
  Requires https://www.powershellgallery.com/packages/7Zip4Powershell
  PS> install-module -name 7zip4powershell

  .EXAMPLE
  PS > .\SnapshotFromLive.ps1 -ConfigDir C:\dev\Projects-TFS\Genesis_Configs
  
#>
Param(
	[Parameter(Mandatory=$true)]
  	[string] $ConfigDir
)
#Requires -Modules 7Zip4Powershell
$webAppMissing = @{
		"Audit" = "\\srv-66\Websites\Audit.cityindex.co.uk";
		"Authentication" = "\\srv-66\Websites\Authentication.cityindex.co.uk";
		"Clientaccountwatchlist" = "\\srv-66\Websites\ClientAccountWatchlist.cityindex.co.uk";
		"Concentration" = "\\srv-66\Websites\Concentration.cityindex.co.uk";
		"Financialsettings" = "\\srv-66\Websites\FinancialSettings.cityindex.co.uk";
		"Download64" = "\\srv-66\Websites\Download64.cityindex.co.uk";
		#"Htmlfunding" = "\\srv-66\Websites\LoginAndTrade\HtmlFunding"; #no config files?
	}
$winServicesMissing = @{
		"SMAService" = "\\srv-66\Apps\SMAService";
		"QuoteExpiryService" = "\\srv-66\Apps\QuoteExpiryService";
		"marketservice" = "\\srv-66\Apps\MarketService";
		"CentralisedLoggingService" = "\\srv-66\Apps\CentralisedLoggingService";
		"VersionInformationGateway" = "\\srv-66\Apps\Gateways\VersionInformationGateway\current";
	}

function createFolder([string]$folder)
{
	if(!(Test-Path $folder))
	{
		New-Item -ItemType Directory -Path $folder
	}
}

function copyFromLive($appFolder, $missing) {
	$working = (Resolve-Path .\).Path + "\working"
	createFolder($working)

	$missing.GetEnumerator() | 
		% { 
			createFolder("$working\$($_.Key)")
			createFolder("$working\$($_.Key)\$appFolder")
			createFolder("$working\$($_.Key)\$appFolder\$($_.Key)")
			$dest = "$working\$($_.Key)\$appFolder\$($_.Key)"
			$source = "$($_.Value)"
			$exclude = @('*.config')
			Get-ChildItem $source -Recurse -Exclude $exclude | 
				Copy-Item -Destination { Join-Path $dest $_.FullName.Replace($source,"") }
		} 
}

function copyConfigs($appFolder, $missing)
{
	$envs = @("PPE", "QAT", "PROD-INX", "PROD-RDB")
	$working = (Resolve-Path .\).Path + "\working"
	$missing.GetEnumerator() | 
		% { 
			$dstConfig = "$working\$($_.Key)\Config"
			createFolder($dstConfig)
			foreach($env in $envs)
			{
				createFolder("$dstConfig\$env")
				createFolder("$dstConfig\$env\$appFolder")
				createFolder("$dstConfig\$env\$appFolder\$($_.Key)")
				Copy-Item -Recurse -Path "$ConfigDir\$env\$appFolder\$($_.Key)\*" -Destination "$dstConfig\$env\$appFolder\$($_.Key)"
			}
		} 
}

function createZips($missing) {
	$working = (Resolve-Path .\).Path + "\working"
	createFolder("$working\FullPackage")
	$missing.GetEnumerator() |
		% {
			$path = "$working\$($_.Key)"
			Compress-7Zip -ArchiveFileName "$($_.Key)-1.0.0.0.7z" -Format SevenZip -Path $path
			Move-Item -Path "$($_.Key)-1.0.0.0.7z" -Destination "$working\FullPackage"
		}
}

copyFromLive "WebSites" $webAppMissing
copyConfigs "WebSites" $webAppMissing
createZips $webAppMissing

copyFromLive "Apps" $winServicesMissing
copyConfigs "Apps" $winServicesMissing
createZips $winServicesMissing