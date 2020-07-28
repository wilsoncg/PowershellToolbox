$subPath = "HKLM:\SOFTWARE\Classes\packagedcom\package\"

$skypePackageId = 
    dir $subPath | 
    ? { $_.Name -like '*skypeapp*' } | 
    select-object -Property name | 
    % { $_.Name } | 
    split-path -Leaf

$withoutClassId = "$subpath" + "$skypePackageId\class\"

$classId = 
    dir $withoutClassId | 
    ? { $_.Property -like '*DllPath*' } | 
    % { $_.Name } |
    split-path -leaf    

$pathWithClassId = "$subpath" + "$skypePackageId\class\$classId"
if((Test-Path $pathWithClassId) -and ($classId -ne $null))
{
    Write-Host "Found $pathWithClassId"
    pushd $withoutClassId
    remove-item $classId -confirm
    popd
}