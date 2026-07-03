#!/bin/zsh
# Robinhood agentic trading cycle runner. Invoked by launchd every 30 minutes.
# Decides whether a market session is open before spending any Cursor usage.

set -u
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin"

DIR="$HOME/ty/trading-agent"
LOG="$DIR/runner.log"
LOCK="$DIR/.cycle.lock"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S %Z') $1" >> "$LOG"; }

# Kill switch: create trading-agent/STOP to halt all trading.
if [[ -f "$DIR/STOP" ]]; then
  log "SKIP: STOP file present"
  exit 0
fi

# Prevent overlapping cycles.
if [[ -f "$LOCK" ]] && kill -0 "$(cat "$LOCK" 2>/dev/null)" 2>/dev/null; then
  log "SKIP: previous cycle still running (pid $(cat "$LOCK"))"
  exit 0
fi
echo $$ > "$LOCK"
trap 'rm -f "$LOCK"' EXIT

# Market gate (ET). Robinhood 24-hour market: Sun 8 PM - Fri 8 PM ET.
# Full cycles every 30 min during regular hours (Mon-Fri 9:30-16:00 ET);
# hourly (minute-zero ticks only) in extended/overnight; skip when closed.
read -r DOW HOUR MIN <<< "$(TZ=America/New_York date '+%u %H %M')"
HOUR=${HOUR#0}; MIN=${MIN#0}; MINS=$((HOUR * 60 + MIN))

session="closed"
if [[ $DOW -le 5 && $MINS -ge 570 && $MINS -lt 960 ]]; then
  session="regular"
elif [[ $DOW -le 4 || ( $DOW -eq 5 && $MINS -lt 1200 ) || ( $DOW -eq 7 && $MINS -ge 1200 ) ]]; then
  session="overnight"
fi

# US market holidays (update yearly).
TODAY=$(TZ=America/New_York date '+%m-%d')
for h in 01-01 01-19 02-16 04-03 05-25 06-19 07-03 09-07 11-26 12-25; do
  [[ "$TODAY" == "$h" ]] && session="closed"
done

if [[ "$session" == "closed" ]]; then
  log "SKIP: market closed"
  exit 0
fi
if [[ "$session" == "overnight" && $MIN -ge 30 ]]; then
  log "SKIP: overnight session, hourly cadence"
  exit 0
fi

log "RUN: session=$session"
cd "$HOME/ty"

PROMPT="You are the autonomous trading agent for the Robinhood Agentic account.
Current session type: $session. Follow /Users/tyler/ty/trading-agent/STRATEGY.md
and the guardrails in .cursor/rules/robinhood-trading-guardrails.mdc exactly.
Run ONE trading cycle now: read the tail of trading-agent/JOURNAL.md for state,
check portfolio/positions/orders via the robinhood-trading MCP, enforce exits
first, then scan for entries per the strategy (ApeWisdom API + web search;
direct Reddit JSON is blocked). Log the cycle to JOURNAL.md. Be decisive but
never violate a guardrail. Do not ask questions; there is no user present."

cursor-agent -p --force --approve-mcps --trust --workspace "$HOME/ty" \
  --output-format text "$PROMPT" >> "$DIR/cycles.log" 2>&1
rc=$?
log "DONE: exit=$rc"

# Sync everything to the private GitHub repo so the user can watch remotely.
cp "$HOME/ty/.cursor/rules/robinhood-trading-guardrails.mdc" "$DIR/guardrails-rule.md" 2>/dev/null
cd "$DIR" && git add -A >/dev/null 2>&1
if ! git diff --cached --quiet 2>/dev/null; then
  GIT_AUTHOR_NAME=tylrcc GIT_AUTHOR_EMAIL=247895347+tylrcc@users.noreply.github.com \
  GIT_COMMITTER_NAME=tylrcc GIT_COMMITTER_EMAIL=247895347+tylrcc@users.noreply.github.com \
  git commit -m "cycle: $(date '+%Y-%m-%d %H:%M %Z')" >/dev/null 2>&1
  git push origin main >/dev/null 2>&1 || log "WARN: git push failed"
fi
