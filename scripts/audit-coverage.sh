#!/usr/bin/env bash
# Coverage gate — deliberately CROSS-METHOD.
#
# `gen-pinned.sh` builds the pin list by asking LEAN'S ENVIRONMENT what exists.
# This gate builds its expectation by reading the SOURCE TEXT instead, and
# compares. The two disagreeing in either direction is the signal.
#
# It is written this way because an earlier version of this check shared the
# generator's logic and so compared the generator against itself: it reported
# "91 of 91" while a dozen definitions whose names contained a dot or a Greek
# letter were silently unpinned.
#
# It also FAILS on an empty or failed enumeration. The previous version counted
# zero declarations and reported "0/0 PASS" when it could not create a temporary
# file -- a check that cannot fail is not a check.
set -uo pipefail
cd "$(dirname "$0")/.."
fail=0

# --- expectation, from the source text -------------------------------------
SRC=$(grep -hoE '^[[:space:]]*(@\[[^]]*\][[:space:]]*)?(private[[:space:]]+|protected[[:space:]]+|noncomputable[[:space:]]+)*(def|abbrev|structure|inductive)[[:space:]]+[^[:space:]:({]+' \
        MatchingLogic/*.lean \
      | sed -E 's/.*(def|abbrev|structure|inductive)[[:space:]]+//' | sort -u)
n_src=$(printf '%s\n' "$SRC" | grep -c . || true)
if [ "${n_src:-0}" -lt 50 ]; then
  echo "FAIL  source scan found only ${n_src:-0} declarations; the scan itself is broken"
  echo "== COVERAGE GATE FAIL =="; exit 1
fi

n_pin=$(grep -cE '^#print |^#check @' gate/pinned.lean || true)
if [ "${n_pin:-0}" -lt 100 ]; then
  echo "FAIL  gate/pinned.lean has only ${n_pin:-0} directives; it has been truncated"
  echo "== COVERAGE GATE FAIL =="; exit 1
fi

# --- every source-written declaration must appear in the pin list -----------
missing=0
while read -r base; do
  [ -z "$base" ] && continue
  # the pin list carries fully qualified names; match on the final segment
  # match the final segment, preceded by a space, a dot or an @
  esc=$(printf '%s' "$base" | sed 's/[.[\*^$]/\\&/g')
  grep -qE "(^|[ .@])${esc}(\.rec)?$" gate/pinned.lean \
    || { echo "FAIL  source declares '$base' but nothing pins it"; missing=$((missing+1)); }
done <<< "$SRC"

echo "-- $((n_src-missing))/$n_src source-written declarations pinned; $n_pin pin directives --"
[ $missing -eq 0 ] || fail=1
[ $fail -eq 0 ] && echo "== COVERAGE GATE PASS ==" || echo "== COVERAGE GATE FAIL =="
exit $fail
