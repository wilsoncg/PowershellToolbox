function Get-ScriptDirectory {
	Split-Path -Parent $script:MyInvocation.MyCommand.Definition
}
$dir = Get-ScriptDirectory
$table = 'PayPalTransactionLedgerTransaction'

set-location "sqlserver:\SQL\pkh-srv-del16.cityindex.co.uk\default\Databases\Payments_cwilson_Genesis_20180802\Tables\dbo.$table\foreignkeys"

dir | % {
	$before = "IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = '$($_.Name)')
BEGIN
	ALTER TABLE [dbo].[$table]
	DROP CONSTRAINT [$($_.Name)]
END
"
	$create = "IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = '$($_.Name)')
BEGIN
	$($_.Script())
END
"
	$before + $create |	out-file -filepath "$dir\CreateForeignKeys.sql" -append
}

set-location $dir