#!/bin/bash
set -e

USERNAME="radheshyam-bhati"

echo "=== PROFILE BADGE GENERATOR ==="
echo "User: $USERNAME"

# Ensure output directory exists
mkdir -p assets

# Use gh CLI (pre-installed and authenticated on GitHub Actions runners)
echo "Fetching data via gh CLI..."
if command -v gh &>/dev/null; then
  PUBLIC_REPOS=$(gh api "users/$USERNAME" --jq '.public_repos // 0')
  FOLLOWERS=$(gh api "users/$USERNAME" --jq '.followers // 0')

  REPOS_JSON=$(gh api "users/$USERNAME/repos?per_page=100&sort=updated")
  REPO_STARS=$(echo "$REPOS_JSON" | jq -r '[.[].stargazers_count] | add // 0')
  REPO_FORKS=$(echo "$REPOS_JSON" | jq -r '[.[].forks_count] | add // 0')
  echo "gh API calls successful"
else
  echo "ERROR: gh CLI not available"
  exit 1
fi

echo ""
echo "Stats: $PUBLIC_REPOS repos, $REPO_STARS stars, $FOLLOWERS followers, $REPO_FORKS forks"

# Guard against non-numeric values
PUBLIC_REPOS=${PUBLIC_REPOS:-0}
REPO_STARS=${REPO_STARS:-0}
FOLLOWERS=${FOLLOWERS:-0}
REPO_FORKS=${REPO_FORKS:-0}

# ---- Render a compact badge SVG (for other repos / header chips) ----
# Usage: render_badge <light|dark>
render_badge() {
  local mode="$1"
  local bg border text muted track dot out

  if [ "$mode" = "light" ]; then
    bg="#FFFFFF"; border="#E8EAED"; text="#17181C"; muted="#6B7280"; track="#F2F3F5"; dot="#1F883D"
    out="assets/profile-badge.svg"
  else
    bg="#0D1117"; border="#30363D"; text="#E6EDF3"; muted="#8B949E"; track="#21262D"; dot="#3FB950"
    out="assets/profile-badge-dark.svg"
  fi

  local FONT="'-apple-system', BlinkMacSystemFont, 'Segoe UI', sans-serif"

  cat > "$out" << SVGEOF
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 620 48" width="100%" max-width="620" height="auto" role="img" aria-label="Radheshyam Bhati — GitHub profile badge: ${PUBLIC_REPOS} repos, ${REPO_STARS} stars, ${FOLLOWERS} followers, ${REPO_FORKS} forks">
  <rect width="620" height="48" rx="24" fill="${track}"/>
  <rect x="2" y="2" width="616" height="44" rx="22" fill="${bg}" stroke="${border}" stroke-width="1"/>

  <circle cx="20" cy="24" r="4" fill="${dot}"/>
  <text x="32" y="28" font-family="${FONT}" font-size="10" font-weight="600" letter-spacing="2" fill="${muted}">RADHESHYAM BHATI</text>

  <line x1="190" y1="12" x2="190" y2="36" stroke="${border}" stroke-width="1"/>

  <g>
    <text x="240" y="20" font-family="${FONT}" font-size="8.5" font-weight="500" letter-spacing="1.5" text-anchor="middle" fill="${muted}">REPOS</text>
    <text x="240" y="38" font-family="${FONT}" font-size="18" font-weight="700" text-anchor="middle" fill="${text}">${PUBLIC_REPOS}</text>
  </g>

  <line x1="290" y1="12" x2="290" y2="36" stroke="${border}" stroke-width="1"/>

  <g>
    <text x="340" y="20" font-family="${FONT}" font-size="8.5" font-weight="500" letter-spacing="1.5" text-anchor="middle" fill="${muted}">STARS</text>
    <text x="340" y="38" font-family="${FONT}" font-size="18" font-weight="700" text-anchor="middle" fill="${text}">${REPO_STARS}</text>
  </g>

  <line x1="390" y1="12" x2="390" y2="36" stroke="${border}" stroke-width="1"/>

  <g>
    <text x="440" y="20" font-family="${FONT}" font-size="8.5" font-weight="500" letter-spacing="1.5" text-anchor="middle" fill="${muted}">FOLLOWERS</text>
    <text x="440" y="38" font-family="${FONT}" font-size="18" font-weight="700" text-anchor="middle" fill="${text}">${FOLLOWERS}</text>
  </g>

  <line x1="490" y1="12" x2="490" y2="36" stroke="${border}" stroke-width="1"/>

  <g>
    <text x="540" y="20" font-family="${FONT}" font-size="8.5" font-weight="500" letter-spacing="1.5" text-anchor="middle" fill="${muted}">FORKS</text>
    <text x="540" y="38" font-family="${FONT}" font-size="18" font-weight="700" text-anchor="middle" fill="${text}">${REPO_FORKS}</text>
  </g>
</svg>
SVGEOF

  echo "Generated $out"
}

render_badge light
render_badge dark

echo "=== DONE ==="
