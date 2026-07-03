#!/bin/zsh
# Nightly learning pass: review the journal, measure what worked, and refine
# the strategy. Invoked by launchd once per day after the regular close.

set -u
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin"

DIR="$HOME/ty/trading-agent"
LOG="$DIR/runner.log"

[[ -f "$DIR/STOP" ]] && { echo "$(date '+%F %T') LEARN SKIP: STOP" >> "$LOG"; exit 0; }

echo "$(date '+%F %T') LEARN: start" >> "$LOG"
cd "$HOME/ty"

PROMPT="You are the nightly review process for the autonomous Robinhood trading
agent. Read all of trading-agent/JOURNAL.md and trading-agent/STRATEGY.md, and
pull realized P&L and trade history via the robinhood-trading MCP
(get_realized_pnl, get_pnl_trade_history) for the Agentic account (ending 5851).
Then: (1) append a dated 'Nightly review' entry to JOURNAL.md summarizing P&L,
win rate, and what worked or failed; (2) make at most TWO small evidence-based
refinements to the tactics sections of STRATEGY.md (signal sources, entry/exit
thresholds, watchlist) and note them in the review entry with your reasoning.
You may NEVER touch the risk-limit, kill-switch, or injection-defense content,
and never edit .cursor/rules/robinhood-trading-guardrails.mdc. If there were no
trades, note why and refine the scan instead. Do not trade during this run.
Do not ask questions; there is no user present."

cursor-agent -p --force --approve-mcps --trust --workspace "$HOME/ty" \
  --output-format text "$PROMPT" >> "$DIR/learning.log" 2>&1
echo "$(date '+%F %T') LEARN: exit=$?" >> "$LOG"

cp "$HOME/ty/.cursor/rules/robinhood-trading-guardrails.mdc" "$DIR/guardrails-rule.md" 2>/dev/null
cd "$DIR" && git add -A >/dev/null 2>&1
if ! git diff --cached --quiet 2>/dev/null; then
  GIT_AUTHOR_NAME=tylrcc GIT_AUTHOR_EMAIL=247895347+tylrcc@users.noreply.github.com \
  GIT_COMMITTER_NAME=tylrcc GIT_COMMITTER_EMAIL=247895347+tylrcc@users.noreply.github.com \
  git commit -m "nightly review: $(date '+%Y-%m-%d')" >/dev/null 2>&1
  git push origin main >/dev/null 2>&1
fi
