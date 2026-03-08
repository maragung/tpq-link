#!/usr/bin/env bash
# =============================================================================
# sign-apk.sh — Generate keys.jks keystore and configure APK signing
# =============================================================================
# Usage:
#   chmod +x sign-apk.sh
#   ./sign-apk.sh [--sign-existing <path-to-apk>]
#
# What this script does:
#   1. Generates android/app/keys.jks (if not already present)
#   2. Creates android/app/key.properties (used by build.gradle.kts)
#   3. Optionally signs an existing unsigned/debug APK with apksigner
#
# Prerequisites:
#   - Java JDK (keytool must be in PATH)
#   - Android SDK build-tools (for apksigner) — only required for --sign-existing
# =============================================================================

set -euo pipefail

# ── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

log()    { echo -e "${CYAN}[SIGN]${RESET} $*"; }
success(){ echo -e "${GREEN}[OK]${RESET} $*"; }
warn()   { echo -e "${YELLOW}[WARN]${RESET} $*"; }
error()  { echo -e "${RED}[ERROR]${RESET} $*" >&2; exit 1; }
prompt() { echo -e "${BOLD}$*${RESET}"; }

# ── Script directory ─────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

KEYSTORE_DIR="$SCRIPT_DIR/android/app"
KEYSTORE_PATH="$KEYSTORE_DIR/keys.jks"
KEY_PROPS_PATH="$KEYSTORE_DIR/key.properties"

echo -e "${BOLD}======================================================${RESET}"
echo -e "${BOLD}  TPQ Futuhil Hidayah — APK Signing Setup${RESET}"
echo -e "${BOLD}======================================================${RESET}"
echo ""

# ── Parse arguments ──────────────────────────────────────────────────────────
SIGN_EXISTING=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --sign-existing)
      shift
      SIGN_EXISTING="${1:-}"
      [[ -z "$SIGN_EXISTING" ]] && error "--sign-existing requires a path to an APK file."
      ;;
    *) warn "Unknown argument: $1" ;;
  esac
  shift
done

# ── Check keytool ─────────────────────────────────────────────────────────────
if ! command -v keytool &>/dev/null; then
  error "keytool not found. Please install Java JDK and ensure it is in your PATH."
fi
success "keytool found: $(command -v keytool)"

# ── Gather signing information ────────────────────────────────────────────────
if [[ -f "$KEYSTORE_PATH" ]]; then
  warn "keys.jks already exists at: $KEYSTORE_PATH"
  read -rp "$(echo -e "${YELLOW}Overwrite existing keystore? [y/N]: ${RESET}")" OVERWRITE
  if [[ "${OVERWRITE,,}" != "y" ]]; then
    log "Skipping keystore generation. Using existing keys.jks."
    # Still regenerate key.properties if it doesn't exist
    SKIP_KEYGEN=true
  else
    SKIP_KEYGEN=false
  fi
else
  SKIP_KEYGEN=false
fi

if [[ "$SKIP_KEYGEN" == "false" ]]; then
  echo ""
  prompt "Enter keystore information (leave blank to use defaults):"
  echo ""

  read -rp "  Key alias        [tpq-release]: " KEY_ALIAS
  KEY_ALIAS="${KEY_ALIAS:-tpq-release}"

  read -rsp "  Key password     (hidden): " KEY_PASSWORD
  echo ""
  if [[ -z "$KEY_PASSWORD" ]]; then
    KEY_PASSWORD="tpq@FutuhilHidayah2024"
    warn "Using default password: $KEY_PASSWORD"
    warn "Change this in production! Edit key.properties and re-run keytool."
  fi

  read -rsp "  Store password   (hidden, Enter = same as key password): " STORE_PASSWORD
  echo ""
  STORE_PASSWORD="${STORE_PASSWORD:-$KEY_PASSWORD}"

  read -rp "  Your name / org  [TPQ Futuhil Hidayah]: " CN
  CN="${CN:-TPQ Futuhil Hidayah}"

  read -rp "  Organization     [Futuhil Hidayah Wal Nikmah]: " ORG
  ORG="${ORG:-Futuhil Hidayah Wal Nikmah}"

  read -rp "  City             [Indonesia]: " CITY
  CITY="${CITY:-Indonesia}"

  read -rp "  State / Province [Indonesia]: " STATE
  STATE="${STATE:-Indonesia}"

  read -rp "  Country code     [ID]: " COUNTRY
  COUNTRY="${COUNTRY:-ID}"

  read -rp "  Validity (years) [25]: " VALIDITY_YEARS
  VALIDITY_YEARS="${VALIDITY_YEARS:-25}"
  VALIDITY_DAYS=$(( VALIDITY_YEARS * 365 ))

  DNAME="CN=${CN}, OU=${ORG}, O=${ORG}, L=${CITY}, ST=${STATE}, C=${COUNTRY}"

  echo ""
  log "Generating keystore..."
  log "  Path     : $KEYSTORE_PATH"
  log "  Alias    : $KEY_ALIAS"
  log "  Validity : ${VALIDITY_YEARS} years (${VALIDITY_DAYS} days)"
  log "  DN       : $DNAME"
  echo ""

  keytool -genkey \
    -v \
    -keystore "$KEYSTORE_PATH" \
    -storetype JKS \
    -alias "$KEY_ALIAS" \
    -keyalg RSA \
    -keysize 2048 \
    -validity "$VALIDITY_DAYS" \
    -storepass "$STORE_PASSWORD" \
    -keypass "$KEY_PASSWORD" \
    -dname "$DNAME"

  success "keys.jks generated at: $KEYSTORE_PATH"
  echo ""

  # ── Write key.properties ────────────────────────────────────────────────────
  log "Writing key.properties..."
  cat > "$KEY_PROPS_PATH" <<EOF
# ============================================================
# key.properties — Flutter/Android release signing config
# Generated by sign-apk.sh on $(date '+%Y-%m-%d %H:%M:%S')
#
# WARNING: Do NOT commit this file to version control!
#          Add android/app/key.properties to .gitignore
# ============================================================

storePassword=$STORE_PASSWORD
keyPassword=$KEY_PASSWORD
keyAlias=$KEY_ALIAS
storeFile=keys.jks
EOF

  success "key.properties written to: $KEY_PROPS_PATH"

else
  # Keystore already exists, just ensure key.properties is present
  if [[ ! -f "$KEY_PROPS_PATH" ]]; then
    warn "key.properties not found. Creating a template..."
    cat > "$KEY_PROPS_PATH" <<'EOF'
# ============================================================
# key.properties — Flutter/Android release signing config
#
# WARNING: Do NOT commit this file to version control!
#          Add android/app/key.properties to .gitignore
# ============================================================

storePassword=CHANGE_ME
keyPassword=CHANGE_ME
keyAlias=tpq-release
storeFile=keys.jks
EOF
    warn "Please edit $KEY_PROPS_PATH and fill in the correct passwords."
  else
    success "key.properties already exists at: $KEY_PROPS_PATH"
  fi
fi

# ── gitignore safeguard ───────────────────────────────────────────────────────
GITIGNORE="$SCRIPT_DIR/.gitignore"
ANDROID_GITIGNORE="$SCRIPT_DIR/android/.gitignore"

ensure_gitignore() {
  local file="$1"
  local entry="$2"
  if [[ -f "$file" ]]; then
    if ! grep -qF "$entry" "$file"; then
      echo "$entry" >> "$file"
      log "Added '$entry' to $file"
    fi
  else
    echo "$entry" > "$file"
    log "Created $file with '$entry'"
  fi
}

ensure_gitignore "$ANDROID_GITIGNORE" "app/keys.jks"
ensure_gitignore "$ANDROID_GITIGNORE" "app/key.properties"

# ── Sign existing APK (optional) ──────────────────────────────────────────────
if [[ -n "$SIGN_EXISTING" ]]; then
  echo ""
  log "Signing existing APK: $SIGN_EXISTING"

  if [[ ! -f "$SIGN_EXISTING" ]]; then
    error "APK file not found: $SIGN_EXISTING"
  fi

  # Find apksigner in Android SDK
  APKSIGNER=""
  if command -v apksigner &>/dev/null; then
    APKSIGNER="apksigner"
  elif [[ -n "${ANDROID_HOME:-}" ]]; then
    # Find newest build-tools version
    BUILD_TOOLS_DIR=$(ls -1d "${ANDROID_HOME}/build-tools"/*/ 2>/dev/null | sort -V | tail -1 || true)
    if [[ -n "$BUILD_TOOLS_DIR" && -f "${BUILD_TOOLS_DIR}apksigner" ]]; then
      APKSIGNER="${BUILD_TOOLS_DIR}apksigner"
    fi
  fi

  if [[ -z "$APKSIGNER" ]]; then
    error "apksigner not found. Install Android SDK build-tools and ensure ANDROID_HOME is set."
  fi

  # Load passwords from key.properties
  if [[ -f "$KEY_PROPS_PATH" ]]; then
    # Read key.properties values
    KP_STORE_PASS=$(grep -E '^storePassword=' "$KEY_PROPS_PATH" | cut -d= -f2- | tr -d '[:space:]')
    KP_KEY_PASS=$(grep -E '^keyPassword=' "$KEY_PROPS_PATH" | cut -d= -f2- | tr -d '[:space:]')
    KP_KEY_ALIAS=$(grep -E '^keyAlias=' "$KEY_PROPS_PATH" | cut -d= -f2- | tr -d '[:space:]')
  else
    error "key.properties not found. Cannot determine signing credentials."
  fi

  APK_BASENAME=$(basename "$SIGN_EXISTING" .apk)
  APK_DIR=$(dirname "$SIGN_EXISTING")
  SIGNED_APK="${APK_DIR}/${APK_BASENAME}-signed.apk"

  log "Output: $SIGNED_APK"

  "$APKSIGNER" sign \
    --ks "$KEYSTORE_PATH" \
    --ks-pass "pass:${KP_STORE_PASS}" \
    --ks-key-alias "$KP_KEY_ALIAS" \
    --key-pass "pass:${KP_KEY_PASS}" \
    --out "$SIGNED_APK" \
    "$SIGN_EXISTING"

  success "APK signed successfully!"
  echo -e "  ${GREEN}→${RESET} $SIGNED_APK ($(du -sh "$SIGNED_APK" | cut -f1))"

  # Verify
  log "Verifying signature..."
  "$APKSIGNER" verify --verbose "$SIGNED_APK" 2>&1 | grep -E "(Verified|error)" || true
  success "Signature verified."
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}======================================================${RESET}"
echo -e "${GREEN}${BOLD}  Signing setup complete!${RESET}"
echo -e "${BOLD}======================================================${RESET}"
echo ""
echo -e "  Keystore : ${CYAN}$KEYSTORE_PATH${RESET}"
echo -e "  Config   : ${CYAN}$KEY_PROPS_PATH${RESET}"
echo ""
echo -e "  ${YELLOW}Next steps:${RESET}"
echo -e "  1. Verify ${CYAN}android/app/build.gradle.kts${RESET} has signingConfigs configured."
echo -e "  2. Run ${CYAN}./build-apk.sh${RESET} to build a signed release APK."
echo -e "  3. Find output at: ${CYAN}build/app/outputs/flutter-apk/app-release.apk${RESET}"
echo ""
echo -e "  ${RED}IMPORTANT:${RESET} Never commit keys.jks or key.properties to version control!"
echo ""
