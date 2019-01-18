<#
.DESCRIPTION
Copies installers necessary for configuring IIS HttpPlatformHandler module.
https://azure.microsoft.com/en-gb/blog/announcing-the-release-of-the-httpplatformhandler-module-for-iis-8/

.PARAMETER VmHostName
VM machine name, E.g. pkh-dev-cw01.cityindex.co.uk

.EXAMPLE
PS> .\SetupIIS.ps1 -VmHostName pkh-dev-cw01.cityindex.co.uk

#>
Param(
    [Parameter(Mandatory=$true)]
  	[string] $VmHostName
)

function Get-ScriptDirectory {
	Split-Path -Parent $script:MyInvocation.MyCommand.Definition
}
$installersFolder = join-path $(Get-ScriptDirectory) "\"

# script variables
$remoteTemppath = "d:\apps\"
$remoteFolder = "\\$VmHostName\D\apps"

# copy
$installs = @(
	 [pscustomobject]@{msiFilename="httpPlatformHandler_amd64.msi";installedProductName='Microsoft HTTP Platform Handler v1.0'}
	 [pscustomobject]@{msiFilename="requestRouter_amd64.msi";installedProductName='Microsoft Application Request Routing 3.0'}
	 [pscustomobject]@{msiFilename="rewrite_amd64_en-US.msi";installedProductName='IIS URL Rewrite Module 2'}
)

function Get-Installs([string]$path)
{
	$installs | 
		% { @{ 
			LocalPath = ("$path" + $_.msiFilename);
			InstalledProductName = $_.installedProductName;
		} }
}

function Copy-Installers([string]$dest)
{
	Write-Host "Getting installers from $installersFolder"
	Get-Installs $installersFolder |
		ForEach-Object {
			Write-Host "Copying from $($_.LocalPath) to $dest"
			Copy-Item -Path $_.LocalPath -Destination $dest
	}
}

function isAlreadyInstalled($displayNameToFind)
{
	Invoke-Command -ComputerName "$VmHostName" -ScriptBlock {
		param([string]$toFind)
		$path = @('HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*')
		$found =
			gp $path |
			.{process{ if ($_.DisplayName -and $_.UninstallString) { $_ } }} | 
			select displayname |
			? { $_.displayname -like "$toFind"}
        $exists = ($found | measure-object).Count -eq 1
        return $exists
    } -ArgumentList @($displayNameToFind)
}

function Run-Installers()
{
	Get-Installs $remoteTemppath |
		% {
			if(isAlreadyInstalled $_.InstalledProductName)
			{
				Write-Warning "Already installed, skipping installation $($_.InstalledProductName)"
				return
			}

			Write-Host "Installing on $VmHostName, $($_.LocalPath)"
			Invoke-Command -ComputerName $VmHostName -ArgumentList @($_.LocalPath) -ScriptBlock { 
				param([string] $LocalPath)

				$tempMSIParameters = "/package $LocalPath /quiet /passive /log $LocalPath.log"
				(Start-Process -FilePath "msiexec.exe" -ArgumentList $tempMSIParameters -Wait -Passthru).ExitCode
		}
	}
}

function Add-RegistryKey([string]$vmHostName, [string]$path, [string]$key, [string]$value)
{
    Invoke-Command -ComputerName "$VmHostName" -ArgumentList @($path, $key, $value) -ScriptBlock {
        param([string]$path, [string]$key, [string]$value)

        $exists = (get-item $path).GetValue($key) -ne $null
        if(!$exists)
        {
            New-ItemProperty -Path $path -Name $key -PropertyType DWORD -Value ([convert]::ToInt32($value))
        }
    }
}

function CreateWebsite([string]$VmHostName, [string]$webSiteName, [int]$port)
{
	if (!(Test-Path "\\$VmHostName\d$\Websites\wiremock-transformer")) {
		# create the folder
		Write-Warning "Cannot find wiremock \\$VmHostName\d$\Websites\wiremock-transformer"
	}		
	
	$webAdminArgs = @{ 
		Website = $webSiteName;
		Port = $port;
		VmHostname = $VmHostName;
	}

	Invoke-Command -ComputerName $VmHostName -ScriptBlock {
		PARAM($webAdminArgs);
		$website = $webAdminArgs.Website
		$port = $webAdminArgs.Port
		$vm = $webAdminArgs.VmHostname

		Import-module WebAdministration; # We need WebAdministration module to work with IIS:		
			
		if(Test-Path "IIS:\Sites\$website") {
			Write-Output "Website $website already exists, stopping and removing"
			$site = Get-Website -Name $website
			if($site.State -eq 'Started')
			{
				Stop-WebSite -Name $website
			}
			Remove-Website -Name $website
		}
		
		if(!(Test-Path "IIS:\AppPools\$website")) {
			# create the app pool
			Write-Output "Creating AppPool for $website"
			New-Item IIS:\AppPools\$website			
		}
		Set-ItemProperty "IIS:\AppPools\$website" managedRuntimeVersion v4.0

		#set apppool as network service so logging can write to logs\web\ folder
		Set-ItemProperty "IIS:\AppPools\$website" -name processModel.identityType -value 2 
		
		if($(Get-WebAppPoolState -Name $website).Value -eq 'Started') {
			# stop the app pool
			Write-Output "Stopping AppPool $website"
			Stop-WebAppPool $website
		}
		
		if(!(Test-Path "IIS:\Sites\$website")) {
			# create website
			Write-Output "Creating new Sites\$website"
			# put into unused var
			$var = New-Website -Name $website -Port $port -PhysicalPath "d:\Websites\$website" -ApplicationPool $website
		}
		
		if((Test-Path "IIS:\Sites\$website")) {
			Write-Output "Reset bindings for $website"
			Clear-ItemProperty IIS:\Sites\$website -Name bindings			
		}
		
		if(!(Test-Path "d:\Websites\$website\__files\index.html")) {
			Add-Content -Path d:\Websites\$website\__files\index.html -Value ""
		}

		if((Test-Path "d:\Websites\$website\__files\index.html")) {			
			Set-ItemProperty "d:\Websites\$website\__files\index.html" -name IsReadOnly -value $false
			Write-Output "Creating default document"
			$html = 
				"<html><head><title>$website</title></head><body><h1>$website website</h1>" + 
				"<p>Wiremock running on port 8100</p>" + 
				"<p>swagger <a href='http://$($vm):8100/__admin/swagger-ui/'>http://$($vm):8100/__admin/swagger-ui/</a></p>" + 
				"<p><ul>" + 
				"<li><strong><span style='color:#a41e22'>Careful: wiremock is case sensitive because it uses the Java file system reader</span></strong></li>" + 
				"<li><span style='color:#c5862b'>changes to mappings files are not automatically reloaded, either use swagger to do a 'POST /__admin/mappings/reset or recycle app pool</span></li>" +
				"<li>anything placed in __files folder is served by wiremock, eg <a href='http://$($vm):8100/tradingapi/'>tradingapi</a></li>" +	
				"<li>wiremock logs are in \\$vm\d\Logs\Web</li>" +
				"</ul></p>" +
				"<p><a href='http://wiremock.org/docs/'>wiremock docs</a></p>" +
				"</body></html>"
			Set-Content -Path d:\Websites\$website\__files\index.html -Value $html
		}

		$site = Get-Website -Name $website
		if($site.State -eq 'Stopped')
		{
			Write-Output "Starting website $website"
			Start-WebSite -Name $website
		}
		
		if($(Get-WebAppPoolState -Name $website).Value -eq 'Stopped') {
			Write-Output "Starting AppPool $website"
			Start-WebAppPool $website
		}
	} -ArgumentList $webAdminArgs
}

function CreateBinding([string]$VmHostName, [string]$webSiteName, [string]$protocol, [string]$binding)
{
	$webAdminArgs = @{ 
		Website = $webSiteName;
		Protocol = $protocol;
		Binding = $binding;
	}

	Invoke-Command -ComputerName $VmHostName -ScriptBlock {
		PARAM($webAdminArgs);
		$website = $webAdminArgs.Website
		$protocol = $webAdminArgs.Protocol
		$binding = $webAdminArgs.Binding
		Import-module WebAdministration; # We need WebAdministration module to work with IIS:		

		Write-Output "Creating binding for $website protocol=$protocol binding=$($binding)"
		New-ItemProperty IIS:\Sites\$website -name bindings -value @{protocol=$protocol;bindingInformation=$($binding)}

	} -ArgumentList $webAdminArgs
}

function SetupArrProxy([string]$vmHostName)
{
	Invoke-Command -ComputerName $VmHostName -ScriptBlock {
		& "$env:windir\system32\inetsrv\appcmd.exe" set config -section:system.webServer/proxy /enabled:"True" /httpVersion:"PassThrough" /keepAlive:"True" /preserveHostHeader:"False" /xForwardedForHeaderName:"X-Forwarded-For" /includePortInXForwardedFor:"True" /logGuidName:"X-ARR-LOG-ID" /commit:apphost
	}
}

function StartIfNotAlreadyStarted([string]$vmHostName, [string]$website)
{
	Invoke-Command -ComputerName $vmHostName -ScriptBlock {
		param([string]$website)
		Import-module WebAdministration

		$site = Get-Website -Name $website
		if($site.State -eq 'Stopped')
		{
			Write-Output "Starting website $website"
			Start-WebSite -Name $website
		}
		
		if($(Get-WebAppPoolState -Name $website).Value -eq 'Stopped') {
			Write-Output "Starting AppPool $website"
			Start-WebAppPool $website
		}
	} -ArgumentList @($website)
}

function deploy( 
    [string]$src,
    [string]$dest,
    [string[]]$dontRemove = @())
{
	Write-Verbose "Copying from $src to $dest"
    # copy items in src
    Copy-Item $src $dest -Recurse -Force
    # remove items not in src
    $dFiles = Get-ChildItem $dest
    $sFiles = Get-ChildItem $src
    $dFiles | 
		Where-Object {$_.Name -inotin ($sFiles|%{$_.Name}) } | 
		%{
			if($_.Name -in $dontRemove) {}
			else 
			{
				Write-Warning "Removing item $($_.FullName)"
				Remove-Item $_.FullName -Force
			}
		}
}

function Copy-Website([string]$vmHostName, [string]$website)
{
	$src = split-path $(Get-ScriptDirectory)
	$dst = "\\$VmHostName\D\Websites\$website"
	Write-Output "Copying from $src to $dst"
	Invoke-Command -ComputerName $vmHostName -ArgumentList @($website) -ScriptBlock {
		param([string]$website)
		if(!(test-path "d:\Websites\$website"))
		{
			cd "d:\Websites\"
			New-Item -ItemType Directory -Name $website
		}
	}
	
	deploy "$src\*" "$dst" -dontRemove "index.html"
}

# good old stack overflow (fix for readonly DomainController)
# https://dba.stackexchange.com/questions/178325/the-computer-must-be-trusted-for-delegation-and-the-current-user-account-must
Add-RegistryKey $VmHostName 'HKLM:\SOFTWARE\Microsoft\Cryptography\Protect\Providers\df9d8cd0-1501-11d1-8c7a-00c04fc297eb' 'ProtectionPolicy' '1'

Copy-Installers $remoteFolder
Run-Installers
Copy-Website $VmHostName "wiremock-transformer"
CreateWebsite $VmHostName "wiremock-transformer" 8100
CreateBinding $VmHostName "wiremock-transformer" "http" "*:8100:"
SetupArrProxy $VmHostName
StartIfNotAlreadyStarted $VmHostName "wiremock-transformer"