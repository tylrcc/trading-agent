#!/bin/zsh
# Window-aware wake loop for the SOXL close-to-open strategy.
# Emits JSON prompt payloads only in the three RTH windows so this chat
# is not burned on idle 15-minute ticks. Robinhood MCP stays in this chat;
# this script never calls mcp login.

set -u
export PATH="/usr/local/bin:/usr/bin:/bin"

PROMPT='Run ONE Robinhood Agentic trading cycle (account ending 5851). This chat holds the ONLY Robinhood MCP grant; never re-login and never call mcp_auth. Read JOURNAL.md tail and STRATEGY.md. Check portfolio/positions/orders via MCP. Close-to-open playbook: sell ANY holding at the open (9:30-9:45 ET); buy SOXL (fallback TQQQ then MU) with ALL settled cash at the close (15:45-16:00 ET); after 16:00 if holding, queue a regular_hours market sell for the next open. Never spend same-day sale proceeds. Max risk, all-in. Log JOURNAL.md + TRADES.csv on fills. Be decisive. No questions.'

DIR="$(cd "$(dirname "$0")" && pwd)"

in_rth_window() {
  local DOW=$1 MINS=$2 TODAY=$3
  for h in 01-01 01-19 02-16 04-03 05-25 06-19 07-03 09-07 11-26 12-25; do
    [[ "$TODAY" == "$h" ]] && return 1
  done
  [[ $DOW -gt 5 ]] && return 1
  # 9:31-9:45 sell, 15:45-16:00 buy, 16:05-16:15 queue next-open sell
  if [[ $MINS -ge 571 && $MINS -lt 585 ]]; then
    echo sell
    return 0
  fi
  if [[ $MINS -ge 945 && $MINS -lt 960 ]]; then
    echo buy
    return 0
  fi
  if [[ $MINS -ge 965 && $MINS -lt 975 ]]; then
    echo queue
    return 0
  fi
  return 1
}

while true; do
  if [[ -f "$DIR/STOP" ]]; then
    sleep 900
    continue
  fi
  if [[ -f "$DIR/PAUSE_UNTIL" ]]; then
    pause_until=$(tr -d '[:space:]' < "$DIR/PAUSE_UNTIL")
    today=$(TZ=America/New_York date '+%Y-%m-%d')
    if [[ "$today" < "$pause_until" ]]; then
      sleep 3600
      continue
    fi
    rm -f "$DIR/PAUSE_UNTIL"
  fi

  read -r DOW HOUR MIN <<< "$(TZ=America/New_York date '+%u %H %M')"
  HOUR=${HOUR#0}; MIN=${MIN#0}
  [[ -z "$HOUR" ]] && HOUR=0
  [[ -z "$MIN" ]] && MIN=0
  MINS=$((HOUR * 60 + MIN))
  TODAY=$(TZ=America/New_York date '+%m-%d')

  role=$(in_rth_window "$DOW" "$MINS" "$TODAY" || true)
  if [[ -n "$role" ]]; then
    TS=$(TZ=America/New_York date '+%H:%M')
    echo "AGENT_LOOP_WAKE_rhtrading {\"session\":\"regular\",\"window\":\"$role\",\"time_et\":\"$TS\",\"prompt\":\"$PROMPT\"}"
    sleep 300
  else
    sleep 60
  fi
done
