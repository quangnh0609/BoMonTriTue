param([Parameter(Mandatory=$true)][string]$ConfigPath)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$connection = $null
$lock = $null
$logging = $false
try {
    $cfg = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
    if ($cfg.Database -ne 'BoMonTriTue') { throw 'This script is scoped to BoMonTriTue.' }
    if ([int]$cfg.RetentionDays -lt 1) { throw 'RetentionDays must be positive.' }
    if (-not [IO.Path]::IsPathRooted($cfg.BackupDirectory) -or $cfg.BackupDirectory.StartsWith('\\')) { throw 'BackupDirectory must be a local absolute path on the SQL Server machine.' }
    if ($cfg.DriveDestination -notmatch '^[^:]+:.+') { throw 'Use a dedicated remote folder, for example gdrive:SQLBackups/BoMonTriTue.' }
    foreach ($path in @($cfg.RcloneExe, $cfg.RcloneConfig)) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing prerequisite: $path" }
    }
    $root = [IO.Path]::GetFullPath($cfg.BackupDirectory)
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    $lock = [IO.File]::Open((Join-Path $root 'backup.lock'), 'OpenOrCreate', 'ReadWrite', 'None')
    $logDir = Join-Path $root 'logs'
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    Start-Transcript -Path (Join-Path $logDir (('run-{0}.log' -f (Get-Date -Format 'yyyyMMdd-HHmmss-fff')))) | Out-Null
    $logging = $true
    function Invoke-Rclone([string[]]$Arguments) {
        $output = & $cfg.RcloneExe @Arguments --config $cfg.RcloneConfig --retries 3 --low-level-retries 10
        if ($LASTEXITCODE -ne 0) { throw "rclone failed with exit code $LASTEXITCODE" }
        return $output
    }
    $builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
    $builder.DataSource = $cfg.SqlServer
    $builder.InitialCatalog = 'master'
    $builder.IntegratedSecurity = $true
    $builder.ApplicationName = 'BoMonTriTue scheduled backup'
    $connection = New-Object System.Data.SqlClient.SqlConnection($builder.ConnectionString)
    $connection.Open()
    function Invoke-Sql([string]$Sql) {
        $command = $connection.CreateCommand()
        try { $command.CommandText = $Sql; $command.CommandTimeout = 0; $command.ExecuteNonQuery() | Out-Null }
        finally { $command.Dispose() }
    }
    $name = 'BoMonTriTue_{0}_{1}.bak' -f (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ'), ([guid]::NewGuid().ToString('N'))
    $file = Join-Path $root $name
    $sqlPath = $file.Replace("'", "''")
    Invoke-Sql "BACKUP DATABASE [BoMonTriTue] TO DISK = N'$sqlPath' WITH COPY_ONLY, CHECKSUM;"
    $pattern = '^BoMonTriTue_(\d{8}T\d{6}Z)_[a-f0-9]{32}\.bak$'
    # Retry retained backups from previous failed uploads before deleting anything.
    foreach ($backup in Get-ChildItem -LiteralPath $root -File | Where-Object { $_.Name -match $pattern }) {
        $marker = $backup.FullName + '.uploaded'
        if (Test-Path -LiteralPath $marker) { continue }
        $verifyPath = $backup.FullName.Replace("'", "''")
        Invoke-Sql "RESTORE VERIFYONLY FROM DISK = N'$verifyPath' WITH CHECKSUM;"
        $remote = $cfg.DriveDestination.TrimEnd('/') + '/' + $backup.Name
        Invoke-Rclone @('copyto', $backup.FullName, $remote) | Out-Null
        $remoteHash = ((Invoke-Rclone @('md5sum', $remote)) -join "`n").Trim()
        $localHash = (Get-FileHash -LiteralPath $backup.FullName -Algorithm MD5).Hash
        if ($remoteHash -notmatch '^([a-fA-F0-9]{32})\s' -or $Matches[1] -ne $localHash) { throw "Uploaded checksum mismatch: $($backup.Name)" }
        Set-Content -LiteralPath $marker -Value $localHash -Encoding ASCII
        Write-Output "Uploaded and verified: $($backup.Name)"
    }
    $cutoff = (Get-Date).ToUniversalTime().AddDays(-[int]$cfg.RetentionDays)
    $remoteFiles = (Invoke-Rclone @('lsjson', $cfg.DriveDestination, '--files-only')) -join "`n" | ConvertFrom-Json
    foreach ($entry in $remoteFiles) {
        if ($entry.Name -notmatch $pattern -or $entry.Path -ne $entry.Name) { continue }
        $created = [datetime]::ParseExact($Matches[1], 'yyyyMMddTHHmmssZ', [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AssumeUniversal).ToUniversalTime()
        if ($created -lt $cutoff) {
            Invoke-Rclone @('deletefile', ($cfg.DriveDestination.TrimEnd('/') + '/' + $entry.Name)) | Out-Null
        }
    }
    foreach ($backup in Get-ChildItem -LiteralPath $root -File | Where-Object { $_.Name -match $pattern }) {
        $null = $backup.Name -match $pattern
        $created = [datetime]::ParseExact($Matches[1], 'yyyyMMddTHHmmssZ', [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AssumeUniversal).ToUniversalTime()
        $marker = $backup.FullName + '.uploaded'
        if ($created -lt $cutoff -and (Test-Path -LiteralPath $marker)) {
            Remove-Item -LiteralPath $backup.FullName
            Remove-Item -LiteralPath $marker
        }
    }
    Write-Output 'Backup, upload verification and retention completed.'
} catch {
    Write-Error $_ -ErrorAction Continue
    exit 1
} finally {
    if ($connection) { $connection.Dispose() }
    if ($logging) { Stop-Transcript | Out-Null }
    if ($lock) { $lock.Dispose() }
}
