<#
.SYNOPSIS
This script constructs a sequenced list of sql files from a specified directory and runs them in against the specified server

.DESCRIPTION
This script constructs a sequenced list of sql files from a specified directory and runs them in against the specified server

.PARAMETER CR
Specifies the CR Number to be deployed, this must be in the form: CR1234

.PARAMETER n
Optional. Specifies the Sequence Number of the script to be deployed, this must be in the form: 001

.PARAMETER R
Specifies whether the operation should be Input or Rollback, this must be in the form: Input or Rollback

.Parameter dbName
Specifies the database name, eg 'Genesis' or 'payments_genesis_010114'

.Parameter dbServer
Specifies the database server, eg'(local)' or '172.16.146.198'

.INPUTS
None, this script cannot be used in a pipeline

.OUTPUTS
Details the input and output the script has used

.EXAMPLE
C:\PS> .\Invoke-SQL_Script.ps1 -CR CR8897 -R Input

Description
-----------
This command will run all the scripts in the Input directory of CR 8897

.EXAMPLE
C:\PS> .\Invoke-SQL_Script.ps1 -CR CR8897 -n 001 -R Input

Description
-----------
This command will run just the first script in the Input directory of CR 8897

.EXAMPLE
C:\PS> .\Invoke-SQL_Script.ps1 -CR CR8897 -R Rollback

Description
-----------
This will run all the scripts in the rollback directory of CR 8897

.EXAMPLE
C:\PS> .\Invoke-SQL_Script.ps1 -CR CR8897 -n 007 -R Rollback

Description
-----------
This command will run just the seventh script in the Rollback directory of CR 8897

#>

##########################################
############# PARAMETERS #################
##########################################

Param(
    [Parameter(Mandatory=$true)]
    [string]$CR,
    [Parameter(Mandatory=$false)]
    [int]$n,
    [Parameter(Mandatory=$false)]
    [string]$R="Input",
    [Parameter(Mandatory=$false)]
    [string]$dbName="Genesis",
    [Parameter(Mandatory=$false)]
    [string]$dbServer="pkh-srv-del12",
	[Parameter(Mandatory=$false)]
    [string]$ScriptPath = "C:\dev\projects-tfs\genesis_temp\main\dbscripts"
)

# Set the active log file
$Log = "C:\Logs\SQL_Runner.log"

##########################################
############## FUNCTIONS #################
##########################################

$sqlerr = $null;
# Construct SQLCMD Command and execute it
Function SQLRun ($dbServer, $I, $U, $P, $RR, $dbName){
	# Check that the Input file has been defined correctly,
	# if it has then continue, if not then throw an error and stop
	If ($I) {
		$t = get-date -uformat "%Y%m%d-%H%M%S"
		$O = $I -Replace "\\$RR\\", "\Output\"
		$O = $O -Replace "sql$" , "txt"
		$O = $O -Replace ".txt" , "_$dbServer.txt"
		$O = $O -Replace ".txt" , "_$t.txt"
		$t = Get-Date
		Write-Host "INFO | $t > | $dbServer | CR: $CR | Started processing => Input: $I"
		
		##############################################
		##### HERE IS THE TARGET SQLCMD COMMAND ######
		##############################################
	
		$InputQuery = Get-Content $I -Raw | ForEach {$_ -replace [regex]::escape('[Genesis]'), "[$dbName]" }
		try {
			$SQL = Invoke-Sqlcmd -Query $InputQuery -ServerInstance $dbServer -Verbose -AbortOnError -ErrorVariable $sqlerr -ConnectionTimeout ([int]::MaxValue) -QueryTimeout ([int]::MaxValue)
			foreach($line in $SQL)
			{
				Add-Content -Path $O -Value $line
			}
		}
		catch
		{
			$t = Get-Date
			Add-Content $O "ERROR | $t > | $dbServer | CR: $CR | $Error | $InputQuery"
			Exit 2
		}
				
		#sqlcmd -S $dbServer -Q $InputQuery -b | Out-File $O -Encoding Ascii
	} Else {
		$t = get-date -uformat "%Y%m%d"
		Write-Host "ERROR [SQLRUN]| $t > | $dbServer | CR: $CR | Input not found or incorrect format => [Could not locate input file(s)]" -F Red
		Add-Content $Log "ERROR [SQLRUN]| $t > | $dbServer | CR: $CR | Input not found or incorrect format => [Could not locate input file(s)]"
		Exit 2
	}
}

##########################################



##########################################
######## VARIABLES and CONSTANTS #########
##########################################

# Define the Source location

$FullPath = $ScriptPath + "\" + $CR + "\" + $R
Write-Host $FullPath
$Output = $ScriptPath + "\" + $CR + "\Output"

# Create the Output directory if it doesn't already exist
If (! (Test-Path $Output)) 
{
	New-Item -ItemType Directory $Output -Force
}

##########################################
################# BODY ###################
##########################################

function GetSequenceNumberFromFileName([string]$fileName)
{
	$split = $fileName -split "_" | Select-Object -Last 1
	$seq = [int]::Parse($split)
	return $seq
}

# Create a HashTable object containing the scripts with their sequence numbers as the key
$OrderedScripts = @{}

function GetOrderedScripts([string]$path)
{
    $Scripts = gci $path -Filter *.sql		
	ForEach ($Script in $Scripts) 
	{
		If ($Script.name -match "_\d+.") 
		{
			$seqId = GetSequenceNumberFromFileName($Script.BaseName)
			$OrderedScripts.Add($seqId, $Script)
		}
	}
}

GetOrderedScripts($FullPath)

# Sort if more than one script
$OrderedScripts = $OrderedScripts.GetEnumerator() | Sort-Object Key
# Run through each script in order
ForEach ($dbScript in $OrderedScripts) 
{
	SQLRun -dbServer $dbServer -I $dbScript.Value.FullName -U $U -P $P -RR $R -dbName $dbName
}
##########################################