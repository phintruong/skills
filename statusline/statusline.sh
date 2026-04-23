#!/usr/bin/env bash

input=$(cat)

# ---------------------------------------------------------------------------
# Claude plan usage limits — fetch with 60s cache
# ---------------------------------------------------------------------------
CREDENTIALS_FILE="$HOME/.claude/.credentials.json"
USAGE_CACHE="$HOME/.claude/.usage_cache.json"

five_pct=""
seven_pct=""
credits_used=""
five_resets_at=""

_fetch_usage() {
  local token
  token=$(jq -r '.claudeAiOauth.accessToken' "$CREDENTIALS_FILE" 2>/dev/null)
  if [ -z "$token" ] || [ "$token" = "null" ]; then
    return 1
  fi
  curl -sf --max-time 3 \
    -H "Authorization: Bearer $token" \
    -H "anthropic-beta: oauth-2025-04-20" \
    -H "Content-Type: application/json" \
    "https://api.anthropic.com/api/oauth/usage" \
    -o "$USAGE_CACHE" 2>/dev/null
}

_load_usage_cache() {
  local needs_fetch=1
  if [ -f "$USAGE_CACHE" ]; then
    local mtime now age
    mtime=$(stat -c %Y "$USAGE_CACHE" 2>/dev/null)
    if [ -n "$mtime" ]; then
      now=$(date +%s)
      age=$(( now - mtime ))
      [ "$age" -lt 60 ] && needs_fetch=0
    fi
  fi

  if [ "$needs_fetch" -eq 1 ]; then
    _fetch_usage
  fi

  if [ -f "$USAGE_CACHE" ]; then
    five_pct=$(jq -r '.five_hour.utilization // empty' "$USAGE_CACHE" 2>/dev/null)
    seven_pct=$(jq -r '.seven_day.utilization // empty' "$USAGE_CACHE" 2>/dev/null)
    credits_used=$(jq -r '.extra_usage.used_credits // empty' "$USAGE_CACHE" 2>/dev/null)
    five_resets_at=$(jq -r '.five_hour.resets_at // empty' "$USAGE_CACHE" 2>/dev/null)
  fi
}

_load_usage_cache

# ---------------------------------------------------------------------------
# Extract fields from JSON input
# ---------------------------------------------------------------------------
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // ""')
model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

# Shorten directory to basename
folder=$(basename "$current_dir")

# Build 8-char progress bar
filled=$(( (${used_pct%.*} * 8 + 50) / 100 ))
[ "$filled" -lt 0 ] && filled=0
[ "$filled" -gt 8 ] && filled=8
empty=$(( 8 - filled ))

bar=""
for (( i=0; i<filled; i++ )); do bar="${bar}▰"; done
for (( i=0; i<empty; i++ )); do bar="${bar}▱"; done

# Format context window size as e.g. 200k
ctx_k=$(( ctx_size / 1000 ))k

# Format 5h reset as local clock time
five_reset_fmt="--"
if [ -n "$five_resets_at" ]; then
  formatted=$(date -d "$five_resets_at" "+%-I:%M %p" 2>/dev/null)
  [ -n "$formatted" ] && five_reset_fmt="$formatted"
fi

# Format cost from account-wide credits (credits / 100 = USD), fallback to session cost
if [ -n "$credits_used" ]; then
  cost_fmt=$(awk -v c="$credits_used" 'BEGIN{ printf "%.2f", c/100 }')
else
  cost_fmt=$(printf "%.2f" "$cost")
fi

# Choose bar color based on percentage
pct_int=${used_pct%.*}
if [ "$pct_int" -gt 80 ]; then
  bar_color='\033[31m'
elif [ "$pct_int" -ge 50 ]; then
  bar_color='\033[33m'
else
  bar_color='\033[32m'
fi

# ---------------------------------------------------------------------------
# Helper: build a colored usage segment
# ---------------------------------------------------------------------------
_build_usage_seg() {
  local raw_pct="$1"
  local pct_int color seg_filled seg_empty seg_bar

  if [ -z "$raw_pct" ]; then
    _seg_color='\033[2;37m'
    _seg_bar="--------"
    _seg_pct_int="--"
    return
  fi

  pct_int=$(printf "%.0f" "$raw_pct" 2>/dev/null)
  _seg_pct_int="$pct_int"

  if [ "$pct_int" -gt 80 ]; then
    _seg_color='\033[31m'
  elif [ "$pct_int" -ge 50 ]; then
    _seg_color='\033[33m'
  else
    _seg_color='\033[32m'
  fi

  seg_filled=$(( (pct_int * 8 + 50) / 100 ))
  [ "$seg_filled" -lt 0 ] && seg_filled=0
  [ "$seg_filled" -gt 8 ] && seg_filled=8
  seg_empty=$(( 8 - seg_filled ))

  seg_bar=""
  for (( i=0; i<seg_filled; i++ )); do seg_bar="${seg_bar}▰"; done
  for (( i=0; i<seg_empty; i++ )); do seg_bar="${seg_bar}▱"; done
  _seg_bar="$seg_bar"
}

_build_usage_seg "$five_pct"
five_bar="$_seg_bar"; five_color="$_seg_color"; five_pct_int="$_seg_pct_int"

_build_usage_seg "$seven_pct"
seven_bar="$_seg_bar"; seven_color="$_seg_color"; seven_pct_int="$_seg_pct_int"

# ANSI color codes
DIM_WHITE='\033[2;37m'
PURPLE='\033[38;5;141m'
GREEN='\033[32m'
CYAN='\033[38;5;117m'
RESET='\033[0m'

# Emit single line
printf "${PURPLE}✨ %s${RESET}${DIM_WHITE} | 5h ${RESET}${five_color}%s %s%%${RESET}${DIM_WHITE} | 7d ${RESET}${seven_color}%s %s%%${RESET}${DIM_WHITE} | ${RESET}${GREEN}💰 \$%s${RESET}${DIM_WHITE} | ${RESET}${bar_color}%s %d%%${RESET} ${DIM_WHITE}%s${RESET}${DIM_WHITE} | ↻ ${RESET}${CYAN}%s${RESET}\n" \
  "$model" \
  "$five_bar" "$five_pct_int" \
  "$seven_bar" "$seven_pct_int" \
  "$cost_fmt" \
  "$bar" "$pct_int" "$ctx_k" \
  "$five_reset_fmt"
