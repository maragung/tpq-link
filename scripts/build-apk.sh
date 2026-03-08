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

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

log()    { echo -e "${CYAN}[BUILD]${RESET} $*"; }
success(){ echo -e "${GREEN}[OK]${RESET}   $*"; }
warn()   { echo -e "${YELLOW}[WARN]${RESET} $*"; }
error()  { echo -e "${RED}[ERROR]${RESET} $*" >&2; exit 1; }

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

# ── Enter project root ────────────────────────────────────────────────────────
cd "$PROJECT_ROOT"

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
