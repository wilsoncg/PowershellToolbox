<#
.DESCRIPTION
Copies installers necessary for configuring IIS in load balanced setup, then runs them.

.PARAMETER VmHostName
VM machine name, E.g. pkh-dev-cw01.cityindex.co.uk

.PARAMETER installersFolder
Provide path to installers, script doesn't have the smarts to figure it out

.EXAMPLE
PS> .\CopyAndInstall.ps1 -VmHostName pkh-dev-cw01.cityindex.co.uk -InstallersFolder "C:\dev\tfs\PaymentTeam\Tools\LoadBalanceSetup\installers\"

#>
Param(
    [Parameter(Mandatory=$true)]
  	[string] $VmHostName,
	[Parameter(Mandatory=$false)]
  	[string] $installersFolder = "C:\dev\Projects-TFS\PaymentTeam\Tools\LoadBalanceSetup\installers\"
)

# script variables
$remoteTemppath = "d:\temp\"
$remoteFolder = "\\$VmHostName\D\Temp"

# copy
 $installs = @(
	 "rewrite_amd64_en-US.msi",
	 "webfarm_v1.1_amd64_en_us.msi",
	 "requestRouter_amd64.msi",
	 "ExternalDiskCache_amd64_en-US.msi"
)

function Get-Installs([string]$path)
{
	$installs | ForEach-Object { @{ $installs = $_; LocalPath = ("$path" + $_ ) } }
}

function Copy-Installers([string]$dest)
{
	Write-Ouptut "Getting installers from $installersFolder"
	Get-Installs $installersFolder |
		ForEach-Object {
			Write-Host "Copying from $($_.LocalPath) to $dest"
			Copy-Item -Path $_.LocalPath -Destination $dest
	}
}

function Run-Installers()
{
	Get-Installs $remoteTemppath |
		ForEach-Object {
			Write-Output "Installing on $VmHostName, $($_.LocalPath)"
			Invoke-Command -ComputerName $VmHostName -ArgumentList @($_.LocalPath) -ScriptBlock { 
				param([string] $LocalPath)

				$tempMSIParameters = "/package $LocalPath /quiet /passive /log $LocalPath.log"
				(Start-Process -FilePath "msiexec.exe" -ArgumentList $tempMSIParameters -Wait -Passthru).ExitCode
			}
	}
}

Copy-Installers $remoteFolder
Run-Installers