#!/bin/bash
set -e

USERNAME="radheshyam-bhati"
OUTPUT_FILE="assets/switchboard-stats.svg"

echo "=== SWITCHBOARD STATS GENERATOR ==="
echo "User: $USERNAME"
echo "Output: $OUTPUT_FILE"

# Ensure output directory exists
mkdir -p assets

# Use gh CLI (pre-installed and authenticated on GitHub Actions runners)
echo "Fetching user data via gh CLI..."
if command -v gh &>/dev/null; then
  GH_AVAILABLE=true
  echo "gh CLI found, using authenticated API calls"

  PUBLIC_REPOS=$(gh api "users/$USERNAME" --jq '.public_repos // 0')
  FOLLOWERS=$(gh api "users/$USERNAME" --jq '.followers // 0')
  
  REPOS_JSON=$(gh api "users/$USERNAME/repos?per_page=100&sort=updated")
  REPO_STARS=$(echo "$REPOS_JSON" | jq -r '[.[].stargazers_count] | add // 0')
  REPO_FORKS=$(echo "$REPOS_JSON" | jq -r '[.[].forks_count] | add // 0')
  LATEST_REPO=$(echo "$REPOS_JSON" | jq -r 'max_by(.pushed_at) | .name // "N/A"')
  LANGUAGES=$(echo "$REPOS_JSON" | jq -r '[.[].language] | unique | map(select(. != null)) | join(", ")' 2>/dev/null || echo "Various")

else
  echo "gh CLI not available, falling back to curl"
  echo "WARNING: This path may hit rate limits"

  USER_DATA=$(curl -s --fail "https://api.github.com/users/$USERNAME" 2>/dev/null) || {
    echo "ERROR: Failed to fetch user data"
    exit 1
  }
  REPOS_DATA=$(curl -s --fail "https://api.github.com/users/$USERNAME/repos?per_page=100&sort=updated" 2>/dev/null) || {
    echo "ERROR: Failed to fetch repos data"
    exit 1
  }

  PUBLIC_REPOS=$(echo "$USER_DATA" | jq -r '.public_repos // 0')
  FOLLOWERS=$(echo "$USER_DATA" | jq -r '.followers // 0')
  REPO_STARS=$(echo "$REPOS_DATA" | jq '[.[].stargazers_count] | add // 0')
  REPO_FORKS=$(echo "$REPOS_DATA" | jq '[.[].forks_count] | add // 0')
  LATEST_REPO=$(echo "$REPOS_DATA" | jq -r 'max_by(.pushed_at) | .name // "N/A"')
  LANGUAGES=$(echo "$REPOS_DATA" | jq -r '[.[].language] | unique | map(select(. != null)) | join(", ")' 2>/dev/null || echo "Various")
fi

LANGUAGES="${LANGUAGES:0:55}"

echo ""
echo "Stats:"
echo "  Repos:     $PUBLIC_REPOS"
echo "  Stars:     $REPO_STARS"
echo "  Followers: $FOLLOWERS"
echo "  Forks:     $REPO_FORKS"
echo "  Latest:    $LATEST_REPO"
echo "  Languages: $LANGUAGES"

# Guard against non-numeric values
PUBLIC_REPOS=${PUBLIC_REPOS:-0}
REPO_STARS=${REPO_STARS:-0}
FOLLOWERS=${FOLLOWERS:-0}
REPO_FORKS=${REPO_FORKS:-0}

# Clamp bar widths (max 115px)
bar_width_repos=$(( PUBLIC_REPOS > 50 ? 115 : PUBLIC_REPOS * 2 ))
bar_width_stars=$(( REPO_STARS > 50 ? 115 : REPO_STARS * 2 ))
bar_width_followers=$(( FOLLOWERS > 50 ? 115 : FOLLOWERS * 2 ))
bar_width_forks=$(( REPO_FORKS > 50 ? 115 : REPO_FORKS * 2 ))

# Format numbers with leading zeros
fmt_repos=$(printf "%02d" $PUBLIC_REPOS)
fmt_stars=$(printf "%02d" $REPO_STARS)
fmt_followers=$(printf "%02d" $FOLLOWERS)
fmt_forks=$(printf "%02d" $REPO_FORKS)

# Current timestamp
NOW=$(date -u "+%Y-%m-%d %H:%M UTC")

echo ""
echo "Generating SVG..."
cat > "$OUTPUT_FILE" << SVGEOF
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 620 160" width="100%" height="auto">
  <defs>
    <linearGradient id="meterBg" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stop-color="#1A1D23"/><stop offset="100%" stop-color="#0A0B0C"/></linearGradient>
    <linearGradient id="meterBar" x1="0" y1="0" x2="1" y2="0"><stop offset="0%" stop-color="#D45500"/><stop offset="100%" stop-color="#C4A35A"/></linearGradient>
    <linearGradient id="meterBarGreen" x1="0" y1="0" x2="1" y2="0"><stop offset="0%" stop-color="#00A86B"/><stop offset="100%" stop-color="#7ECF8A"/></linearGradient>
    <linearGradient id="meterBarBlue" x1="0" y1="0" x2="1" y2="0"><stop offset="0%" stop-color="#4A90D9"/><stop offset="100%" stop-color="#8BB8F0"/></linearGradient>
    <linearGradient id="meterBarGold" x1="0" y1="0" x2="1" y2="0"><stop offset="0%" stop-color="#C4A35A"/><stop offset="100%" stop-color="#E8D5B7"/></linearGradient>
    <filter id="glow"><feGaussianBlur stdDeviation="2"/><feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge></filter>
  </defs>
  <rect x="0" y="0" width="620" height="160" rx="6" fill="url(#meterBg)" stroke="#2A2F38" stroke-width="1.5"/>
  <rect x="210" y="6" width="200" height="16" rx="2" fill="#0A0B0C" stroke="#8B7355" stroke-width="0.5"/>
  <text x="310" y="18" font-family="monospace" font-size="8" fill="#C4A35A" text-anchor="middle" letter-spacing="4" opacity="0.8">LIVE METER PANEL</text>
  <g transform="translate(22,30)">
    <rect x="0" y="0" width="135" height="55" rx="3" fill="#0A0B0C" stroke="#2A2F38" stroke-width="0.5"/>
    <text x="8" y="14" font-family="monospace" font-size="7" fill="#8B7355" letter-spacing="1">LINES OPEN</text>
    <rect x="8" y="20" width="115" height="8" rx="4" fill="#1A1D23" stroke="#2A2F38" stroke-width="0.5"/>
    <rect x="8" y="20" width="${bar_width_repos}" height="8" rx="4" fill="url(#meterBar)" opacity="0.9"/>
    <text x="8" y="44" font-family="monospace" font-size="18" fill="#D45500" filter="url(#glow)">${fmt_repos}</text>
    <text x="115" y="44" font-family="monospace" font-size="7" fill="#5A4A35" text-anchor="end">repos</text>
  </g>
  <g transform="translate(169,30)">
    <rect x="0" y="0" width="135" height="55" rx="3" fill="#0A0B0C" stroke="#2A2F38" stroke-width="0.5"/>
    <text x="8" y="14" font-family="monospace" font-size="7" fill="#8B7355" letter-spacing="1">SIGNALS</text>
    <rect x="8" y="20" width="115" height="8" rx="4" fill="#1A1D23" stroke="#2A2F38" stroke-width="0.5"/>
    <rect x="8" y="20" width="${bar_width_stars}" height="8" rx="4" fill="url(#meterBarGold)" opacity="0.9"/>
    <text x="8" y="44" font-family="monospace" font-size="18" fill="#C4A35A" filter="url(#glow)">${fmt_stars}</text>
    <text x="115" y="44" font-family="monospace" font-size="7" fill="#5A4A35" text-anchor="end">stars</text>
  </g>
  <g transform="translate(316,30)">
    <rect x="0" y="0" width="135" height="55" rx="3" fill="#0A0B0C" stroke="#2A2F38" stroke-width="0.5"/>
    <text x="8" y="14" font-family="monospace" font-size="7" fill="#8B7355" letter-spacing="1">ROUTES</text>
    <rect x="8" y="20" width="115" height="8" rx="4" fill="#1A1D23" stroke="#2A2F38" stroke-width="0.5"/>
    <rect x="8" y="20" width="${bar_width_followers}" height="8" rx="4" fill="url(#meterBarBlue)" opacity="0.9"/>
    <text x="8" y="44" font-family="monospace" font-size="18" fill="#4A90D9" filter="url(#glow)">${fmt_followers}</text>
    <text x="115" y="44" font-family="monospace" font-size="7" fill="#5A4A35" text-anchor="end">followers</text>
  </g>
  <g transform="translate(463,30)">
    <rect x="0" y="0" width="135" height="55" rx="3" fill="#0A0B0C" stroke="#2A2F38" stroke-width="0.5"/>
    <text x="8" y="14" font-family="monospace" font-size="7" fill="#8B7355" letter-spacing="1">BANDWIDTH</text>
    <rect x="8" y="20" width="115" height="8" rx="4" fill="#1A1D23" stroke="#2A2F38" stroke-width="0.5"/>
    <rect x="8" y="20" width="${bar_width_forks}" height="8" rx="4" fill="url(#meterBarGreen)" opacity="0.9"/>
    <text x="8" y="44" font-family="monospace" font-size="18" fill="#00A86B" filter="url(#glow)">${fmt_forks}</text>
    <text x="115" y="44" font-family="monospace" font-size="7" fill="#5A4A35" text-anchor="end">forks</text>
  </g>
  <rect x="22" y="95" width="576" height="1" fill="#2A2F38" opacity="0.5"/>
  <g transform="translate(22,105)"><text x="0" y="10" font-family="monospace" font-size="7" fill="#8B7355">LATEST:</text><text x="55" y="10" font-family="monospace" font-size="7" fill="#E8D5B7">${LATEST_REPO}</text></g>
  <g transform="translate(22,122)"><text x="0" y="10" font-family="monospace" font-size="7" fill="#8B7355">SPECTRUM:</text><text x="65" y="10" font-family="monospace" font-size="7" fill="#E8D5B7">${LANGUAGES}</text></g>
  <circle cx="585" cy="108" r="3" fill="#00A86B" filter="url(#glow)"/>
  <text x="575" y="112" font-family="monospace" font-size="6" fill="#5A4A35" text-anchor="end">LIVE</text>
  <g transform="translate(22,140)"><text x="0" y="10" font-family="monospace" font-size="6" fill="#5A4A35">UPDATED: ${NOW}</text></g>
</svg>
SVGEOF

echo ""
echo "SVG generated successfully at $OUTPUT_FILE"
echo "=== DONE ==="
