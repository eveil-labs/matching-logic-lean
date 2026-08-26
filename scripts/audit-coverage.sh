#!/usr/bin/env bash
# Coverage gate -- deliberately CROSS-METHOD.
#
# `gen-pinned.sh` builds the pin list by asking LEAN'S ENVIRONMENT what exists.
# This gate builds its expectation by reading the SOURCE TEXT instead, and
# compares. The two disagreeing in either direction is the signal.
#
# Four ways this check has failed open, all now closed:
#
#   * R6: it shared the generator's regex, so it compared the generator against
#     itself and reported "91 of 91" while a dozen names were unpinned;
#   * R7: it reported "0/0 PASS" when its own enumeration failed. Hence the
#     plausibility floors;
#   * R8: the floors validated the INPUTS, and the comparison loop then read a
#     here-string. If that here-string was empty the loop ran zero times,
#     `missing` stayed 0, and it printed "106/106 PASS". Hence the loop
#     iteration count, which must equal the number of declarations found;
#   * R9, twice. It matched `def|abbrev|structure|inductive|theorem|lemma`
#     only, so an `instance`, `class`, `partial def` or `unsafe def` was outside
#     its expectation entirely -- demonstrated, five unpinned public
#     declarations in `MatchingLogic/` with the gate reporting 201/201. And it
#     compared FINAL NAME SEGMENTS, deduplicated with a locale-sensitive
#     `sort -u`: `MatchingLogic.Unpinned.soundness` was matched by the pin
#     directive for `MatchingLogic.soundness` and vanished, and under
#     `LC_ALL=en_US.UTF-8` four declarations (`box_coord₂`, `coord₂`,
#     `stepAt_coord₂`, `φ3`) silently left the expectation while the gate
#     reported PASS on the survivors.
#
# So the scan now tracks `namespace`/`section`/`end` and emits FULLY QUALIFIED
# names, compared against the exact set of names `gate/pinned.lean` pins. No
# final-segment matching, no dedup, and `LC_ALL=C` on every sort.
#
# What this scan does NOT match, stated so the claim is not larger than the
# check: it reads line-anchored declaration keywords, optionally behind
# attributes, so a declaration written after `in` on a `set_option` line is
# invisible to it. That direction is covered by the generator, which enumerates
# from the kernel, and by CI re-running the generator and diffing. The direction
# the generator cannot see is private names, and those are rejected by
# `scripts/audit-axiom-decls.sh`, from the kernel, by module rather than by name.
set -uo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C          # `sort -u` collation is locale-dependent; see R9 above
fail=0

SRCFILES="MatchingLogic.lean $(ls MatchingLogic/*.lean)"

# --- expectation: fully qualified names, from the source text ---------------
# awk keeps a namespace stack. `section` pushes a frame that contributes no
# name component, so `end Cover` closing `section Cover` does not pop a
# namespace. Private declarations are recorded separately: the generator cannot
# reach a private name, so a private DEFINITION is a defect (rejected by the
# declaration gate, from the kernel) and a private THEOREM is fine.
QUALIFY='
  function top() { return depth }
  /^[[:space:]]*namespace[[:space:]]/ { split($0,a,/[[:space:]]+/); i=1; while(a[i]=="") i++;
      depth++; kind[depth]="ns"; nm[depth]=a[i+1]; next }
  /^[[:space:]]*section([[:space:]]|$)/ { depth++; kind[depth]="sec"; nm[depth]=""; next }
  /^[[:space:]]*end([[:space:]]|$)/ { if (depth>0) depth--; next }
  {
    line=$0
    sub(/^[[:space:]]+/,"",line)
    while (match(line,/^@\[[^]]*\][[:space:]]*/)) line=substr(line,RLENGTH+1)
    priv=0
    while (match(line,/^(private|protected|noncomputable|partial|unsafe|scoped|local)[[:space:]]+/)) {
      if (line ~ /^private[[:space:]]/) priv=1
      line=substr(line,RLENGTH+1)
    }
    if (line !~ /^(def|abbrev|structure|inductive|theorem|lemma|instance|class)[[:space:]]/) next
    split(line,b,/[[:space:]]+/); kw=b[1]; nme=b[2]
    if (nme ~ /^[:({\[]/ || nme=="") { print (priv ? "PRIVANON " : "ANON ") kw; next }
    sub(/[:({].*$/,"",nme)
    if (nme=="") next
    pre=""
    for (i=1;i<=depth;i++) if (kind[i]=="ns") pre = pre nm[i] "."
    print (priv ? "PRIV " : "PUB ") pre nme
  }'

SCAN=$(awk "$QUALIFY" $SRCFILES)
PUBN=$(printf '%s\n' "$SCAN" | awk '$1=="PUB"{print $2}' | sort)
n_src=$(printf '%s\n' "$PUBN" | grep -c . || true)
n_privthm=$(printf '%s\n' "$SCAN" | awk '$1=="PRIV"{print $2}' | grep -c . || true)
n_anon=$(printf '%s\n' "$SCAN" | grep -cE '^(PRIV)?ANON ' || true)

if [ "${n_src:-0}" -lt 150 ]; then
  echo "FAIL  source scan found only ${n_src:-0} public declarations; the scan itself is broken"
  echo "== COVERAGE GATE FAIL =="; exit 1
fi
if [ "${n_anon:-0}" -ne 0 ]; then
  echo "FAIL  ${n_anon} anonymous declaration(s); an unnamed instance or class cannot be pinned by name:"
  printf '%s\n' "$SCAN" | grep -E '^(PRIV)?ANON ' | sed 's/^/      /'; fail=1
fi

# --- the pin set: exactly the names gate/pinned.lean pins -------------------
PINNED=$(sed -nE 's/^#print[[:space:]]+([^[:space:]]+).*/\1/p; s/^#check[[:space:]]+@([^[:space:]]+).*/\1/p' gate/pinned.lean \
         | sed -E 's/\.rec$//' | sort -u)
n_pin=$(printf '%s\n' "$PINNED" | grep -c . || true)
if [ "${n_pin:-0}" -lt 250 ]; then
  echo "FAIL  gate/pinned.lean names only ${n_pin:-0} declarations; it has been truncated"
  echo "== COVERAGE GATE FAIL =="; exit 1
fi

# --- every public source-written declaration must be in the pin set ---------
missing=0
checked=0
while read -r q; do
  [ -z "$q" ] && continue
  checked=$((checked+1))
  printf '%s\n' "$PINNED" | grep -qxF "$q" \
    || { echo "FAIL  source declares '$q' but nothing pins it"; missing=$((missing+1)); }
done <<< "$PUBN"

# THE loop assertion. Everything above validates the inputs; this is the only
# thing that says the comparison actually happened.
if [ "$checked" -ne "$n_src" ]; then
  echo "FAIL  the comparison loop ran $checked times for $n_src declarations -- it did not execute"
  echo "== COVERAGE GATE FAIL =="; exit 1
fi

echo "-- $((n_src-missing))/$n_src public source-written declarations pinned by qualified name, all $checked compared; $n_pin names in the pin list; $n_privthm private theorems, unpinnable by design --"
[ $missing -eq 0 ] || fail=1
[ $fail -eq 0 ] && echo "== COVERAGE GATE PASS ==" || echo "== COVERAGE GATE FAIL =="
exit $fail
