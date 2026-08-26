#!/usr/bin/env bash
# Declaration-KIND gate: no `axiom`, no `opaque`, no private definition.
#
# Round eight: `axiom localCompleteness : StrongLocalCompleteness S Var`
# compiles, contains no `sorry`, and passed EVERY gate here. `scripts/audit.sh`
# reports the axioms a certified theorem DEPENDS on; nothing rejected the
# declaration itself, and nothing looked at a file that merely postulated
# something and stopped. The whole design rests on (L) and (S) being `Prop`
# HYPOTHESES carried in the statements that use them.
#
# ROUND NINE broke the first version of this gate, twice, by the same mistake:
# its kernel scan filtered on `s.startsWith "MatchingLogic"`, copied from the
# pin generator, where filtering by NAME is right. Here it is wrong.
#
#   * an axiom declared OUTSIDE the namespace -- `axiom smuggled_L : ...` at
#     the root of `MatchingLogic/EntryPoints.lean` -- has a name the filter
#     rejects, and `set_option ... in` on the same line defeats the source scan.
#     Both reviewers reached full CI green with (L) as an axiom;
#   * a PRIVATE axiom inside the namespace is called
#     `_private.MatchingLogic.ProofSystem.0.MatchingLogic.localCompleteness`,
#     which also does not start with `MatchingLogic`.
#
# Ownership is therefore keyed on the DECLARING MODULE, not the name. A
# declaration is ours if the environment reports no module for it (it is in the
# file being compiled) or its module is one of ours. That is immune to how the
# name is spelled, which namespace it sits in, and whether it is private.
#
# Two methods still, and the source scan is the weaker one -- it is line
# oriented and a declaration can be written after `in` on a `set_option` line.
# It earns its place only for text the kernel scan cannot reach; every Lean file
# this repository ships that CAN be compiled is compiled below.
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
  let mut leaked := #[]
  let mut npriv := 0
  let mut seen := 0
  for (n, ci) in env.constants.toList do
    -- OURS = declared in the file being compiled, or in a module of ours.
    -- Never a test on the NAME: that is what round nine defeated twice.
    let ours ←
      match env.getModuleIdxFor? n with
      | none     => pure true
      | some idx => pure ((env.header.moduleNames[idx.toNat]!).toString.startsWith "MatchingLogic")
    unless ours do continue
    -- A private name is `_private.<Module>.0.<realName>`, which `isInternal`
    -- reports TRUE for -- so filtering on `isInternal` would skip every private
    -- declaration before its kind is looked at. Strip the wrapper first.
    let user := (privateToUserName? n).getD n
    if user.isInternal then continue
    seen := seen + 1
    let s := n.toString
    match ci with
    | .axiomInfo _  => bad := bad.push s!"axiom {s}"
    | .opaqueInfo _ => bad := bad.push s!"opaque {s}"
    | .defnInfo _   => if isPrivateName n then npriv := npriv + 1
    | .inductInfo _ => if isPrivateName n then npriv := npriv + 1
    | _ => pure ()
    -- A private name cannot be reached by `#print`, so no pin list built from
    -- the environment covers it. That only MATTERS when such a name appears in
    -- the TYPE of something PUBLIC: then a public statement says something the
    -- pin list cannot see. Round nine banned private definitions outright;
    -- meeting the entry-(iii) development showed that rule was too strong --
    -- many internals of the construction are private definitions and not one
    -- surfaces in a public type. So check the thing that actually matters.
    -- (No apostrophes in this block: it is inside a single-quoted shell string.)
    unless isPrivateName n do
      for c in ci.type.getUsedConstants do
        if isPrivateName c then
          let cOurs ←
            match env.getModuleIdxFor? c with
            | none     => pure true
            | some i   => pure ((env.header.moduleNames[i.toNat]!).toString.startsWith "MatchingLogic")
          if cOurs then leaked := leaked.push s!"private-in-public-type {s} uses {c}"
  IO.println s!"AXIOMSCAN seen={seen} raw={bad.size + leaked.size} priv={npriv}"
  for x in bad.qsort (· < ·) do IO.println s!"BAD {x}"
  for x in leaked.qsort (· < ·) do IO.println s!"BAD {x}"
'

# Compiler-generated private auxiliaries -- the `match_N.splitter` definitions
# Lean emits for pattern matches. There are ten in the library and they are not
# source-written; `gen-pinned.sh` discards the same shapes.
#
# KNOWN LIMIT, stated rather than papered over: this is a name pattern, and a
# hand-written private definition deliberately named to match it, written after
# `in` on a `set_option` line so the source scan below also misses it, would
# pass. Nothing in this repository does that, and the source scan is un-filtered
# precisely so that the ordinary spelling is caught by something.
AUX='\.(match_[0-9]+|eq_[0-9]+|proof_[0-9]+)(\.|$)|\.(splitter|recOn|casesOn|noConfusion|noConfusionType|ctorIdx|below|brecOn|ndrec|binductionOn|injEq|sizeOf_spec)$|\.mk\.noConfusion$'

kernel_scan () {           # $1 = label, $2 = lean file to append the scan to, $3 = floor
  local label=$1 src=$2 floor=$3 tmp out seen bad
  tmp="$TD/run/$(basename "$src")"
  cat "$src" > "$tmp"
  printf '\n%s\n' "$SCAN" >> "$tmp"
  out=$(lake env lean "$tmp" 2>&1); local rc=$?
  rm -f "$tmp"
  # A `sorry` is a warning and leaves the exit status 0, so nonzero here means
  # the file did not elaborate. Lean runs the scan even after an error, so an
  # AXIOMSCAN line is not by itself evidence the file is sound.
  if [ $rc -ne 0 ]; then
    echo "FAIL  $label -- lean exited $rc; the scan ran over a broken environment"
    printf '%s\n' "$out" | grep -i error | head -3; fail=1; return
  fi
  local line
  line=$(printf '%s\n' "$out" | grep '^AXIOMSCAN ' | tail -1)
  # `[ "$x" -ne 0 ]` on a non-number returns 2, which an `if` reads as false --
  # a fail-open path. Parse only a line that is exactly the expected shape.
  # `[[ =~ ]]`, not `printf | grep -qE`: no pipe, so no EPIPE/pipefail race.
  if ! [[ "$line" =~ ^AXIOMSCAN\ seen=[0-9]+\ raw=[0-9]+\ priv=[0-9]+$ ]]; then
    echo "FAIL  $label -- no well-formed scan line; a scan that produces nothing is not a scan"
    fail=1; return
  fi
  seen=${line#*seen=}; seen=${seen%% *}
  npriv=${line#*priv=}; npriv=${npriv%% *}
  bad=$(printf '%s\n' "$out" | grep '^BAD ' | grep -vE "$AUX" | grep -c . || true)
  # An empty environment would report "0 axioms" and look clean.
  if [ "$seen" -lt "$floor" ]; then
    echo "FAIL  $label -- the scan saw only $seen of our declarations, floor $floor; it did not run properly"
    fail=1; return
  fi
  if [ "$bad" -ne 0 ]; then
    echo "FAIL  $label -- $bad forbidden declaration(s) or private leak(s):"
    printf '%s\n' "$out" | grep '^BAD ' | grep -vE "$AUX" | sed 's/^BAD /      /'; fail=1; return
  fi
  echo "ok    $label -- $seen declarations, no axiom, no opaque, no private name in a public type ($npriv private definitions, none leaked)"
}

echo "== kernel scan =="
LIB="$TD/lib.lean"; echo "import MatchingLogic" > "$LIB"
kernel_scan "MatchingLogic (library)" "$LIB" 500
n=0
for f in variants/V*.lean;    do kernel_scan "$f" "$f" 75; n=$((n+1)); done
[ "$n" -eq 5 ] || { echo "FAIL  scanned $n variants, expected 5"; fail=1; }
# alternates/ is evidence and nothing imports it, so the library scan cannot see
# it. It compiles standalone, so scan it rather than trusting a grep.
n=0
for f in alternates/*.lean;   do kernel_scan "$f" "$f" 75; n=$((n+1)); done
[ "$n" -eq 3 ] || { echo "FAIL  scanned $n alternates, expected 3"; fail=1; }

echo "== source scan =="
# Secondary and line-oriented. Every compilable file is covered above; this is
# for text, and for the two files with nothing to compile.
# `find`, not a flat glob: on the entry-point-(iii) branch a flat glob reported
# "30 Lean files" while 29 more sat one directory down, unscanned.
FILES=$( { echo MatchingLogic.lean; \
           find gate MatchingLogic variants alternates -name '*.lean'; } 2>/dev/null | sort)
nf=$(printf '%s\n' "$FILES" | grep -c . || true)
if [ "${nf:-0}" -lt 25 ]; then
  echo "FAIL  source scan found only ${nf:-0} Lean files; the file list is broken"; fail=1
else
  hits=$(printf '%s\n' "$FILES" | tr '\n' '\0' \
         | xargs -0 grep -nE '(^|[[:space:]]in)[[:space:]]*(@\[[^]]*\][[:space:]]*)*(private[[:space:]]+|protected[[:space:]]+|noncomputable[[:space:]]+)*(axiom|opaque)[[:space:]]' \
         || true)
  if [ -n "$hits" ]; then
    echo "FAIL  axiom/opaque declared in source:"; printf '%s\n' "$hits" | sed 's/^/      /'; fail=1
  else
    echo "ok    $nf Lean files, no axiom/opaque declaration"
  fi
fi

[ $fail -eq 0 ] && echo "== DECLARATION GATE PASS ==" || echo "== DECLARATION GATE FAIL =="
exit $fail
