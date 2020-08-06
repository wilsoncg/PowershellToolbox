# See also get-filehash -Algorithm SHA256
Param(
    [string[]] $toHash
)

$hash = 
    [System.IO.File]::OpenRead($toHash) | 
        % { $sha = New-Object System.Security.Cryptography.SHA256CryptoServiceProvider;$sha.ComputeHash($_) } | 
        #% { $result = "" } { $result += "{0:x2}" -f $_ } { $result } | 
        #% { $result = [System.Collections.Generic.List[char]]::new() } { [byte]$byte=$_; $result.Add([System.Convert]::ToChar($byte)) } { $result }
        % { $result = [System.Collections.Generic.List[byte]]::new() } { [byte]$byte=$_; $result.Add($byte) } { $result }
[System.Convert]::ToBase64String($hash)