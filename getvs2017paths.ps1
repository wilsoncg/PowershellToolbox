function getBuildPath
{
	if($env:VSINSTALLDIR -ne $null -and (test-path $env:VSINSTALLDIR)){
		return (join-path $env:VSINSTALLDIR "MSBuild")
	}

	$vs2017paths = @(
		$(join-path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\2017\BuildTools\MSBuild\15.0\Bin\MSBuild.exe"),
		$(join-path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\2017\Enterprise\MSBuild\15.0\Bin\MSBuild.exe"),
		$(join-path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\2017\Professional\MSBuild\15.0\Bin\MSBuild.exe"),
		$(join-path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\2017\Community\MSBuild\15.0\Bin\MSBuild.exe"))

	$valid2017paths =
		$vs2017paths | 
		% { @{ path = $_; exists = (test-path $_)} } |
		? { $_.exists -eq $true }  

	if(($valid2017paths).Count -ge 1) {
		return ($valid2017paths | select -First 1).path
	}
}

$path = getBuildPath
Write-Host $path