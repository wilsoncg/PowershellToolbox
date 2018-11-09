function LocalRegistry([string]$path, [string]$key, [string]$value)
{
	$exists = (get-item $path).GetValue($key) -ne $null
	if(!$exists)
	{
		Write-Verbose "Updating $path/$key to $value"
		New-ItemProperty -Path $path -Name $key -PropertyType DWORD -Value ([convert]::ToInt32($value))
	}
}

LocalRegistry "HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NetFramework\v4.0.30319" "SchUseStrongCrypto" "1"
LocalRegistry "HKLM:\SOFTWARE\Microsoft\.NetFramework\v4.0.30319" "SchUseStrongCrypto" "1"
LocalRegistry "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp" "WINHTTP_OPTION_SECURE_PROTOCOLS" "2560"
LocalRegistry "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp" "WINHTTP_OPTION_SECURE_PROTOCOLS" "2560"