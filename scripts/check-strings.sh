#!/bin/bash
# Lint: detect hardcoded user-facing strings in source/ (excluding Strings.mc itself)

ERRORS=0

while IFS= read -r line; do
    file=$(echo "$line" | cut -d: -f1)
    num=$(echo "$line" | cut -d: -f2)
    content=$(echo "$line" | cut -d: -f3-)
    echo "  $file:$num →$content"
    ((ERRORS++))
done < <(grep -rn --include="*.mc" -E '(drawText|MenuItem|ToggleMenuItem|Menu2\.initialize).*"[A-Z][a-z]' source/ \
    | grep -v "Strings.mc" \
    | grep -v "Wordmark.mc" \
    | grep -v "//")

if [ $ERRORS -gt 0 ]; then
    echo ""
    echo "Found $ERRORS potential hardcoded strings."
    exit 1
fi

echo "No hardcoded strings found."
exit 0
