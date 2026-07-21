#!/bin/bash
set -x

USERNAME="radheshyam-bhati"
OUTPUT_FILE="assets/switchboard-stats.svg"
DEBUG_LOG="assets/switchboard-debug.log"

# Ensure output directory exists
mkdir -p assets

# Capture all output to debug file
exec > "$DEBUG_LOG" 2>&1

echo "=== SWITCHBOARD STATS GENERATOR (DEBUG) ==="
echo "User: $USERNAME"
echo "Date: $(date -u)"

# Step 1: Check gh CLI
echo "=== Step 1: gh CLI check ==="
if command -v gh &>/dev/null; then
  echo "gh found"
  gh --version 2>&1
else
  echo "gh NOT found"
fi

# Step 2: gh auth status
echo "=== Step 2: gh auth ==="
gh auth status 2>&1 || echo "auth status failed"

# Step 3: Simple gh api test
echo "=== Step 3: gh api user test ==="
gh api "users/$USERNAME" 2>&1 | head -c 500
echo ""
echo "gh api exit code: $?"

# Step 4: Simple gh api repos test
echo "=== Step 4: gh api repos test ==="
gh api "users/$USERNAME/repos?per_page=5&sort=updated" 2>&1 | head -c 500
echo ""
echo "gh api repos exit code: $?"

# Step 5: jq check
echo "=== Step 5: jq check ==="
which jq 2>&1
jq --version 2>&1

# Step 6: curl fallback test
echo "=== Step 6: curl test ==="
curl -v "https://api.github.com/users/$USERNAME" 2>&1 | head -c 300
echo ""
echo "curl exit code: $?"

echo "=== DEBUG COMPLETE ==="

# Always create a fallback SVG so the commit step doesn't error
cat > "$OUTPUT_FILE" << 'SVGEOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 620 160" width="100%" height="auto">
  <rect x="0" y="0" width="620" height="160" rx="6" fill="#0A0B0C" stroke="#2A2F38" stroke-width="1.5"/>
  <text x="310" y="85" font-family="monospace" font-size="12" fill="#D45500" text-anchor="middle">SWITCHBOARD STATS UNAVAILABLE</text>
  <text x="310" y="105" font-family="monospace" font-size="8" fill="#5A4A35" text-anchor="middle">Check debug log for details</text>
</svg>
SVGEOF

echo "Fallback SVG written"
echo "=== END OF DEBUG SCRIPT ==="
