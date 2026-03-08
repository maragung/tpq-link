# =============================================================================
# scripts/install.ps1 — Install & verify all dependencies for TPQ Link (Windows)
# =============================================================================
# Usage (PowerShell as Administrator):
#   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned -Force
#   .\scripts\install.ps1
#
# What this script does:
#   1. Checks / installs Winget (Windows Package Manager)
#   2. Checks / installs Java JDK 17 (Temurin)
#   3. Checks / installs Flutter SDK
#   4. Checks / installs Android Studio (includes SDK)
#   5. Runs flutter doctor
#   6. Fetches project dependencies
# =============================================================================

$ErrorActionPreference = "Stop"
$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ProjectRoot = Split-Path -Parent $ScriptDir

# ── Colors / helpers ──────────────────────────────────────────────────────────
function Log   ($msg) { Write-Host "[INSTALL] $msg" -ForegroundColor Cyan }
function Ok    ($msg) { Write-Host "[OK]      $msg" -ForegroundColor Green }
function Warn  ($msg) { Write-Host "[WARN]    $msg" -ForegroundColor Yellow }
function Err   ($msg) { Write-Host "[ERROR]   $msg" -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "══════════════════════════════════════════════════════" -ForegroundColor White
Write-Host "  TPQ Link — Install Dependencies (Windows)           " -ForegroundColor White
Write-Host "══════════════════════════════════════════════════════" -ForegroundColor White
Write-Host ""

# ── Check running as Administrator ────────────────────────────────────────────
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Warn "Not running as Administrator. Some installations may fail."
    Warn "Right-click PowerShell and choose 'Run as Administrator' for best results."
}

# ── Winget ────────────────────────────────────────────────────────────────────
Log "Checking winget..."
if (Get-Command winget -ErrorAction SilentlyContinue) {
    Ok "winget found: $(winget --version)"
} else {
    Warn "winget not found. Install it from https://aka.ms/winget or update Windows."
}

# ── Java JDK 17 ───────────────────────────────────────────────────────────────
Log "Checking Java JDK 17..."
$javaOk = $false
if (Get-Command java -ErrorAction SilentlyContinue) {
    $javaVer = (java --version 2>&1) | Select-Object -First 1
    if ($javaVer -match "version ""(17|2\d)") {
        Ok "Java found: $javaVer"
        $javaOk = $true
    }
}
if (-not $javaOk) {
    Log "Installing Java 17 (Eclipse Temurin) via winget..."
    winget install --id EclipseAdoptium.Temurin.17.JDK --accept-source-agreements --accept-package-agreements | Out-Null
    $env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17*" | Resolve-Path -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path -First 1
    $env:PATH += ";$env:JAVA_HOME\bin"
    Ok "Java installed."
}

# Verify keytool
if (Get-Command keytool -ErrorAction SilentlyContinue) {
    Ok "keytool found."
} else {
    Warn "keytool not in PATH. Ensure JAVA_HOME\bin is in your system PATH."
}

# ── Flutter SDK ───────────────────────────────────────────────────────────────
Log "Checking Flutter SDK..."
if (Get-Command flutter -ErrorAction SilentlyContinue) {
    $flutterVer = (flutter --version 2>&1) | Select-Object -First 1
    Ok "Flutter found: $flutterVer"
} else {
    Log "Installing Flutter via winget..."
    winget install --id Google.Flutter --accept-source-agreements --accept-package-agreements | Out-Null
    # Refresh PATH
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("PATH", "User")
    if (Get-Command flutter -ErrorAction SilentlyContinue) {
        Ok "Flutter installed: $((flutter --version 2>&1) | Select-Object -First 1)"
    } else {
        Warn "Flutter installed but not yet in PATH. Restart your terminal and re-run."
        Warn "Or add 'C:\Users\<you>\flutter\bin' to your PATH manually."
    }
}

# ── Android Studio / SDK ─────────────────────────────────────────────────────
Log "Checking Android SDK..."
$androidHome = $env:ANDROID_HOME
if (-not $androidHome -or -not (Test-Path $androidHome)) {
    $candidates = @(
        "$env:LOCALAPPDATA\Android\Sdk",
        "$env:USERPROFILE\AppData\Local\Android\Sdk"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { $androidHome = $c; break }
    }
}
if ($androidHome -and (Test-Path $androidHome)) {
    Ok "Android SDK found: $androidHome"
    $env:ANDROID_HOME = $androidHome
} else {
    Warn "Android SDK not found. Installing Android Studio..."
    winget install --id Google.AndroidStudio --accept-source-agreements --accept-package-agreements | Out-Null
    Ok "Android Studio installed. Launch it once to complete SDK setup, then re-run."
}

# ── Flutter doctor ────────────────────────────────────────────────────────────
Log "Running flutter doctor..."
try {
    flutter doctor --android-licenses 2>$null
} catch {}
flutter doctor
Write-Host ""

# ── Project dependencies ──────────────────────────────────────────────────────
Log "Fetching project dependencies..."
Set-Location $ProjectRoot
flutter pub get
Ok "Dependencies fetched."

# ── Make scripts visible ────────────────────────────────────────────────────-
Log "Unblocking scripts..."
Get-ChildItem "$ScriptDir\*.ps1" | Unblock-File
Get-ChildItem "$ScriptDir\*.bat" | Unblock-File
Ok "Scripts unblocked."

# ── Summary ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "══════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  Installation complete!                               " -ForegroundColor Green
Write-Host "══════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor White
Write-Host "  1. Generate signing key :  .\scripts\sign-apk.ps1"   -ForegroundColor Cyan
Write-Host "  2. Build release APK    :  .\scripts\build-apk.ps1 -SplitPerAbi" -ForegroundColor Cyan
Write-Host "  3. Build Play Store AAB :  .\scripts\build-apk.ps1 -Aab" -ForegroundColor Cyan
Write-Host ""
