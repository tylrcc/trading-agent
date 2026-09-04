#!/bin/bash
# Commit and push the repo's pending changes, but only every few days.
#
# GitHub counts a contribution on the commit's author date, so holding pushes
# back would not change the graph: the commits would still be dated to every
# single day. Instead this leaves changes uncommitted in the working tree
# until a batch day arrives, then commits them dated that day. Journal and
# strategy edits are still written nightly either way, they just land in git
# in clusters.
set -uo pipefail

DIR="$HOME/ty/projects/trading-agent"
STATE="$DIR/.next-batch"          # gitignored; holds the next batch date
cd "$DIR" || exit 0

# Use an email that is NOT on the GitHub account so these automated
# commits never light up the contribution graph. Manual real-work
# commits still use tylrcc and still count.
export GIT_AUTHOR_NAME=trading-agent
export GIT_AUTHOR_EMAIL=trading-agent@noreply.local
export GIT_COMMITTER_NAME=trading-agent
export GIT_COMMITTER_EMAIL=trading-agent@noreply.local

today=$(date '+%Y-%m-%d')

# Rest 2-5 days between batches.
next_date() {
  date -v"+$(( RANDOM % 4 + 2 ))d" '+%Y-%m-%d' 2>/dev/null \
    || date -d "+$(( RANDOM % 4 + 2 )) days" '+%Y-%m-%d'
}

if [ ! -f "$STATE" ]; then
  next_date > "$STATE"
  echo "batch-commit: first run, next batch $(cat "$STATE")"
  exit 0
fi

due=$(cat "$STATE")
if [[ ! "$due" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  next_date > "$STATE"
  echo "batch-commit: bad state, reset to $(cat "$STATE")"
  exit 0
fi

if [[ "$today" < "$due" ]]; then
  echo "batch-commit: holding changes until $due"
  exit 0
fi

if git diff --quiet && git diff --cached --quiet && [ -z "$(git status --porcelain)" ]; then
  echo "batch-commit: nothing pending"
  next_date > "$STATE"
  exit 0
fi

# Split the batch into a few commits by file group so a batch day looks like
# a working session rather than one giant catch-all commit.
committed=0
commit_group() {
  local msg="$1"; shift
  local found=0
  for p in "$@"; do
    if [ -n "$(git status --porcelain -- "$p" 2>/dev/null)" ]; then
      git add -- "$p" >/dev/null 2>&1 && found=1
    fi
  done
  [ "$found" -eq 1 ] || return 0
  git diff --cached --quiet && return 0
  if git commit -m "$msg" >/dev/null 2>&1; then
    committed=$(( committed + 1 ))
  fi
}

commit_group "trades: reconcile fills through $today" TRADES.csv
commit_group "journal: reviews through $today" JOURNAL.md
commit_group "strategy: tactic refinements through $today" STRATEGY.md
commit_group "chore: sync guardrails and logs" .

if [ "$committed" -eq 0 ]; then
  echo "batch-commit: nothing to commit"
  next_date > "$STATE"
  exit 0
fi

git pull --rebase --autostash origin main >/dev/null 2>&1
if git push origin main >/dev/null 2>&1; then
  echo "batch-commit: pushed $committed commit(s); next batch $(next_date | tee "$STATE")"
else
  echo "batch-commit: push FAILED, will retry next run" >&2
  # Leave the state date in the past so the next run retries the push.
  exit 1
fi
