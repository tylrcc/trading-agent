"""Animated Monte Carlo density surface for social posts.

The outcome distribution builds day by day while the camera orbits; a stats
panel tracks the simulation. $10,000 hypothetical initial capital, 10,000
paths, same return assumptions as every other chart in this repo (51% win
rate, fat-tailed wins, stops that can gap to -18%, 65% active days).
"""

import matplotlib.pyplot as plt
import numpy as np
from matplotlib.animation import FuncAnimation, PillowWriter
from matplotlib.colors import LinearSegmentedColormap

RNG = np.random.default_rng(7)

START = 10000.0
DAYS = 252
PATHS = 10000

win = RNG.random((PATHS, DAYS)) < 0.51
gains = RNG.lognormal(mean=np.log(0.038), sigma=0.95, size=(PATHS, DAYS))
losses = np.minimum(RNG.lognormal(mean=np.log(0.040), sigma=0.6, size=(PATHS, DAYS)), 0.18)
daily = np.where(win, gains, -losses)
daily = np.where(RNG.random((PATHS, DAYS)) < 0.35, 0.0, daily)

equity = START * np.cumprod(1 + daily, axis=1)
equity = np.hstack([np.full((PATHS, 1), START), equity])
logeq = np.log(equity)

# Honest portfolio-level stats from the simulation.
mean_d, std_d = daily.mean(), daily.std()
sharpe = mean_d / std_d * np.sqrt(252)
downside = daily[daily < 0].std()
sortino = mean_d / downside * np.sqrt(252)
running_max = np.maximum.accumulate(equity, axis=1)
maxdd = ((equity - running_max) / running_max).min(axis=1)
med_dd = np.median(maxdd)

# Density grid over all days (computed once).
day_idx = np.arange(2, DAYS + 1, 2)
lo, hi = np.percentile(logeq, [0.5, 99.5])
bins = np.linspace(lo, hi, 120)
centers = (bins[:-1] + bins[1:]) / 2

dens = np.zeros((len(day_idx), len(centers)))
for i, d in enumerate(day_idx):
    h, _ = np.histogram(logeq[:, d], bins=bins, density=True)
    dens[i] = h
k = np.array([1, 4, 6, 4, 1], dtype=float); k /= k.sum()
for i in range(dens.shape[0]):
    dens[i] = np.convolve(dens[i], k, mode="same")
for j in range(dens.shape[1]):
    dens[:, j] = np.convolve(dens[:, j], k, mode="same")
dens = dens / dens.max(axis=1, keepdims=True)

BG = "#f4f7fc"
INK = "#5b6b8c"
HEAD = "#2f4468"
BLUE = "#3f6fc4"
pastel = LinearSegmentedColormap.from_list(
    "pastelblue", ["#eaf2fb", "#c9def5", "#a3c6ee", "#7fabe3", "#5d8fd6", "#3f6fc4"])

fig = plt.figure(figsize=(9, 8.2), dpi=92, facecolor=BG)
ax = fig.add_subplot(111, projection="3d", facecolor=BG)

title = fig.text(0.07, 0.955, "Monte Carlo simulation", fontsize=17,
                 fontweight="bold", color=HEAD)
sub = fig.text(0.07, 0.922,
               "Algorithmic momentum strategy - 10,000 simulated paths - \\$10,000 initial capital",
               fontsize=9.5, color=INK)
stat1 = fig.text(0.07, 0.885, "", fontsize=10, color=BLUE, fontweight="bold")
stat2 = fig.text(0.07, 0.855, "", fontsize=8.5, color=INK)

FRAMES = 54
HOLD = 12


def draw(frame):
    ax.clear()
    ax.set_facecolor(BG)
    t = min(frame / (FRAMES - HOLD - 1), 1.0)
    n = max(3, int(t * len(day_idx)))
    d = day_idx[n - 1]

    X, Y = np.meshgrid(centers, day_idx[:n])
    ax.plot_surface(X, Y, dens[:n], cmap=pastel, rstride=1, cstride=1,
                    linewidth=0.05, edgecolor="#ffffff25", antialiased=True,
                    vmin=0, vmax=1)

    ticks = [2500, 10000, 40000, 150000]
    ax.set_xticks([np.log(v) for v in ticks])
    ax.set_xticklabels([f"\\${v/1000:g}k" for v in ticks], fontsize=8, color=INK)
    ax.set_xlim(lo, hi)
    ax.set_ylim(0, DAYS)
    ax.set_zlim(0, 1.05)
    ax.set_yticks([0, 50, 100, 150, 200, 250])
    ax.tick_params(colors=INK, labelsize=8)
    ax.set_xlabel("Portfolio value", fontsize=9, color=INK, labelpad=8)
    ax.set_ylabel("Trading days", fontsize=9, color=INK, labelpad=8)
    ax.zaxis.set_ticklabels([])
    ax.xaxis.set_pane_color((1, 1, 1, 0.55))
    ax.yaxis.set_pane_color((1, 1, 1, 0.35))
    ax.zaxis.set_pane_color((1, 1, 1, 0.15))
    for axis in (ax.xaxis, ax.yaxis, ax.zaxis):
        axis._axinfo["grid"].update(color="#d5e0f0", linewidth=0.5)

    ax.view_init(elev=27, azim=-64 + 14 * t)
    ax.set_box_aspect((1.15, 1.0, 0.5))

    med = np.median(equity[:, d])
    p95 = np.percentile(equity[:, d], 95)
    mx = equity[:, d].max()
    stat1.set_text(
        f"Day {d:>3}   median \\${med:,.0f}   95th pct \\${p95:,.0f}   best path \\${mx:,.0f}")
    stat2.set_text(
        f"Sharpe {sharpe:.2f}   Sortino {sortino:.2f}   median max drawdown {med_dd:.0%}   "
        f"win rate 51%   assumptions fixed across all charts")
    return []


anim = FuncAnimation(fig, draw, frames=FRAMES, blit=False)
anim.save("assets/linkedin.gif", writer=PillowWriter(fps=12))
print(f"sharpe {sharpe:.2f} sortino {sortino:.2f} medDD {med_dd:.0%}")
print(f"final: median {np.median(equity[:,-1]):,.0f} p95 {np.percentile(equity[:,-1],95):,.0f} "
      f"max {equity[:,-1].max():,.0f}")
