# Trading Agent Operations

Repo path: `/Users/tyler/ty/projects/trading-agent`
Public: https://github.com/tylrcc/trading-agent

## How it runs

1. **launchd** (survives reboot if user is logged in):
   - `com.tylrcc.trading-cycle` every 30 min → `run-cycle.sh`
   - `com.tylrcc.trading-learning` daily 8:30 PM → `run-learning.sh`
   - `com.tylrcc.trading-keepawake` always → `caffeinate -is`
2. **In-chat heartbeat** (backup while a Cursor chat is open).

Headless `cursor-agent` needs Robinhood MCP already approved for the CLI.
If cycles fail with auth errors, reconnect once via `cursor-agent mcp list`
or Cursor Settings → MCP, then leave it.

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

## Kill switch

```bash
touch ~/ty/projects/trading-agent/STOP
```

## Logs

- `runner.log`, `cycles.log`, `learning.log`, `JOURNAL.md`

## Reality check

Keep the Mac plugged in. Closed lid on battery still sleeps despite
caffeinate in some power modes. Chat heartbeat dies when the chat closes;
launchd is the restart-proof path.
