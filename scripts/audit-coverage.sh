#!/usr/bin/env bash
# Coverage gate. Asks LEAN which declarations exist and checks each is pinned.
#
# This must not use the same pattern the generator uses. An earlier coverage
# check did, and so compared the generator against itself: it reported 91 of 91
# while a dozen definitions with dotted or Greek names were silently missing.
set -uo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.elan/bin:$PATH"
GEN=$(mktemp /tmp/mlcov-XXXXXX.lean); trap 'rm -f "$GEN"' EXIT
cat > "$GEN" <<'LEAN'
import MatchingLogic
open Lean in
run_cmd do
  let env ← getEnv
  let mut out := #[]
  for (n, ci) in env.constants.toList do
    let s := n.toString
    unless s.startsWith "MatchingLogic" do continue
    if n.isInternal then continue
    if (s.splitOn "._").length > 1 then continue
    -- compiler-generated companions of a type are pinned via its recursor
    if s.endsWith ".rec" || s.endsWith ".recOn" || s.endsWith ".casesOn" || s.endsWith ".below"
       || s.endsWith ".brecOn" || s.endsWith ".brecOn.go" || s.endsWith ".ndrec" || s.endsWith ".ibelow"
       || s.endsWith ".binductionOn" || s.endsWith ".noConfusion" || s.endsWith ".noConfusionType"
       || s.endsWith ".sizeOf" || s.endsWith ".injEq" || s.endsWith ".inj" || s.endsWith ".eq_def"
       || s.endsWith ".mk" || s.endsWith ".toCtorIdx" || s.endsWith ".ofNat" || s.endsWith ".elim"
       || s.endsWith ".ctorIdx" || s.endsWith ".ctorElim" || s.endsWith ".ctorElimType" then continue
    match ci with
    | .defnInfo _ => out := out.push s
    | .inductInfo _ => out := out.push s
    | _ => pure ()
  for x in out.qsort (· < ·) do IO.println x
LEAN
ALL=$(lake env lean "$GEN" 2>/dev/null | grep -vE '\.(eq_[0-9]|match_[0-9]|proof_[0-9]|_sunfold|_unsafe_rec|_cstage|decEq)')
miss=0; tot=0
while read -r n; do
  [ -z "$n" ] && continue
  tot=$((tot+1))
  grep -qxF "#print $n" gate/pinned.lean || grep -qxF "#check @$n.rec" gate/pinned.lean \
    || grep -qxF "#check @$n" gate/pinned.lean \
    || { echo "FAIL  not pinned: $n"; miss=$((miss+1)); }
done <<< "$ALL"
echo "-- $((tot-miss))/$tot declarations pinned --"
[ $miss -eq 0 ] && echo "== COVERAGE GATE PASS ==" || echo "== COVERAGE GATE FAIL =="
exit $([ $miss -eq 0 ] && echo 0 || echo 1)
