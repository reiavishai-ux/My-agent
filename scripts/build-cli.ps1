$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$git = 'C:/Program Files/Git/cmd/git.exe'
$go = 'C:/Program Files/Go/bin/go.exe'
$python = Join-Path $env:LOCALAPPDATA 'Programs/Python/Python313/python.exe'
$source = Join-Path $root '.local/source-fee3f8a'
$archive = Join-Path $root '.local/source-fee3f8a.zip'
$upstream = Join-Path $root '.local/upstream'
$expected = 'fee3f8a8184871ff6626d3ecc58cd0574853038c'
$actual = & $git -c ('safe.directory=' + $upstream.Replace('\','/')) -C $upstream rev-parse $expected
if ($LASTEXITCODE -ne 0 -or $actual -ne $expected) { throw 'Unexpected upstream source commit.' }
if (Test-Path -LiteralPath $source) { throw 'Build source already exists. Review it rather than overwriting.' }
& $git -c ('safe.directory=' + $upstream.Replace('\','/')) -C $upstream archive --format=zip ('--output=' + $archive) $expected
if ($LASTEXITCODE -ne 0) { throw 'Source archive failed.' }
Expand-Archive -LiteralPath $archive -DestinationPath $source
& $python (Join-Path $PSScriptRoot 'patch_upstream.py') $source
if ($LASTEXITCODE -ne 0) { throw 'Source patch failed.' }
$compiler = Get-ChildItem (Join-Path $env:LOCALAPPDATA 'Microsoft/WinGet/Packages') -Filter gcc.exe -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.FullName -match 'BrechtSanders.*mingw64\\bin\\gcc.exe$' } | Select-Object -First 1
if (-not $compiler) { throw 'WinLibs gcc.exe was not found.' }
$env:PATH = $compiler.DirectoryName + ';' + $env:PATH
$env:CC = $compiler.FullName
$env:CGO_ENABLED = '1'
$env:GOMODCACHE = Join-Path $root '.local/gomodcache'
$env:GOCACHE = Join-Path $root '.local/gocache'
Push-Location $source
try {
    & $go mod download
    if ($LASTEXITCODE -ne 0) { throw 'Dependency download failed.' }
    & $go test ./...
    if ($LASTEXITCODE -ne 0) { throw 'Upstream tests failed.' }
    & $go build -ldflags '-X main.version=fee3f8a-my-agent-text-only -extldflags=-static' -o (Join-Path $root '.local/bin/whatsapp-cli-text-only.exe') .
    if ($LASTEXITCODE -ne 0) { throw 'Build failed.' }
} finally { Pop-Location }
& (Join-Path $root '.local/bin/whatsapp-cli-text-only.exe') version
