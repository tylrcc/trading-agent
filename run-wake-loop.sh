#!/bin/zsh
# Market-aware wake loop for in-chat trading. Emits JSON prompt payloads per
# the Cursor loop skill so each wake tells the agent exactly what to run.

set -u
export PATH="/usr/local/bin:/usr/bin:/bin"

PROMPT='Run ONE Robinhood Agentic trading cycle (account ending 5851). Read JOURNAL.md tail and STRATEGY.md. Check portfolio/positions/orders via MCP. Enforce exits first. Regime check (SPY/VIX). Deploy settled cash per ORB playbook and daily mandate. Signal via ApeWisdom + web search. HQM-lite score, RVOL >= 1.3x, above VWAP for regular-hours buys. Log JOURNAL.md + TRADES.csv on fills. If >36h since last journal entry or a full regular session was missed, use post-outage fast deploy. Be decisive. No questions.'

DIR="$(cd "$(dirname "$0")" && pwd)"

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
  HOUR=${HOUR#0}; MIN=${MIN#0}; MINS=$((HOUR * 60 + MIN))
  TODAY=$(TZ=America/New_York date '+%m-%d')
  session="closed"
  if [[ $DOW -le 5 && $MINS -ge 570 && $MINS -lt 960 ]]; then
    session="regular"
  elif [[ $DOW -le 4 || ( $DOW -eq 5 && $MINS -lt 1200 ) || ( $DOW -eq 7 && $MINS -ge 1200 ) ]]; then
    session="overnight"
  fi
  for h in 01-01 01-19 02-16 04-03 05-25 06-19 07-03 09-07 11-26 12-25; do
    [[ "$TODAY" == "$h" ]] && session="closed"
  done

  if [[ "$session" == "regular" ]]; then
    TS=$(TZ=America/New_York date '+%H:%M')
    echo "AGENT_LOOP_WAKE_rhtrading {\"session\":\"regular\",\"time_et\":\"$TS\",\"prompt\":\"$PROMPT\"}"
    sleep 900
  elif [[ "$session" == "overnight" ]]; then
    if [[ $MIN -lt 15 ]]; then
      TS=$(TZ=America/New_York date '+%H:%M')
      echo "AGENT_LOOP_WAKE_rhtrading {\"session\":\"overnight\",\"time_et\":\"$TS\",\"prompt\":\"$PROMPT\"}"
    fi
    sleep 900
  else
    sleep 900
  fi
done
