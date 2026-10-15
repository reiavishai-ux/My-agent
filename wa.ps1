param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Arguments)
$ErrorActionPreference = 'Stop'
$python = Join-Path $env:LOCALAPPDATA 'Programs/Python/Python313/python.exe'
if (-not (Test-Path -LiteralPath $python)) { throw 'Python 3.13 is missing. See README.' }
$env:PYTHONUTF8 = '1'
& $python (Join-Path $PSScriptRoot 'assistant.py') @Arguments
exit $LASTEXITCODE
