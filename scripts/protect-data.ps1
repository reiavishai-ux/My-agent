$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$configFile = Join-Path $root 'config.local.json'
$data = Join-Path $env:LOCALAPPDATA 'My-agent'
if (Test-Path -LiteralPath $configFile) {
    $config = Get-Content -LiteralPath $configFile -Raw | ConvertFrom-Json
    if ($config.data_dir) { $data = [IO.Path]::GetFullPath($config.data_dir) }
}
$data = [IO.Path]::GetFullPath($data)
$profileData = [IO.Path]::GetFullPath($env:LOCALAPPDATA).TrimEnd('\') + '\'
if (-not $data.StartsWith($profileData, [StringComparison]::OrdinalIgnoreCase) -or (Split-Path -Leaf $data) -ne 'My-agent') {
    throw 'This script only protects a dedicated My-agent folder under LOCALAPPDATA. Review custom-location ACLs separately.'
}
New-Item -ItemType Directory -Path $data -Force | Out-Null
$owner = [System.Security.Principal.WindowsIdentity]::GetCurrent().User
$system = New-Object System.Security.Principal.SecurityIdentifier('S-1-5-18')
$acl = Get-Acl -LiteralPath $data
$acl.SetAccessRuleProtection($true, $false)
foreach ($rule in @($acl.Access)) { $acl.RemoveAccessRuleSpecific($rule) }
foreach ($sid in @($owner, $system)) {
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($sid, 'FullControl', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
    $acl.AddAccessRule($rule)
}
Set-Acl -LiteralPath $data -AclObject $acl
$verified = Get-Acl -LiteralPath $data
if (-not $verified.AreAccessRulesProtected) { throw 'ACL inheritance is still enabled.' }
foreach ($rule in $verified.Access) {
    $sid = $rule.IdentityReference.Translate([System.Security.Principal.SecurityIdentifier])
    if ($sid -ne $owner -and $sid -ne $system) { throw 'Unexpected principal can access account data.' }
}
Write-Output 'Verified private data-directory ACL: current user and SYSTEM only.'
