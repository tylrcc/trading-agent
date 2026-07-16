# Trading Agent Operations

Repo path: `/Users/tyler/ty/projects/trading-agent`
Public: https://github.com/tylrcc/trading-agent

## How it runs

1. **In-chat loop (PRIMARY).** Robinhood permits only ONE active Cursor
   connection per user; the IDE chat session holds it. Headless
   `cursor-agent` cannot obtain a second grant (Robinhood returns
   oauth/error). **Never run `cursor-agent mcp login robinhood-trading`
   while this chat is connected.** Trading runs through this chat via
   `run-wake-loop.sh`, which emits `AGENT_LOOP_WAKE_rhtrading` lines with
   a JSON `prompt` payload every 15 min (regular) / hourly (overnight).
   The agent must execute that prompt on each wake. Requirement: keep
   this Cursor chat open; keepawake job prevents sleep.
2. **launchd (WATCHDOG + future backup):**
   - `com.tylrcc.trading-cycle` every 15 min → `run-cycle.sh`; it checks CLI
     auth first and logs `SKIP: robinhood MCP needs login` instead of
     burning a cycle. If Robinhood ever allows a second (CLI) grant, this
     becomes the restart-proof engine automatically.
   - `com.tylrcc.trading-learning` daily 8:30 PM → `run-learning.sh`
   - `com.tylrcc.trading-keepawake` always → `caffeinate -is`

## Install / reinstall after path moves

```bash
cp ~/ty/projects/trading-agent/com.tylrcc.trading-*.plist ~/Library/LaunchAgents/
chmod +x ~/ty/projects/trading-agent/run-*.sh
launchctl bootout gui/$(id -u)/com.tylrcc.trading-cycle 2>/dev/null
launchctl bootout gui/$(id -u)/com.tylrcc.trading-learning 2>/dev/null
launchctl bootout gui/$(id -u)/com.tylrcc.trading-keepawake 2>/dev/null
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.tylrcc.trading-cycle.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.tylrcc.trading-learning.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.tylrcc.trading-keepawake.plist
```

## Start / restart the in-chat wake loop

Run from a Cursor agent session (not launchd; needs chat MCP auth):

```bash
# stop any old loop first
pkill -f run-wake-loop.sh 2>/dev/null
# arm new loop (agent starts this with notify_on_output on AGENT_LOOP_WAKE_rhtrading)
~/ty/projects/trading-agent/run-wake-loop.sh
```

Each wake line includes a JSON `prompt` field. The agent must execute that
prompt on every wake. If wakes fire but no JOURNAL entries appear, the chat
is not processing notifications: reopen this chat and say "run cycle".

## Kill switch

```bash
touch ~/ty/projects/trading-agent/STOP
```

## Pause until a date (e.g. usage-limit cooldown)

```bash
echo 2026-08-07 > ~/ty/projects/trading-agent/PAUSE_UNTIL
# cycles and wake loop skip until that ET calendar day; file auto-deletes then
rm ~/ty/projects/trading-agent/PAUSE_UNTIL   # resume early
```

## Dry-run mode (test without real orders)

```bash
touch ~/ty/projects/trading-agent/DRYRUN   # cycles review + log, never place
rm ~/ty/projects/trading-agent/DRYRUN      # back to live
```

Concept borrowed from openalgo's Analyzer Mode: full pipeline runs against
live data, order placement is the only step skipped.

## Logs

- `runner.log`, `cycles.log`, `learning.log`, `JOURNAL.md`
- `TRADES.csv`: structured fill ledger (one row per entry/exit); the nightly
  review computes win rate and expectancy from it

## Reality check

Keep the Mac plugged in. Closed lid on battery still sleeps despite
caffeinate in some power modes. Chat heartbeat dies when the chat closes;
launchd is the restart-proof path.
