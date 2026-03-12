#!/usr/bin/env bash
# =============================================================================
# scripts/sign-apk.sh — Generate keystore and configure APK release signing
# =============================================================================
# Usage:
#   cd scripts && ./sign-apk.sh
#
# What this script does:
#   1. Generates scripts/keys.jks (if not already present)
#   2. Creates android/app/key.properties (used by build.gradle)
#
# Prerequisites (run scripts/install.sh first):
#   - Java JDK 17+  (keytool must be in PATH)
# =============================================================================

set -euo pipefail

# ── Paths ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

KEYSTORE_PATH="$SCRIPT_DIR/keys.jks"
KEY_PROPS_PATH="$PROJECT_ROOT/android/app/key.properties"
KEYSTORE_RELATIVE_PATH="../../scripts/keys.jks"
PUBSPEC_PATH="$PROJECT_ROOT/pubspec.yaml"
LOCAL_PROPERTIES_PATH="$PROJECT_ROOT/android/local.properties"

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

log()    { echo -e "${CYAN}[SIGN]${RESET} $*"; }
success(){ echo -e "${GREEN}[OK]${RESET}   $*"; }
warn()   { echo -e "${YELLOW}[WARN]${RESET} $*"; }
error()  { echo -e "${RED}[ERROR]${RESET} $*" >&2; exit 1; }

bump_project_version() {
  local version_line current_version current_name current_code
  local major minor patch next_patch next_code next_version

  [[ -f "$PUBSPEC_PATH" ]] || error "pubspec.yaml not found at: $PUBSPEC_PATH"

  version_line=$(grep -E '^version:' "$PUBSPEC_PATH" | head -n 1 || true)
  [[ -n "$version_line" ]] || error "Unable to find version in pubspec.yaml"

  current_version=$(echo "$version_line" | sed -E 's/^version:[[:space:]]*//')
  current_name=${current_version%%+*}
  current_code=${current_version##*+}

  IFS='.' read -r major minor patch <<< "$current_name"
  [[ -n "$major" && -n "$minor" && -n "$patch" && "$current_code" =~ ^[0-9]+$ ]] || \
    error "Unsupported version format in pubspec.yaml: $current_version"

  next_patch=$((patch + 1))
  next_code=$((current_code + 1))
  next_version="$major.$minor.$next_patch+$next_code"

  sed -i -E "s/^version:[[:space:]]*.*/version: $next_version/" "$PUBSPEC_PATH"

  if [[ -f "$LOCAL_PROPERTIES_PATH" ]]; then
    if grep -qE '^flutter\.versionName=' "$LOCAL_PROPERTIES_PATH"; then
      sed -i -E "s/^flutter\.versionName=.*/flutter.versionName=$major.$minor.$next_patch/" "$LOCAL_PROPERTIES_PATH"
    else
      printf '\nflutter.versionName=%s\n' "$major.$minor.$next_patch" >> "$LOCAL_PROPERTIES_PATH"
    fi

    if grep -qE '^flutter\.versionCode=' "$LOCAL_PROPERTIES_PATH"; then
      sed -i -E "s/^flutter\.versionCode=.*/flutter.versionCode=$next_code/" "$LOCAL_PROPERTIES_PATH"
    else
      printf 'flutter.versionCode=%s\n' "$next_code" >> "$LOCAL_PROPERTIES_PATH"
    fi
  fi

  success "Version bumped: $current_version -> $next_version"
}

echo -e "${BOLD}══════════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}  TPQ Link — APK Signing Setup                        ${RESET}"
echo -e "${BOLD}══════════════════════════════════════════════════════${RESET}"
echo ""

# ── Check keytool ─────────────────────────────────────────────────────────────
command -v keytool &>/dev/null || error "keytool not found. Install Java JDK and add it to PATH. Run scripts/install.sh."
success "keytool: $(command -v keytool)"

# ── Auto increment app version ───────────────────────────────────────────────
bump_project_version

# ── Handle existing keystore ──────────────────────────────────────────────────
SKIP_KEYGEN=false
if [[ -f "$KEYSTORE_PATH" ]]; then
  warn "keys.jks already exists at: $KEYSTORE_PATH"
  read -rp "$(echo -e "${YELLOW}Overwrite existing keystore? [y/N]: ${RESET}")" OVERWRITE
  [[ "${OVERWRITE,,}" == "y" ]] || SKIP_KEYGEN=true
fi

if [[ "$SKIP_KEYGEN" == "false" ]]; then
  echo ""
  echo -e "${BOLD}Enter keystore information (press Enter to accept default):${RESET}"
  echo ""

  read -rp "  Key alias        [tpq-release]: " KEY_ALIAS
  KEY_ALIAS="${KEY_ALIAS:-tpq-release}"

  read -rsp "  Key password     (hidden): " KEY_PASSWORD; echo ""
  if [[ -z "$KEY_PASSWORD" ]]; then
    KEY_PASSWORD="tpq@Link2024"
    warn "Using default password. Change it in production!"
  fi

  read -rsp "  Store password   (Enter = same as key password): " STORE_PASSWORD; echo ""
  STORE_PASSWORD="${STORE_PASSWORD:-$KEY_PASSWORD}"

  read -rp "  Name / org       [TPQ Futuhil Hidayah]: " CN
  CN="${CN:-TPQ Futuhil Hidayah}"

  read -rp "  Organization     [Futuhil Hidayah Wal Nikmah]: " ORG
  ORG="${ORG:-Futuhil Hidayah Wal Nikmah}"

  read -rp "  City             [Indonesia]: " CITY
  CITY="${CITY:-Indonesia}"

  read -rp "  State/Province   [Indonesia]: " STATE
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
  log "  Validity : ${VALIDITY_YEARS} years"
  log "  DN       : $DNAME"
  echo ""

  keytool -genkey -v \
    -keystore "$KEYSTORE_PATH" \
    -storetype JKS \
    -alias "$KEY_ALIAS" \
    -keyalg RSA -keysize 2048 \
    -validity "$VALIDITY_DAYS" \
    -storepass "$STORE_PASSWORD" \
    -keypass  "$KEY_PASSWORD" \
    -dname    "$DNAME"

  success "keys.jks generated: $KEYSTORE_PATH"
else
  # Read existing alias/passwords to use as defaults, but still prompt the user.
  if [[ -f "$KEY_PROPS_PATH" ]]; then
    EXISTING_KEY_ALIAS=$(grep -E '^keyAlias' "$KEY_PROPS_PATH" | cut -d= -f2- | sed 's/^[[:space:]]*//')
    EXISTING_KEY_PASSWORD=$(grep -E '^keyPassword' "$KEY_PROPS_PATH" | cut -d= -f2- | sed 's/^[[:space:]]*//')
    EXISTING_STORE_PASSWORD=$(grep -E '^storePassword' "$KEY_PROPS_PATH" | cut -d= -f2- | sed 's/^[[:space:]]*//')
  else
    EXISTING_KEY_ALIAS="tpq-release"
    EXISTING_KEY_PASSWORD=""
    EXISTING_STORE_PASSWORD=""
    warn "key.properties not found — no saved credentials available."
  fi

  read -rp "  Key alias        [${EXISTING_KEY_ALIAS:-tpq-release}]: " KEY_ALIAS
  KEY_ALIAS="${KEY_ALIAS:-${EXISTING_KEY_ALIAS:-tpq-release}}"

  read -rsp "  Key password     (hidden, Enter = keep current): " KEY_PASSWORD; echo ""
  KEY_PASSWORD="${KEY_PASSWORD:-$EXISTING_KEY_PASSWORD}"
  [[ -n "$KEY_PASSWORD" ]] || error "Key password is required."

  read -rsp "  Store password   (hidden, Enter = same/current): " STORE_PASSWORD; echo ""
  STORE_PASSWORD="${STORE_PASSWORD:-${EXISTING_STORE_PASSWORD:-$KEY_PASSWORD}}"
  [[ -n "$STORE_PASSWORD" ]] || error "Store password is required."

  log "Using existing key alias: $KEY_ALIAS"
fi

# ── Write key.properties ──────────────────────────────────────────────────────
mkdir -p "$(dirname "$KEY_PROPS_PATH")"
log "Writing key.properties to: $KEY_PROPS_PATH"

cat > "$KEY_PROPS_PATH" << EOF
# ============================================================
# android/app/key.properties — Flutter release signing config
# Generated by scripts/sign-apk.sh on $(date '+%Y-%m-%d %H:%M:%S')
#
# WARNING: Do NOT commit this file to version control!
#          Ensure android/app/key.properties is in .gitignore
# ============================================================

storePassword=${STORE_PASSWORD}
keyPassword=${KEY_PASSWORD}
keyAlias=${KEY_ALIAS}
storeFile=${KEYSTORE_RELATIVE_PATH}
EOF

success "key.properties written."
echo ""
echo -e "${BOLD}══════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}${BOLD}  Signing setup complete!                             ${RESET}"
echo -e "${BOLD}══════════════════════════════════════════════════════${RESET}"
echo ""
echo -e "  Keystore   : ${BOLD}$KEYSTORE_PATH${RESET}"
echo -e "  Properties : ${BOLD}$KEY_PROPS_PATH${RESET}"
echo ""
echo -e "${YELLOW}  Keep keys.jks safe — losing it means you cannot update the app on Play Store!${RESET}"
echo -e "${YELLOW}  Backup keys.jks and remember your passwords.${RESET}"
echo ""
echo "  Next step: run  ./scripts/build-apk.sh --split-per-abi"
