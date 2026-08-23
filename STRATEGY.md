# Agentic Trading Strategy

Account: Robinhood Agentic (cash, equities only, long only), ending 5851.
Starting capital: $53.00 (2026-07-02). Location: `/Users/tyler/ty/projects/trading-agent`.
Guardrails in `.cursor/rules/robinhood-trading-guardrails.mdc` override this file.

**Single MCP grant:** Robinhood allows one Cursor connection. The live IDE
chat that already authenticated `user-robinhood-trading` is the only
tradable session. Never call `mcp_auth`, never run
`cursor-agent mcp login robinhood-trading`, never open a second grant.
A second login kicks this session and trading dies.

## Goal

Trade **MU only**: buy at the regular-hours close, sell at the next
regular-hours open. Compound settled cash. Accept total loss.

This is a close-to-open overnight hold, not a day trade and not a
sentiment scan. Idle settled cash through a close is failure.

## Why this cadence

MU (~$967 as of 2026-08-21 close) is not affordable as a whole share on
this account. Fractional / dollar orders are regular-hours only
(9:30-16:00 ET). Overnight and extended sessions cannot buy or sell
fractional MU, so the edge has to be captured inside RTH: buy 15:45-16:00
ET, sell 9:30-9:45 ET the next session.

Cash-account T+1: never spend same-day sale proceeds. That means one
overnight hold per settled-cash cycle (typically every other trading
day), not two holds in a row.

## Position: flatten non-MU first

If any symbol other than MU is held (currently TQQQ), sell 100% of
`shares_available_for_sells` at the next regular open. Do not buy MU
until that sale has settled (buying_power > 0 and no same-day sale).
Then the MU playbook starts at the next close with settled cash.

## Playbook (every regular session)

### 1. Open window (9:30-9:45 ET) — SELL

If holding MU (or a non-MU flatten target):
- Side sell, type market, `quantity` = `shares_available_for_sells`,
  `market_hours=regular_hours`, `time_in_force=gfd`.
- Review first. Non-empty `order_checks` = do not place; log and retry
  next cycle in this window only.
- Do not buy anything in the open window.

If flat: heartbeat only.

### 2. Close window (15:45-16:00 ET) — BUY MU

If settled `buying_power` >= $1.00 AND no same-day sale AND not already
holding MU:
- Side buy, type market, `dollar_amount` = all settled buying power
  (leave at most $0.50 buffer only if the review requires it),
  symbol **MU**, `market_hours=regular_hours`, `time_in_force=gfd`.
- Review first. `EQUITY_SUITABILITY` or any other alert = skip the rest
  of the session (recon only). Do not rotate to a substitute ticker.
- If buying_power is 0 because of unsettled proceeds: log skip, wait
  for the next session's close after settlement.

If already holding MU into the close: hold overnight (that is the trade).
Do not sell at 15:45.

### 3. After close (16:05-16:15 ET) — queue next-open sell

If holding MU and no sell is already open:
- Place a regular_hours market sell for full `shares_available_for_sells`.
  After 16:00 ET this queues for the next regular open.
- This is the reliability path so a missed 9:31 wake still exits.
- Do not queue a sell before 16:00 (it would fill the same session and
  kill the overnight hold).

### Hard skips

- Halted / not `state=active`: skip.
- Daily loss floor already tripped (equity <= 50% of start-of-day value):
  cancel opens, no new buys until next calendar day.
- STOP file or PAUSE_UNTIL in the future: no trading.
- Overnight / weekend / holiday: no orders. Fractional MU cannot print
  outside regular hours. Heartbeat line only.
- Earnings: MU next report ~2026-09-22 (pm, unverified). Still trade the
  close-to-open unless the name is halted.

## Order style

- Regular hours only for this strategy.
- Dollar buy at the close (type=market). Share-qty sell at the open
  (type=market). Guardrails prefer limits, but dollar/fractional MU is
  market+regular_hours only; a whole-share limit is impossible at this
  size.
- ALWAYS `review_equity_order` before `place_equity_order`.
- Never retry a rejected order with modified parameters to force it
  through.
- Never average down. One MU position, all-in settled cash.

## Stops (overnight hold)

- Gap catastrophe is accepted under HIGH-RISK mode; still flatten at the
  open rather than hoping for a reclaim.
- If the queued open sell is rejected, fire a live market sell in the
  9:30-9:45 window. If that also fails, keep retrying each 9:xx cycle
  until flat. Do not hold MU into a second regular session.

## Cycle checklist

1. Confirm this chat still holds the Robinhood grant. If tools are
   missing, log `MCP offline — cycle skipped` and stop. Do not re-login.
2. Read JOURNAL.md tail. Check STOP / DRYRUN / PAUSE_UNTIL.
3. `get_portfolio`, `get_equity_positions`, `get_equity_orders` on
   account 621325851.
4. Enforce the window: sell at open, buy MU at close, queue sell after
   close. At most one new order per cycle.
5. review → place if clean (skip place in DRYRUN). Log JOURNAL + TRADES.csv.
6. If market closed: one heartbeat line, re-arm for the next window.

## Trade ledger

Append one row to `TRADES.csv` on every fill (entry or exit):
`timestamp_et,symbol,side,qty_or_dollars,fill_price,notional,thesis,exit_reason,realized_pnl`
(realized_pnl and exit_reason empty on entries).

## Dry-run / pause / kill

Unchanged from guardrails: `DRYRUN`, `PAUSE_UNTIL`, `STOP`.
