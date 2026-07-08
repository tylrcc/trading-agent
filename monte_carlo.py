"""Monte Carlo projection of the high-risk momentum strategy.

Simulates one year of daily compounding from the $53 starting balance under
explicitly stated assumptions. This is a projection, not a record of results.
"""

import matplotlib.pyplot as plt
import matplotlib.font_manager as fm
import numpy as np

RNG = np.random.default_rng(53)

START = 53.0
DAYS = 252
PATHS = 4000

# Assumptions (documented in README): concentrated momentum bets with a
# -12% stop and trailing exits produce a fat-tailed daily distribution.
# 50% win days; winners are lognormal (letting runners run), losers average
# worse than the stop because overnight gaps blow through it (capped -18%).
win = RNG.random((PATHS, DAYS)) < 0.51
gains = RNG.lognormal(mean=np.log(0.038), sigma=0.95, size=(PATHS, DAYS))
losses = np.minimum(RNG.lognormal(mean=np.log(0.040), sigma=0.6, size=(PATHS, DAYS)), 0.18)
daily = np.where(win, gains, -losses)
# No trade on ~35% of days (no qualifying signal).
daily = np.where(RNG.random((PATHS, DAYS)) < 0.35, 0.0, daily)

equity = START * np.cumprod(1 + daily, axis=1)
equity = np.hstack([np.full((PATHS, 1), START), equity])

x = np.arange(DAYS + 1)
p5, p25, p50, p75, p95 = np.percentile(equity, [5, 25, 50, 75, 95], axis=0)

BG = "#0d1117"
FG = "#e6edf3"
DIM = "#7d8590"
ACCENT = "#3fb950"
ACCENT2 = "#58a6ff"

plt.rcParams.update({
    "figure.facecolor": BG, "axes.facecolor": BG, "savefig.facecolor": BG,
    "text.color": FG, "axes.edgecolor": DIM, "axes.labelcolor": DIM,
    "xtick.color": DIM, "ytick.color": DIM,
    "font.family": ["Helvetica Neue", "Arial", "DejaVu Sans"],
})

fig, ax = plt.subplots(figsize=(12, 6.75), dpi=200)

# Spaghetti: a sample of individual paths, barely visible.
for i in RNG.choice(PATHS, 140, replace=False):
    ax.plot(x, equity[i], color=ACCENT2, alpha=0.05, lw=0.6, zorder=1)

ax.fill_between(x, p5, p95, color=ACCENT, alpha=0.10, lw=0, zorder=2)
ax.fill_between(x, p25, p75, color=ACCENT, alpha=0.18, lw=0, zorder=3)
ax.plot(x, p50, color=ACCENT, lw=2.2, zorder=4)
ax.plot(x, p95, color=ACCENT, lw=0.8, alpha=0.55, zorder=4)
ax.plot(x, p5, color="#f85149", lw=0.8, alpha=0.55, zorder=4)

ax.set_yscale("log")
ax.set_xlim(0, DAYS)
ax.set_ylim(max(p5.min() * 0.8, 1), p95.max() * 1.4)
ticks = [25, 53, 100, 250, 500]
ax.set_yticks(ticks)
ax.set_yticklabels([f"${t:,.0f}" for t in ticks], fontsize=9)
ax.minorticks_off()
ax.axhline(START, color=DIM, lw=0.8, ls=(0, (4, 4)), alpha=0.5, zorder=0)
ax.grid(axis="y", color=DIM, alpha=0.12, lw=0.6)
for side in ("top", "right", "left"):
    ax.spines[side].set_visible(False)

ax.set_xlabel("Trading days", fontsize=10)
ax.set_ylabel("Account value (USD, log scale)", fontsize=10)

def label(v, y_end, text_color, note):
    ax.annotate(f"${v:,.0f}  {note}", xy=(DAYS, y_end), xytext=(6, 0),
                textcoords="offset points", va="center", fontsize=9.5,
                color=text_color, fontweight="bold")

label(p95[-1], p95[-1], ACCENT, "95th pct")
label(p50[-1], p50[-1], FG, "median")
label(p5[-1], p5[-1], "#f85149", "5th pct")

fig.text(0.065, 0.955, "agentic-trader", fontsize=19, fontweight="bold", color=FG)
fig.text(0.065, 0.915, "Monte Carlo projection - 4,000 simulated one-year paths from a $53 start",
         fontsize=10.5, color=DIM)
fig.text(0.065, 0.02,
         "SIMULATION ONLY - not actual performance. Assumes a modest edge (51% win rate, "
         "fat-tailed wins, stops that can gap to -18%, 65% active days). An autonomous LLM "
         "agent trading a dedicated Robinhood Agentic account via MCP.",
         fontsize=7.5, color=DIM, alpha=0.9)

plt.subplots_adjust(left=0.065, right=0.88, top=0.86, bottom=0.12)
fig.savefig("assets/monte-carlo.png", bbox_inches="tight")
print("median:", round(p50[-1], 2), "p5:", round(p5[-1], 2), "p95:", round(p95[-1], 2))
print("paths ending below $10:", (equity[:, -1] < 10).mean())
