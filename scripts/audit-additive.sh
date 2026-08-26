#!/usr/bin/env bash
# Additive gate — for long-running work that EXTENDS an already-verified base.
#
# Entry point (iii) adds a proof of (L). It must not alter anything that was
# already verified. The check is simply: against `upstream/main`, are there any
# MODIFICATIONS or DELETIONS to the existing library and gate data, as opposed
# to additions?
#
# This uses git's comparison with the verified base.  Untracked paths must be
# counted separately: `git diff` cannot see them, but they are still additions
# in the working tree and should be reported as such.
set -uo pipefail
cd "$(dirname "$0")/.."
BASE="${1:-upstream/main}"
git rev-parse --verify --quiet "$BASE" >/dev/null || {
  echo "FAIL  cannot resolve $BASE -- run: git fetch upstream"; exit 1; }

# Files that existed in the verified base and have been changed at all.
CHANGED=$(git diff --name-status "$BASE" -- MatchingLogic/ gate/ scripts/ \
          | awk '$1 != "A" {print $1"  "$2}')
if [ -n "$CHANGED" ]; then
  echo "FAIL  these verified files are modified or deleted, not merely added to:"
  printf '%s\n' "$CHANGED"
  echo
  echo "Entry point (iii) should ADD a development. If one of these changes is"
  echo "genuinely required, it needs review on its own merits -- say so"
  echo "explicitly rather than letting it ride along."
  echo "== ADDITIVE GATE FAIL =="
  exit 1
fi
TRACKED_ADDED=$(git diff --name-status "$BASE" -- MatchingLogic/ gate/ scripts/ |
                awk '$1 == "A" {count++} END {print count+0}')
UNTRACKED=$(git ls-files --others --exclude-standard -- MatchingLogic/ gate/ scripts/)
UNTRACKED_ADDED=$(printf '%s\n' "$UNTRACKED" | sed '/^$/d' | wc -l | tr -d ' ')
ADDED=$((TRACKED_ADDED + UNTRACKED_ADDED))
echo "ok    no verified file modified; $ADDED new file(s) added"
if [ "$UNTRACKED_ADDED" -ne 0 ]; then
  echo "-- $UNTRACKED_ADDED untracked addition(s) included in the count"
  printf '%s\n' "$UNTRACKED"
fi
echo "== ADDITIVE GATE PASS =="
