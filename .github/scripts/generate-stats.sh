#!/bin/bash
# Debug mode: capture ALL output to a log file
set -x

USERNAME="radheshyam-bhati"
OUTPUT_FILE="assets/switchboard-stats.svg"
DEBUG_LOG="assets/switchboard-debug.log"

# Redirect all output to debug log as well
exec > "$DEBUG_LOG" 2>&1

echo "=== SWITCHBOARD STATS GENERATOR (DEBUG) ==="
echo "User: $USERNAME"
echo "Date: $(date -u)"

mkdir -p assets

echo "=== Step 1: Check gh CLI ==="
if command -v gh &>/dev/null; then
  echo "gh CLI found"
  gh --version
  echo "=== Step 2: gh auth status ==="
  gh auth status 2>&1 || echo "gh auth status failed (continuing)"
else
  echo "gh CLI NOT found"
fi

echo "=== Step 3: Direct curl test ==="
curl -s -w "\nHTTP_CODE:%{http_code}" "https://api.github.com/users/$USERNAME" 2>&1 | tail -20

echo ""
echo "=== Step 4: gh api test ==="
gh api "users/$USERNAME" 2>&1 | head -c 500 || echo "gh api call failed"

echo ""
echo "=== Step 5: jq test ==="
which jq && jq --version || echo "jq not found"

echo ""
echo "=== DONE ==="
