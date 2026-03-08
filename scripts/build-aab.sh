#!/usr/bin/env bash
# =============================================================================
# scripts/build-aab.sh — Convenience wrapper: build .aab for Google Play Store
# =============================================================================
# Usage:
#   cd scripts && ./build-aab.sh
#   OR from project root:  bash scripts/build-aab.sh
#
# This simply calls build-apk.sh --aab which runs:
#   flutter build appbundle --release
#
# The resulting .aab will be at:
#   build/app/outputs/bundle/release/app-release.aab
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/build-apk.sh" --aab
