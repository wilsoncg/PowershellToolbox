<#
.DESCRIPTION
Setup IIS on a remote machine with a load balanced setup. Uses ARR (Application Request Routing), with a configured webfarm

.PARAMETER VmHostName
VM machine name, E.g. pkh-dev-cw01.cityindex.co.uk

.EXAMPLE
PS> .\SetupIIS.ps1 -VmHostName pkh-dev-cw01.cityindex.co.uk

#>
Param(
    [Parameter(Mandatory=$true)]
  	[string] $VmHostName
)

$vmHost = $VmHostName

function ConfigEntry([string]$VmHostName, [string]$webSiteName, [string]$configXpath, [string]$configPropName, [string]$configPropValue)
{
	$webAdminArgs = @{ 
		WebSite = $webSiteName;
		ConfigXpath = $configXpath;
		ConfigPropName = $configPropName;
		ConfigPropValue = $configPropValue;
	}

	Invoke-Command -ComputerName $VmHostName -ScriptBlock {
		PARAM($webAdminArgs);
		$website = $webAdminArgs.WebSite
		$configXpath = $webAdminArgs.ConfigXpath
		$configPropName = $webAdminArgs.ConfigPropName
		$configPropValue = $webAdminArgs.ConfigPropValue
		Import-module WebAdministration; # We need WebAdministration module to work with IIS:

		if((Test-Path "IIS:\Sites\$website\web.config")) {
			Write-Output "Creating new c:\inetpub\wwwroot\$website\web.config"
			Remove-Item -Path c:\inetpub\wwwroot\$website\web.config -Force

			[xml]$Doc = New-Object System.Xml.XmlDocument
			$dec = $Doc.CreateXmlDeclaration("1.0","UTF-8",$null)
			$doc.AppendChild($dec)
			$root = $doc.CreateNode("element","configuration",$null)
			$systemWeb = $doc.CreateNode("element","system.webServer",$null)
			$httpProto = $doc.CreateNode("element","httpProtocol",$null)
			$headers = $doc.CreateNode("element","customHeaders",$null)
			$doc.AppendChild($root)
			$root.AppendChild($systemWeb)
			$systemWeb.AppendChild($httpProto)
			$httpProto.AppendChild($headers)
			$doc.save("c:\inetpub\wwwroot\$website\web.config")
		}

		if(!(Test-Path "$($env:windir)\System32\inetsrv\config\schema\FX_schema.patch.xml")) {
		# https://serverfault.com/questions/629254/unrecognized-element-provideroption-when-trying-to-use-powershell-set-webconfi
		# On IIS 7 and IIS 7.5, FX_schema.xml is missing the declarations for providerOption
			$pathToConfig = "$($env:windir)\System32\inetsrv\config\schema\FX_schema.patch.xml"
			New-Item -Path $pathToConfig -ItemType File			
			[xml]$appSettingsXml = @"
<!--

    IIS 7.0 and IIS 7.5 contain incorrect system.codedom sections in their FX_schema.xml files.
    This version was taken from IIS 8.5 and contains the correct validations for the default web.config 
    in the CLR 4.0 folder. This file is only required on Windows Vista, 7, Server 2008 and Server 2008 R2.

-->
<configSchema>
    <sectionSchema name="system.codedom">
        <element name="compilers">
            <collection addElement="compiler" removeElement="remove" clearElement="clear">
                <attribute name="language" type="string" isCombinedKey="true" />
                <attribute name="extension" type="string" isCombinedKey="true" />
                <attribute name="type" type="string" />
                <attribute name="warningLevel" type="int" />
                <attribute name="compilerOptions" type="string" />
				<collection addElement="providerOption" >
                    <attribute name="name" type="string"  isCombinedKey="true" />
                    <attribute name="value" type="string" isCombinedKey="true" />
                </collection>
            </collection>
        </element>
    </sectionSchema>
</configSchema>
"@
			$appSettingsXml.Save($pathToConfig)
			Write-Output "Recreated $pathToConfig"
			Write-Output "Restart IIS so schema patch is picked up"
			Restart-Service w3svc
		}

		Write-Output "Adding new web.config entry at $($configXpath) name=$configPropName,value=$configPropValue"
		Add-WebConfigurationProperty $($configXpath) IIS:\Sites\$website -AtIndex 0 -Name collection -Value @{name=$configPropName;value=$configPropValue}

	} -ArgumentList $webAdminArgs
}

function ReconfigureDefaultWebsite([string]$VmHostName)
{
	if (!(Test-Path "\\$VmHostName\d\wwwroot")) {
		# create the folder
		Write-Output "Creating \\$VmHostName\d\wwwroot"
		New-Item "\\$VmHostName\d\wwwroot" -type Directory
	}

	Invoke-Command -ComputerName $VmHostName -ScriptBlock {
		Import-module WebAdministration; # We need WebAdministration module to work with IIS:

		Write-Output "Repointing 'Default Web Site' from c:\inetpub\wwwroot to D:\wwwroot"
		Set-ItemProperty 'IIS:\Sites\Default Web Site' -Name physicalPath -Value "D:\wwwroot"

		if((Test-Path "IIS:\Sites\Default Web Site")) {
			Write-Output "Clear and reset bindings for Default Web Site"
			Clear-ItemProperty 'IIS:\Sites\Default Web Site' -Name bindings
			New-ItemProperty 'IIS:\Sites\Default Web Site' -name bindings -value @{protocol="http";bindingInformation="*:85:"}
			New-ItemProperty 'IIS:\Sites\Default Web Site' -name bindings -value @{protocol="net.tcp";bindingInformation="808:*"}
			New-ItemProperty 'IIS:\Sites\Default Web Site' -name bindings -value @{protocol="net.pipe";bindingInformation="*"}
			New-ItemProperty 'IIS:\Sites\Default Web Site' -name bindings -value @{protocol="net.msmq";bindingInformation="localhost"}
			New-ItemProperty 'IIS:\Sites\Default Web Site' -name bindings -value @{protocol="msmq.formatname";bindingInformation="localhost"}
		}
	}
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

function CreateWebsite([string]$VmHostName, [string]$webSiteName, [int]$port)
{
	if (!(Test-Path "\\$VmHostName\c$\inetpub\wwwroot\$webSiteName")) {
		# create the folder
		Write-Output "Creating \\$VmHostName\c$\inetpub\wwwroot\$webSiteName"
		New-Item "\\$VmHostName\c$\inetpub\wwwroot\$webSiteName" -type Directory
	}		
	
	$webAdminArgs = @{ 
		Website = $webSiteName;
		Port = $port;
	}

	Invoke-Command -ComputerName $VmHostName -ScriptBlock {
		PARAM($webAdminArgs);
		$website = $webAdminArgs.Website
		$port = $webAdminArgs.Port
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
		
		if($(Get-WebAppPoolState -Name $website).Value -eq 'Started') {
			# stop the app pool
			Write-Output "Stopping AppPool $website"
			Stop-WebAppPool $website
		}
		
		if(!(Test-Path "IIS:\Sites\$website")) {
			# create website
			Write-Output "Creating new Sites\$website"
			# put into unused var
			$var = New-Website -Name $website -Port $port -PhysicalPath "c:\inetpub\wwwroot\$website" -ApplicationPool $website
		}
		
		if((Test-Path "IIS:\Sites\$website")) {
			Write-Output "Reset bindings for $website"
			Clear-ItemProperty IIS:\Sites\$website -Name bindings			
		}
		
		if(!(Test-Path "C:\inetpub\wwwroot\$website\index.html")) {
			Add-Content -Path C:\inetpub\wwwroot\$website\index.html -Value ""
		}

		if((Test-Path "C:\inetpub\wwwroot\$website\index.html")) {
			Write-Output "Creating default document"
			$html = "<html><head><title>$website</title></head><body><h1>$website</h1></body></html>"
			Set-Content -Path C:\inetpub\wwwroot\$website\index.html -Value $html
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

function CreateWebFarm([string]$VmHostName, [string]$webFarmName)
{
	$webAdminArgs = @{ 
		Website = $webSiteName;
		Webfarmname = $webFarmName;
	}

	Invoke-Command -ComputerName $VmHostName -ScriptBlock {
		PARAM($webAdminArgs);
		$webfarmname = $webAdminArgs.Webfarmname
		Import-module WebAdministration; # We need WebAdministration module to work with IIS:

		$webFarmExists = ((Get-WebConfigurationProperty -Filter /webFarms -Name Collection[*]) -ne $null) -and ((Get-WebConfigurationProperty -Filter /webFarms -name Collection[name="*"] -PSPath 'IIS:\' | where { $_.name -eq $webfarmname } | Measure-Object).Count -eq 1)

		if(!($webFarmExists)) {
			Write-Output "Creating web farm $webfarmname"
			& "$env:windir\system32\inetsrv\appcmd.exe" set config -section:webFarms /+"[name='$webfarmname']" /commit:apphost
		}

		Write-Output "Enabling web farm $webfarmname"
		Set-WebConfigurationProperty -filter "/webFarms/webFarm" -name enabled -value true -PSPath IIS:\

		Write-Output "Set $webfarmname to WeightedRoundRobin"
		Set-WebConfigurationProperty -pspath "IIS:\" -filter "webFarms/webFarm[@name='$webfarmname']/applicationRequestRouting/loadBalancing" -name "algorithm" -value "WeightedRoundRobin"

	} -ArgumentList $webAdminArgs
}

function AddServerToWebFarm([string]$VmHostName, [string]$webFarmName, [string]$address, [int]$httpPort)
{
	$webAdminArgs = @{ 
		Webfarmname = $webFarmName;
		Address = $address;
		HttpPort = $httpPort;
	}

	Invoke-Command -ComputerName $VmHostName -ScriptBlock {
		PARAM($webAdminArgs);
		$webfarmname = $webAdminArgs.Webfarmname
		$address = $webAdminArgs.Address
		$httpPort = $webAdminArgs.HttpPort
		Import-module WebAdministration; # We need WebAdministration module to work with IIS:

		$serverNotExists = ((get-webconfiguration //webFarms/webFarm).collection | where { $_.address -eq $address } | Measure-Object).Count -eq 0

		if($serverNotExists) {
			Write-Output "Creating server $address under farm $webfarmname"
			& "$env:windir\system32\inetsrv\appcmd.exe" set config -section:webFarms /+"[name='$webfarmname'].[address='$address']" /commit:apphost

			Write-Output "Set port $httpPort"
			Set-WebConfigurationProperty -pspath "IIS:\" -filter "webFarms/webFarm[@name='$webfarmname']/server[@address='$address']/applicationRequestRouting" -name "httpPort" -value $httpPort
		}

		Write-Output "Enabling server $address"
		Set-WebConfigurationProperty -filter "/webFarms/webFarm/server" -name enabled -value true -PSPath IIS:\

	} -ArgumentList $webAdminArgs
}

function AllowWebConfigDownload([string]$VmHostName, [string]$website)
{
	$webAdminArgs = @{ Website = $website; }

	Invoke-Command -ComputerName $VmHostName -ScriptBlock {
		PARAM($webAdminArgs);
		$website = $webAdminArgs.Website		
		Import-module WebAdministration; # We need WebAdministration module to work with IIS:

		if(Test-Path "IIS:\Sites\$website\web.config") {
				Write-Output "Creating new c:\inetpub\wwwroot\$website\web.config"
				Remove-Item -Path c:\inetpub\wwwroot\$website\web.config -Force

				[xml]$config = @"
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <system.webServer>
        <staticContent>
            <mimeMap fileExtension=".config" mimeType="text/xml" />
            <mimeMap fileExtension=".netmodule" mimeType="application/x-msdownload" />
            <mimeMap fileExtension=".pdb" mimeType="application/x-msdownload" />
        </staticContent>
        <handlers>
            <clear />
            <add name="StaticFile" path="*" verb="*" type="" modules="StaticFileModule,DefaultDocumentModule,DirectoryListingModule" scriptProcessor="" resourceType="Either" requireAccess="Read" allowPathInfo="false" preCondition="" responseBufferLimit="4194304" />
        </handlers>
        <security>
            <requestFiltering>
                <fileExtensions>
                    <remove fileExtension=".config" />
                </fileExtensions>
            </requestFiltering>
        </security>
    </system.webServer>
</configuration>
"@
				$config.save("c:\inetpub\wwwroot\$website\web.config")
			}
	} -ArgumentList $webAdminArgs
}

function SetupArrProxy([string]$vmHostName)
{
	Invoke-Command -ComputerName $VmHostName -ScriptBlock {
		& "$env:windir\system32\inetsrv\appcmd.exe" set config -section:system.webServer/proxy /enabled:"True" /httpVersion:"PassThrough" /keepAlive:"True" /preserveHostHeader:"False" /xForwardedForHeaderName:"X-Forwarded-For" /includePortInXForwardedFor:"True" /logGuidName:"X-ARR-LOG-ID" /commit:apphost
	}
}

function CreateRewriteRules([string]$VmHostName, [string]$siteName)
{
	$webAdminArgs = @{ }

	Invoke-Command -ComputerName $VmHostName -ScriptBlock {
		Import-module WebAdministration; # We need WebAdministration module to work with IIS:
		
		Write-Output "Removing existing rewrite rules"
		Remove-WebConfigurationProperty system.webServer/rewrite/globalRules -name '.'

		function Rule([string]$arrRewriteRuleName, [string]$actionType, [string]$actionUrl, [string]$matchUrl, 
		[ValidateSet("Wildcard","Regex","None")]
		[string]$patternType)
		{
			Write-Output "Creating rule: $arrRewriteRuleName"

			if($patternType -eq "Wildcard") {
				Add-WebConfigurationProperty -pspath "IIS:\" -filter "system.webServer/rewrite/globalRules" -name "." -value @{name="$arrRewriteRuleName";enabled='True';stopProcessing='True';patternSyntax="Wildcard"}
			}
			if($patternType -eq "Regex") {
				Add-WebConfigurationProperty -pspath "IIS:\" -filter "system.webServer/rewrite/globalRules" -name "." -value @{name="$arrRewriteRuleName";enabled='True';stopProcessing='True';patternSyntax="ECMAScript"}
			}
			if($patternType -eq "None") {
				Add-WebConfigurationProperty -pspath "IIS:\" -filter "system.webServer/rewrite/globalRules" -name "." -value @{name="$arrRewriteRuleName";enabled='True';stopProcessing='True'}
			}
			
			Set-WebConfigurationProperty -pspath "IIS:\" -filter "system.webServer/rewrite/globalRules/rule[@name='$arrRewriteRuleName']/match" -name "url" -value $matchUrl			
			
			Set-WebConfigurationProperty -pspath "IIS:\" -filter "system.webServer/rewrite/globalRules/rule[@name='$arrRewriteRuleName']/action" -name "type" -value $actionType
			Set-WebConfigurationProperty -pspath "IIS:\" -filter "system.webServer/rewrite/globalRules/rule[@name='$arrRewriteRuleName']/action" -name "url" -value $actionUrl
		}

		function Condition([string]$ruleName, [string]$cinput, [string]$cpattern, [bool]$negate)
		{
			Write-Output "Creating condition: $cinput $cpattern for $ruleName"

			Add-WebConfigurationProperty -pspath "IIS:\" -filter "system.webServer/rewrite/globalRules/rule[@name='$ruleName']/conditions" -name "." -value @{input=$cinput;matchType='Pattern';pattern=$cpattern;negate="$negate"}
		}
		
		Rule "Redirect localab.com to load balancer" "Rewrite" "http://LocalWebFarm/{R:0}" ".*" "None"
		Condition "Redirect localab.com to load balancer" '{HTTP_HOST}' "localab.com" $false
		Condition "Redirect localab.com to load balancer" '{SERVER_PORT}' "(81|82)" $true
		Condition "Redirect localab.com to load balancer" '{HTTP_X_ARR_LOG_ID}' "^(?!\s*$).+" $true

		Rule "Custom redirect to load balancer" "Rewrite" "http://LocalWebFarm/{R:0}" "(payment|funding)/(\w+(?:\.asmx|\.svc))" "Regex"
		Condition "Custom redirect to load balancer" '{SERVER_PORT}' "(81|82)" $true
		Condition "Custom redirect to load balancer" '{HTTP_X_ARR_LOG_ID}' "^(?!\s*$).+" $true

		Rule "Other services to Default web site" "Rewrite" "http://localhost:85/{R:0}" ".*" "None"
		Condition "Other services to Default web site" '{SERVER_PORT}' "(81|82)" $true	
		Condition "Other services to Default web site" '{HTTP_X_ARR_LOG_ID}' "^(?!\s*$).+" $true	
		
	} -ArgumentList $webAdminArgs	
}

function AddHostsFileEntry([string]$VmHostName, [string[]]$hostnameEntries)
{
	$webAdminArgs = @{ 
		Hostnames = $hostnameEntries;
	}

	Invoke-Command -ComputerName $VmHostName -ScriptBlock {
		PARAM($webAdminArgs);
		$hostnameEntries = $webAdminArgs.Hostnames

		$hostnameEntries | 
		foreach { 
			If ((Get-Content "$($env:windir)\system32\Drivers\etc\hosts" ) -notcontains "127.0.0.1 $_")
			{
				Write-Output "Adding etc\hosts entry 127.0.0.1 $_"
				ac -Encoding UTF8 "$($env:windir)\system32\Drivers\etc\hosts" "127.0.0.1 $_" 
			}
		}

	} -ArgumentList $webAdminArgs	
}

ReconfigureDefaultWebsite $vmHost
CreateWebsite $vmHost "localab" 80
CreateBinding $vmHost "localab" "http" "*:80:localab.com"
CreateBinding $vmHost "localab" "http" "*:80:"
AllowWebConfigDownload $vmHost "localab"

CreateWebsite $vmHost "locala" 81
CreateBinding $vmHost "locala" "http" "*:81:"

CreateWebsite $vmHost "localb" 82
CreateBinding $vmHost "localb" "http" "*:82:"

ConfigEntry $vmHost "locala" "//system.webServer/httpProtocol/customHeaders" "X-Forwarded-From-Host" "locala"
ConfigEntry $vmHost "localb" "//system.webServer/httpProtocol/customHeaders" "X-Forwarded-From-Host" "localb"

## https://docs.microsoft.com/en-us/iis/extensions/configuring-application-request-routing-arr/define-and-configure-an-application-request-routing-server-farm
## create web farm
CreateWebFarm $vmHost "LocalWebFarm"
AddServerToWebFarm $vmHost "LocalWebFarm" "locala" 81
AddServerToWebFarm $vmHost "LocalWebFarm" "localb" 82

# https://docs.microsoft.com/en-us/iis/extensions/configuring-application-request-routing-arr/http-load-balancing-using-application-request-routing
# create rewrite rules
CreateRewriteRules $vmHost

SetupArrProxy $vmHost
AddHostsFileEntry $vmHost "locala","localb","localab.com"