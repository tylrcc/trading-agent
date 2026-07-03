# Trading Agent Operations

The trading agent runs on its own via macOS launchd + the Cursor CLI
(`cursor-agent`, logged in as ty853496@ucf.edu, billed to the Cursor plan).
No chat session needs to be open.

## Jobs

| Job | Schedule | What it does |
|---|---|---|
| `com.tylrcc.trading-cycle` | every 30 min | `run-cycle.sh`: skips if market closed / STOP file / already running; hourly cadence overnight; full strategy cycle otherwise |
| `com.tylrcc.trading-learning` | daily 8:30 PM local | `run-learning.sh`: reviews journal + realized P&L, appends nightly review, makes up to 2 tactic refinements to STRATEGY.md (never touches risk limits) |
| `com.tylrcc.trading-keepawake` | always | `caffeinate -i` so scheduled runs are not lost to idle sleep |

## Stop everything (kill switch)

Fastest: `touch ~/ty/trading-agent/STOP` (all runs skip until removed).
Full removal:

```bash
launchctl bootout gui/$(id -u)/com.tylrcc.trading-cycle
launchctl bootout gui/$(id -u)/com.tylrcc.trading-learning
launchctl bootout gui/$(id -u)/com.tylrcc.trading-keepawake
```

Also: disconnecting the agent in the Robinhood app instantly revokes all
trading access regardless of what runs here.

## Logs

- `runner.log` — one line per tick (RUN / SKIP reason / exit code)
- `cycles.log` — full agent output per trading cycle
- `learning.log` — nightly review output
- `JOURNAL.md` — the agent's own trade log and reasoning

## Limitations / cost

- The Mac must be powered on with the user logged in; a closed lid on battery
  still sleeps the machine. Keep it plugged in for true 24/7.
- Each cycle consumes Cursor plan usage (~35-40 headless runs per weekday at
  current cadence). To guarantee it never spends beyond the plan, keep
  usage-based / on-demand pricing OFF in cursor.com dashboard settings; runs
  then stop instead of billing extra. To lower usage, raise StartInterval in
  `~/Library/LaunchAgents/com.tylrcc.trading-cycle.plist` (seconds), then
  `launchctl bootout` + `launchctl bootstrap` the job.
- Market holidays are hardcoded in run-cycle.sh (update yearly).
