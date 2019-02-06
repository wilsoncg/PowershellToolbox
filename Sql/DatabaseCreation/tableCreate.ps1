function Get-ScriptDirectory {
	Split-Path -Parent $script:MyInvocation.MyCommand.Definition
}
$dir = Get-ScriptDirectory
$table = 'PlaidSettings'

set-location "sqlserver:\SQL\pkh-srv-del16.cityindex.co.uk\default\Databases\Payments_cwilson_Genesis_20180802\Tables\dbo.$table"

dir | % {
	$before = "IF OBJECT_ID(N'dbo.$($_.Name)', N'U') IS NOT NULL
BEGIN
DROP TABLE [dbo].[$($_.Name)]
END
"
	$create = "IF OBJECT_ID(N'dbo.$($_.Name)', N'U') IS NULL
BEGIN
	$($_.Script())
END
"
	$before + $create |	out-file -filepath "$dir\CreateTable.sql" -append
}

set-location $dir