#!/bin/bash
set -e

USERNAME="radheshyam-bhati"

echo "=== PROFILE STATS GENERATOR ==="
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
  LATEST_REPO=$(echo "$REPOS_JSON" | jq -r 'max_by(.pushed_at) | .name // "N/A"')
  LATEST_REPO="${LATEST_REPO:0:24}"
  echo "gh API calls successful"
else
  echo "ERROR: gh CLI not available"
  exit 1
fi

echo ""
echo "Stats: $PUBLIC_REPOS repos, $REPO_STARS stars, $FOLLOWERS followers, $REPO_FORKS forks"
echo "Latest: $LATEST_REPO"

# Guard against non-numeric values
PUBLIC_REPOS=${PUBLIC_REPOS:-0}
REPO_STARS=${REPO_STARS:-0}
FOLLOWERS=${FOLLOWERS:-0}
REPO_FORKS=${REPO_FORKS:-0}

# Clamp bar widths (max 130px on a 130px track — full track at 65+)
bar_width_repos=$(( PUBLIC_REPOS > 65 ? 130 : PUBLIC_REPOS * 2 ))
bar_width_stars=$(( REPO_STARS > 65 ? 130 : REPO_STARS * 2 ))
bar_width_followers=$(( FOLLOWERS > 65 ? 130 : FOLLOWERS * 2 ))
bar_width_forks=$(( REPO_FORKS > 65 ? 130 : REPO_FORKS * 2 ))

# Current timestamp
NOW=$(date -u "+%Y-%m-%d")

# ---- TOP LANGUAGES breakdown (by repo count, top 6) ----
LANG_ROWS=$(echo "$REPOS_JSON" | jq -r '
  [.[].language] | map(select(. != null)) | group_by(.) |
  map({lang: .[0], count: length}) | sort_by(-.count) | .[:6] |
  (map(.count) | add) as $total |
  .[] | "\(.lang)\t\(((.count * 100) / $total) | floor)\t\(((.count * 380) / $total) | floor)"
' 2>/dev/null || echo "")

# ---- Render a themed SVG ----
# Usage: render_svg <light|dark>
render_svg() {
  local mode="$1"
  local bg border text muted faint track bar dot out

  if [ "$mode" = "light" ]; then
    bg="#FFFFFF"; border="#E8EAED"; text="#17181C"; muted="#6B7280"; faint="#9CA3AF"; track="#F2F3F5"; bar="#17181C"; dot="#1F883D"
    out="assets/profile-stats.svg"
  else
    bg="#0D1117"; border="#30363D"; text="#E6EDF3"; muted="#8B949E"; faint="#6E7681"; track="#21262D"; bar="#E6EDF3"; dot="#3FB950"
    out="assets/profile-stats-dark.svg"
  fi

  local FONT="'-apple-system', BlinkMacSystemFont, 'Segoe UI', sans-serif"

  # Build language rows with theme colors
  local langs_svg=""
  local row_y=182
  while IFS=$'\t' read -r lang pct barw; do
    [ -z "$lang" ] && continue
    langs_svg+="
  <g>
    <text x=\"20\" y=\"${row_y}\" font-family=\"${FONT}\" font-size=\"12\" font-weight=\"500\" fill=\"${text}\">${lang}</text>
    <rect x=\"130\" y=\"$((row_y - 8))\" width=\"380\" height=\"2\" rx=\"1\" fill=\"${track}\"/>
    <rect x=\"130\" y=\"$((row_y - 8))\" width=\"${barw}\" height=\"2\" rx=\"1\" fill=\"${bar}\"/>
    <text x=\"600\" y=\"${row_y}\" font-family=\"${FONT}\" font-size=\"11\" text-anchor=\"end\" fill=\"${muted}\">${pct}%</text>
  </g>"
    row_y=$((row_y + 23))
  done <<< "$LANG_ROWS"

  # Graceful fallback when no language data is available
  if [ -z "$langs_svg" ]; then
    langs_svg="
  <text x=\"20\" y=\"196\" font-family=\"${FONT}\" font-size=\"12\" fill=\"${faint}\">—</text>"
  fi

  cat > "$out" << SVGEOF
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 620 310" width="100%" height="auto" role="img" aria-label="GitHub profile statistics">
  <rect width="620" height="310" rx="20" fill="${track}"/>
  <rect x="2" y="2" width="616" height="306" rx="18" fill="${bg}" stroke="${border}" stroke-width="1"/>

  <text x="20" y="28" font-family="${FONT}" font-size="10" font-weight="600" letter-spacing="2.5" fill="${muted}">PROFILE STATS</text>
  <text x="600" y="28" font-family="${FONT}" font-size="9" font-weight="500" letter-spacing="1.5" text-anchor="end" fill="${faint}">UPDATED ${NOW}</text>

  <g>
    <text x="20" y="58" font-family="${FONT}" font-size="10" font-weight="500" letter-spacing="1.2" fill="${muted}">REPOSITORIES</text>
    <text x="20" y="86" font-family="${FONT}" font-size="28" font-weight="700" fill="${text}">${PUBLIC_REPOS}</text>
    <rect x="20" y="96" width="130" height="2" rx="1" fill="${track}"/>
    <rect x="20" y="96" width="${bar_width_repos}" height="2" rx="1" fill="${bar}"/>
  </g>

  <line x1="160" y1="42" x2="160" y2="102" stroke="${border}" stroke-width="1"/>

  <g>
    <text x="165" y="58" font-family="${FONT}" font-size="10" font-weight="500" letter-spacing="1.2" fill="${muted}">STARS</text>
    <text x="165" y="86" font-family="${FONT}" font-size="28" font-weight="700" fill="${text}">${REPO_STARS}</text>
    <rect x="165" y="96" width="130" height="2" rx="1" fill="${track}"/>
    <rect x="165" y="96" width="${bar_width_stars}" height="2" rx="1" fill="${bar}"/>
  </g>

  <line x1="305" y1="42" x2="305" y2="102" stroke="${border}" stroke-width="1"/>

  <g>
    <text x="310" y="58" font-family="${FONT}" font-size="10" font-weight="500" letter-spacing="1.2" fill="${muted}">FOLLOWERS</text>
    <text x="310" y="86" font-family="${FONT}" font-size="28" font-weight="700" fill="${text}">${FOLLOWERS}</text>
    <rect x="310" y="96" width="130" height="2" rx="1" fill="${track}"/>
    <rect x="310" y="96" width="${bar_width_followers}" height="2" rx="1" fill="${bar}"/>
  </g>

  <line x1="450" y1="42" x2="450" y2="102" stroke="${border}" stroke-width="1"/>

  <g>
    <text x="455" y="58" font-family="${FONT}" font-size="10" font-weight="500" letter-spacing="1.2" fill="${muted}">FORKS</text>
    <text x="455" y="86" font-family="${FONT}" font-size="28" font-weight="700" fill="${text}">${REPO_FORKS}</text>
    <rect x="455" y="96" width="130" height="2" rx="1" fill="${track}"/>
    <rect x="455" y="96" width="${bar_width_forks}" height="2" rx="1" fill="${bar}"/>
  </g>

  <line x1="20" y1="122" x2="600" y2="122" stroke="${border}" stroke-width="1"/>

  <text x="20" y="148" font-family="${FONT}" font-size="10" font-weight="600" letter-spacing="2.5" fill="${muted}">TOP LANGUAGES</text>
  <g>
    <circle cx="600" cy="145" r="3" fill="${dot}"/>
    <text x="590" y="148" font-family="${FONT}" font-size="9" text-anchor="end" fill="${muted}">LATEST · ${LATEST_REPO}</text>
  </g>
${langs_svg}
</svg>
SVGEOF

  echo "Generated $out"
}

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

render_svg light
render_svg dark
render_badge light
render_badge dark

echo "=== DONE ==="
