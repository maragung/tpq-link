#!/usr/bin/env bash
# =============================================================================
# scripts/install.sh — Install & verify all dependencies for TPQ Link
# =============================================================================
# What this script does:
#   1. Checks / installs Java JDK 17 (keytool, needed by sign-apk.sh)
#   2. Checks / installs Flutter SDK (needed by build-apk.sh)
#   3. Runs `flutter doctor` to verify Android toolchain
#   4. Optionally installs Android command-line tools & platform
#
# Supported host platforms:
#   - Ubuntu/Debian Linux   (apt)
#   - macOS                 (Homebrew)
#   - Windows               → use install.ps1 or install.bat instead
# =============================================================================

set -euo pipefail

# ── Paths ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

log()    { echo -e "${CYAN}[INSTALL]${RESET} $*"; }
success(){ echo -e "${GREEN}[OK]      ${RESET} $*"; }
warn()   { echo -e "${YELLOW}[WARN]    ${RESET} $*"; }
error()  { echo -e "${RED}[ERROR]   ${RESET} $*" >&2; exit 1; }
step()   { echo -e "\n${BOLD}${CYAN}── $* ──────────────────────────────────${RESET}"; }

# ── Helpers ──────────────────────────────────────────────────────────────────
normalize_path() {
  local path="$1"
  [[ -z "$path" ]] && return 0
  if [[ "$path" =~ ^[A-Za-z]:\\ || "$path" == *"\\"* ]] && grep -qi microsoft /proc/version 2>/dev/null; then
    if command -v wslpath >/dev/null 2>&1; then
      wslpath -u "$path"
    else
      echo "$path" | sed -E 's/([A-Za-z]):\\/\/\L\1\//;s/\\/\//g'
    fi
  else
    echo "$path"
  fi
}

# ── Detect OS ─────────────────────────────────────────────────────────────────
OS="unknown"
IS_WSL=false
if grep -qi microsoft /proc/version 2>/dev/null; then
  IS_WSL=true
  OS="linux"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  OS="macos"
else
  error "Unsupported OS: $OSTYPE — use install.ps1 (PowerShell) or install.bat on Windows."
fi

echo -e "${BOLD}══════════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}  TPQ Link — Install Dependencies                     ${RESET}"
echo -e "${BOLD}══════════════════════════════════════════════════════${RESET}"
echo ""
log "Detected OS: $OS (WSL: $IS_WSL)"

# ── Java JDK 17 ───────────────────────────────────────────────────────────────
step "Java JDK 17"
if command -v java &>/dev/null && java --version 2>&1 | grep -qE "version \"(17|2[0-9])"; then
  success "Java already installed: $(java --version 2>&1 | head -1)"
else
  warn "Java 17+ not found — installing..."
  if [[ "$OS" == "linux" ]]; then
    if command -v apt-get &>/dev/null; then
      sudo apt-get update -qq
      sudo apt-get install -y openjdk-17-jdk
    elif command -v dnf &>/dev/null; then
      sudo dnf install -y java-17-openjdk-devel
    else
      error "Unsupported package manager. Install Java JDK 17 manually: https://adoptium.net"
    fi
  elif [[ "$OS" == "macos" ]]; then
    if ! command -v brew &>/dev/null; then
      error "Homebrew not found. Install it from https://brew.sh then re-run this script."
    fi
    brew install --cask temurin@17
    export PATH="$(/usr/libexec/java_home -v 17)/bin:$PATH"
  fi
  success "Java installed: $(java --version 2>&1 | head -1)"
fi

# ── Flutter SDK ───────────────────────────────────────────────────────────────
step "Flutter SDK"
if command -v flutter &>/dev/null; then
  success "Flutter already installed: $(flutter --version 2>&1 | head -1)"
else
  warn "Flutter not found — checking common locations..."
  for _cand in "$HOME/flutter/bin" "/usr/local/flutter/bin" "/opt/flutter/bin" "/mnt/c/Apps/flutter/bin"; do
    if [[ -x "$_cand/flutter" ]]; then
      export PATH="$_cand:$PATH"
      success "Flutter found at $_cand"
      break
    fi
  done
  
  if ! command -v flutter &>/dev/null; then
     warn "Flutter still not found — installing latest stable..."
     FLUTTER_INSTALL_DIR="$HOME/flutter"
     if [[ "$OS" == "linux" ]]; then
       FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.27.4-stable.tar.xz"
       curl -fsSL "$FLUTTER_URL" -o /tmp/flutter.tar.xz
       tar xf /tmp/flutter.tar.xz -C "$HOME"
       rm /tmp/flutter.tar.xz
     elif [[ "$OS" == "macos" ]]; then
       brew install --cask flutter 2>/dev/null || {
         FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_3.27.4-stable.zip"
         curl -fsSL "$FLUTTER_URL" -o /tmp/flutter.zip
         unzip -q /tmp/flutter.zip -d "$HOME"
         rm /tmp/flutter.zip
       }
     fi
     export PATH="$FLUTTER_INSTALL_DIR/bin:$PATH"
     success "Flutter installed to $FLUTTER_INSTALL_DIR"
  fi
fi

# ── Android SDK ───────────────────────────────────────────────────────────────
step "Android SDK"
if [[ -n "${ANDROID_HOME:-}" ]]; then
  ANDROID_HOME=$(normalize_path "$ANDROID_HOME")
fi

if [[ -n "${ANDROID_HOME:-}" && -d "$ANDROID_HOME" ]]; then
  success "ANDROID_HOME: $ANDROID_HOME"
elif [[ -d "$HOME/Android/Sdk" ]]; then
  export ANDROID_HOME="$HOME/Android/Sdk"
  success "ANDROID_HOME auto-detected: $ANDROID_HOME"
elif [[ -d "/mnt/c/Users/$USER/AppData/Local/Android/Sdk" ]]; then
  export ANDROID_HOME="/mnt/c/Users/$USER/AppData/Local/Android/Sdk"
  success "ANDROID_HOME auto-detected (WSL-Windows): $ANDROID_HOME"
elif [[ -d "$HOME/android-sdk" ]]; then
  export ANDROID_HOME="$HOME/android-sdk"
  success "ANDROID_HOME auto-detected: $ANDROID_HOME"
else
  warn "Android SDK not found. Setup it manually or run build-apk.sh to try auto-fix."
fi

if [[ -n "${ANDROID_HOME:-}" && -d "$ANDROID_HOME" ]]; then
  export ANDROID_SDK_ROOT="$ANDROID_HOME"
  # Sync to local.properties
  if [[ -f "$PROJECT_ROOT/android/local.properties" ]]; then
    sed -i "s|^sdk\.dir=.*$|sdk.dir=$ANDROID_HOME|" "$PROJECT_ROOT/android/local.properties" || \
    printf '\nsdk.dir=%s\n' "$ANDROID_HOME" >> "$PROJECT_ROOT/android/local.properties"
  else
    printf 'sdk.dir=%s\n' "$ANDROID_HOME" > "$PROJECT_ROOT/android/local.properties"
  fi
  success "android/local.properties synced."
fi

# ── Flutter Doctor ────────────────────────────────────────────────────────────
step "Flutter Doctor"
flutter doctor

# ── Project dependencies ──────────────────────────────────────────────────────
step "Project Dependencies"
cd "$PROJECT_ROOT"
flutter pub get
success "Dependencies fetched."

# ── Permissions ───────────────────────────────────────────────────────────────
step "Script Permissions"
chmod +x "$SCRIPT_DIR"/*.sh
success "Scripts are now executable."

echo ""
echo -e "${BOLD}══════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}${BOLD}  Installation complete!                              ${RESET}"
echo -e "${BOLD}══════════════════════════════════════════════════════${RESET}"
echo ""
