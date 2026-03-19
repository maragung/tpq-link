#!/bin/bash
# setup_wsl.sh — Final fix for scripts and environment in WSL

echo "Finalizing scripts for WSL..."

# 1. Clean CRLF in all scripts
for f in scripts/*.sh; do
    echo "  Clean $f..."
    tr -d '\r' < "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    chmod +x "$f"
done

# 2. Fix local.properties SDK path (Windows to WSL)
LP="android/local.properties"
if [[ -f "$LP" ]]; then
    SDK_LINE=$(grep '^sdk.dir=' "$LP" || true)
    if [[ -n "$SDK_LINE" ]]; then
        WIN_PATH="${SDK_LINE#sdk.dir=}"
        # If it contains drive letter or \
        if [[ "$WIN_PATH" =~ ^[A-Za-z]: || "$WIN_PATH" == *"\\"* ]]; then
             WIN_PATH=$(echo "$WIN_PATH" | tr -d '\r')
             if command -v wslpath >/dev/null 2>&1; then
                 WSL_PATH=$(wslpath -u "$WIN_PATH")
                 sed -i "s|^sdk.dir=.*$|sdk.dir=$WSL_PATH|" "$LP"
                 echo "  SDK path converted to: $WSL_PATH"
             fi
        fi
    fi
fi

# 3. Add common Flutter path to current PATH for this script session
for _cand in "$HOME/flutter/bin" "/usr/local/flutter/bin" "/opt/flutter/bin" "/mnt/c/Apps/flutter/bin"; do
    if [[ -x "$_cand/flutter" ]]; then
       export PATH="$_cand:$PATH"
       echo "  Flutter found at $_cand (added to PATH)"
       break
    fi
done

# 4. Check Java
if command -v java >/dev/null 2>&1; then
    echo "  Java: $(java --version | head -1)"
fi

# 5. Run build-apk.sh
echo ""
echo "══════════════════════════════════════════════════════"
echo "  Executing ./scripts/build-apk.sh --split-abi        "
echo "══════════════════════════════════════════════════════"
echo ""

# Terminating existing install.sh if possible? No need.
exec ./scripts/build-apk.sh --split-abi
