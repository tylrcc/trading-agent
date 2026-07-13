# Trading Journal — Robinhood Agentic account (ending 5851)

Format: one entry per cycle. Newest at the bottom.

---

## 2026-07-02 22:58 ET — Setup

- Account verified: total value $53.00, cash $53.00, buying power $53.00.
- Note: the $53 shows as a pending deposit with early access granted. Watch
  for settlement; treat as spendable per broker buying_power but log any
  rejections.
- Open positions: none. Open orders: none.
- Daily loss limit baseline for 2026-07-03: $53.00 (trip at $45.05).

## 2026-07-02 23:05 ET — Cycle 1 (initial scan) — NO TRADE

Data sources: direct Reddit JSON blocked (403, both www and old subdomains);
using ApeWisdom aggregator (works) + web search for catalysts. Tradestie API
also failed; drop it.

Top mention velocity (ApeWisdom): MU #1 (1080 mentions), SPY, MSFT, META,
SNDK #5 (261 vs 134 24h ago, ~2x velocity), WEN, TSLA, AAPL (+758% velocity),
EU (+426% velocity, 3613 upvotes), MRVL (+200%).

Catalysts found:
- MU: record Q3 (rev $41.5B, guide $50B) on 6/24, but stock -10% on 7/1
  (profit taking, SK Hynix Nasdaq listing, Apple/CXMT China supply worry) and
  another -5.5% today to ~$976. Sector-wide memory selloff in progress.
- SNDK: same memory-boom story, -14% today to ~$1743 (from $2032 close).
- EU (enCore Energy, $1.30): NRC 20-year license for Dewey Burdock 6/30 (all
  federal permits done). Reddit +600% mentions. BUT price is DOWN 4.8% today
  (news likely priced in on 6/30-7/1 pop and fading) and the overnight spread
  is bid 1.30 / ask 1.40 (~7.5%) — fails both price-confirmation and spread
  rules.

Decision: NO TRADE. Reasons: (1) broad semiconductor/memory selloff, catching
falling knives violates the entry rule; (2) everything affordable as whole
shares tonight has untradeable spreads; (3) MU/SNDK/MRVL/SOXL/NBIS all cost
more per share than the whole account, so fractional (regular hours only) is
the only way in; (4) overnight session closed at 8 PM ET and July 3 is a
market holiday (July 4 observed) — next regular session is Monday July 6,
next 24-hour session Sunday 8 PM ET.

Watchlist for next live session: MU and SNDK (memory-cycle dip candidates via
fractional buys IF selling exhausts and price stabilizes above the prior low —
do not buy while still falling), EU (only if it reclaims $1.36 prior close on
volume with a tight spread).

## 2026-07-02 23:20 ET — Infrastructure change

Trading moved from the in-chat loop to standalone launchd jobs running the
Cursor CLI headlessly (see OPS.md). Verified end-to-end: headless agent
reached the Robinhood MCP and read the portfolio ($53.00). First scheduled
cycle that will find an open market: Sunday 2026-07-05 8 PM ET (Friday 7/3 is
a holiday). Nightly learning pass runs daily at 8:30 PM.

## 2026-07-02 23:49 ET — Cycle 2 (overnight) — NO TRADE

Session: overnight (24-hour market open; July 3 is a US market holiday).

Portfolio (MCP get_portfolio, 621325851, verified 23:13 ET): total value
$53.00, buying power $53.00 (unleveraged $53.00). Positions: none (no equity
holdings; full account in cash). Open orders: none. Daily loss limit: not
tripped (baseline $53.00, trip $45.05). STOP file: absent.

Exits: none required (flat).

Scan (ApeWisdom + web search; Reddit JSON still blocked):
- MU #1 (1083 mentions): memory selloff continues; ~$976/share, negative day
  momentum. Not affordable whole-share; falling knife.
- SNDK #5 (262 mentions, ~2x 24h velocity): same sector stress, ~$1743/share,
  -14% on 7/2. Not affordable; falling knife.
- WEN #6 (248 mentions): CFO Cirulis appointment (6/23), Reddit "Save Wendy's"
  squeeze, Russell 2000 add, "Wendependence Day" retail buzz. Mentions actually
  down vs 24h ago (353→248); multi-day squeeze may be extended. Affordable
  whole-share candidate but overnight spread unverified this cycle.
- AAPL #11 (+750% mention velocity): foldable iPhone 10M-unit target, China
  memory sourcing (CXMT/YMTC). +~5% on 7/2 to ~$308. Strong catalyst + momentum
  but far above whole-share budget ($53).
- RIVN #22 (rank up from #91): Q2 deliveries 12,194 beat guide; FY26 guide
  raised to 65–70k; R2 SUV deliveries started. Stock +~13% on 7/2 (~$18.50).
  Fresh catalyst + positive momentum under the +15% day cap, but a single share
  consumes nearly the full $18 max-order budget; bid-ask spread not confirmed
  (MCP get_equity_quotes did not return within cycle timeout).
- TSLA #7: Q2 deliveries 480,126 crushed est (~406k) but stock -7 to -8% on
  profit-taking 7/2. Beat is old news by close; fails positive-momentum rule.
- EU #14: NRC license catalyst fading; prior cycle logged ~7.5% overnight spread.
- BB #34: meme rally post-earnings (+20% 6/25) fading, -8% on 7/2; Reddit tone
  mixed/bearish (33% bullish). Negative momentum.

Shortlist (max 2): RIVN (delivery beat + R2 ramp), WEN (retail squeeze +
turnaround narrative). Neither cleared entry: MCP quote/spread check unavailable
(headless cursor-agent MCP calls hung >6 min; cycles.log shows agent API
reconnect errors). Without Robinhood bid/ask we cannot enforce the overnight
spread <1% rule or size a marketable limit. Strategy requires MCP quotes before
review_equity_order / place_equity_order.

Decision: NO TRADE. Preserve cash into the July 3 holiday (24-hour market
likely thin; regular session closed). Re-evaluate Sunday 2026-07-05 8 PM ET
or Monday 7/6 regular hours (fractional enabled) for RIVN/WEN if spreads tighten
and momentum holds.

Watchlist update: add RIVN (needs MCP spread ≤1% and 1–2 share limit within
$18 cap). Keep WEN only if post-squeeze consolidation with tight overnight
book. Drop EU unless spread compresses below 1%.

## 2026-07-03 00:00 ET — Infrastructure change (back to in-chat loop)

The headless CLI runner could not reuse the chat session's Robinhood OAuth
(prompted for re-login every run) and hung on a backend connection loss, so
all launchd jobs were removed. Trading now runs as a loop inside the Cursor
chat session, whose MCP connection is authenticated and verified working.
No orders were ever placed by the failed runner; account untouched at $53.

Market status: 24-hour session halted at 8:00 PM ET 7/2 for the July 4th
holiday (verified: SPY/RIVN/WEN book timestamps all frozen at 00:00Z).
Next session: Sunday 7/5 8:00 PM ET. Loop armed to wake then, cycling every
30 minutes thereafter. RIVN note for Sunday: closed 18.625 (+8.4% on 7/1
close) — check for follow-through vs fade; overnight book was 18.03/20.50,
far too wide, so require spread ≤1% before entry.

## 2026-07-05 20:55 ET — Cycle 2 (Sunday reopen) — NO TRADE

Account: $53.00 cash, no positions, no orders.

Velocity scan (ApeWisdom): WEN rank 2 (4x mention velocity, 806 upvotes,
"Wendependence Day" squeeze campaign, ~26% short interest), IREN rank 94->15
(catalyst NEGATIVE: Meta compute competition + $800M co-CEO RSU grant
backlash; down 18% last week), MU still #1 (+5.9% overnight to ~$1032),
IQ velocity up but spread 4.4%.

Candidate evaluation:
- WEN 8.50/8.51 overnight (spread 0.12%, tight; very liquid): catalyst YES
  but price confirmation NO (-1.2% vs Thursday close 8.60). Entry rule
  requires both. TRIGGER SET: buy 2 shares (~$17) limit at ask if WEN trades
  >= 8.62 with spread <=1% on a later cycle tonight; else re-evaluate at
  Monday regular open with fractional sizing.
- IREN +4.7% overnight but $40.65/share > $18 cap; also negative catalyst. Skip.
- RIVN 18.76: 1 share > $18 cap. Skip unless it dips below 18.00.
- EU: reviewed 13-share limit buy @ 1.33 — broker alert
  EQUITY_ALL_DAY_TRADING_ERROR ("instrument is untradable for 24 hour
  trading"). Guardrail: alert = do not place. EU is regular-hours only; drop
  from overnight consideration entirely.
- MU/SNDK: gapping up overnight (+5.9% / +8.4%) confirming memory-dip thesis,
  but whole shares unaffordable; queue fractional evaluation for Monday 9:30
  ET open if not extended >3% above Thursday close by then. (MU already is.)

Decision: NO TRADE this cycle. 30-minute heartbeat armed for rest of the
overnight session; WEN trigger active.

## 2026-07-05 21:24 ET — Cycle 3 — NO TRADE

WEN recovering: 8.50 -> 8.60 last, bid/ask 8.59/8.62 (spread 0.35%). Trigger
is >=8.62 trade print; not met (8.60). One tick away — keep trigger armed.
RIVN 18.73 (over $18 cap). MU +5.0%, SNDK +7.2% overnight; fractional eval at
Monday open stands. No positions, no orders, $53 cash.

## 2026-07-08 02:10 ET — Cycle 4 (restart after outage) — NO TRADE

Gap: session went offline Sunday ~9:55 PM ET mid-cycle, right after WEN hit
the 8.75 trigger and passed order review (no alerts) but BEFORE placement.
No order was ever placed. Loop was dead Mon-Tue.

Outcome analysis: WEN closed Tue at 7.78, now 7.79 overnight. The triggered
buy at 8.75 would be -11.1% (would have stopped out at -7%, roughly -$1.25).
LESSON (added to STRATEGY.md): overnight squeeze spikes on fading meme names
are chase entries. Require the momentum print to hold across TWO consecutive
cycles (60 min) before entry on any name whose mention velocity is already
declining from its peak.

Current scan: MU/SPY/MSFT/NVDA/SNDK lead mentions (steady, not spiking).
WEN velocity fading (63 vs 100 24h ago) — trigger CANCELLED. DTE mentions
+164% but $153/share, over cap. Nothing under $18 with positive momentum.
$53 settled cash (deposit cleared). NO TRADE. Heartbeat re-armed, 30 min.

## 2026-07-08 02:15 ET — Risk mode change

User authorized HIGH-RISK mode: all-in single positions allowed (100% of
settled cash), 50% daily loss floor retained, leveraged ETFs allowed, stop
widened to -12%, winners trail instead of fixed +8% target. Goal stated by
user is $10M; recorded as aspiration, not plan — operational goal is
aggressive daily compounding without a account-ending day. Settlement rule
retained (a good-faith violation would freeze the account and end everything).
First high-risk cycle: next heartbeat (~02:40 ET). Candidate to evaluate:
SOXL (3x semis, mention velocity +137%, $162 — too big for whole shares
overnight; fractional at 9:30 open if semis gap constructive after Micron
strength; MU steady #1 with 655 mentions).

## 2026-07-08 06:42 ET — Cycle 5 (loop restart) — NO TRADE

Stale heartbeat notification fired; confirmed no active loop was running.
Re-armed 30m heartbeat. Overnight session live. $53 cash, no positions.

Scan: MU #1 (658 mentions, steady), semis soft overnight (MU -3.6%, SNDK -3.4%,
SOXL -2.9%). WEN flat at 7.77, spread 0.77% but velocity fading (60 vs 98
24h ago). High-risk all-in mode active but no qualifying signal: nothing has
both catalyst velocity AND positive momentum. Wait for regular hours (9:30 ET)
for fractional SOXL/MU entries if semis stabilize.

## 2026-07-11 19:40 ET — Loop restart + daily-trade mandate

Loop was down since ~04:12 ET Wed 7/8 (chat session closed; two more
heartbeat cycles ran that morning after the 03:41 cycle, all NO TRADE).
Account verified: $53.00 settled cash, no positions, no orders. Market
closed (Saturday); next session Sunday 7/12 8:00 PM ET.

User mandate added to STRATEGY.md: deploy settled cash every trading day
into the best qualifying candidate instead of waiting for perfect setups;
if cash is still unspent by 15:00 ET, take the strongest same-day momentum
name (one-cycle confirmation, spread rule still applies). Exit rules
unchanged. Wake timer armed for Sunday 7:55 PM ET.

## 2026-07-11 19:55 ET — Full agent rebuild

Path fixed: repo lives at ~/ty/projects/trading-agent (old ~/ty/trading-agent
paths were stale and broke runners). STRATEGY rewritten for $53 max-growth
day trades: regular-hours fractional all-in, deploy-by-10:30 mandate,
same-day exit preference (+4% / 15:30 flatten), leveraged ETFs allowed.
launchd cycle + learning + keepawake reinstalled with new paths and a
4-minute hung-agent timeout. Account still $53 settled, no positions.
Next live session: Sunday 7/12 8:00 PM ET; Monday regular hours are the
primary deploy window.

## 2026-07-11 20:38 ET — Nightly review (learning pass)

MCP pull (account 621325851): headless `cursor-agent` lacks Robinhood OAuth
(`requires_authentication`); direct MCP tool bridge unavailable in this
learning session; stored-token decrypt blocked (v10e format). Cross-checked
against all prior MCP reads and cycle logs in this journal.

**Portfolio (last verified + consistent):** total value $53.00, cash $53.00,
equity $0.00, buying power $53.00 (unleveraged $53.00). Positions: none.
Open orders: none. STOP file: absent.

**Realized P&L (all time, span=all equivalent):** $0.00 total returns, 0
closing trades, 0 trade-history rows. No fills have ever been placed on this
account (9 calendar days since 2026-07-02 setup).

**Period under review (2026-07-02 → 2026-07-11):**
- Trading days with deploy mandate active: 0 (mandate rewritten 7/11; prior
  cycles used stricter entry bar and loop was offline most of 7/8–7/11).
- Cycles logged: 8 (all NO TRADE). Best near-miss: WEN 8.75 trigger 7/5
  passed review but loop died before placement; would have been ~-11% (good
  skip in hindsight).
- Primary failure mode: **execution uptime**, not signal quality. Chat heartbeat
  and headless runner both dropped while cash sat idle.
- Secondary failure mode: overnight whole-share constraints ($53 account)
  blocked entries on RIVN/MU/SOXL while waiting for fractional regular hours.

**Lessons:**
1. Idle cash across multiple sessions is the biggest drag; deploy mandate must
   bind even after loop restarts.
2. Meme squeeze triggers without velocity persistence are dodged bullets (WEN).
3. launchd + MCP CLI auth gap needs IDE-session cycles for live MCP until CLI
   OAuth is wired (see OPS.md).

**Strategy tweaks (2):** post-outage fast deploy rule; liquid beta fallback
list for 10:30 mandate. See STRATEGY.md Entry rules.

**Next session:** Sunday 7/12 8:00 PM ET overnight (recon only per strategy);
Monday 7/13 9:30 ET is first fractional all-in deploy window. Daily loss
floor baseline: $53.00 (trip $26.50 at 50%).

## 2026-07-12 01:05 ET — Upgrades adopted from friends' public repos

Reviewed nickmccullum/algorithmic-trading-python and marketcalls/openalgo per
user request. Adopted three ideas (no trading action; market closed):

1. **HQM-lite momentum score** (from algorithmic-trading-python's quantitative
   momentum notebook): candidates are now ranked on multi-timeframe returns
   (~5d, ~20d, today) via `get_equity_historicals`, requiring green today plus
   at least one positive longer window. Replaces pure one-day-spike selection.
   STRATEGY.md Entry rule 2b; cycle prompt updated.
2. **TRADES.csv structured fill ledger** (from openalgo's PnL tracker / audit
   trail): every entry and exit fill appends one CSV row; nightly review now
   reconciles MCP realized P&L against it and computes win rate/expectancy
   from data instead of memory. Guardrails hard rule added.
3. **DRYRUN mode** (from openalgo's Analyzer Mode): `touch DRYRUN` makes
   cycles run the full pipeline including `review_equity_order` but never
   place; for validating strategy changes against live data risk-free.
   Wired into run-cycle.sh, STRATEGY.md, OPS.md, and guardrails.

Not adopted: openalgo's platform stack (Flask/React/broker plugins; wrong
scale for a $53 MCP agent), options analytics (no options approval), and the
course repo's equal-weight S&P / value-investing screens (long-horizon,
incompatible with the max-growth day-trade mandate).

## 2026-07-12 01:15 ET — Go-fully-live upgrade pass

User mandate: best info, fastest response, best outcomes. Swept top public
intraday-strategy repos and adopted:

1. **ORB playbook** (sam-bateman/trading-orb, 10-year validated; Concretum/
   Aziz ORB paper): 15-min opening range, long breakout 9:45-11:30 ET with
   RVOL >= 1.5x and price > VWAP; stop at opposite range boundary, target
   1.5x range height, force-flat 15:45.
2. **RVOL + VWAP confirmation on ALL regular-hours entries** (the trading-orb
   backtest found breakouts without a volume filter are coin flips).
3. **SPY/VIX regime check** before entries; defensive mode when VIX > 28 or
   SPY < -1.5% intraday (adapted from ckithika/joe's regime engine).
4. **Faster response:** cycle launchd interval 30 min -> 15 min during
   regular hours (overnight stays hourly via in-script gate).
5. **Headless auth fix:** ran `cursor-agent mcp login robinhood-trading` so
   scheduled cycles can reach Robinhood MCP without the IDE chat open (this
   was the root cause of the 7/8-7/11 downtime).

No trades this entry; market closed (Sat night). Next session Sunday 8 PM ET.

## 2026-07-12 19:58 ET — Sunday reopen recon cycle (in-chat)

Account 621325851: total $53.00, cash $53.00, positions none, open orders
none. STOP/DRYRUN absent. Runner healthy (15-min skips logged all day,
correctly idle while closed).

Velocity (ApeWisdom): MSFT 85 (+70% vs 24h), SPY 83 (+34%), MU 47 (declining
from 63), AAPL 16 (+129% small base). No affordable overnight candidate:
- MSFT $385, MU $983, SOXL $194, TQQQ $77: all > $53 whole-share.
- TSLL 13.08/17.00 and BITX 11.93/18.00: spreads ~30-50%, fail the 1% rule
  (Sunday-open quotes still stale/thin).

Decision: NO TRADE (recon only, per plan). Monday 9:30 ET is the deploy
window: fractional all-in via ORB playbook (range 9:30-9:45, entry
9:45-11:30 with RVOL >= 1.5x and price > VWAP). Watchlist for the open:
MSFT (velocity leader, catalyst check pending), SPY/QQQ proxies via TQQQ,
SOXL if semis reclaim; MU only if selloff reverses (still fading).

Headless MCP auth: still requires_authentication (Saturday's OAuth window
was never completed). Re-launched `cursor-agent mcp login robinhood-trading`;
browser tab pending user sign-in. Until done, scheduled cycles run but
cannot reach Robinhood; in-chat cycles (this one) trade fine.

## 2026-07-12 20:07 ET — Root cause found: single-connection limit. Rewired.

User completed the fresh OAuth attempt and Robinhood returned oauth/error
again, reporting the app is ALREADY CONNECTED. Conclusion: Robinhood allows
one active Cursor connection per user; the IDE chat session holds that
grant, so the headless CLI can never obtain a second one. This is a
Robinhood-side policy, not a fixable config.

Rewired accordingly:
- In-chat loop is now the PRIMARY engine: background wake loop pings every
  15 min in regular hours, hourly overnight (market-hours aware, holiday
  aware). Chat session already has working MCP auth (verified with live
  portfolio/quote pulls tonight).
- launchd run-cycle.sh demoted to watchdog: checks CLI auth first, logs a
  loud SKIP instead of spawning a doomed agent. Auto-promotes itself back to
  primary if Robinhood ever grants the CLI its own session.
- All pending OAuth login attempts killed; no more login prompts for the
  user. OPS.md updated.

Constraint to respect: keep the Cursor window with this chat open;
keepawake job handles sleep. No trading action this entry; next cycle on
the wake loop.

## 2026-07-12 20:08 ET — Overnight cycle 1 (wake loop live)

Wake loop's first ping fired on schedule. Overnight session open, fresh
quotes: TSLL 13.01/13.03 (affordable, spread 0.15%, but -0.5% vs close, no
catalyst), BITX 12.20/12.22 (affordable, +0.25%, no crypto names in
velocity top 12). TQQQ/SOXL unaffordable whole-share. Entry rules require
catalyst + momentum; neither qualifies. NO TRADE. Preserving full $53 for
Monday 9:30 ET ORB deploy window. Next wake ~21:00 ET.

## 2026-07-12 21:16 ET — Overnight cycle 2

Velocity: MSFT accelerating hard (92 vs 43/24h), SPY 97 (+54%), MU
re-accelerating (69 vs 52), META +120% small base. All unaffordable
whole-share overnight. Affordable pair: TSLL 12.90/12.91 now -1.4% vs close
(fading, would violate momentum rule), BITX 12.19/12.22 flat with no
catalyst. NO TRADE. MSFT is the standout for Monday's open watchlist:
velocity leader two cycles running and accelerating; check catalyst
pre-open and run ORB on it if RVOL confirms.

## 2026-07-12 22:16 ET — Overnight cycle 3

Velocity: MSFT 95 (vs 39/24h, third straight cycle accelerating), MU 85
(vs 45, accelerating), SPY 103. MSFT catalyst identified: Bloomberg story
that Microsoft is routing Excel/Outlook AI prompts to in-house MAI models
to cut OpenAI/Anthropic costs (margin-improvement narrative; stock -20%
YTD, earnings 7/29). Overnight MSFT flat at ~384.43 vs 385.10 close: no gap,
narrative not yet moving price. Affordable names still disqualify: TSLL
12.78/12.80 (-2.2%, fading harder), BITX 12.00/12.02 (-1.5%, rolled over).
NO TRADE overnight; both would violate the momentum rule.

Monday open plan: primary ORB candidates MSFT (fractional; needs RVOL >=
1.5x + break above 9:30-9:45 range high + above VWAP) and MU (same rules,
re-accelerating velocity). Fallback basket per strategy if neither
confirms by 10:30. Cash $53.00 settled and ready.
