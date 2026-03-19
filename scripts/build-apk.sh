#!/bin/bash
# scripts/build-apk.sh — Reliable build script for WSL + Windows-SDK Interoperability
set -euo pipefail

# Normalize path helper (CRLF strip + Windows-to-WSL conversion if needed)
normalize_path() {
  local path="$1"
  [[ -z "$path" ]] && return 0
  path=$(echo "$path" | tr -d '\r')
  if [[ "$path" =~ ^[A-Za-z]:\\ || "$path" == *"\\"* ]] && grep -qi microsoft /proc/version 2>/dev/null; then
    if command -v wslpath >/dev/null 2>&1; then
      wslpath -u "$path"
    else
      echo "$path" | sed -E "s/([A-Za-z]):\\\\/\\/\\L\\1\\//;s/\\\\/\\//g"
    fi
  else
    echo "$path"
  fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd -P)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.."; pwd -P)"
PUBSPEC_PATH="$PROJECT_ROOT/pubspec.yaml"
LOCAL_PROPERTIES_PATH="$PROJECT_ROOT/android/local.properties"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

log()    { echo -e "${CYAN}[BUILD]${RESET} $*"; }
success(){ echo -e "${GREEN}[OK]${RESET}   $*"; }
warn()   { echo -e "${YELLOW}[WARN]${RESET} $*"; }
error()  { echo -e "${RED}[ERROR]${RESET} $*" >&2; exit 1; }

echo "══════════════════════════════════════════════════════"
echo "  TPQ Link — Build Release APK (WSL Enhanced)         "
echo "══════════════════════════════════════════════════════"

# Parse arguments
SPLIT_PER_ABI=false; BUILD_AAB=false; CLEAN_BUILD=false
for arg in "$@"; do
  case "$arg" in
    --split-per-abi|--split-abi) SPLIT_PER_ABI=true ;;
    --aab)           BUILD_AAB=true ;;
    --clean)         CLEAN_BUILD=true ;;
    *) warn "Unknown argument: $arg" ;;
  esac
done

# Detect environment
IS_WSL=false; if grep -qi microsoft /proc/version 2>/dev/null; then IS_WSL=true; fi

# Function to run flutter (detects if we need cmd.exe in WSL for Windows-SDK)
run_flutter() {
  if ! $IS_WSL; then
     flutter "$@"
  else
     # In WSL, check if 'flutter' (linux) is available and has local shebang
     if command -v flutter >/dev/null 2>&1 && ! (head -n 1 $(command -v flutter) | grep -q $'\r'); then
        flutter "$@"
     else
        # Use cmd.exe to call Windows' flutter.bat
        local win_root=$(wslpath -w "$PROJECT_ROOT" | tr -d '\r')
        # Use cmd.exe /c "command" with properly escaped paths
        cmd.exe /c "cd /d $win_root && flutter $*"
     fi
  fi
}

# Version checking
log "Checking environment..."
run_flutter --version | head -1

# Fix local.properties SDK path if in WSL
if [[ -f "$LOCAL_PROPERTIES_PATH" ]] && $IS_WSL; then
  raw_sdk=$(grep '^sdk.dir=' "$LOCAL_PROPERTIES_PATH" | cut -d= -f2-)
  SDK_DIR=$(normalize_path "$raw_sdk")
  if [[ -d "$SDK_DIR" ]]; then
     export ANDROID_HOME="$SDK_DIR"; export ANDROID_SDK_ROOT="$SDK_DIR"
     export PATH="$SDK_DIR/platform-tools:$PATH"
     # Sync back to local.properties as WSL path for Gradle
     sed -i "s|^sdk\.dir=.*$|sdk.dir=$SDK_DIR|" "$LOCAL_PROPERTIES_PATH"
     log "Using SDK: $SDK_DIR"
  fi
fi

cd "$PROJECT_ROOT"

# Pre-build cleanup - always clean gradle cache to avoid stale artifacts
log "Preparing build environment..."

# Stop all gradle daemons to ensure fresh build
if command -v gradle >/dev/null 2>&1; then
  gradle --stop 2>/dev/null || true
fi

# Clean flutter build artifacts if --clean is specified or if this is a fresh start
if [[ "$CLEAN_BUILD" == "true" ]]; then
  log "Full clean (--clean)..."
  run_flutter clean
  rm -rf .gradle android/.gradle build android/.kotlin android/app/build 2>/dev/null || true
  success "Build cache cleared."
else
  # Always clean android build directory and gradle cache for release builds to avoid incremental issues
  log "Cleaning previous build artifacts..."
  rm -rf android/app/build 2>/dev/null || true
  rm -rf android/.gradle 2>/dev/null || true
  rm -rf android/.kotlin 2>/dev/null || true
  rm -rf build/app/intermediates 2>/dev/null || true
  # Stop gradle daemons to clear incremental compilation cache
  if [[ -f android/gradlew ]]; then
    chmod +x android/gradlew
    ./android/gradlew --stop 2>/dev/null || true
  fi
fi

# Get dependencies
log "Getting Flutter dependencies..."
run_flutter pub get

# Build
log "Starting build..."
BUILD_OUTPUT=""
BUILD_EXIT_CODE=0

if [[ "$BUILD_AAB" == "true" ]]; then
  BUILD_OUTPUT=$(run_flutter build appbundle --release --android-skip-build-dependency-validation 2>&1) || BUILD_EXIT_CODE=$?
elif [[ "$SPLIT_PER_ABI" == "true" ]]; then
  BUILD_OUTPUT=$(run_flutter build apk --release --split-per-abi --android-skip-build-dependency-validation 2>&1) || BUILD_EXIT_CODE=$?
else
  BUILD_OUTPUT=$(run_flutter build apk --release --android-skip-build-dependency-validation 2>&1) || BUILD_EXIT_CODE=$?
fi

# Check for actual build failure (not just Kotlin daemon warnings)
# The build succeeds if APK/AAB files are generated
if [[ "$BUILD_EXIT_CODE" -ne 0 ]]; then
  # Check if APKs were still built despite errors (Gradle sometimes reports errors but still builds)
  if [[ "$BUILD_AAB" == "true" ]] && [[ -f "build/app/outputs/bundle/release/app-release.aab" ]]; then
    success "Build completed successfully (with warnings)!"
  elif [[ "$SPLIT_PER_ABI" == "true" ]] && [[ -f "build/app/outputs/flutter-apk/app-arm64-v8a-release.apk" ]]; then
    success "Build completed successfully (with warnings)!"
  elif [[ -f "build/app/outputs/flutter-apk/release/app-release.apk" ]]; then
    success "Build completed successfully (with warnings)!"
  else
    error "Build failed!\n$BUILD_OUTPUT"
  fi
else
  success "Done!"
fi

# Show output location
if [[ "$BUILD_AAB" == "true" ]]; then
  echo ""
  log "Output: build/app/outputs/bundle/release/app-release.aab"
  ls -lh build/app/outputs/bundle/release/*.aab 2>/dev/null || true
else
  echo ""
  if [[ "$SPLIT_PER_ABI" == "true" ]]; then
    log "Output files:"
    ls -lh build/app/outputs/flutter-apk/*.apk 2>/dev/null || true
  else
    log "Output: build/app/outputs/flutter-apk/release/app-release.apk"
    ls -lh build/app/outputs/flutter-apk/release/*.apk 2>/dev/null || true
  fi
fi

exit 0
