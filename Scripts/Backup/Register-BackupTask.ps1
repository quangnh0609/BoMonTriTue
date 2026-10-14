param(
    [Parameter(Mandatory=$true)][string]$ConfigPath,
    [string]$TaskName = 'BoMonTriTue-Backup-ToDrive'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$config = (Resolve-Path -LiteralPath $ConfigPath).Path
$script = Join-Path $PSScriptRoot 'Backup-ToDrive.ps1'
if ($config.Contains('"') -or $script.Contains('"')) { throw 'Paths cannot contain quotes.' }
$credential = Get-Credential -Message 'Windows account used for SQL backup and Google Drive upload'
$action = New-ScheduledTaskAction -Execute "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument "-NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$script`" -ConfigPath `"$config`""
$trigger = New-ScheduledTaskTrigger -Daily -At '06:00'
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Hours 12)
Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -User $credential.UserName -Password $credential.GetNetworkCredential().Password -Description 'Daily SQL Server backup to Google Drive; retain 30 days.' | Out-Null
Write-Output "Registered $TaskName at 06:00 in the server's local timezone."
