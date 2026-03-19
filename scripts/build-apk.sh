#!/bin/bash
# scripts/build-apk.sh — Final fixed version for WSL + Windows-SDK Interoperability
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

# Final Cleanup (Incremental by default)
cd "$PROJECT_ROOT"
if [[ "$CLEAN_BUILD" == "true" ]]; then
  log "Full clean (--clean)..."
  run_flutter clean
  rm -rf .gradle android/.gradle 2>/dev/null || true
  success "Build cache cleared."
else
  log "Using incremental build (fast)."
fi

# Build
log "Starting build..."
if [[ "$BUILD_AAB" == "true" ]]; then
  run_flutter build appbundle --release
elif [[ "$SPLIT_PER_ABI" == "true" ]]; then
  run_flutter build apk --release --split-per-abi
else
  run_flutter build apk --release
fi

success "Done!"
exit 0
