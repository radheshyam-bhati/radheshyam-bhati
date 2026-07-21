#!/bin/bash
# Switchboard Stats Generator
# Fetches live GitHub stats and generates a vintage meter panel SVG

set -e

USERNAME="radheshyam-bhati"
OUTPUT_FILE="assets/switchboard-stats.svg"

# Helper to escape XML special characters
xml_escape() {
  echo "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&#39;/g'
}

# Fetch data from GitHub API with error handling
echo "Fetching user data for $USERNAME..."
USER_DATA=$(curl -s --fail "https://api.github.com/users/$USERNAME" 2>/dev/null) || {
  echo "ERROR: Failed to fetch user data from GitHub API"
  exit 1
}

REPOS_DATA=$(curl -s --fail "https://api.github.com/users/$USERNAME/repos?per_page=100&type=public" 2>/dev/null) || {
  echo "ERROR: Failed to fetch repos data from GitHub API"
  exit 1
}

# Validate JSON
echo "$USER_DATA" | jq empty 2>/dev/null || {
  echo "ERROR: Invalid JSON response from user API"
  exit 1
}

# Extract values with defaults
PUBLIC_REPOS=$(echo "$USER_DATA" | jq -r '.public_repos // 0')
FOLLOWERS=$(echo "$USER_DATA" | jq -r '.followers // 0')
FOLLOWING=$(echo "$USER_DATA" | jq -r '.following // 0')

# Calculate total stars across all repos
TOTAL_STARS=$(echo "$REPOS_DATA" | jq '[.[].stargazers_count] | add // 0')
TOTAL_FORKS=$(echo "$REPOS_DATA" | jq '[.[].forks_count] | add // 0')

# Get latest repo name (sanitized)
LATEST_REPO=$(echo "$REPOS_DATA" | jq -r 'max_by(.pushed_at) | .name // "N/A"')
LATEST_REPO=$(xml_escape "$LATEST_REPO")

# Get primary languages used (sanitized)
LANGUAGES=$(echo "$REPOS_DATA" | jq -r '[.[].language] | unique | map(select(. != null)) | join(", ")' 2>/dev/null || echo "Various")
LANGUAGES=$(xml_escape "$LANGUAGES")
LANGUAGES=${LANGUAGES:0:55}

echo "Stats: $PUBLIC_REPOS repos, $TOTAL_STARS stars, $FOLLOWERS followers"
echo "Latest: $LATEST_REPO"
echo "Languages: $LANGUAGES"

# Build the SVG
cat > "$OUTPUT_FILE" << SVGEOF
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 620 160" width="100%" height="auto">
  <defs>
    <linearGradient id="meterBg" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#1A1D23"/>
      <stop offset="100%" stop-color="#0A0B0C"/>
    </linearGradient>
    <linearGradient id="meterBar" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0%" stop-color="#D45500"/>
      <stop offset="100%" stop-color="#C4A35A"/>
    </linearGradient>
    <linearGradient id="meterBarGreen" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0%" stop-color="#00A86B"/>
      <stop offset="100%" stop-color="#7ECF8A"/>
    </linearGradient>
    <linearGradient id="meterBarBlue" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0%" stop-color="#4A90D9"/>
      <stop offset="100%" stop-color="#8BB8F0"/>
    </linearGradient>
    <linearGradient id="meterBarGold" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0%" stop-color="#C4A35A"/>
      <stop offset="100%" stop-color="#E8D5B7"/>
    </linearGradient>
    <filter id="glow">
      <feGaussianBlur stdDeviation="2" result="blur"/>
      <feMerge><feMergeNode in="blur"/><feMergeNode in="SourceGraphic"/></feMerge>
    </filter>
  </defs>

  <!-- Panel background -->
  <rect x="0" y="0" width="620" height="160" rx="6" fill="url(#meterBg)" stroke="#2A2F38" stroke-width="1.5"/>
  <rect x="3" y="3" width="614" height="154" rx="4" fill="none" stroke="#8B7355" stroke-width="0.5" opacity="0.3"/>

  <!-- Panel title -->
  <rect x="210" y="6" width="200" height="16" rx="2" fill="#0A0B0C" stroke="#8B7355" stroke-width="0.5"/>
  <text x="310" y="18" font-family="'Courier New', monospace" font-size="8" fill="#C4A35A" text-anchor="middle" letter-spacing="4" opacity="0.8">LIVE METER PANEL</text>

  <!-- Meter 1: Lines Open (Repos) -->
  <g transform="translate(22, 30)">
    <rect x="0" y="0" width="135" height="55" rx="3" fill="#0A0B0C" stroke="#2A2F38" stroke-width="0.5"/>
    <text x="8" y="14" font-family="monospace" font-size="7" fill="#8B7355" letter-spacing="1">LINES OPEN</text>
    <rect x="8" y="20" width="115" height="8" rx="4" fill="#1A1D23" stroke="#2A2F38" stroke-width="0.5"/>
    <rect x="8" y="20" width="$(( PUBLIC_REPOS > 50 ? 115 : PUBLIC_REPOS * 2 ))" height="8" rx="4" fill="url(#meterBar)" opacity="0.9"/>
    <text x="8" y="44" font-family="monospace" font-size="18" fill="#D45500" filter="url(#glow)">$(printf "%02d" $PUBLIC_REPOS)</text>
    <text x="115" y="44" font-family="monospace" font-size="7" fill="#5A4A35" text-anchor="end">repos</text>
  </g>

  <!-- Meter 2: Signals (Stars) -->
  <g transform="translate(169, 30)">
    <rect x="0" y="0" width="135" height="55" rx="3" fill="#0A0B0C" stroke="#2A2F38" stroke-width="0.5"/>
    <text x="8" y="14" font-family="monospace" font-size="7" fill="#8B7355" letter-spacing="1">SIGNALS</text>
    <rect x="8" y="20" width="115" height="8" rx="4" fill="#1A1D23" stroke="#2A2F38" stroke-width="0.5"/>
    <rect x="8" y="20" width="$(( TOTAL_STARS > 50 ? 115 : TOTAL_STARS * 2 ))" height="8" rx="4" fill="url(#meterBarGold)" opacity="0.9"/>
    <text x="8" y="44" font-family="monospace" font-size="18" fill="#C4A35A" filter="url(#glow)">$(printf "%02d" $TOTAL_STARS)</text>
    <text x="115" y="44" font-family="monospace" font-size="7" fill="#5A4A35" text-anchor="end">stars</text>
  </g>

  <!-- Meter 3: Routes (Followers) -->
  <g transform="translate(316, 30)">
    <rect x="0" y="0" width="135" height="55" rx="3" fill="#0A0B0C" stroke="#2A2F38" stroke-width="0.5"/>
    <text x="8" y="14" font-family="monospace" font-size="7" fill="#8B7355" letter-spacing="1">ROUTES</text>
    <rect x="8" y="20" width="115" height="8" rx="4" fill="#1A1D23" stroke="#2A2F38" stroke-width="0.5"/>
    <rect x="8" y="20" width="$(( FOLLOWERS > 50 ? 115 : FOLLOWERS * 2 ))" height="8" rx="4" fill="url(#meterBarBlue)" opacity="0.9"/>
    <text x="8" y="44" font-family="monospace" font-size="18" fill="#4A90D9" filter="url(#glow)">$(printf "%02d" $FOLLOWERS)</text>
    <text x="115" y="44" font-family="monospace" font-size="7" fill="#5A4A35" text-anchor="end">followers</text>
  </g>

  <!-- Meter 4: Bandwidth (Forks) -->
  <g transform="translate(463, 30)">
    <rect x="0" y="0" width="135" height="55" rx="3" fill="#0A0B0C" stroke="#2A2F38" stroke-width="0.5"/>
    <text x="8" y="14" font-family="monospace" font-size="7" fill="#8B7355" letter-spacing="1">BANDWIDTH</text>
    <rect x="8" y="20" width="115" height="8" rx="4" fill="#1A1D23" stroke="#2A2F38" stroke-width="0.5"/>
    <rect x="8" y="20" width="$(( TOTAL_FORKS > 50 ? 115 : TOTAL_FORKS * 2 ))" height="8" rx="4" fill="url(#meterBarGreen)" opacity="0.9"/>
    <text x="8" y="44" font-family="monospace" font-size="18" fill="#00A86B" filter="url(#glow)">$(printf "%02d" $TOTAL_FORKS)</text>
    <text x="115" y="44" font-family="monospace" font-size="7" fill="#5A4A35" text-anchor="end">forks</text>
  </g>

  <!-- Bottom status bar -->
  <rect x="22" y="95" width="576" height="1" fill="#2A2F38" opacity="0.5"/>

  <!-- Latest activity -->
  <g transform="translate(22, 105)">
    <text x="0" y="10" font-family="monospace" font-size="7" fill="#8B7355">LATEST:</text>
    <text x="55" y="10" font-family="monospace" font-size="7" fill="#E8D5B7">$LATEST_REPO</text>
  </g>

  <!-- Language diversity -->
  <g transform="translate(22, 122)">
    <text x="0" y="10" font-family="monospace" font-size="7" fill="#8B7355">SPECTRUM:</text>
    <text x="65" y="10" font-family="monospace" font-size="7" fill="#E8D5B7">$LANGUAGES</text>
  </g>

  <!-- Pulse indicators -->
  <circle cx="585" cy="108" r="3" fill="#00A86B" filter="url(#glow)"/>
  <text x="575" y="112" font-family="monospace" font-size="6" fill="#5A4A35" text-anchor="end">LIVE</text>

  <!-- Timestamp -->
  <g transform="translate(22, 140)">
    <text x="0" y="10" font-family="monospace" font-size="6" fill="#5A4A35">UPDATED: $(date -u "+%Y-%m-%d %H:%M UTC")</text>
  </g>
</svg>
SVGEOF

echo "Stats SVG generated at $OUTPUT_FILE"
echo "Done."
