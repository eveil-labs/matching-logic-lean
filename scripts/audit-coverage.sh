#!/usr/bin/env bash
# Coverage gate -- deliberately CROSS-METHOD.
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
# Three ways this check has failed open, all now closed:
#
#   * it counted zero declarations and reported "0/0 PASS" when it could not
#     create a temporary file. The plausibility floors below answer that;
#   * round eight: the floors validated the INPUTS, and the comparison loop then
#     read a here-string. If the temp file behind the here-string could not be
#     created the loop ran zero times, `missing` stayed 0, and it printed
#     "106/106 PASS". The loop now COUNTS ITS ITERATIONS and the count must
#     equal the number of declarations found;
#   * round eight: the scan matched `def|abbrev|structure|inductive` only, so a
#     `theorem` -- or an `axiom` -- was outside its expectation entirely.
#     Theorem kinds are scanned now, and `scripts/audit-axiom-decls.sh` rejects
#     an `axiom` outright.
#
# What this scan does NOT match, stated so the claim is not larger than the
# check: it reads line-anchored declaration keywords, optionally behind an
# attribute, so a declaration written after `in` on a `set_option` line is
# invisible to it. That direction is harmless -- the generator enumerates from
# the kernel and pins it anyway. The dangerous direction is source the
# GENERATOR cannot see, which is private names; private definitions are
# rejected below for exactly that reason.
set -uo pipefail
cd "$(dirname "$0")/.."
fail=0

KW='def|abbrev|structure|inductive|theorem|lemma'
PRE='^[[:space:]]*(@\[[^]]*\][[:space:]]*)*'
MOD='(private[[:space:]]+|protected[[:space:]]+|noncomputable[[:space:]]+)*'

# --- private definitions are forbidden --------------------------------------
# A private name cannot be reached by `#print`, so the generator cannot pin it,
# while a private DEFINITION can still appear inside a public statement's type.
# Private theorems are a different case and are allowed: a theorem's type is not
# part of anything public, only its proof, which the kernel checks.
privdef=$(grep -nE "${PRE}private[[:space:]]+(noncomputable[[:space:]]+)*(def|abbrev|structure|inductive)[[:space:]]" \
            MatchingLogic.lean MatchingLogic/*.lean || true)
if [ -n "$privdef" ]; then
  echo "FAIL  private definitions cannot be pinned:"; printf '%s\n' "$privdef" | sed 's/^/      /'; fail=1
fi
n_privthm=$(grep -hcE "${PRE}private[[:space:]]+(theorem|lemma)[[:space:]]" MatchingLogic/*.lean \
            | awk '{s+=$1} END{print s+0}')

# --- expectation, from the source text --------------------------------------
SRC=$(grep -hoE "${PRE}${MOD}(${KW})[[:space:]]+[^[:space:]:({]+" MatchingLogic.lean MatchingLogic/*.lean \
      | grep -vE "^[[:space:]]*(@\[[^]]*\][[:space:]]*)*private[[:space:]]" \
      | sed -E "s/.*(${KW})[[:space:]]+//" | sort -u)
n_src=$(printf '%s\n' "$SRC" | grep -c . || true)
if [ "${n_src:-0}" -lt 150 ]; then
  echo "FAIL  source scan found only ${n_src:-0} public declarations; the scan itself is broken"
  echo "== COVERAGE GATE FAIL =="; exit 1
fi

n_pin=$(grep -cE '^#print |^#check @' gate/pinned.lean || true)
if [ "${n_pin:-0}" -lt 300 ]; then
  echo "FAIL  gate/pinned.lean has only ${n_pin:-0} directives; it has been truncated"
  echo "== COVERAGE GATE FAIL =="; exit 1
fi

# --- every public source-written declaration must appear in the pin list -----
missing=0
checked=0
while read -r base; do
  [ -z "$base" ] && continue
  checked=$((checked+1))
  # the pin list carries fully qualified names; match on the final segment,
  # preceded by a space, a dot or an @
  esc=$(printf '%s' "$base" | sed 's/[.[\*^$]/\\&/g')
  grep -qE "(^|[ .@])${esc}(\.rec)?$" gate/pinned.lean \
    || { echo "FAIL  source declares '$base' but nothing pins it"; missing=$((missing+1)); }
done <<< "$SRC"

# THE loop assertion. Everything above validates the inputs; this is the only
# thing that says the comparison actually happened.
if [ "$checked" -ne "$n_src" ]; then
  echo "FAIL  the comparison loop ran $checked times for $n_src declarations -- it did not execute"
  echo "== COVERAGE GATE FAIL =="; exit 1
fi

echo "-- $((n_src-missing))/$n_src public source-written declarations pinned, all $checked compared; $n_pin pin directives; $n_privthm private theorems, unpinnable by design --"
[ $missing -eq 0 ] || fail=1
[ $fail -eq 0 ] && echo "== COVERAGE GATE PASS ==" || echo "== COVERAGE GATE FAIL =="
exit $fail
