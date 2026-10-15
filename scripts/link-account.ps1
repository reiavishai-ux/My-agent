$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $root
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding
$Host.UI.RawUI.WindowTitle = 'My-agent WhatsApp account linking'
Write-Host 'In WhatsApp on your phone: Settings > Linked devices > Link a device.'
Write-Host 'Scan the QR shown below. No messages will be sent.'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'wa.ps1') auth
Write-Host 'Return to Codex when linking completes, or report the error shown above.'
