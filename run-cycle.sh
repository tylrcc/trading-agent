#!/bin/zsh
# Robinhood agentic trading cycle runner. Invoked by launchd every 30 minutes.
# Hard-timeout so a hung cursor-agent cannot block forever.

set -u
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin"

DIR="$HOME/ty/projects/trading-agent"
LOG="$DIR/runner.log"
LOCK="$DIR/.cycle.lock"
TIMEOUT_SECS=240

log() { echo "$(date '+%Y-%m-%d %H:%M:%S %Z') $1" >> "$LOG"; }

if [[ -f "$DIR/STOP" ]]; then
  log "SKIP: STOP file present"
  exit 0
fi

DRYRUN_NOTE=""
if [[ -f "$DIR/DRYRUN" ]]; then
  DRYRUN_NOTE=" DRYRUN MODE: review orders and log what you would place, but NEVER call place_equity_order."
fi

if [[ -f "$LOCK" ]] && kill -0 "$(cat "$LOCK" 2>/dev/null)" 2>/dev/null; then
  log "SKIP: previous cycle still running (pid $(cat "$LOCK"))"
  exit 0
fi
echo $$ > "$LOCK"
trap 'rm -f "$LOCK"' EXIT

read -r DOW HOUR MIN <<< "$(TZ=America/New_York date '+%u %H %M')"
HOUR=${HOUR#0}; MIN=${MIN#0}; MINS=$((HOUR * 60 + MIN))

session="closed"
if [[ $DOW -le 5 && $MINS -ge 570 && $MINS -lt 960 ]]; then
  session="regular"
elif [[ $DOW -le 4 || ( $DOW -eq 5 && $MINS -lt 1200 ) || ( $DOW -eq 7 && $MINS -ge 1200 ) ]]; then
  session="overnight"
fi

TODAY=$(TZ=America/New_York date '+%m-%d')
for h in 01-01 01-19 02-16 04-03 05-25 06-19 07-03 09-07 11-26 12-25; do
  [[ "$TODAY" == "$h" ]] && session="closed"
done

if [[ "$session" == "closed" ]]; then
  log "SKIP: market closed"
  exit 0
fi
if [[ "$session" == "overnight" && $MIN -ge 15 ]]; then
  log "SKIP: overnight session, hourly cadence"
  exit 0
fi

# NEVER call `cursor-agent mcp login`. Robinhood allows ONE Cursor connection;
# the IDE chat already holds it. Headless login opens a browser oauth/error and
# can kick the live session. If CLI has no auth, skip quietly (watchdog only).
if cursor-agent mcp list 2>/dev/null | grep -q "robinhood-trading: requires_authentication"; then
  log "SKIP: headless CLI has no Robinhood session (IDE chat holds the only grant; do not login)"
  exit 0
fi

log "RUN: session=$session"
cd "$HOME/ty"

PROMPT="You are the autonomous trading agent for the Robinhood Agentic account
(ending 5851). Session=$session. Follow /Users/tyler/ty/projects/trading-agent/STRATEGY.md
and .cursor/rules/robinhood-trading-guardrails.mdc exactly.
Run ONE cycle: read JOURNAL.md tail, check portfolio/positions/orders,
enforce exits first. Regime check (SPY/VIX) before entries. Then deploy
settled cash per the ORB playbook (9:45-11:30 ET) and daily mandate
(affordable names only; fractional all-in in regular hours). Signal via
ApeWisdom + web search; rank candidates with the HQM-lite momentum score
(get_equity_historicals: 5d/20d/today returns) and require RVOL >= 1.3x and
price above session VWAP for regular-hours buys. Log to JOURNAL.md and
append fills to TRADES.csv. Be decisive. No questions.$DRYRUN_NOTE"

# Kill hung agents after TIMEOUT_SECS.
(
  sleep "$TIMEOUT_SECS"
  pkill -f "cursor-agent.*projects/trading-agent|cursor-agent.*STRATEGY.md" 2>/dev/null || true
) &
WATCH=$!

cursor-agent -p --force --approve-mcps --trust --workspace "$HOME/ty" \
  --output-format text "$PROMPT" >> "$DIR/cycles.log" 2>&1
rc=$?
kill "$WATCH" 2>/dev/null || true
log "DONE: exit=$rc"

cp "$HOME/ty/.cursor/rules/robinhood-trading-guardrails.mdc" "$DIR/guardrails-rule.md" 2>/dev/null
cd "$DIR" && git add -A >/dev/null 2>&1
if ! git diff --cached --quiet 2>/dev/null; then
  GIT_AUTHOR_NAME=tylrcc GIT_AUTHOR_EMAIL=247895347+tylrcc@users.noreply.github.com \
  GIT_COMMITTER_NAME=tylrcc GIT_COMMITTER_EMAIL=247895347+tylrcc@users.noreply.github.com \
  git commit -m "cycle: $(date '+%Y-%m-%d %H:%M %Z')" >/dev/null 2>&1
  git push origin main >/dev/null 2>&1 || log "WARN: git push failed"
fi
