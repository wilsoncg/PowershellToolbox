[cmdletbinding()]
 Param()
 
If ($PSBoundParameters['Verbose']) {
    $VerbosePreference = 'Continue'
}

function Map-Scheme([string] $scheme)
{
	if($scheme -like "*mastercard*")
	{
		return "MCI"
	}
	if($scheme -like "*visa*")
	{
		return "VISA"
	}
	return "unknown"
}

function Map-Corporate([string] $brand)
{
	if($brand -like "business")
	{
		return "CP"
	}
	else
	{
		return "CN"
	}
}

function Map-Issuer([string] $issuer)
{
	if([string]::IsNullOrEmpty($issuer))
	{
		return "UNKNOWN"
	}
	if($issuer -like "*unknown*")
	{
		return "UNKNOWN"
	}
	else
	{
		if($issuer.Length -ge 30)
		{ return $issuer.ToUpper().SubString(0,30) }
		return $issuer.ToUpper()
	}
}

$codes = @{
"533" = "ABW"; 
"004" = "AFG"; 
"024" = "AGO"; 
"660" = "AIA"; 
"008" = "ALB"; 
"020" = "AND"; 
"784" = "ARE"; 
"032" = "ARG"; 
"051" = "ARM"; 
"016" = "ASM"; 
"010" = "ATA"; 
"260" = "ATF";
"028" = "ATG";
"036" = "AUS";
"040" = "AUT"; 
"031" = "AZE"; 
"108" = "BDI"; 
"056" = "BEL"; 
"204" = "BEN"; 
"854" = "BFA"; 
"050" = "BGD"; 
"100" = "BGR"; 
"048" = "BHR"; 
"044" = "BHS"; 
"070" = "BIH"; 
"112" = "BLR"; 
"084" = "BLZ"; 
"060" = "BMU"; 
"068" = "BOL"; 
"076" = "BRA"; 
"052" = "BRB"; 
"096" = "BRN"; 
"064" = "BTN"; 
"074" = "BVT"; 
"072" = "BWA"; 
"140" = "CAF"; 
"124" = "CAN"; 
"166" = "CCK"; 
"756" = "CHE"; 
"152" = "CHL"; 
"156" = "CHN"; 
"384" = "CIV"; 
"120" = "CMR"; 
"180" = "COD"; 
"178" = "COG"; 
"184" = "COK"; 
"170" = "COL"; 
"174" = "COM"; 
"132" = "CPV"; 
"188" = "CRI"; 
"192" = "CUB"; 
"531" = "CUW"; 
"162" = "CXR"; 
"136" = "CYM"; 
"196" = "CYP"; 
"203" = "CZE"; 
"280" = "DEU"; 
"262" = "DJI"; 
"212" = "DMA"; 
"208" = "DNK"; 
"214" = "DOM"; 
"012" = "DZA"; 
"218" = "ECU"; 
"818" = "EGY"; 
"232" = "ERI"; 
"732" = "ESH"; 
"724" = "ESP"; 
"233" = "EST"; 
"231" = "ETH"; 
"246" = "FIN"; 
"242" = "FJI"; 
"238" = "FLK"; 
"250" = "FRA"; 
"234" = "FRO"; 
"583" = "FSM"; 
"266" = "GAB"; 
"826" = "GBR"; 
"268" = "GEO"; 
"288" = "GHA"; 
"292" = "GIB"; 
"324" = "GIN"; 
"312" = "GLP"; 
"270" = "GMB"; 
"624" = "GNB"; 
"226" = "GNQ"; 
"300" = "GRC"; 
"308" = "GRD"; 
"304" = "GRL"; 
"320" = "GTM"; 
"254" = "GUF"; 
"316" = "GUM"; 
"328" = "GUY"; 
"344" = "HKG"; 
"334" = "HMD"; 
"340" = "HND"; 
"191" = "HRV"; 
"332" = "HTI"; 
"348" = "HUN"; 
"360" = "IDN"; 
"833" = "IMN"; 
"356" = "IND"; 
"086" = "IOT"; 
"372" = "IRL"; 
"364" = "IRN"; 
"368" = "IRQ"; 
"352" = "ISL"; 
"376" = "ISR"; 
"380" = "ITA"; 
"388" = "JAM"; 
"400" = "JOR"; 
"392" = "JPN"; 
"398" = "KAZ"; 
"404" = "KEN"; 
"417" = "KGZ"; 
"116" = "KHM"; 
"296" = "KIR"; 
"659" = "KNA"; 
"410" = "KOR"; 
"414" = "KWT"; 
"418" = "LAO"; 
"422" = "LBN"; 
"430" = "LBR"; 
"434" = "LBY"; 
"662" = "LCA"; 
"438" = "LIE"; 
"144" = "LKA"; 
"426" = "LSO"; 
"440" = "LTU"; 
"442" = "LUX"; 
"428" = "LVA"; 
"446" = "MAC"; 
"504" = "MAR"; 
"492" = "MCO"; 
"498" = "MDA"; 
"450" = "MDG"; 
"462" = "MDV"; 
"484" = "MEX"; 
"584" = "MHL"; 
"807" = "MKD"; 
"466" = "MLI"; 
"470" = "MLT"; 
"104" = "MMR"; 
"499" = "MNE"; 
"496" = "MNG"; 
"580" = "MNP"; 
"508" = "MOZ"; 
"478" = "MRT"; 
"500" = "MSR"; 
"474" = "MTQ"; 
"480" = "MUS"; 
"454" = "MWI"; 
"458" = "MYS"; 
"175" = "MYT"; 
"516" = "NAM"; 
"540" = "NCL"; 
"562" = "NER"; 
"574" = "NFK"; 
"566" = "NGA"; 
"558" = "NIC"; 
"570" = "NIU"; 
"528" = "NLD"; 
"578" = "NOR"; 
"524" = "NPL"; 
"520" = "NRU"; 
"554" = "NZL"; 
"512" = "OMN"; 
"586" = "PAK"; 
"591" = "PAN"; 
"612" = "PCN"; 
"604" = "PER"; 
"608" = "PHL"; 
"585" = "PLW"; 
"598" = "PNG"; 
"616" = "POL"; 
"630" = "PRI"; 
"408" = "PRK"; 
"620" = "PRT"; 
"600" = "PRY"; 
"275" = "PSE"; 
"258" = "PYF"; 
"634" = "QAT"; 
"900" = "QZZ"; 
"638" = "REU"; 
"642" = "ROM"; 
"643" = "RUS"; 
"646" = "RWA"; 
"682" = "SAU"; 
"729" = "SDN"; 
"686" = "SEN"; 
"702" = "SGP"; 
"239" = "SGS"; 
"654" = "SHN"; 
"744" = "SJM"; 
"090" = "SLB"; 
"694" = "SLE"; 
"222" = "SLV"; 
"674" = "SMR"; 
"706" = "SOM"; 
"666" = "SPM"; 
"688" = "SRB"; 
"678" = "STP"; 
"968" = "SUR"; 
"703" = "SVK"; 
"705" = "SVN"; 
"752" = "SWE"; 
"748" = "SWZ"; 
"534" = "SXM"; 
"690" = "SYC"; 
"760" = "SYR"; 
"796" = "TCA"; 
"148" = "TCD"; 
"768" = "TGO"; 
"764" = "THA"; 
"762" = "TJK"; 
"772" = "TKL"; 
"795" = "TKM"; 
"776" = "TON"; 
"780" = "TTO"; 
"788" = "TUN"; 
"792" = "TUR"; 
"798" = "TUV"; 
"158" = "TWN"; 
"834" = "TZA"; 
"800" = "UGA"; 
"804" = "UKR"; 
"581" = "UMI"; 
"858" = "URY"; 
"840" = "USA"; 
"860" = "UZB"; 
"336" = "VAT"; 
"670" = "VCT"; 
"862" = "VEN"; 
"092" = "VGB"; 
"850" = "VIR"; 
"704" = "VNM"; 
"548" = "VUT"; 
"876" = "WLF"; 
"882" = "WSM"; 
"887" = "YEM"; 
"710" = "ZAF"; 
"894" = "ZMB"; 
"716" = "ZWE"; }
function Get-AlphaCodeFromNumericCode([string] $numericCode)
{
	return $codes.Get_Item($numericCode)
}

function Get-NumericCodeFromAlphaCode([string] $alphaCode)
{
	return $codes.Keys | ? { $codes[$_] -eq $alphaCode }
}

function Check-bin ([string] $bin)
{
	$url = "https://lookup.binlist.net/$bin"
	Write-Verbose "Url $url"
	$result = Invoke-RestMethod -Uri $url -Headers @{ "Accept-Version" = "3" }
	$binInfo = @{}
	$binInfo.Scheme = Map-Scheme $($result.scheme).ToUpper()
	$binInfo.CardType = $($($result).'type').ToUpper()
	$binInfo.CardScheme = "$($binInfo.Scheme) $($binInfo.CardType)"
	$binInfo.CountryNumericCode = $result.country.Numeric
	$binInfo.AlphaCode = Get-AlphaCodeFromNumericCode $result.Country.Numeric
	$binInfo.Corporate = Map-Corporate $result.brand
	$binInfo.Issuer = Map-Issuer $result.bank.name
	$binInfo.Bin = $bin
	return $binInfo	
}

function To-BinInfoFromCsv($bin)
{
	Write-Verbose "Creating binInfo from $($bin.number)"
	$binInfo = @{}
	$binInfo.Scheme = Map-Scheme $($bin.scheme).ToUpper()
	$binInfo.CardType = $($($bin).'type').ToUpper()
	$binInfo.CardScheme = "$($binInfo.Scheme) $($binInfo.CardType)"
	$binInfo.CountryNumericCode = Get-NumericCodeFromAlphaCode $bin.country.ToUpper()
	$binInfo.AlphaCode = $bin.country.ToUpper()
	$binInfo.Corporate = Map-Corporate $bin.brand
	$binInfo.Issuer = Map-Issuer $bin.issuer
	$binInfo.Bin = $bin.number
	return $binInfo	
}

function To-Sql($binInfo)
{
	$insert = "INSERT INTO @tblTempTable([LowerRange], [UpperRange], [CardType], [CardScheme], [Issuer], [CountryAlphaCode], [CountryNumericCode]) VALUES "
	$values = "('$($binInfo.bin)000', '$($binInfo.bin)000', '$($binInfo.Corporate)', '$($binInfo.CardScheme)', '$($binInfo.Issuer)', '$($binInfo.AlphaCode)', '$($binInfo.CountryNumericCode)')"
	return "$insert $values"
}

function match($bin, $data)
{
	return 
		$data | 
		%{ 
			if($bin -eq $_.number)
			{
				Write-Verbose "$bin found."
				return $_
			}
		}
}

function Check-BinsInDatacashInfoTable($binsToCheck)
{
	$inExpression = [string]::Join(",", $binsToCheck.bin)
	$sqlQuery = "select ec.number,ec.scheme,ec.issuer,ci.country,ec.brand,ec.type from [dbo].[cardinfo-enhanced] ec inner join [dbo].[cardinfo] ci on ec.number = ci.number where ec.number in ($inExpression)"
	Write-Verbose "Running query: $sqlQuery"
	Invoke-Sqlcmd -Query $sqlQuery -ServerInstance "(localdb)\ProjectsV13" -Database "BinNumbers"
}

function Get-Country($bin)
{
	$inExpression = [string]::Join(",", $bin.Bin)
	$sqlQuery = "select country from [dbo].[cardinfo] where number in ($inExpression)"
	Write-Verbose "Running query: $sqlQuery"
	Invoke-Sqlcmd -Query $sqlQuery -ServerInstance "(localdb)\ProjectsV13" -Database "BinNumbers"
}

function Check-BinsInEFTCardBinRange($binsToCheck)
{
	$padded = $binsToCheck | % { "'$($_.bin)"+"000'" }
	$inExpression = [string]::Join(",", $padded)
	$sqlQuery = "select * from EFTCardBinRange where LowerRange in ($inExpression)"
	Write-Verbose "Running query: $sqlQuery"
	Invoke-Sqlcmd -Query $sqlQuery -ServerInstance "pkh-srv-del16.cityindex.co.uk" -Database "Payments_cwilson_Genesis_20171212"
}

function To-BinInfoForMissingCountry($binInfo)
{
	if([string]::IsNullOrEmpty($binInfo.AlphaCode))
	{
		$country = $(Get-Country $binInfo).Country.ToUpper() #| select-object @{ Name="country";Expression={$_."country".ToUpper()} }
		$binInfo.CountryNumericCode = Get-NumericCodeFromAlphaCode $country
		$binInfo.AlphaCode = $country
	}
	return $binInfo	
}

$binsToExamine = Import-Csv C:\dev\Projects-TFS\PaymentTeam\binnumbers.csv |
	select-object @{ Name="bin";Expression={$_."CardNumber".Substring(0,6)} } -Unique
Write-Verbose "$($binsToExamine.Count) bins to examine"

$binsInDb = Check-BinsInEFTCardBinRange $binsToExamine
Write-Verbose "Found $($binsInDb.Count) bins in EFTCardBinRange table"

$binsCandidates =
	$binsToExamine |
	Where-object { $binsInDb.LowerRange.Contains("$($_.bin)000") -eq $false }
Write-Verbose "$($binsCandidates.Count) bins to check against Datacash bin info"

$binInfos = 
	Check-BinsInDatacashInfoTable $binsCandidates | 
	%{ To-BinInfoFromCsv $_ } |
	%{ To-Sql $_ } 	| 
	%{ Add-Content -Path "C:\dev\Projects-TFS\PaymentTeam\bins.sql" -Value $_ -PassThru }


#$binInfos | ft -AutoSize @{Expression={$_.Scheme};Label="Scheme";}, @{Expression={$_.CardType};Label="CardType";}

#Get-BinInfo
#To-Sql (Check-bin "559861")

#$binsInDb = Check-BinsInEFTCardBinRange $binsToFind #| select-object @{ Name="bin"; Expression={$_.LowerRange} }
#$binsInDb
#get-member -InputObject $binsInDb 
#$binsInDb | select-object -first 1 | % { get-member -InputObject $_  }
#$binsInDb.LowerRange.Contains("400733000")

#$binsToFind | 
#	%{ 
#		$padded = "$($_.bin)000"
#		$contains = $binsInDb.LowerRange.Contains($padded)
#		$_ | Add-Member -MemberType NoteProperty -Name ExistsInDb -Value $contains -PassThru 
#	}