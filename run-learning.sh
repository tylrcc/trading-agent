#!/bin/zsh
# Nightly learning pass after the regular close.

set -u
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin"

DIR="$HOME/ty/projects/trading-agent"
LOG="$DIR/runner.log"

[[ -f "$DIR/STOP" ]] && { echo "$(date '+%F %T') LEARN SKIP: STOP" >> "$LOG"; exit 0; }

echo "$(date '+%F %T') LEARN: start" >> "$LOG"
cd "$HOME/ty"

PROMPT="Nightly review for Robinhood Agentic account ending 5851.
Read /Users/tyler/ty/projects/trading-agent/JOURNAL.md, TRADES.csv, and
STRATEGY.md. Pull realized P&L via robinhood-trading MCP and reconcile it
against TRADES.csv (fix any missing rows). Compute win rate and expectancy
from TRADES.csv. Append a Nightly review to JOURNAL.md. Make at most TWO
tactic refinements to STRATEGY.md (never touch risk limits or guardrails).
Do not trade. No questions."

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
