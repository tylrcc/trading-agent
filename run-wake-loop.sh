#!/bin/zsh
# Single-shot wake loop. Sleeps until NEXT_WAKE (ET), emits ONE line, then
# waits for the agent to write a later NEXT_WAKE. Never re-fires the same
# timestamp. This chat holds the only Robinhood grant; never mcp login.

set -u
export PATH="/usr/local/bin:/usr/bin:/bin"

PROMPT='Run ONE Robinhood Agentic trading cycle (account ending 5851). This chat holds the ONLY Robinhood MCP grant; never re-login and never call mcp_auth. Read JOURNAL.md tail, STRATEGY.md, and NEXT_WAKE. Check portfolio/positions/orders via MCP. Do the action this window requires (sell at open if holding, buy SOXL at close if settled cash, queue next-open sell after close if holding). Then rewrite NEXT_WAKE to the next needed trade time only. Never spend same-day sale proceeds. Max risk, all-in. Log JOURNAL.md + TRADES.csv on fills. Be decisive. No questions.'

DIR="$(cd "$(dirname "$0")" && pwd)"
WAKE_FILE="$DIR/NEXT_WAKE"
FIRED_FILE="$DIR/LAST_FIRED"

parse_et_epoch() {
  TZ=America/New_York date -j -f '%Y-%m-%d %H:%M' "$1" '+%s' 2>/dev/null
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

  if [[ ! -f "$WAKE_FILE" ]]; then
    sleep 3600
    continue
  fi

  target=$(head -n 1 "$WAKE_FILE" | tr -d '\r' | awk '{$1=$1; print}')
  tgt_epoch=$(parse_et_epoch "$target")
  if [[ -z "$tgt_epoch" ]]; then
    sleep 3600
    continue
  fi

  last=""
  [[ -f "$FIRED_FILE" ]] && last=$(head -n 1 "$FIRED_FILE" | tr -d '\r' | awk '{$1=$1; print}')
  if [[ "$target" == "$last" ]]; then
    sleep 300
    continue
  fi

  now_epoch=$(TZ=America/New_York date '+%s')
  delta=$((tgt_epoch - now_epoch))
  if [[ $delta -gt 0 ]]; then
    chunk=$delta
    [[ $chunk -gt 3600 ]] && chunk=3600
    sleep $chunk
    continue
  fi

  TS=$(TZ=America/New_York date '+%H:%M')
  echo "AGENT_LOOP_WAKE_rhtrading {\"session\":\"regular\",\"next_wake\":\"$target\",\"time_et\":\"$TS\",\"prompt\":\"$PROMPT\"}"
  printf '%s\n' "$target" > "$FIRED_FILE"
  sleep 300
done
