function Get-NodeDescription([System.Xml.XmlNode] $xmlNode)
{
    $sb = New-Object -TypeName "System.Text.StringBuilder"

    $sb.Append("<") > $null;
    $sb.Append($xmlNode.Name) > $null;
    if ($xmlNode.Attributes -ne $null -and $xmlNode.Attributes.Count -gt 0)
    {
        foreach ($xmlAttribute in $xmlNode.Attributes)
        {
            $sb.AppendFormat(" {0}='{1}'", $xmlAttribute.Name, $xmlAttribute.Value) > $null;
        }
    }
    $sb.Append(">") > $null;

    return $sb.ToString();
}

function Get-NodePathDescription([System.Xml.XmlNode] $xmlNode)
{
    if (($xmlNode -eq $null) -or ($xmlNode -is [System.Xml.XmlDocument]))
    {
        return [string]::Empty
    }

    return "$(Get-NodePathDescription $xmlNode.ParentNode)$(Get-NodeDescription $xmlNode)"
}

function Update-XmlNodeAttribute([string] $XmlDocumentPath, [string] $LocatorXPath, [string] $AttributeName, [string] $newValue)
{
	Write-Output $XmlDocumentPath
    [xml] $xml = Get-Content $XmlDocumentPath
	#$nsMgr = New-Object System.Xml.XmlNamespaceManager -ArgumentList $xml.NameTable
	#$nsMgr.AddNamespace('conf','"http://schemas.microsoft.com/.NetConfiguration/v2.0')

    $xmlNode = $xml.SelectSingleNode($LocatorXPath)
    if ($xmlNode -ne $null)
    {
        #$newValue = [Regex]::Replace($xmlNode.Attributes[$AttributeName].Value, $AttributeValuePattern, $AttributeValueReplacement, "IgnoreCase")
        if ($xmlNode.Attributes[$AttributeName].Value -ne $newValue)
        {
			Write-Output ("`tChanging attribute '{0}' on node {1} to value '{2}'" -f $AttributeName, (Get-NodePathDescription $xmlNode), $newValue)
            $xmlNode.Attributes[$AttributeName].Value = $newValue

            $xml.Save($XmlDocumentPath)
        }
    }
    else
    {
        Write-Error "Not able to find matching node"
    }
}

function Add-XmlNodeAppendChild([string] $XmlDocumentPath, [string] $LocatorXPath, [string] $DuplicityCheckXPath, [string] $NewChild)
{
	Write-Output $XmlDocumentPath
    [xml] $xml = Get-Content $XmlDocumentPath
    $xmlNode = $xml.SelectSingleNode($LocatorXPath)

    $NewChildXml = ([xml] "<root xmlns=`"$($xmlNode.NamespaceURI)`">$NewChild</root>").DocumentElement.ChildNodes[0]
    
    if ($xmlNode -ne $null)
    {
        if ($xml.SelectSingleNode($DuplicityCheckXPath) -eq $null)
        {
			Write-Output ("`tAppending new child node '{0}' to node {1}" -f $NewChildXml.OuterXml, (Get-NodePathDescription $xmlNode))
            $newChildImported = $xmlNode.OwnerDocument.ImportNode($NewChildXml, $true)
            $xmlNode.AppendChild($newChildImported) > $null

            $xml.Save($XmlDocumentPath)
        }
        else
        {
			Write-Output "`tFile up to date"
        }
    }
    else
    {
        Write-Error "Not able to find matching node"
    }
}

function Remove-XmlNode([string] $XmlDocumentPath, [string] $LocatorXPath)
{
	Write-Output $XmlDocumentPath
    [xml] $xml = Get-Content $XmlDocumentPath

    $xmlNode = $xml.SelectSingleNode($LocatorXPath)
    if ($xmlNode -ne $null)
    {
		Write-Output ("`tRemoving node {0}" -f (Get-NodePathDescription $xmlNode))
        $xmlNode.ParentNode.RemoveChild($xmlNode) > $null

        $xml.Save($XmlDocumentPath)
    }
    else
    {
		Write-Output "`tFile up to date"
    }
}

# Hashtable settings for each environment
$QATsettings = @{
	"PW" = "https://Funding.qat.cityindex.co.uk/EcheckService.svc";
}
$PPEsettings = @{
	"PW" = "https://Funding.ppe.cityindex.co.uk/EcheckService.svc";
}
$PRODINXsettings = @{
	"PW" = "https://Funding.live.cityindex.co.uk/EcheckService.svc";
}
$PRODRDBsettings = @{
	"PW" = "https://Funding.live.cityindex.co.uk/EcheckService.svc";
}
# Hashtable mapping environment name to each hashtable of settings
$settings = @{"QAT" = $QATsettings;"PPE" = $PPEsettings;"PROD-INX"=$PRODINXsettings;"PROD-RDB"=$PRODRDBsettings }
# Array of environments
$envs = @("QAT","PPE","PROD-INX","PROD-RDB")

# Pass Env Property along pipeline to generate list of configs which contain the Env name, for accessing the hashtable later
$webConfigs = $envs | ForEach-Object -Process { 
	gci "C:\dev\Projects-TFS\Genesis_Configs\$_" -Recurse | Add-Member -MemberType NoteProperty -Name Env -Value $_ -PassThru | where-object {$_.Extension -match "config" -and ($_.Name -match "Genesis2.exe") }
	} | Select-Object -Property FullName, Name, Env

function Update-Config()
{
	foreach($config in $webConfigs)
	{
		#Remove-XmlNode -XmlDocumentPath $config.FullName -LocatorXPath "/*[local-name()='configuration']/*[local-name()='system.serviceModel']/*[local-name()='bindings']/*[local-name()='binding']"
		$url = $settings.Get_Item($config.Env).Get_Item("PW")
		Add-XmlNodeAppendChild -XmlDocumentPath $config.FullName -LocatorXPath "/*[local-name()='configuration']/*[local-name()='system.serviceModel']/*[local-name()='client']" -DuplicityCheckXPath "//*[local-name()='endpoint' and @name='ECheckService']" -NewChild "<endpoint address=`"$url`" binding=`"basicHttpBinding`" bindingConfiguration=`"BasicHttpBinding_IFundingService`" behaviorConfiguration=`"SecurityHeaderClientBehaviour`" contract=`"CityIndex.Services.Funding.Contracts.ServiceContracts.IECheckService`" name=`"ECheckService`" />"
		
		#Add-XmlNodeAppendChild -XmlDocumentPath $config.FullName -LocatorXPath "/*[local-name()='configuration']/*[local-name()='system.serviceModel']/*[local-name()='bindings']/*[local-name()='basicHttpBinding']" -DuplicityCheckXPath "//*[local-name()='binding' and @name='BasicHttpBinding_IPendingWithdrawalService']" -NewChild "<binding name=`"BasicHttpBinding_IPendingWithdrawalService`" maxReceivedMessageSize=`"20971520`"><security mode=`"Transport`"><transport clientCredentialType=`"None`" proxyCredentialType=`"None`" realm=`"`" /><message clientCredentialType=`"UserName`" algorithmSuite=`"Default`" /></security></binding>"
	}
}

Update-Config