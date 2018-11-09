$name = @{ Namespace = 'root\cimv2\power' }
$lid = '5ca83367-6e45-459f-a27b-476b1d01c936'
# Subgroup GUID: 4f971e89-eebd-4455-a8de-9e59040e7347  (Power buttons and lid)
$powerAndLid = '4f971e89-eebd-4455-a8de-9e59040e7347'
$g = (Get-WmiObject @Name Win32_PowerPlan -Filter "IsActive = TRUE") -replace '.*(\{.*})"', '$1'
$active = [System.Guid]::Parse("$g").Guid

powercfg -SETACVALUEINDEX $active $powerAndLid $lid 0 #0 = do nothing

# $class = ([wmi] '\root\cimv2\power:Win32_PowerSettingDataIndex.InstanceID="Microsoft:PowerSettingDataIndex\\$active\\DC\\$lid"')
# $class.SettingIndexValue = 0
# $class.Put()