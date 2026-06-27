param(
    [Parameter(Mandatory = $true)]
    [string]$ProvisionProfilePath
)

$ErrorActionPreference = "Stop"

if (!(Test-Path $ProvisionProfilePath)) {
    throw "Provisioning profile not found: $ProvisionProfilePath"
}

$base64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($ProvisionProfilePath))
$base64 | Set-Clipboard

Write-Host "BUILD_PROVISION_PROFILE_BASE64 copied to clipboard."

