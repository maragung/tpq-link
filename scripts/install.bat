@echo off
:: =============================================================================
:: scripts\install.bat — Install & verify all dependencies for TPQ Link (Windows)
:: =============================================================================
:: Usage: Run as Administrator from any directory:
::   scripts\install.bat
::
:: For a richer experience with colours and secure prompts, use the PowerShell
:: version instead:  scripts\install.ps1
:: =============================================================================
setlocal EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%..\"
:: Normalize PROJECT_ROOT
for %%i in ("%PROJECT_ROOT%") do set "PROJECT_ROOT=%%~fi"

echo.
echo ==========================================================
echo   TPQ Link ^— Install Dependencies (Windows)
echo ==========================================================
echo.

:: ── Java JDK 17 ──────────────────────────────────────────────────────────────
echo [INSTALL] Checking Java JDK 17...
java --version >nul 2>&1
if %errorlevel% == 0 (
    for /f "tokens=*" %%v in ('java --version ^2^>^&1') do (
        echo [OK]      Java: %%v
        goto :java_ok
    )
)
echo [INSTALL] Java not found. Installing Eclipse Temurin 17 via winget...
winget install --id EclipseAdoptium.Temurin.17.JDK --accept-source-agreements --accept-package-agreements
if %errorlevel% neq 0 (
    echo [WARN]    Winget install failed. Download Java 17 from https://adoptium.net
)
:java_ok

:: Verify keytool
keytool >nul 2>&1
if %errorlevel% == 0 (
    echo [OK]      keytool found.
) else (
    echo [WARN]    keytool not in PATH. Add JAVA_HOME\bin to your system PATH.
)

:: ── Flutter SDK ───────────────────────────────────────────────────────────────
echo.
echo [INSTALL] Checking Flutter SDK...
flutter --version >nul 2>&1
if %errorlevel% == 0 (
    for /f "tokens=*" %%v in ('flutter --version ^2^>^&1') do (
        echo [OK]      Flutter: %%v
        goto :flutter_ok
    )
)
echo [INSTALL] Flutter not found. Installing via winget...
winget install --id Google.Flutter --accept-source-agreements --accept-package-agreements
if %errorlevel% neq 0 (
    echo [WARN]    Winget install failed. Download Flutter from https://flutter.dev/docs/get-started/install/windows
    echo [WARN]    Then add flutter\bin to your PATH.
)
:flutter_ok

:: ── Android Studio / SDK ─────────────────────────────────────────────────────
echo.
echo [INSTALL] Checking Android SDK...
if exist "%LOCALAPPDATA%\Android\Sdk" (
    echo [OK]      Android SDK found: %LOCALAPPDATA%\Android\Sdk
    set "ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk"
) else (
    echo [WARN]    Android SDK not found. Installing Android Studio via winget...
    winget install --id Google.AndroidStudio --accept-source-agreements --accept-package-agreements
    echo [OK]      Android Studio installed. Launch it once to complete SDK setup.
)

:: ── Flutter doctor ────────────────────────────────────────────────────────────
echo.
echo [INSTALL] Running flutter doctor...
flutter doctor
echo.

:: ── Project dependencies ──────────────────────────────────────────────────────
echo [INSTALL] Fetching project dependencies...
pushd "%PROJECT_ROOT%"
flutter pub get
popd
echo [OK]      Dependencies fetched.

:: ── Summary ───────────────────────────────────────────────────────────────────
echo.
echo ==========================================================
echo   Installation complete!
echo ==========================================================
echo.
echo   Next steps:
echo   1. Generate signing key :  scripts\sign-apk.bat
echo   2. Build release APK    :  scripts\build-apk.bat --split-per-abi
echo   3. Build Play Store AAB :  scripts\build-apk.bat --aab
echo.
endlocal
pause
