#!/usr/bin/env bash
# Axiom-DECLARATION gate.
#
# Round eight: `axiom localCompleteness : StrongLocalCompleteness S Var`
# compiles, contains no `sorry`, and passed EVERY gate in this repository. The
# pin generator enumerated `defnInfo` and `inductInfo` only; the coverage scan
# matched `def|abbrev|structure|inductive` only; `scripts/audit.sh` reports the
# axioms a certified theorem DEPENDS on, and a theorem proved from a local
# `axiom` names it -- but nothing rejected the declaration itself, and nothing
# looked at a file that merely postulated something and stopped.
#
# The whole design rests on (L) and (S) being `Prop` HYPOTHESES carried in the
# statements that use them, never axioms. This gate is what says so.
#
# Two methods, on purpose, because the source scan alone is defeatable (`axiom`
# can be written after `in` on a `set_option` line) and the kernel scan alone
# cannot see a file nothing imports:
#
#   1. KERNEL: ask Lean's environment for every `axiomInfo`/`opaqueInfo` under
#      `MatchingLogic`, in the library and again in each variant file.
#   2. SOURCE: grep every Lean file this repository ships.
#
# Each reports how much it looked at, and the gate fails if a scan did not run.
set -uo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.elan/bin:$PATH"
fail=0
TD=$(mktemp -d); trap 'rm -rf "$TD"' EXIT
mkdir -p "$TD/run"   # copies live apart from the sources: `cat x > x` truncates x

SCAN='
open Lean in
run_cmd do
  let env ← getEnv
  let mut bad := #[]
  let mut seen := 0
  for (n, ci) in env.constants.toList do
    let s := n.toString
    unless s.startsWith "MatchingLogic" do continue
    seen := seen + 1
    match ci with
    | .axiomInfo _  => bad := bad.push s!"axiom {s}"
    | .opaqueInfo _ => bad := bad.push s!"opaque {s}"
    | _ => pure ()
  IO.println s!"AXIOMSCAN seen={seen} bad={bad.size}"
  for x in bad.qsort (· < ·) do IO.println s!"BAD {x}"
'

kernel_scan () {           # $1 = label, $2 = lean file to append the scan to
  local label=$1 src=$2 tmp out seen bad
  tmp="$TD/run/$(basename "$src")"
  cat "$src" > "$tmp"
  printf '\n%s\n' "$SCAN" >> "$tmp"
  out=$(lake env lean "$tmp" 2>&1); local rc=$?
  rm -f "$tmp"
  # A `sorry` is a warning and leaves the exit status 0, so a nonzero status
  # here means the file did not elaborate. Lean still runs the scan after an
  # error, so an AXIOMSCAN line is not evidence that the file is sound.
  if [ $rc -ne 0 ]; then
    echo "FAIL  $label -- lean exited $rc; the scan ran over a broken environment"
    printf '%s\n' "$out" | grep -i error | head -3; fail=1; return
  fi
  local line
  line=$(printf '%s\n' "$out" | grep '^AXIOMSCAN ' | tail -1)
  if [ -z "$line" ]; then
    echo "FAIL  $label -- no AXIOMSCAN line; a scan that produces nothing is not a scan"; fail=1; return
  fi
  # `[ "$x" -ne 0 ]` on a non-number returns 2, which an `if` reads as false --
  # a fail-open path. Parse only a line that is exactly the expected shape.
  if ! printf '%s' "$line" | grep -qE '^AXIOMSCAN seen=[0-9]+ bad=[0-9]+$'; then
    echo "FAIL  $label -- malformed scan line: $line"; fail=1; return
  fi
  seen=${line#*seen=}; seen=${seen%% *}
  bad=${line#*bad=}
  # An empty environment would report "0 axioms" and look clean.
  if [ "${seen:-0}" -lt 100 ]; then
    echo "FAIL  $label -- the scan saw only ${seen:-0} MatchingLogic declarations; it did not run properly"; fail=1; return
  fi
  if [ "${bad:-1}" -ne 0 ]; then
    echo "FAIL  $label -- $bad axiom/opaque declaration(s):"
    printf '%s\n' "$out" | grep '^BAD ' | sed 's/^BAD /      /'; fail=1; return
  fi
  echo "ok    $label -- $seen declarations, no axiom, no opaque"
}

echo "== kernel scan =="
LIB="$TD/lib.lean"; echo "import MatchingLogic" > "$LIB"
kernel_scan "MatchingLogic (library)" "$LIB"
nvar=0
for f in variants/V*.lean; do kernel_scan "$f" "$f"; nvar=$((nvar+1)); done
[ "$nvar" -eq 5 ] || { echo "FAIL  scanned $nvar variants, expected 5"; fail=1; }

echo "== source scan =="
# Every Lean file this repository ships, including the ones nothing imports.
FILES=$(ls MatchingLogic.lean MatchingLogic/*.lean variants/*.lean alternates/*.lean gate/pinned.lean 2>/dev/null)
nf=$(printf '%s\n' "$FILES" | grep -c . || true)
if [ "${nf:-0}" -lt 25 ]; then
  echo "FAIL  source scan found only ${nf:-0} Lean files; the file list is broken"; fail=1
else
  hits=$(printf '%s\n' "$FILES" | tr '\n' '\0' \
         | xargs -0 grep -nE '^[[:space:]]*(@\[[^]]*\][[:space:]]*)?(private[[:space:]]+|protected[[:space:]]+|noncomputable[[:space:]]+)*(axiom|opaque)[[:space:]]' \
         || true)
  if [ -n "$hits" ]; then
    echo "FAIL  axiom/opaque declared in source:"; printf '%s\n' "$hits" | sed 's/^/      /'; fail=1
  else
    echo "ok    $nf Lean files, no axiom/opaque declaration"
  fi
fi

[ $fail -eq 0 ] && echo "== AXIOM DECLARATION GATE PASS ==" || echo "== AXIOM DECLARATION GATE FAIL =="
exit $fail
