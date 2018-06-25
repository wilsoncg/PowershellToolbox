Param(
    [string[]] $toHash
)
$md5 = New-Object System.Security.Cryptography.MD5CryptoServiceProvider
$concat = $toHash | % { $result = "" } { $result += $_ } { $result }
$bytes = ([System.Text.Encoding]::UTF8).GetBytes($concat)
$md5.ComputeHash($bytes) | % { $result = "" } { $result += "{0:x2}" -f $_ } { $result }