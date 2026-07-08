"""Presentation version of the Monte Carlo density surface for social posts.

$1,500 hypothetical initial capital, 10,000 simulated one-year paths of the
momentum strategy's return process. Labeled as a simulation in the title.
"""

import matplotlib.pyplot as plt
import numpy as np
from matplotlib.colors import LinearSegmentedColormap

RNG = np.random.default_rng(7)

START = 1500.0
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

day_idx = np.arange(4, DAYS + 1, 4)
lo, hi = np.percentile(logeq, [0.5, 99.5])
bins = np.linspace(lo, hi, 130)
centers = (bins[:-1] + bins[1:]) / 2

density = np.zeros((len(day_idx), len(centers)))
for i, d in enumerate(day_idx):
    h, _ = np.histogram(logeq[:, d], bins=bins, density=True)
    density[i] = h

k = np.array([1, 4, 6, 4, 1], dtype=float); k /= k.sum()
for i in range(density.shape[0]):
    density[i] = np.convolve(density[i], k, mode="same")
for j in range(density.shape[1]):
    density[:, j] = np.convolve(density[:, j], k, mode="same")
density = density / density.max(axis=1, keepdims=True)

X, Y = np.meshgrid(centers, day_idx)

BG = "#f4f7fc"
INK = "#5b6b8c"
pastel = LinearSegmentedColormap.from_list(
    "pastelblue", ["#eaf2fb", "#c9def5", "#a3c6ee", "#7fabe3", "#5d8fd6", "#3f6fc4"])

fig = plt.figure(figsize=(11, 10), dpi=200, facecolor=BG)
ax = fig.add_subplot(111, projection="3d", facecolor=BG)

ax.plot_surface(X, Y, density, cmap=pastel, rstride=1, cstride=1,
                linewidth=0.1, edgecolor="#ffffff30", antialiased=True, shade=True)

ticks = [500, 1500, 4000, 10000, 25000]
ticks = [t for t in ticks if lo <= np.log(t) <= hi]
ax.set_xticks([np.log(t) for t in ticks])
ax.set_xticklabels([f"${t:,.0f}" for t in ticks], fontsize=9, color=INK)
ax.set_yticks([0, 50, 100, 150, 200, 250])
ax.tick_params(colors=INK, labelsize=9)
ax.set_xlabel("Portfolio value (USD)", fontsize=10, color=INK, labelpad=12)
ax.set_ylabel("Trading days", fontsize=10, color=INK, labelpad=10)
ax.set_zlabel("Relative density", fontsize=10, color=INK, labelpad=6)
ax.zaxis.set_ticklabels([])

ax.xaxis.set_pane_color((1, 1, 1, 0.55))
ax.yaxis.set_pane_color((1, 1, 1, 0.35))
ax.zaxis.set_pane_color((1, 1, 1, 0.15))
for axis in (ax.xaxis, ax.yaxis, ax.zaxis):
    axis._axinfo["grid"].update(color="#d5e0f0", linewidth=0.6)

ax.view_init(elev=28, azim=-58)
ax.set_box_aspect((1.15, 1.0, 0.55))

p95 = np.percentile(equity[:, -1], 95)
med = np.percentile(equity[:, -1], 50)

fig.text(0.09, 0.945, "Monte Carlo simulation", fontsize=20, fontweight="bold", color="#2f4468")
fig.text(0.09, 0.912,
         f"Algorithmic momentum strategy - 10,000 simulated one-year paths - $1,500 initial capital",
         fontsize=11, color=INK)
fig.text(0.09, 0.878,
         f"Median outcome \\${med:,.0f} - 95th percentile \\${p95:,.0f}",
         fontsize=10.5, color="#3f6fc4", fontweight="bold")

plt.subplots_adjust(left=0, right=1, top=1.02, bottom=0.02)
fig.savefig("assets/linkedin.png", bbox_inches="tight")
print(f"median {med:,.0f} | p95 {p95:,.0f} | max {equity[:, -1].max():,.0f}")
