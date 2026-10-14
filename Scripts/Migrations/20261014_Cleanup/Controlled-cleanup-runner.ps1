param([Parameter(Mandatory=$true)][string]$ConnectionString)
$ErrorActionPreference='Stop'
$dir='D:\Project\BoMonTriTue\Scripts\Migrations\20261014_Cleanup'
$keep=@(Get-Content -LiteralPath (Join-Path $dir 'Retained-identities.json') -Raw|ConvertFrom-Json)
$removed=@(Import-Csv -LiteralPath (Join-Path $dir 'Removed-objects.csv'))
$c=New-Object System.Data.SqlClient.SqlConnection $ConnectionString
function QueryTable([string]$sql){$cmd=$c.CreateCommand();$cmd.CommandTimeout=180;$cmd.CommandText=$sql;$t=New-Object System.Data.DataTable;$t.Load($cmd.ExecuteReader());return ,$t}
function Execute([string]$sql){$cmd=$c.CreateCommand();$cmd.CommandTimeout=180;$cmd.CommandText=$sql;[void]$cmd.ExecuteNonQuery()}
function TableCounts([bool]$LockTables){
 $rows=@();foreach($o in $keep|Where-Object type -eq 'U'){
  $suffix=if($LockTables){' WITH (TABLOCKX,HOLDLOCK)'}else{''}
  $t=QueryTable ('SELECT COUNT_BIG(*) n FROM ['+$o.schema+'].['+$o.name+']'+$suffix)
  $rows+=[pscustomobject]@{name=$o.name;rows=[long]$t.Rows[0].n}
 };return $rows
}
try{
 $c.Open()
 $identity=QueryTable "SELECT CONVERT(nvarchar(128),SERVERPROPERTY('MachineName')) machine,DB_NAME() db"
 if($identity.Rows[0].machine -ne 'QUANGNH' -or $identity.Rows[0].db -ne 'TAPHOA_FBOHRMSP229_App'){throw 'Wrong server/database'}
 $actual=QueryTable 'SELECT object_id,SCHEMA_NAME(schema_id) schema_name,name,RTRIM(type) type FROM sys.objects WHERE is_ms_shipped=0'
 $systemChildren=QueryTable 'SELECT o.object_id,SCHEMA_NAME(o.schema_id) schema_name,o.name,RTRIM(o.type) type,p.name parent_name FROM sys.objects o JOIN sys.objects p ON p.object_id=o.parent_object_id WHERE o.is_ms_shipped=0 AND p.is_ms_shipped=1'
 foreach($o in $systemChildren.Rows){if($o.parent_name -ne 'dtproperties' -or $o.name -notin @('pk_dtproperties','DF__dtpropert__versi__39237A9A')){throw ('Unexpected system-owned child: '+$o.name)}}
 $systemChildIds=@($systemChildren.Rows|ForEach-Object object_id)
 $expected=@{};foreach($o in $keep){$expected[([string]$o.schema+'.'+$o.name)]=[string]$o.type}
 foreach($o in $removed){$expected[([string]$o.schema_name+'.'+$o.name)]=[string]$o.type}
 if($actual.Rows.Count -ne $expected.Count){throw 'Database object inventory changed; refusing stale deletion plan'}
 foreach($o in $actual.Rows){$key=[string]$o.schema_name+'.'+$o.name;if(-not $expected.ContainsKey($key) -or $expected[$key] -ne $o.type){throw ('Unexpected object: '+$key)}}
 foreach($o in $keep){$match=@($actual.Rows|Where-Object object_id -eq $o.object_id);if($match.Count -ne 1 -or $match[0].name -ne $o.name){throw ('Retained identity changed: '+$o.name)}}
 $deps=QueryTable 'SELECT referencing_id,referenced_id,referenced_database_name,referenced_schema_name,referenced_entity_name FROM sys.sql_expression_dependencies'
 $keepIds=@($keep|ForEach-Object object_id)
 foreach($d in $deps.Rows){if($d.referencing_id -in $keepIds){
  if($d.referenced_id -isnot [DBNull] -and $d.referenced_id -notin $keepIds){throw ('Retained dependency outside allowlist: '+$d.referenced_entity_name)}
  if($d.referenced_database_name -isnot [DBNull] -and -not ($d.referenced_database_name -eq 'a' -and $d.referenced_schema_name -eq 'Item' -and $d.referenced_entity_name -eq 'value')){throw ('Cross-database dependency: '+$d.referenced_database_name)}
 }}
 foreach($name in @('App','Sys')){Execute "RESTORE VERIFYONLY FROM DISK = N'D:\Project\BoMonTriTue\Databases\$name.bak'";Write-Output ($name+'.bak verified')}
 Execute 'SET XACT_ABORT ON; BEGIN TRANSACTION;'
 $before=TableCounts $true
 $before|Export-Csv -LiteralPath (Join-Path $dir 'Before-table-counts.csv') -NoTypeInformation -Encoding utf8
 $sql=Get-Content -LiteralPath (Join-Path $dir '02_RemoveUnusedAppObjects.sql') -Raw
 $sql=$sql.Replace('BEGIN TRANSACTION;','-- Transaction owned by controlled runner').Replace('COMMIT TRANSACTION;','-- Commit after verification')
 $batches=[regex]::Split($sql,'(?im)^\s*GO\s*\r?$');$n=0
 foreach($batch in $batches){if([string]::IsNullOrWhiteSpace($batch)){continue};Execute $batch;$n++;if($n%25 -eq 0){Write-Output "Executed $n cleanup batches"}}
 $after=TableCounts $false
 foreach($r in $before){$match=$after|Where-Object name -eq $r.name;if($match.rows -ne $r.rows){throw ('Row count changed: '+$r.name)}}
 $actual=QueryTable 'SELECT object_id,name,RTRIM(type) type FROM sys.objects WHERE is_ms_shipped=0'
 $actualIds=@($actual.Rows|Where-Object {$_.object_id -notin $systemChildIds}|ForEach-Object object_id)
 if($actualIds.Count -ne $keepIds.Count -or @($actualIds|Where-Object {$_ -notin $keepIds}).Count -gt 0 -or @($keepIds|Where-Object {$_ -notin $actualIds}).Count -gt 0){
  $extra=@($actual.Rows|Where-Object {$_.object_id -notin $keepIds}|ForEach-Object {"$($_.object_id):$($_.name):$($_.type)"})
  $missing=@($keep|Where-Object {$_.object_id -notin $actualIds}|ForEach-Object {"$($_.object_id):$($_.name):$($_.type)"})
  throw "Object allowlist mismatch actual=$($actualIds.Count) expected=$($keepIds.Count); extra=$($extra -join ','); missing=$($missing -join ',')"
 }
 foreach($o in $keep|Where-Object type -eq 'V'){[void](QueryTable ('SELECT TOP (0) * FROM ['+$o.schema+'].['+$o.name+']'))}
 [void](QueryTable "SELECT dbo.bet_check_right(id,N'bet_match_insert') allowed FROM dbo.userinfo2 WHERE user_yn=1")
 Execute 'COMMIT TRANSACTION;'
 $after|Export-Csv -LiteralPath (Join-Path $dir 'After-table-counts.csv') -NoTypeInformation -Encoding utf8
 @($systemChildren.Rows|ForEach-Object {[pscustomobject]@{object_id=$_.object_id;name=$_.name;type=$_.type;parent_name=$_.parent_name}})|Export-Csv -LiteralPath (Join-Path $dir 'Preserved-system-constraints.csv') -NoTypeInformation -Encoding utf8
 Write-Output "APP COMMITTED: $($actualIds.Count) retained objects; all 14 table counts unchanged; retained views and permission function readable."
 'App cleanup committed; Sys deletion not yet executed.'|Set-Content -LiteralPath (Join-Path $dir 'Execution-status.txt') -Encoding utf8
}catch{
 if($c.State -eq 'Open'){Execute 'IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION'}
 throw
}finally{$c.Dispose()}
