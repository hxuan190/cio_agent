#!/bin/bash
# safe-exec.sh - Intercept and compress massive terminal outputs.
# Usage: ./core/scripts/safe-exec.sh "npm run build"

COMMAND="$1"
if [ -z "$COMMAND" ]; then
    echo "❌ Usage: $0 \"your_command\""
    exit 1
fi

TMP_OUT=$(mktemp)

echo "⚙️ Executing (Safely): $COMMAND"
eval "$COMMAND" > "$TMP_OUT" 2>&1
EXIT_CODE=$?

LINES=$(wc -l < "$TMP_OUT")
MAX_LINES=100

if [ "$LINES" -gt "$MAX_LINES" ]; then
    echo ""
    echo "⚠️ --- OUTPUT TRUNCATED TO SAVE AI TOKENS (Total $LINES lines) --- ⚠️"
    echo "--- HEAD (First 40 lines) ---"
    head -n 40 "$TMP_OUT"
    echo ""
    echo "... [$(($LINES - 80)) lines hidden. Check manually if needed] ..."
    echo ""
    echo "--- TAIL (Last 40 lines) ---"
    tail -n 40 "$TMP_OUT"
    echo "⚠️ --- END TRUNCATED OUTPUT --- ⚠️"
else
    cat "$TMP_OUT"
fi

rm -f "$TMP_OUT"
exit $EXIT_CODE
