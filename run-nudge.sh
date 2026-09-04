#!/bin/zsh
# OS-level nudge at 09:31 / 15:45 / 16:05 ET weekdays. Does NOT place
# orders and does NOT call mcp login. Robinhood stays in the IDE chat.
# Purpose: foreground Cursor and ping so this chat can actually trade.

set -u
export PATH="/usr/bin:/bin:/usr/sbin:/sbin"
DIR="$HOME/ty/projects/trading-agent"
LOG="$DIR/runner.log"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S %Z') NUDGE: $1" >> "$LOG"; }

[[ -f "$DIR/STOP" ]] && { log "skip STOP"; exit 0; }

TODAY=$(TZ=America/New_York date '+%m-%d')
for h in 01-01 01-19 02-16 04-03 05-25 06-19 07-03 09-07 11-26 12-25; do
  if [[ "$TODAY" == "$h" ]]; then
    log "skip holiday $TODAY"
    exit 0
  fi
done

DOW=$(TZ=America/New_York date '+%u')
[[ $DOW -gt 5 ]] && { log "skip weekend"; exit 0; }

TS=$(TZ=America/New_York date '+%H:%M')
log "window $TS, opening Cursor"

osascript >/dev/null 2>&1 <<'APPLESCRIPT'
display notification "Open the Agentic trading chat and say run cycle." with title "Robinhood trade window" sound name "Glass"
APPLESCRIPT

open -a Cursor >/dev/null 2>&1 || true
exit 0
