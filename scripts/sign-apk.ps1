# =============================================================================
# scripts/sign-apk.ps1 — Generate keystore and configure APK signing (Windows)
# =============================================================================
# Usage (PowerShell):
#   .\scripts\sign-apk.ps1
#
# What this script does:
#   1. Generates scripts\keys.jks (if not already present)
#   2. Creates android\app\key.properties (used by build.gradle.kts)
#
# Prerequisites:
#   - Java JDK 17+ in PATH (run scripts\install.ps1 first)
# =============================================================================

$ErrorActionPreference = "Stop"
$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ProjectRoot = Split-Path -Parent $ScriptDir

$KeystorePath = Join-Path $ScriptDir "keys.jks"
$KeyPropsPath = Join-Path $ProjectRoot "android\app\key.properties"

function Log   ($msg) { Write-Host "[SIGN]    $msg" -ForegroundColor Cyan }
function Ok    ($msg) { Write-Host "[OK]      $msg" -ForegroundColor Green }
function Warn  ($msg) { Write-Host "[WARN]    $msg" -ForegroundColor Yellow }
function Err   ($msg) { Write-Host "[ERROR]   $msg" -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "══════════════════════════════════════════════════════" -ForegroundColor White
Write-Host "  TPQ Link — APK Signing Setup (Windows)              " -ForegroundColor White
Write-Host "══════════════════════════════════════════════════════" -ForegroundColor White
Write-Host ""

# ── Check keytool ─────────────────────────────────────────────────────────────
if (-not (Get-Command keytool -ErrorAction SilentlyContinue)) {
    Err "keytool not found. Install Java JDK 17 and add JAVA_HOME\bin to PATH. Run scripts\install.ps1."
}
Ok "keytool found: $(Get-Command keytool | Select-Object -ExpandProperty Source)"

# ── Handle existing keystore ──────────────────────────────────────────────────
$SkipKeygen = $false
if (Test-Path $KeystorePath) {
    Warn "keys.jks already exists at: $KeystorePath"
    $overwrite = Read-Host "Overwrite existing keystore? [y/N]"
    if ($overwrite -ne "y" -and $overwrite -ne "Y") {
        Log "Keeping existing keystore."
        $SkipKeygen = $true
    }
}

if (-not $SkipKeygen) {
    Write-Host ""
    Write-Host "Enter keystore information (press Enter to accept default):" -ForegroundColor White
    Write-Host ""

    $KeyAlias = Read-Host "  Key alias        [tpq-release]"
    if ([string]::IsNullOrWhiteSpace($KeyAlias)) { $KeyAlias = "tpq-release" }

    $KeyPasswordInput = Read-Host "  Key password     (hidden)" -AsSecureString
    $KeyPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($KeyPasswordInput))
    if ([string]::IsNullOrWhiteSpace($KeyPassword)) {
        $KeyPassword = "tpq@Link2024"
        Warn "Using default password: $KeyPassword — change this in production!"
    }

    $StorePasswordInput = Read-Host "  Store password   (Enter = same as key password)" -AsSecureString
    $StorePassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($StorePasswordInput))
    if ([string]::IsNullOrWhiteSpace($StorePassword)) { $StorePassword = $KeyPassword }

    $CN     = Read-Host "  Name / org       [TPQ Futuhil Hidayah]"
    $Org    = Read-Host "  Organization     [Futuhil Hidayah Wal Nikmah]"
    $City   = Read-Host "  City             [Indonesia]"
    $State  = Read-Host "  State/Province   [Indonesia]"
    $Country = Read-Host "  Country code     [ID]"
    $ValidityYears = Read-Host "  Validity (years) [25]"

    if ([string]::IsNullOrWhiteSpace($CN))            { $CN = "TPQ Futuhil Hidayah" }
    if ([string]::IsNullOrWhiteSpace($Org))           { $Org = "Futuhil Hidayah Wal Nikmah" }
    if ([string]::IsNullOrWhiteSpace($City))          { $City = "Indonesia" }
    if ([string]::IsNullOrWhiteSpace($State))         { $State = "Indonesia" }
    if ([string]::IsNullOrWhiteSpace($Country))       { $Country = "ID" }
    if ([string]::IsNullOrWhiteSpace($ValidityYears)) { $ValidityYears = "25" }

    $ValidityDays = [int]$ValidityYears * 365
    $Dname = "CN=$CN, OU=$Org, O=$Org, L=$City, ST=$State, C=$Country"

    Write-Host ""
    Log "Generating keystore..."
    Log "  Path     : $KeystorePath"
    Log "  Alias    : $KeyAlias"
    Log "  Validity : $ValidityYears years"
    Log "  DN       : $Dname"
    Write-Host ""

    keytool -genkey -v `
        -keystore $KeystorePath `
        -storetype JKS `
        -alias $KeyAlias `
        -keyalg RSA -keysize 2048 `
        -validity $ValidityDays `
        -storepass $StorePassword `
        -keypass $KeyPassword `
        -dname $Dname

    Ok "keys.jks generated: $KeystorePath"
} else {
    # Read existing values from key.properties if present
    if (Test-Path $KeyPropsPath) {
        $props = Get-Content $KeyPropsPath | Where-Object { $_ -match "=" } |
            ForEach-Object { $k, $v = $_ -split "=", 2; @{$k.Trim() = $v.Trim()} }
        $map = @{}; $props | ForEach-Object { $_.GetEnumerator() | ForEach-Object { $map[$_.Key] = $_.Value } }
        $KeyAlias     = $map["keyAlias"]
        $KeyPassword  = $map["keyPassword"]
        $StorePassword = $map["storePassword"]
    } else {
        $KeyAlias     = "tpq-release"
        $KeyPassword  = "tpq@Link2024"
        $StorePassword = $KeyPassword
        Warn "key.properties not found — generating with defaults."
    }
}

# ── Write key.properties ──────────────────────────────────────────────────────
$KeyPropsDir = Split-Path -Parent $KeyPropsPath
if (-not (Test-Path $KeyPropsDir)) { New-Item -ItemType Directory -Force -Path $KeyPropsDir | Out-Null }

Log "Writing key.properties to: $KeyPropsPath"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

@"
# ============================================================
# android/app/key.properties — Flutter release signing config
# Generated by scripts/sign-apk.ps1 on $timestamp
#
# WARNING: Do NOT commit this file to version control!
#          Ensure android/app/key.properties is in .gitignore
# ============================================================

storePassword=$StorePassword
keyPassword=$KeyPassword
keyAlias=$KeyAlias
storeFile=$KeystorePath
"@ | Set-Content -Path $KeyPropsPath -Encoding UTF8

Ok "key.properties written."
Write-Host ""
Write-Host "══════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  Signing setup complete!                              " -ForegroundColor Green
Write-Host "══════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "  Keystore   : $KeystorePath" -ForegroundColor White
Write-Host "  Properties : $KeyPropsPath" -ForegroundColor White
Write-Host ""
Write-Host "  Keep keys.jks safe — losing it prevents Play Store updates!" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Next step: .\scripts\build-apk.ps1 -SplitPerAbi" -ForegroundColor Cyan
