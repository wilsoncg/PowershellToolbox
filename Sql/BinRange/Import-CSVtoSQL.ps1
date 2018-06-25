# stolen from internet https://gallery.technet.microsoft.com/scriptcenter/Import-Large-CSVs-into-SQL-216223d9

#################################################### 
# 
# PowerShell CSV to SQL Import Script 
# 
#################################################### 
 
# Database variables 
$sqlserver = "(localdb)\ProjectsV13" 
$database = "BinNumbers" 
$table = "[cardinfo]" 
  
# CSV variables 
$csvfile = "C:\dev\Projects-TFS\PaymentTeam\CardInfo\CardInfo.csv" 
$csvdelimiter = "," 
$FirstRowColumnNames = $true 
  
################### No need to modify anything below ################### 
Write-Host "Script started..." 
$elapsed = [System.Diagnostics.Stopwatch]::StartNew()  
[void][Reflection.Assembly]::LoadWithPartialName("System.Data") 
[void][Reflection.Assembly]::LoadWithPartialName("System.Data.SqlClient") 
[void][Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic") 
  
# 50k worked fastest and kept memory usage to a minimum 
$batchsize = 50000 
  
# Build the sqlbulkcopy connection, and set the timeout to infinite 
$connectionstring = "Data Source=$sqlserver;Integrated Security=true;Initial Catalog=$database;" 
$bulkcopy = New-Object Data.SqlClient.SqlBulkCopy($connectionstring, [System.Data.SqlClient.SqlBulkCopyOptions]::TableLock) 
$bulkcopy.DestinationTableName = $table 
$bulkcopy.bulkcopyTimeout = 0 
$bulkcopy.batchsize = $batchsize 
  
# Create the datatable, and autogenerate the columns. 
$datatable = New-Object System.Data.DataTable 
  
# Open the text file from disk 
#$reader = New-Object System.IO.StreamReader($csvfile) 
$reader = New-Object Microsoft.VisualBasic.FileIO.TextFieldParser($csvfile)
$reader.Delimiters = @(",")
$columns = (Get-Content $csvfile -First 1).Split($csvdelimiter) 
if ($FirstRowColumnNames -eq $true) { $null = $reader.readLine() } 
  
foreach ($column in $columns) {  
    $null = $datatable.Columns.Add() 
} 
  
# Read in the data, line by line 
while (($line = $reader.ReadFields()) -ne $null)  { 
    
	#$split = $line.Split($csvdelimiter)
	$split = $line
	if($split.Length -ne $columns.Count)
	{
		Write-Warning "$split.Count <> $columns.Count!"
	}
    $null = $datatable.Rows.Add($split) 
 
    $i++; if (($i % $batchsize) -eq 0) {  
        $bulkcopy.WriteToServer($datatable)  
        Write-Host "$i rows have been inserted in $($elapsed.Elapsed.ToString())." 
        $datatable.Clear()  
    }  
}  
  
# Add in all the remaining rows since the last clear 
if($datatable.Rows.Count -gt 0) { 
    $bulkcopy.WriteToServer($datatable) 
    $datatable.Clear() 
} 
  
# Clean Up 
$reader.Close(); $reader.Dispose() 
$bulkcopy.Close(); $bulkcopy.Dispose() 
$datatable.Dispose() 
  
Write-Host "Script complete. $i rows have been inserted into the database." 
Write-Host "Total Elapsed Time: $($elapsed.Elapsed.ToString())" 
# Sometimes the Garbage Collector takes too long to clear the huge datatable. 
[System.GC]::Collect()