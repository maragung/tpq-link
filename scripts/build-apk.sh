#!/usr/bin/env bash
# =============================================================================
# scripts/build-apk.sh — Build release APK / AAB for TPQ Link
# =============================================================================
# Usage:
#   cd scripts && ./build-apk.sh [--split-per-abi] [--aab]
#   OR from project root:  bash scripts/build-apk.sh [options]
#
# Options:
#   --split-per-abi   Build separate APKs per ABI (arm64-v8a, armeabi-v7a, x86_64)
#   --aab             Build Android App Bundle (.aab) for Play Store
#
# Prerequisites (run scripts/install.sh first):
#   - Flutter SDK in PATH
#   - Java JDK 17+
#   - scripts/keys.jks  +  android/app/key.properties  (run sign-apk.sh first)
# =============================================================================

set -euo pipefail

# ── Paths ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEFAULT_FLUTTER_NDK_VERSION="28.2.13676358"

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

log()    { echo -e "${CYAN}[BUILD]${RESET} $*"; }
success(){ echo -e "${GREEN}[OK]${RESET}   $*"; }
warn()   { echo -e "${YELLOW}[WARN]${RESET} $*"; }
error()  { echo -e "${RED}[ERROR]${RESET} $*" >&2; exit 1; }

resolve_android_sdk_dir() {
  local candidate sdk_dir

  if [[ -f "$PROJECT_ROOT/android/local.properties" ]]; then
    sdk_dir=$(grep -E '^sdk\.dir=' "$PROJECT_ROOT/android/local.properties" | head -n 1 | cut -d= -f2- || true)
    if [[ -n "$sdk_dir" && -d "$sdk_dir" ]]; then
      if [[ "$sdk_dir" == "/usr/lib/android-sdk" && -d "$HOME/Android/Sdk" ]]; then
        echo "$HOME/Android/Sdk"
        return 0
      fi
      echo "$sdk_dir"
      return 0
    fi
  fi

  for candidate in \
    "$HOME/Android/Sdk" \
    "$HOME/android-sdk" \
    "/usr/lib/android-sdk"
  do
    if [[ -d "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  done

  for candidate in "${ANDROID_SDK_ROOT:-}" "${ANDROID_HOME:-}"; do
    if [[ -n "$candidate" && -d "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  done

  return 1
}

sync_local_properties_sdk() {
  local sdk_dir="$1"
  local local_props="$PROJECT_ROOT/android/local.properties"

  [[ -n "$sdk_dir" ]] || return 0

  if [[ -f "$local_props" ]]; then
    if grep -qE '^sdk\.dir=' "$local_props"; then
      sed -i "s|^sdk\.dir=.*$|sdk.dir=$sdk_dir|" "$local_props"
    else
      printf '\nsdk.dir=%s\n' "$sdk_dir" >> "$local_props"
    fi
  else
    printf 'sdk.dir=%s\n' "$sdk_dir" > "$local_props"
  fi
}

resolve_sdkmanager() {
  local sdk_dir="${1:-}"
  local candidate

  if command -v sdkmanager >/dev/null 2>&1; then
    command -v sdkmanager
    return 0
  fi

  for candidate in \
    "$sdk_dir/cmdline-tools/latest/bin/sdkmanager" \
    "$sdk_dir/cmdline-tools/latest-2/bin/sdkmanager" \
    "$sdk_dir/cmdline-tools/bin/sdkmanager" \
    "$sdk_dir/tools/bin/sdkmanager"
  do
    if [[ -x "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  done

  if [[ -d "$sdk_dir/cmdline-tools" ]]; then
    candidate=$(find "$sdk_dir/cmdline-tools" -maxdepth 3 -type f -name sdkmanager 2>/dev/null | head -n 1 || true)
    if [[ -n "$candidate" && -x "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  fi

  return 1
}

normalize_signing_config() {
  local expected_store_file="../../scripts/keys.jks"

  [[ -f "$KEY_PROPS" && -f "$KEYSTORE" ]] || return 0

  if grep -qE '^storeFile=' "$KEY_PROPS"; then
    if ! grep -qE '^storeFile=\.\./\.\./scripts/keys\.jks$' "$KEY_PROPS"; then
      sed -i "s|^storeFile=.*$|storeFile=$expected_store_file|" "$KEY_PROPS"
      success "Signing path normalized in android/app/key.properties."
    fi
  else
    printf '\nstoreFile=%s\n' "$expected_store_file" >> "$KEY_PROPS"
    success "Signing path added to android/app/key.properties."
  fi
}

ensure_android_sdk_requirements() {
  local sdk_dir sdkmanager

  sdk_dir=$(resolve_android_sdk_dir || true)
  if [[ -z "$sdk_dir" ]]; then
    warn "Android SDK directory not found. Skipping automatic SDK setup."
    return 0
  fi

  log "Android SDK: $sdk_dir"
  sync_local_properties_sdk "$sdk_dir"

  sdkmanager=$(resolve_sdkmanager "$sdk_dir" || true)
  if [[ -z "$sdkmanager" ]]; then
    warn "sdkmanager not found. Install Android command-line tools to enable automatic license acceptance."
    log "Trying Flutter's Android license helper..."
    yes | flutter doctor --android-licenses >/dev/null 2>&1 || true
    return 0
  fi

  log "Accepting Android SDK licenses..."
  yes | "$sdkmanager" --sdk_root="$sdk_dir" --licenses >/dev/null 2>&1 || true

  log "Ensuring Flutter-required Android SDK packages are available..."
  "$sdkmanager" --sdk_root="$sdk_dir" --install \
    "platform-tools" \
    "platforms;android-36" \
    "build-tools;36.0.0" \
    "ndk;$DEFAULT_FLUTTER_NDK_VERSION" >/dev/null || \
    error "Failed to install required Android SDK packages. Check Android SDK permissions, licenses, and network access."

  success "Android SDK packages ready."
}

echo -e "${BOLD}══════════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}  TPQ Link — Build Release APK                        ${RESET}"
echo -e "${BOLD}══════════════════════════════════════════════════════${RESET}"
echo ""

# ── Parse arguments ───────────────────────────────────────────────────────────
SPLIT_PER_ABI=false
BUILD_AAB=false
for arg in "$@"; do
  case "$arg" in
    --split-per-abi) SPLIT_PER_ABI=true ;;
    --aab)           BUILD_AAB=true ;;
    *) warn "Unknown argument: $arg" ;;
  esac
done

# ── Resolve Flutter PATH ──────────────────────────────────────────────────────
if ! command -v flutter &>/dev/null; then
  # Try common install locations before giving up
  for _flutter_candidate in \
    "$HOME/flutter/bin" \
    "/opt/flutter/bin" \
    "/usr/local/flutter/bin"
  do
    if [[ -x "$_flutter_candidate/flutter" ]]; then
      export PATH="$_flutter_candidate:$PATH"
      log "Flutter found at $_flutter_candidate (added to PATH)"
      break
    fi
  done
fi

# ── Check Flutter ─────────────────────────────────────────────────────────────
command -v flutter &>/dev/null || error "Flutter SDK not found in PATH. Run scripts/install.sh first."
FLUTTER_VERSION=$(flutter --version 2>&1 | head -1)
log "Flutter: $FLUTTER_VERSION"

# ── Check signing config ──────────────────────────────────────────────────────
KEYSTORE="$SCRIPT_DIR/keys.jks"
KEY_PROPS="$PROJECT_ROOT/android/app/key.properties"

SIGNED=false
if [[ -f "$KEY_PROPS" && -f "$KEYSTORE" ]]; then
  success "Release signing configured."
  SIGNED=true
else
  warn "Release signing NOT configured (key.properties or keys.jks missing)."
  warn "APK will be built with debug keys. Run scripts/sign-apk.sh to fix this."
fi

normalize_signing_config

# ── Enter project root ────────────────────────────────────────────────────────
cd "$PROJECT_ROOT"

# ── Android SDK prerequisites ────────────────────────────────────────────────
ensure_android_sdk_requirements
# ── Resolve and export Android SDK for Gradle ───────────────────────────────
ANDROID_SDK_DIR=$(resolve_android_sdk_dir || true)
if [[ -n "$ANDROID_SDK_DIR" ]]; then
  export ANDROID_HOME="$ANDROID_SDK_DIR"
  export ANDROID_SDK_ROOT="$ANDROID_SDK_DIR"
  sync_local_properties_sdk "$ANDROID_SDK_DIR"
  log "Gradle will use Android SDK: $ANDROID_SDK_DIR"
  log "android/local.properties synced to sdk.dir=$ANDROID_SDK_DIR"
fi

# ── Clear Gradle cache to ensure fresh SDK path resolution ──────────────────
log "Clearing Gradle cache..."
rm -rf "$PROJECT_ROOT/.gradle" "$PROJECT_ROOT/android/.gradle" 2>/dev/null || true
success "Gradle cache cleared."
# ── Clean ─────────────────────────────────────────────────────────────────────
log "Cleaning previous build artifacts..."
flutter clean
success "Clean done."

# ── Dependencies ──────────────────────────────────────────────────────────────
log "Fetching dependencies..."
flutter pub get
success "Dependencies fetched."

# ── Build ─────────────────────────────────────────────────────────────────────
OUTPUT_DIR="$PROJECT_ROOT/build/app/outputs/flutter-apk"

if [[ "$BUILD_AAB" == "true" ]]; then
  log "Building Android App Bundle (.aab) for Play Store..."
  flutter build appbundle --release
  echo ""
  AAB="$PROJECT_ROOT/build/app/outputs/bundle/release/app-release.aab"
  [[ -f "$AAB" ]] && success "AAB ready: $AAB  ($(du -sh "$AAB" | cut -f1))" \
                  || error "AAB not found at expected location: $AAB"

elif [[ "$SPLIT_PER_ABI" == "true" ]]; then
  log "Building APKs split by ABI..."
  flutter build apk --release --split-per-abi
  echo ""
  success "APKs ready:"
  for f in "$OUTPUT_DIR"/app-*-release.apk; do
    [[ -f "$f" ]] && echo -e "  ${GREEN}→${RESET} $f  ($(du -sh "$f" | cut -f1))"
  done

else
  log "Building universal release APK..."
  flutter build apk --release
  echo ""
  APK="$OUTPUT_DIR/app-release.apk"
  [[ -f "$APK" ]] && success "APK ready: $APK  ($(du -sh "$APK" | cut -f1))" \
                  || error "APK not found at expected location: $APK"
fi

echo ""
echo -e "${BOLD}══════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}${BOLD}  Build successful!                                   ${RESET}"
echo -e "${BOLD}══════════════════════════════════════════════════════${RESET}"
echo ""
[[ "$SIGNED" == "false" ]] && warn "APK was built with debug keys. Run scripts/sign-apk.sh to configure release signing."
