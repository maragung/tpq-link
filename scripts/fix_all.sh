#!/bin/bash
# scripts/fix_all.sh
for f in scripts/*.sh; do
    echo "Processing $f"
    tr -d '\r' < "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    chmod +x "$f"
done
echo "All scripts fixed."
./scripts/build-apk.sh --split-abi
