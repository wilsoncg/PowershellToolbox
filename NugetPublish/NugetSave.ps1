<#
.DESCRIPTION
Copy from public nuget.org and publish to library.nuget.cityindex.co.uk

.PARAMETER ApiKey
Nuget api key

.EXAMPLE
PS> .\NugetSave.ps1 -ApiKey abcdef -verbose

#>
[CmdletBinding()]
Param(
  	[string] $ApiKey='abdef'
)

function createFolder([string]$folder)
{
	if(!(Test-Path $folder))
	{
		New-Item -ItemType Directory -Path $folder
	}
}

$config = Get-Content -Path .\nuget-config.json | ConvertFrom-Json
createFolder '.\downloads'

function publish([object]$package)
{
	$publishParam = @{
		Source  = 'http://library.nuget.cityindex.co.uk/api/v2/package'
		ApiKey = $ApiKey
		Force = $true
	}
	
	$nugetexe = (Resolve-Path .\).Path + '\4.7.1' + '\nuget.exe'
	$path = '.\downloads\{0}\{0}.{1}.nupkg' -f @($package.Name, $package.Version)
	$args = @('push', $path, $publishParam.ApiKey,'-source', $publishParam.Source)
	&$nugetexe $args
}

foreach($module in $config.Modules)
{
	$findParam = @{
		Name = $module.Name
		RequiredVersion = $module.RequiredVersion
		Provider = 'NuGet'
		Source = 'nuget.org'
	}
	
	$save = @{
		LiteralPath = (Resolve-Path .\).Path + '\downloads\{0}' -f $module.Name
	}
	createFolder $save.LiteralPath

	Find-Package @findParam -Verbose:$VerbosePreference | % {
		Save-Package @save -Verbose:$VerbosePreference -Force -InputObject $_
		publish $_
	}
}