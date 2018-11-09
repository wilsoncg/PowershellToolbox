Param(
    [string] $file
)
#  https://blogs.technet.microsoft.com/heyscriptingguy/2014/03/22/weekend-scripter-use-powershell-to-investigate-file-signaturespart-1/
$filePath = Convert-Path .\$file
$filestream = New-Object IO.FileStream -ArgumentList $filePath, ([IO.FileMode]::Open), ([IO.FileAccess]::Read)
$ByteOffset = 0
$ByteLimit = 3
$filestream.Position = $ByteOffset

$bytebuffer = New-Object "Byte[]" -ArgumentList $ByteLimit
[void]$filestream.Read($bytebuffer, 0, $bytebuffer.Length)
$filestream.Close()

if(!(($bytebuffer[0] -eq 0xEF) -and 
	($bytebuffer[1] -eq 0xBB) -and 
	($bytebuffer[2] -eq 0xBF)))
{
	Write-Warning "No BOM found"
}
else
{
	Write-Host "BOM found"
}

$bytebuffer | % { $result = "" } { $result += "{0:X}" -f $_ } { $result }