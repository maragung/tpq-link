#!/bin/bash
# scripts/build-apk.sh
set -euo pipefail

# Normalize path helper
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

log()    { echo -e "[BUILD] $*"; }
success(){ echo -e "[OK]    $*"; }
warn()   { echo -e "[WARN]  $*"; }
error()  { echo -e "[ERROR] $*" >&2; exit 1; }

echo "══════════════════════════════════════════════════════"
echo "  TPQ Link — Build Release APK"
echo "══════════════════════════════════════════════════════"

# Skip long parts for brief check
SPLIT_PER_ABI=false
BUILD_AAB=false
for arg in "$@"; do
  case "$arg" in
    --split-per-abi|--split-abi) SPLIT_PER_ABI=true ;;
    --aab)           BUILD_AAB=true ;;
  esac
done

if ! command -v flutter &>/dev/null; then
  for _cand in "$HOME/flutter/bin" "/opt/flutter/bin" "/usr/local/flutter/bin" "/mnt/c/Apps/flutter/bin"; do
    if [[ -x "$_cand/flutter" ]]; then
       export PATH="$_cand:$PATH"
       break
    fi
  done
fi

command -v flutter &>/dev/null || error "Flutter not found. Run scripts/install.sh"
log "Flutter: $(flutter --version | head -1)"

# Check SDK
if [[ -f "$PROJECT_ROOT/android/local.properties" ]]; then
  raw_sdk=$(grep '^sdk.dir=' "$PROJECT_ROOT/android/local.properties" | cut -d= -f2-)
  SDK_DIR=$(normalize_path "$raw_sdk")
  if [[ -d "$SDK_DIR" ]]; then
     export ANDROID_HOME="$SDK_DIR"
     export ANDROID_SDK_ROOT="$SDK_DIR"
     export PATH="$SDK_DIR/platform-tools:$PATH"
     log "Using SDK: $SDK_DIR"
  fi
fi

cd "$PROJECT_ROOT"
log "Building..."
if [[ "$BUILD_AAB" == "true" ]]; then
  flutter build appbundle --release
elif [[ "$SPLIT_PER_ABI" == "true" ]]; then
  flutter build apk --release --split-per-abi
else
  flutter build apk --release
fi

success "Build complete."
exit 0
