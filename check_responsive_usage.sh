#!/bin/bash

# Check which screens use ResponsiveUtils
echo "Checking ResponsiveUtils usage in screens..."
echo ""

SCREENS_DIR="lib/screens"
OTHER_SCREENS="lib/login_screen.dart lib/register_screen.dart"

echo "=== Screens WITH ResponsiveUtils ==="
grep -l "ResponsiveUtils\|responsive" "$SCREENS_DIR"/*.dart 2>/dev/null | sed 's|.*/||' | sort

echo ""
echo "=== Screens WITHOUT ResponsiveUtils ==="
for file in "$SCREENS_DIR"/*.dart; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        if ! grep -q "ResponsiveUtils\|responsive" "$file" 2>/dev/null; then
            echo "$filename"
        fi
    fi
done

for file in $OTHER_SCREENS; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        if ! grep -q "ResponsiveUtils\|responsive" "$file" 2>/dev/null; then
            echo "$filename"
        fi
    fi
done
