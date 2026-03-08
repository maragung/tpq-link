# =============================================================================
# scripts/build-apk.ps1 — Build release APK / AAB for TPQ Link (Windows)
# =============================================================================
# Usage (PowerShell):
#   .\scripts\build-apk.ps1 [-SplitPerAbi] [-Aab]
#
# Options:
#   -SplitPerAbi    Build separate APKs per ABI (arm64-v8a, armeabi-v7a, x86_64)
#   -Aab            Build Android App Bundle (.aab) for Play Store
#
# Prerequisites (run scripts\install.ps1 first):
#   - Flutter SDK in PATH
#   - Java JDK 17+
#   - scripts\keys.jks + android\app\key.properties (run sign-apk.ps1 first)
# =============================================================================

param(
    [switch]$SplitPerAbi,
    [switch]$Aab
)

$ErrorActionPreference = "Stop"
$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ProjectRoot = Split-Path -Parent $ScriptDir

function Log   ($msg) { Write-Host "[BUILD]   $msg" -ForegroundColor Cyan }
function Ok    ($msg) { Write-Host "[OK]      $msg" -ForegroundColor Green }
function Warn  ($msg) { Write-Host "[WARN]    $msg" -ForegroundColor Yellow }
function Err   ($msg) { Write-Host "[ERROR]   $msg" -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "══════════════════════════════════════════════════════" -ForegroundColor White
Write-Host "  TPQ Link — Build Release APK / AAB (Windows)        " -ForegroundColor White
Write-Host "══════════════════════════════════════════════════════" -ForegroundColor White
Write-Host ""

# ── Check Flutter ─────────────────────────────────────────────────────────────
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Err "Flutter not found. Run scripts\install.ps1 first or add Flutter to PATH."
}
Log "Flutter: $((flutter --version 2>&1) | Select-Object -First 1)"

# ── Check signing config ──────────────────────────────────────────────────────
$Keystore = Join-Path $ScriptDir "keys.jks"
$KeyProps = Join-Path $ProjectRoot "android\app\key.properties"

$Signed = (Test-Path $Keystore) -and (Test-Path $KeyProps)
if ($Signed) {
    Ok "Release signing configured."
} else {
    Warn "Signing NOT configured (keys.jks or key.properties missing)."
    Warn "APK will be built with debug keys. Run scripts\sign-apk.ps1 to fix this."
}

# ── Enter project root ────────────────────────────────────────────────────────
Set-Location $ProjectRoot

# ── Clean ─────────────────────────────────────────────────────────────────────
Log "Cleaning previous build artifacts..."
flutter clean
Ok "Clean done."

# ── Dependencies ──────────────────────────────────────────────────────────────
Log "Fetching dependencies..."
flutter pub get
Ok "Dependencies fetched."

# ── Build ─────────────────────────────────────────────────────────────────────
$OutputDir = Join-Path $ProjectRoot "build\app\outputs\flutter-apk"

if ($Aab) {
    Log "Building Android App Bundle (.aab) for Play Store..."
    flutter build appbundle --release
    $AabPath = Join-Path $ProjectRoot "build\app\outputs\bundle\release\app-release.aab"
    if (Test-Path $AabPath) {
        $size = [math]::Round((Get-Item $AabPath).Length / 1MB, 1)
        Ok "AAB ready: $AabPath  ($size MB)"
    } else {
        Err "AAB not found at expected location: $AabPath"
    }
} elseif ($SplitPerAbi) {
    Log "Building APKs split by ABI..."
    flutter build apk --release --split-per-abi
    Write-Host ""
    Ok "APKs ready:"
    Get-ChildItem "$OutputDir\app-*-release.apk" -ErrorAction SilentlyContinue | ForEach-Object {
        $size = [math]::Round($_.Length / 1MB, 1)
        Write-Host "  -> $($_.FullName)  ($size MB)" -ForegroundColor Green
    }
} else {
    Log "Building universal release APK..."
    flutter build apk --release
    $ApkPath = Join-Path $OutputDir "app-release.apk"
    if (Test-Path $ApkPath) {
        $size = [math]::Round((Get-Item $ApkPath).Length / 1MB, 1)
        Ok "APK ready: $ApkPath  ($size MB)"
    } else {
        Err "APK not found at expected location: $ApkPath"
    }
}

Write-Host ""
Write-Host "══════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  Build successful!                                    " -ForegroundColor Green
Write-Host "══════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
if (-not $Signed) {
    Warn "APK built with debug keys. Run scripts\sign-apk.ps1 to configure release signing."
}
