#!/usr/bin/env bash
# =============================================================================
# build-apk.sh — Build release APK for TPQ Futuhil Hidayah
# =============================================================================
# Usage:
#   chmod +x build-apk.sh
#   ./build-apk.sh [--split-per-abi]
#
# Options:
#   --split-per-abi   Build separate APKs for each ABI (arm64-v8a, armeabi-v7a, x86_64)
#
# Prerequisites:
#   - Flutter SDK in PATH
#   - keys.jks file in android/app/ directory (run sign-apk.sh to create it)
#   - key.properties file in android/app/ directory (created by sign-apk.sh)
# =============================================================================

set -euo pipefail

# ── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

log()    { echo -e "${CYAN}[BUILD]${RESET} $*"; }
success(){ echo -e "${GREEN}[OK]${RESET} $*"; }
warn()   { echo -e "${YELLOW}[WARN]${RESET} $*"; }
error()  { echo -e "${RED}[ERROR]${RESET} $*" >&2; exit 1; }

# ── Script directory ─────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${BOLD}======================================================${RESET}"
echo -e "${BOLD}  TPQ Futuhil Hidayah — Build Release APK${RESET}"
echo -e "${BOLD}======================================================${RESET}"
echo ""

# ── Parse arguments ──────────────────────────────────────────────────────────
SPLIT_PER_ABI=false
for arg in "$@"; do
  case "$arg" in
    --split-per-abi) SPLIT_PER_ABI=true ;;
    *) warn "Unknown argument: $arg" ;;
  esac
done

# ── Check Flutter ─────────────────────────────────────────────────────────────
if ! command -v flutter &>/dev/null; then
  error "Flutter SDK not found in PATH. Please install Flutter and add it to your PATH."
fi
FLUTTER_VERSION=$(flutter --version --machine 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('frameworkVersion','unknown'))" 2>/dev/null || flutter --version 2>&1 | head -1)
log "Flutter version: $FLUTTER_VERSION"

# ── Check key.properties ──────────────────────────────────────────────────────
KEY_PROPS="$SCRIPT_DIR/android/app/key.properties"
KEYSTORE="$SCRIPT_DIR/android/app/keys.jks"

if [[ ! -f "$KEY_PROPS" ]]; then
  warn "key.properties not found at: $KEY_PROPS"
  warn "The APK will be built but NOT signed with a release key."
  warn "Run ./sign-apk.sh first to set up signing, or sign later."
  SIGNED=false
else
  success "key.properties found."
  SIGNED=true
fi

if [[ "$SIGNED" == "true" && ! -f "$KEYSTORE" ]]; then
  warn "keys.jks not found at: $KEYSTORE"
  warn "Build will proceed but signing may fail."
fi

# ── Clean previous build ──────────────────────────────────────────────────────
log "Cleaning previous build artifacts..."
flutter clean
success "Clean done."

# ── Get dependencies ──────────────────────────────────────────────────────────
log "Fetching dependencies..."
flutter pub get
success "Dependencies fetched."

# ── Build ─────────────────────────────────────────────────────────────────────
OUTPUT_DIR="$SCRIPT_DIR/build/app/outputs/flutter-apk"

if [[ "$SPLIT_PER_ABI" == "true" ]]; then
  log "Building release APKs split by ABI..."
  flutter build apk --release --split-per-abi
  echo ""
  success "Build completed! Output files:"
  for f in "$OUTPUT_DIR"/app-*-release.apk; do
    [[ -f "$f" ]] && echo -e "  ${GREEN}→${RESET} $f ($(du -sh "$f" | cut -f1))"
  done
else
  log "Building universal release APK..."
  flutter build apk --release
  echo ""
  APK_PATH="$OUTPUT_DIR/app-release.apk"
  if [[ -f "$APK_PATH" ]]; then
    APK_SIZE=$(du -sh "$APK_PATH" | cut -f1)
    success "Build completed!"
    echo -e "  ${GREEN}→${RESET} $APK_PATH (${APK_SIZE})"
  else
    error "APK not found at expected location: $APK_PATH"
  fi
fi

echo ""
echo -e "${BOLD}======================================================${RESET}"
echo -e "${GREEN}${BOLD}  Build successful!${RESET}"
echo -e "${BOLD}======================================================${RESET}"
echo ""

if [[ "$SIGNED" == "false" ]]; then
  warn "APK was built with debug keys. Run ./sign-apk.sh to set up release signing."
fi
