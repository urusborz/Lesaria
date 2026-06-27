$ErrorActionPreference = "Stop"

$desktop = [Environment]::GetFolderPath("Desktop")
$infPath = Join-Path $desktop "lesaria_distribution.inf"
$csrPath = Join-Path $desktop "lesaria_distribution.csr"

$inf = @"
[Version]
Signature="$Windows NT$"

[NewRequest]
Subject = "CN=Lesaria Distribution"
KeySpec = 1
KeyLength = 2048
Exportable = TRUE
MachineKeySet = FALSE
SMIME = FALSE
PrivateKeyArchive = FALSE
UserProtected = FALSE
UseExistingKeySet = FALSE
ProviderName = "Microsoft RSA SChannel Cryptographic Provider"
ProviderType = 12
RequestType = PKCS10
KeyUsage = 0xa0
HashAlgorithm = sha256
"@

[IO.File]::WriteAllText($infPath, $inf, [Text.Encoding]::ASCII)

if (Test-Path $csrPath) {
    Remove-Item $csrPath -Force
}

certreq -new $infPath $csrPath | Out-Host

Write-Host ""
Write-Host "Created CSR: $csrPath"
Write-Host "Private key was created in the Current User certificate store and marked exportable."
Write-Host "Upload this CSR when creating an Apple Distribution certificate."

