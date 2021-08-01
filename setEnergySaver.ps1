function LocalRegistry([string]$path, [string]$key, [string]$value)
{
	$exists = (get-item $path).GetValue($key) -ne $null
	if(!$exists)
	{
		Write-Verbose "Updating $path/$key to $value"
		New-ItemProperty -Path $path -Name $key -PropertyType DWORD -Value ([convert]::ToInt32($value))
	}
}
function createFolder([string]$folder)
{
	if(!(Test-Path $folder))
	{
		Write-Host "Creating directory $folder"
		New-Item -ItemType Directory -Path $folder | out-null
	}
}

# https://docs.microsoft.com/en-us/windows-hardware/customize/power-settings/battery-threshold
# PowerCfg: ESBATTTHRESHOLD
# set registry value, doesn't seem to activate DC battery saver power plan

createFolder "HKLM:\SOFTWARE\Policies\Microsoft\Power"
createFolder "HKLM:\SOFTWARE\Policies\Microsoft\Power\PowerSettings"
createFolder "HKLM:\SOFTWARE\Policies\Microsoft\Power\PowerSettings\E69653CA-CF7F-4F05-AA73-CB833FA90AD4"

LocalRegistry "HKLM:\SOFTWARE\Policies\Microsoft\Power\PowerSettings\E69653CA-CF7F-4F05-AA73-CB833FA90AD4" "DCSettingIndex" "95"