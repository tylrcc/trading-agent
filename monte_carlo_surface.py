"""3D Monte Carlo density surface: probability distribution of account value
over one simulated year, rendered as a pastel-blue surface.

Same simulation as monte_carlo.py (shared assumptions); this renders the
cross-sectional density instead of individual paths. SIMULATION ONLY.
"""

import matplotlib.pyplot as plt
import numpy as np
from matplotlib.colors import LinearSegmentedColormap

RNG = np.random.default_rng(53)

START = 53.0
DAYS = 252
PATHS = 4000

win = RNG.random((PATHS, DAYS)) < 0.51
gains = RNG.lognormal(mean=np.log(0.038), sigma=0.95, size=(PATHS, DAYS))
losses = np.minimum(RNG.lognormal(mean=np.log(0.040), sigma=0.6, size=(PATHS, DAYS)), 0.18)
daily = np.where(win, gains, -losses)
daily = np.where(RNG.random((PATHS, DAYS)) < 0.35, 0.0, daily)

equity = START * np.cumprod(1 + daily, axis=1)
equity = np.hstack([np.full((PATHS, 1), START), equity])
logeq = np.log(equity)

# Density grid: log-value bins x sampled days.
day_idx = np.arange(4, DAYS + 1, 4)
lo, hi = np.percentile(logeq, [0.5, 99.5])
bins = np.linspace(lo, hi, 130)
centers = (bins[:-1] + bins[1:]) / 2

density = np.zeros((len(day_idx), len(centers)))
for i, d in enumerate(day_idx):
    h, _ = np.histogram(logeq[:, d], bins=bins, density=True)
    density[i] = h

# Light smoothing so the surface reads as terrain, not noise.
k = np.array([1, 4, 6, 4, 1], dtype=float); k /= k.sum()
for i in range(density.shape[0]):
    density[i] = np.convolve(density[i], k, mode="same")
for j in range(density.shape[1]):
    density[:, j] = np.convolve(density[:, j], k, mode="same")

# Normalize each day's slice so the ridge stays visible as the distribution
# spreads (z becomes relative density per day).
density = density / density.max(axis=1, keepdims=True)

X, Y = np.meshgrid(centers, day_idx)  # x stays in log units; ticks relabeled below

BG = "#f4f7fc"
INK = "#5b6b8c"
pastel = LinearSegmentedColormap.from_list(
    "pastelblue", ["#eaf2fb", "#c9def5", "#a3c6ee", "#7fabe3", "#5d8fd6", "#3f6fc4"])

fig = plt.figure(figsize=(11, 10), dpi=200, facecolor=BG)
ax = fig.add_subplot(111, projection="3d", facecolor=BG)

ax.plot_surface(X, Y, density, cmap=pastel, rstride=1, cstride=1,
                linewidth=0.1, edgecolor="#ffffff30", antialiased=True, shade=True)

ticks = [10, 25, 53, 100, 250, 500]
ticks = [t for t in ticks if lo <= np.log(t) <= hi]
ax.set_xticks([np.log(t) for t in ticks])
ax.set_xticklabels([f"${t}" for t in ticks], fontsize=9, color=INK)
ax.set_yticks([0, 50, 100, 150, 200, 250])
ax.tick_params(colors=INK, labelsize=9)
ax.set_xlabel("Account value (USD)", fontsize=10, color=INK, labelpad=10)
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

fig.text(0.09, 0.945, "agentic-trader", fontsize=20, fontweight="bold", color="#2f4468")
fig.text(0.09, 0.912, "Where 4,000 simulated one-year account paths land, starting from $53",
         fontsize=11, color=INK)
fig.text(0.09, 0.055,
         "SIMULATION ONLY - not actual performance. Modest assumed edge (51% win rate, fat-tailed "
         "wins, stops that can gap to -18%).\nAutonomous LLM agent trading a dedicated Robinhood "
         "Agentic account via MCP.",
         fontsize=8, color=INK, alpha=0.9)

plt.subplots_adjust(left=0, right=1, top=1.02, bottom=0.02)
fig.savefig("assets/monte-carlo-3d.png", bbox_inches="tight")
print("saved assets/monte-carlo-3d.png")
