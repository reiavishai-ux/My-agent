param([ValidateSet('Enable','Disable','Status')][string]$Action = 'Status')
$ErrorActionPreference = 'Stop'
$taskName = 'My-agent WhatsApp Sync'
if ($Action -eq 'Enable') {
    $python = Join-Path $env:LOCALAPPDATA 'Programs/Python/Python313/pythonw.exe'
    $script = Join-Path $PSScriptRoot 'assistant.py'
    $taskAction = New-ScheduledTaskAction -Execute $python -Argument ('"' + $script + '" sync-start') -WorkingDirectory $PSScriptRoot
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
    $principal = New-ScheduledTaskPrincipal -UserId ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name) -LogonType Interactive -RunLevel Limited
    $settings = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew -ExecutionTimeLimit ([TimeSpan]::Zero) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -TaskName $taskName -Action $taskAction -Trigger $trigger -Principal $principal -Settings $settings -Description 'Local WhatsApp synchronization only. No AI approval or sending.' -Force | Select-Object TaskName,State
} elseif ($Action -eq 'Disable') {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
} else {
    Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue | Select-Object TaskName,State
}
