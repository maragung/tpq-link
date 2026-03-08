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
#
# Usage:
#   chmod +x scripts/install.sh
#   ./scripts/install.sh
# =============================================================================

set -euo pipefail

# ── Paths ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

log()    { echo -e "${CYAN}[INSTALL]${RESET} $*"; }
success(){ echo -e "${GREEN}[OK]${RESET}      $*"; }
warn()   { echo -e "${YELLOW}[WARN]${RESET}    $*"; }
error()  { echo -e "${RED}[ERROR]${RESET}   $*" >&2; exit 1; }
step()   { echo -e "\n${BOLD}${CYAN}── $* ──────────────────────────────────${RESET}"; }

# ── Detect OS ─────────────────────────────────────────────────────────────────
OS="unknown"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
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
log "Detected OS: $OS"

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
    # Add to PATH for this session
    export PATH="$(/usr/libexec/java_home -v 17)/bin:$PATH"
  fi
  success "Java installed: $(java --version 2>&1 | head -1)"
fi

# Verify keytool
command -v keytool &>/dev/null && success "keytool: $(command -v keytool)" \
  || warn "keytool not found in PATH. Ensure JAVA_HOME/bin is in PATH."

# ── Flutter SDK ───────────────────────────────────────────────────────────────
step "Flutter SDK"
if command -v flutter &>/dev/null; then
  success "Flutter already installed: $(flutter --version 2>&1 | head -1)"
else
  warn "Flutter not found — installing latest stable..."
  FLUTTER_INSTALL_DIR="$HOME/flutter"
  if [[ "$OS" == "linux" ]]; then
    FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.27.4-stable.tar.xz"
    log "Downloading Flutter stable (linux)..."
    curl -fsSL "$FLUTTER_URL" -o /tmp/flutter.tar.xz
    tar xf /tmp/flutter.tar.xz -C "$HOME"
    rm /tmp/flutter.tar.xz
  elif [[ "$OS" == "macos" ]]; then
    brew install --cask flutter 2>/dev/null || {
      log "Falling back to manual install..."
      FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_3.27.4-stable.zip"
      curl -fsSL "$FLUTTER_URL" -o /tmp/flutter.zip
      unzip -q /tmp/flutter.zip -d "$HOME"
      rm /tmp/flutter.zip
    }
  fi

  # Add to PATH for this session
  export PATH="$FLUTTER_INSTALL_DIR/bin:$PATH"

  # Add permanently to shell profile
  SHELL_PROFILE=""
  if [[ -f "$HOME/.zshrc" ]]; then
    SHELL_PROFILE="$HOME/.zshrc"
  elif [[ -f "$HOME/.bashrc" ]]; then
    SHELL_PROFILE="$HOME/.bashrc"
  fi
  if [[ -n "$SHELL_PROFILE" ]]; then
    if ! grep -q 'flutter/bin' "$SHELL_PROFILE"; then
      echo "" >> "$SHELL_PROFILE"
      echo "# Flutter SDK" >> "$SHELL_PROFILE"
      echo "export PATH=\"\$HOME/flutter/bin:\$PATH\"" >> "$SHELL_PROFILE"
      log "Added Flutter to $SHELL_PROFILE"
    fi
  fi
  success "Flutter installed: $(flutter --version 2>&1 | head -1)"
fi

# ── Android SDK (basic check) ────────────────────────────────────────────────
step "Android SDK"
if [[ -n "${ANDROID_HOME:-}" && -d "$ANDROID_HOME" ]]; then
  success "ANDROID_HOME: $ANDROID_HOME"
elif [[ -d "$HOME/Android/Sdk" ]]; then
  export ANDROID_HOME="$HOME/Android/Sdk"
  success "ANDROID_HOME auto-detected: $ANDROID_HOME"
elif [[ -d "$HOME/android-sdk" ]]; then
  export ANDROID_HOME="$HOME/android-sdk"
  success "ANDROID_HOME auto-detected: $ANDROID_HOME"
else
  warn "Android SDK not found. Flutter will download it automatically on first build."
  warn "Or set ANDROID_HOME manually and re-run this script."
fi

# ── Flutter doctor ────────────────────────────────────────────────────────────
step "Flutter Doctor"
log "Running flutter doctor..."
flutter doctor --android-licenses 2>/dev/null || true
echo ""
flutter doctor
echo ""

# ── Project dependencies ──────────────────────────────────────────────────────
step "Project Dependencies"
cd "$PROJECT_ROOT"
log "Running flutter pub get..."
flutter pub get
success "Dependencies fetched."

# ── Make scripts executable ───────────────────────────────────────────────────
step "Script Permissions"
chmod +x "$SCRIPT_DIR/build-apk.sh" "$SCRIPT_DIR/sign-apk.sh" "$SCRIPT_DIR/install.sh"
success "Scripts are now executable."

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}══════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}${BOLD}  Installation complete!                              ${RESET}"
echo -e "${BOLD}══════════════════════════════════════════════════════${RESET}"
echo ""
echo -e "  ${BOLD}Next steps:${RESET}"
echo -e "  1. Generate signing key  :  ${CYAN}./scripts/sign-apk.sh${RESET}"
echo -e "  2. Build release APK     :  ${CYAN}./scripts/build-apk.sh --split-per-abi${RESET}"
echo -e "  3. Build Play Store AAB  :  ${CYAN}./scripts/build-apk.sh --aab${RESET}"
echo ""
