#!/bin/bash
for f in scripts/*.sh; do
  echo "Fixing $f..."
  tr -d '\r' < "$f" > "$f.tmp"
  mv "$f.tmp" "$f"
  chmod +x "$f"
done
echo "All .sh files fixed."
