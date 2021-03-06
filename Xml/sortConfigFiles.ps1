Param(
    [string] $TibService = '2001',
  	[string] $TibNetwork = ';239.10.20.1',
    [string] $TibDaemon = 'localhost:7500',
    [string] $TibPrefix = 'LONWS01157.DATA.',
	[string] $path = 'C:\dev\Projects-TFS\Genesis_FundingEcheck\Main\UiFramework\',
	[string] $datasource = '(localdb)\ProjectsV13',
	[string] $dbName = 'Genesis',
	[switch] $dbUntrustedConnection = $false
)
If ($PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
}

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

function Update-XmlNodeAttribute([string] $XmlDocumentPath, [string] $LocatorXPath, [string] $AttributeName, [string] $AttributeValuePattern, [string] $AttributeValueReplacement)
{
	Write-Debug $XmlDocumentPath
    [xml] $xml = Get-Content $XmlDocumentPath

    $xmlNode = $xml.SelectSingleNode($LocatorXPath)
    if ($xmlNode -ne $null)
    {
        $newValue = [Regex]::Replace($xmlNode.Attributes[$AttributeName].Value, $AttributeValuePattern, $AttributeValueReplacement, "IgnoreCase")

        if ($xmlNode.Attributes[$AttributeName].Value -ne $newValue)
        {
			Write-Debug ("`tChanging attribute '{0}' on node {1} to value '{2}'" -f $AttributeName, (Get-NodePathDescription $xmlNode), $newValue)
            $xmlNode.Attributes[$AttributeName].Value = $newValue

            $xml.Save($XmlDocumentPath)
        }
        else
        {
			Write-Debug "Nothing to update, target attribute $($xmlNode.Attributes[$AttributeName].Value) equals $newValue"
        }
    }
    else
    {
        Write-Warning "Not able to find matching node at path $($LocatorXPath)"
    }
}

function Remove-XmlNode([string] $XmlDocumentPath, [string] $LocatorXPath)
{
	[xml] $xml = Get-Content $XmlDocumentPath
	#$nsMgr = New-Object System.Xml.XmlNamespaceManager -ArgumentList $xml.NameTable
	#$nsMgr.AddNamespace('conf','"http://schemas.microsoft.com/.NetConfiguration/v2.0')
    #$xmlNode = $xml.SelectSingleNode($LocatorXPath, $nsMgr)
	
	$xmlNode = $xml.SelectSingleNode($LocatorXPath)
    if ($xmlNode -ne $null)
    {
		$desc = Get-NodePathDescription $xmlNode
		Write-Debug "Removing node $desc"
        $xmlNode.ParentNode.RemoveChild($xmlNode) > $null

        $xml.Save($XmlDocumentPath)
    }
}

function Add-XmlNodeAppendChild([string] $XmlDocumentPath, [string] $LocatorXPath, [string] $DuplicityCheckXPath, [string] $NewChild)
{
	Write-Debug $XmlDocumentPath
    [xml] $xml = Get-Content $XmlDocumentPath
    $xmlNode = $xml.SelectSingleNode($LocatorXPath)

    $NewChildXml = ([xml] "<root xmlns=`"$($xmlNode.NamespaceURI)`">$NewChild</root>").DocumentElement.ChildNodes[0]
    
    if ($xmlNode -ne $null)
    {
        if ($xml.SelectSingleNode($DuplicityCheckXPath) -eq $null)
        {
			Write-Debug ("`tAppending new child node '{0}' to node {1}" -f $NewChildXml.OuterXml, (Get-NodePathDescription $xmlNode))
            $newChildImported = $xmlNode.OwnerDocument.ImportNode($NewChildXml, $true)
            $xmlNode.AppendChild($newChildImported) > $null

            $xml.Save($XmlDocumentPath)
        }
        else
        {
			Write-Debug "`tFile up to date"
        }
    }
}

function Remove-Vot([string]$documentPath)
{
	Remove-XmlNode -XmlDocumentPath $documentPath -LocatorXPath "/*[local-name()='configuration']/*[local-name()='configSections']/*[local-name()='section' and @name='DefaultTibTransport']"
	Remove-XmlNode -XmlDocumentPath $documentPath -LocatorXPath "/*[local-name()='configuration']/*[local-name()='configSections']/*[local-name()='section' and @name='SubjectPrefixes']"
	Remove-XmlNode -XmlDocumentPath $documentPath -LocatorXPath "/*[local-name()='configuration']/*[local-name()='configSections']/*[local-name()='section' and @name='StatisticsConfiguration']"
	Remove-XmlNode -XmlDocumentPath $documentPath -LocatorXPath "/*[local-name()='configuration']/*[local-name()='configSections']/*[local-name()='section' and @name='MessageLogger']"
	Remove-XmlNode -XmlDocumentPath $documentPath -LocatorXPath "/*[local-name()='configuration']/*[local-name()='DefaultTibTransport']"
	Remove-XmlNode -XmlDocumentPath $documentPath -LocatorXPath "/*[local-name()='configuration']/*[local-name()='SubjectPrefixes']"
	Remove-XmlNode -XmlDocumentPath $documentPath -LocatorXPath "/*[local-name()='configuration']/*[local-name()='MessageLogger']"
	Remove-XmlNode -XmlDocumentPath $documentPath -LocatorXPath "/*[local-name()='configuration']/*[local-name()='StatisticsConfiguration']"
}

function Remove-ExpirationPeriod([string]$documentPath)
{
	Remove-XmlNode -XmlDocumentPath $documentPath -LocatorXPath "//add[@key='RefundTransactionExpirationPeriod']"
}

function Update-Db([string]$documentPath)
{
    $locatorXPath = "/*[local-name()='configuration']/*[local-name()='connectionStrings']/*[local-name()='add' and @name='Atlas']"
    $attributeName = "connectionString"
    $attributeValuePattern = "(^|.*;)\s*(?<ApplicationName>Application\s+Name\s*=\s*[^;]+).*|^.*$" # We want to extract application name from the connection string
	$attributeValueReplacement = "Data Source=$($datasource);Initial Catalog=$($dbName);Trusted_Connection=yes;`${ApplicationName}"
	if($dbUntrustedConnection -eq $true) {
		$attributeValueReplacement = "Data Source=$($datasource);Initial Catalog=$($dbName);User Id=user;password=password;`${ApplicationName}"
	}
	# Use the appliction name (if captured) from the original connection string
    Update-XmlNodeAttribute $documentPath $locatorXPath $attributeName $attributeValuePattern $attributeValueReplacement
}

function Update-Tib([string]$documentPath)
{
	Update-XmlNodeAttribute -XmlDocumentPath $documentPath -LocatorXPath "/*[local-name()='configuration']/*[local-name()='CarbonTibcoTransport']" -AttributeName "Daemon" -AttributeValuePattern "^.*$" -AttributeValueReplacement $TibDaemon
	Update-XmlNodeAttribute -XmlDocumentPath $documentPath -LocatorXPath "/*[local-name()='configuration']/*[local-name()='CarbonTibcoTransport']" -AttributeName "Network" -AttributeValuePattern "^.*$" -AttributeValueReplacement $TibNetwork
    Update-XmlNodeAttribute -XmlDocumentPath $documentPath -LocatorXPath "/*[local-name()='configuration']/*[local-name()='CarbonTibcoTransport']" -AttributeName "Service" -AttributeValuePattern "^.*$" -AttributeValueReplacement $TibService
	Update-XmlNodeAttribute -XmlDocumentPath $documentPath -LocatorXPath "/*[local-name()='configuration']/*[local-name()='CarbonTibcoSubjects']" -AttributeName "Prefix" -AttributeValuePattern "^.*$" -AttributeValueReplacement $TibPrefix
}

function Stop-Spam([string]$documentPath)
{
	Add-XmlNodeAppendChild -XmlDocumentPath $documentPath -LocatorXPath "//*[local-name()='log4net']" -DuplicityCheckXPath "//*[local-name()='configuration']/*[local-name()='log4net']/*[local-name()='logger' and @name='CityIndex.Tibco.Carbon.Native.ListenerCallback+NoConflationStrategy']" -NewChild "<logger name=`"CityIndex.Tibco.Carbon.Native.ListenerCallback+NoConflationStrategy`"><level value=`"WARN`"/></logger>"
	Add-XmlNodeAppendChild -XmlDocumentPath $documentPath -LocatorXPath "//*[local-name()='log4net']" -DuplicityCheckXPath "//*[local-name()='configuration']/*[local-name()='log4net']/*[local-name()='logger' and @name='CityIndex.Tibco.Carbon.Native.NativeTransport']" -NewChild "<logger name=`"CityIndex.Tibco.Carbon.Native.NativeTransport`"><level value=`"WARN`"/></logger>"
	
	Remove-XmlNode -XmlDocumentPath $documentPath -LocatorXPath "//*[local-name()='log4net']/*[local-name()='appender' and @type='log4net.Appender.RollingFileAppender']/filter"
	Add-XmlNodeAppendChild -XmlDocumentPath $documentPath -LocatorXPath "//*[local-name()='appender' and @type='log4net.Appender.RollingFileAppender']" -DuplicityCheckXPath "//*[local-name()='filter']/*[local-name()='stringToMatch' and @value='Heartbeat from carbon.']" -NewChild "<filter type=`"log4net.Filter.StringMatchFilter`"><stringToMatch value=`"Heartbeat from carbon.`" /><acceptOnMatch value=`"false`" /></filter>"
	Add-XmlNodeAppendChild -XmlDocumentPath $documentPath -LocatorXPath "//*[local-name()='log4net']/*[local-name()='appender' and @type='log4net.Appender.RollingFileAppender']" -DuplicityCheckXPath "//*[local-name()='filter']/*[local-name()='stringToMatch' and @value='Performance Counter category']" -NewChild "<filter type=`"log4net.Filter.StringMatchFilter`"><stringToMatch value=`"Performance Counter category`" /><acceptOnMatch value=`"false`" /></filter>"
	Add-XmlNodeAppendChild -XmlDocumentPath $documentPath -LocatorXPath "//*[local-name()='log4net']/*[local-name()='appender' and @type='log4net.Appender.RollingFileAppender']" -DuplicityCheckXPath "//*[local-name()='filter']/*[local-name()='stringToMatch' and @value='messages in Tibco native queue']" -NewChild "<filter type=`"log4net.Filter.StringMatchFilter`"><stringToMatch value=`"messages in Tibco native queue`" /><acceptOnMatch value=`"false`" /></filter>"
	Add-XmlNodeAppendChild -XmlDocumentPath $documentPath -LocatorXPath "//*[local-name()='log4net']/*[local-name()='appender' and @type='log4net.Appender.RollingFileAppender']" -DuplicityCheckXPath "//*[local-name()='filter']/*[local-name()='stringToMatch' and @value='The module was expected to contain an assembly manifest.']" -NewChild "<filter type=`"log4net.Filter.StringMatchFilter`"><stringToMatch value=`"The module was expected to contain an assembly manifest.`" /><acceptOnMatch value=`"false`" /></filter>"
}

function Update-log4net([string]$documentPath)
{	
	Remove-XmlNode -XmlDocumentPath $documentPath -LocatorXPath "//*[local-name()='log4net']/*[local-name()='appender' and @type='log4net.Appender.RemoteSyslogAppender']"
	Remove-XmlNode -XmlDocumentPath $documentPath -LocatorXPath "//*[local-name()='log4net']/*[local-name()='root']/*[local-name()='appender-ref' and @ref='RemoteSyslogAppender']"
	Remove-XmlNode -XmlDocumentPath $documentPath -LocatorXPath "//*[local-name()='log4net']/*[local-name()='logger']/*[local-name()='appender-ref' and @ref='RemoteAppender']"
	#remove 
	#<datePattern value=".yyyyMMdd'.log'" />
    #<rollingStyle value="Date" />
	Remove-XmlNode -XmlDocumentPath $documentPath -LocatorXPath "//*[local-name()='log4net']/*[local-name()='appender']/*[local-name()='datePattern']"
	Remove-XmlNode -XmlDocumentPath $documentPath -LocatorXPath "//*[local-name()='log4net']/*[local-name()='appender']/*[local-name()='rollingStyle']"
	#set
	#<appendToFile value="true" />
    #<maximumFileSize value="10MB" />
	Update-XmlNodeAttribute -XmlDocumentPath $documentPath -LocatorXPath "/*[local-name()='log4net']/*[local-name()='appender']/*[local-name()='appendToFile']" -AttributeName "value" -AttributeValuePattern "^.*$" -AttributeValueReplacement "true"
}

$webConfigs = gci $path -Recurse | where-object {$_.Extension -match "config" -and ($_.Name -match "app.config" -or $_.Name -match "web.config" -or $_.Name -match "log4net.config") } 
foreach($config in $webConfigs)
{
	Write-Host $config.FullName
	#Remove-ExpirationPeriod $config.FullName
	Remove-Vot $config.FullName
	Update-Db $config.FullName
	Update-Tib $config.FullName
	Stop-Spam $config.FullName
	Update-log4net $config.FullName
}