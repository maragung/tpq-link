@echo off
:: =============================================================================
:: scripts\build-apk.bat — Build release APK / AAB for TPQ Link (Windows)
:: =============================================================================
:: Usage:
::   scripts\build-apk.bat [--split-per-abi] [--aab]
::
:: Options:
::   --split-per-abi   Build separate APKs per ABI
::   --aab             Build Android App Bundle for Play Store
::
:: Prerequisites:
::   - Flutter SDK in PATH  (run scripts\install.bat first)
::   - Java JDK 17+
::   - scripts\keys.jks + android\app\key.properties  (run sign-apk.bat first)
:: =============================================================================
setlocal EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%..\"
for %%i in ("%PROJECT_ROOT%") do set "PROJECT_ROOT=%%~fi"

set "SPLIT_PER_ABI=0"
set "BUILD_AAB=0"

:parse_args
if "%~1"=="" goto :done_args
if /i "%~1"=="--split-per-abi" set "SPLIT_PER_ABI=1"
if /i "%~1"=="--aab"           set "BUILD_AAB=1"
shift
goto :parse_args
:done_args

echo.
echo ==========================================================
echo   TPQ Link ^— Build Release APK / AAB (Windows)
echo ==========================================================
echo.

:: ── Check Flutter ─────────────────────────────────────────────────────────────
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR]   Flutter not found. Run scripts\install.bat first.
    exit /b 1
)
for /f "tokens=*" %%v in ('flutter --version ^2^>^&1') do echo [BUILD]   Flutter: %%v & goto :flutter_ver_done
:flutter_ver_done

:: ── Check signing config ──────────────────────────────────────────────────────
set "SIGNED=0"
if exist "%SCRIPT_DIR%keys.jks" (
    if exist "%PROJECT_ROOT%android\app\key.properties" (
        echo [OK]      Release signing configured.
        set "SIGNED=1"
    )
)
if !SIGNED!==0 (
    echo [WARN]    Signing NOT configured. APK will use debug keys.
    echo [WARN]    Run scripts\sign-apk.bat to configure release signing.
)

:: ── Enter project root ────────────────────────────────────────────────────────
pushd "%PROJECT_ROOT%"

:: ── Clean ─────────────────────────────────────────────────────────────────────
echo [BUILD]   Cleaning previous build artifacts...
flutter clean
echo [OK]      Clean done.

:: ── Dependencies ──────────────────────────────────────────────────────────────
echo [BUILD]   Fetching dependencies...
flutter pub get
echo [OK]      Dependencies fetched.

:: ── Build ─────────────────────────────────────────────────────────────────────
set "OUTPUT_DIR=%PROJECT_ROOT%build\app\outputs\flutter-apk"

if !BUILD_AAB!==1 (
    echo [BUILD]   Building Android App Bundle for Play Store...
    flutter build appbundle --release
    set "AAB=%PROJECT_ROOT%build\app\outputs\bundle\release\app-release.aab"
    if exist "!AAB!" (
        echo [OK]      AAB ready: !AAB!
    ) else (
        echo [ERROR]   AAB not found at expected location.
        popd
        exit /b 1
    )
) else if !SPLIT_PER_ABI!==1 (
    echo [BUILD]   Building APKs split by ABI...
    flutter build apk --release --split-per-abi
    echo [OK]      APKs ready:
    for %%f in ("!OUTPUT_DIR!\app-*-release.apk") do echo    ^-^> %%f
) else (
    echo [BUILD]   Building universal release APK...
    flutter build apk --release
    set "APK=!OUTPUT_DIR!\app-release.apk"
    if exist "!APK!" (
        echo [OK]      APK ready: !APK!
    ) else (
        echo [ERROR]   APK not found at expected location.
        popd
        exit /b 1
    )
)

popd

echo.
echo ==========================================================
echo   Build successful!
echo ==========================================================
echo.
if !SIGNED!==0 (
    echo [WARN]    APK was built with debug keys. Run scripts\sign-apk.bat.
)
endlocal
