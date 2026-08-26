#!/usr/bin/env bash
# Axiom gate. Fails if any certified theorem is missing, uses `sorry`, or
# depends on an axiom outside the standard three.
#
#   scripts/audit.sh
#
# Run from the repository root. Used by CI and after every merge.
set -uo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.elan/bin:$PATH"

LIST=${1:-gate/certified.txt}   # read-only; overridable so the gate itself can be tested
TD=$(mktemp -d); trap 'rm -rf "$TD"' EXIT
GEN="$TD/audit.lean"

echo "import MatchingLogic" > "$GEN"
NAMES=()
while IFS= read -r line; do
  case "$line" in ''|'#'*) continue ;; esac
  NAMES+=("$line")
  echo "#print axioms $line" >> "$GEN"
done < "$LIST"

# An empty or truncated list would audit nothing and report a pass. The gate is
# overridable so it can be tested against a small list, so the floor applies to
# the DEFAULT manifest only.
if [ "$LIST" = "gate/certified.txt" ] && [ "${#NAMES[@]}" -lt 90 ]; then
  echo "FAIL: gate/certified.txt lists only ${#NAMES[@]} names; it has been truncated"
  echo "== AUDIT FAIL =="; exit 1
fi
if [ "${#NAMES[@]}" -eq 0 ]; then
  echo "FAIL: nothing to audit; a gate over an empty list is not a gate"
  echo "== AUDIT FAIL =="; exit 1
fi
echo "== auditing ${#NAMES[@]} certified theorems =="
OUT=$(lake env lean "$GEN" 2>&1)
RC=$?
if [ $RC -ne 0 ]; then
  echo "FAIL: the audit file did not elaborate (a certified name may not exist)"
  echo "$OUT"
  exit 1
fi


# `#print axioms` WRAPS. The kernel breaks a long axiom list across physical
# lines, and reading only the first line stops at "[propext," -- so a forbidden
# axiom on a continuation line is invisible. Measured on this tree: 33 of the
# 369 certified names wrap. `scripts/audit-entry-iii.sh` found and repaired this
# for its own gate; the repair was never carried here until round ten said so.
#
# Emit the whole stanza for $1, joined onto one line.
axiom_stanza () {
  # The name must be followed by a SPACE: `denote_rho` is a prefix of
  # `denote_rho'`, and a prefix test swallowed the following stanza --
  # caught by running this against the real 369-name output, not a sample.
  # The quote character is passed in as a variable so the awk program itself
  # contains none, which is what the shell quoting requires.
  awk -v want="'$1'" -v q="'" '
    substr($0, 1, length(want) + 1) == want " " { inb = 1 }
    inb {
      if (started && substr($0, 1, 1) == q) exit
      gsub(/^[[:space:]]+|[[:space:]]+$/, "")
      if (started) printf " "
      printf "%s", $0
      started = 1
    }
    END { if (started) print "" }
  '
}

fail=0
for n in "${NAMES[@]}"; do
  line=$(printf '%s\n' "$OUT" | axiom_stanza "$n")
  if [ -z "$line" ]; then
    echo "FAIL  $n -- no axiom line reported"; fail=1; continue
  fi
  # A fully constructive theorem prints "does not depend on any axioms", with no
  # list at all.  That is the STRONGEST outcome, not a missing one; measured on
  # Model.step_iff_exists_coord, which the first version of this gate would have
  # rejected.
  case "$line" in
    *"does not depend on any axioms"*) echo "ok    $n (no axioms)"; continue ;;
  esac
  axioms=${line#*axioms: }
  bad=$(printf '%s' "$axioms" | tr -d '[]' | tr ',' '\n' | sed 's/ //g' \
        | grep -vE '^(propext|Classical\.choice|Quot\.sound)$' | grep -v '^$')
  if [ -n "$bad" ]; then
    echo "FAIL  $n -- disallowed axioms: $(echo $bad | tr '\n' ' ')"; fail=1
  else
    echo "ok    $n"
  fi
done

# A certified theorem must not be reachable from any `sorry` anywhere.
# `case`, not `printf | grep -q`. Under `set -o pipefail`, grep -q exits on
# first match and closes the pipe, printf takes EPIPE and exits nonzero, and the
# PIPELINE is then nonzero -- so `if ... ; then FAIL` does not fire and a real
# sorryAx is silently accepted. Measured on CI, 2026-08-26. Pattern matching
# uses no pipe, no subprocess and no temp file.
if case "$OUT" in *sorryAx*) true ;; *) false ;; esac; then
  echo "FAIL: sorryAx reachable from a certified theorem"; fail=1
fi


# --- every certified name must be a THEOREM DECLARED IN THIS LIBRARY ---------
# Round twelve, from an independent audit: audit.sh checked the AXIOMS of
# whatever the certified names resolve to. A Mathlib theorem, or one of our own
# `def`s, would sail through -- the axiom verdict would be clean because the
# thing really is clean, and the gate would attest to a name that is not a
# claim this library makes. Key on the DECLARING MODULE, never on how the name
# is spelled, and on the kind reported by the kernel.
OWNERSHIP=$(cat <<'LEANEOF'
import MatchingLogic
open Lean
def certifiedNames : List String := [
LEANEOF
)
while read -r n; do
  [ -z "$n" ] && continue
  OWNERSHIP="$OWNERSHIP
  \"$n\","
done < <(grep -vE '^#|^$' gate/certified.txt)
OWNERSHIP="$OWNERSHIP
  \"\" ]

open Lean in
run_cmd do
  let env <- getEnv
  let mut bad : Array String := #[]
  let mut checked := 0
  for s in certifiedNames do
    if s.isEmpty then continue
    checked := checked + 1
    let n := s.toName
    match env.find? n with
    | none => bad := bad.push s!\"{s} -- no such declaration\"
    | some ci =>
      match ci with
      | .thmInfo _ => pure ()
      | _          => bad := bad.push s!\"{s} -- certified but not a theorem\"
      match env.getModuleIdxFor? n with
      | none     => bad := bad.push s!\"{s} -- not declared in any imported module\"
      | some idx =>
        let m := (env.header.moduleNames[idx.toNat]!).toString
        unless m.startsWith \"MatchingLogic\" do
          bad := bad.push s!\"{s} -- declared in {m}, not in this library\"
  IO.println s!\"OWNERSHIP checked={checked} bad={bad.size}\"
  for x in bad do IO.println s!\"BAD {x}\"
"
OWNFILE=$(mktemp "${TMPDIR:-/tmp}/ml-ownership.XXXXXX.lean")
printf '%s\n' "$OWNERSHIP" > "$OWNFILE"
OWNOUT=$(lake env lean "$OWNFILE" 2>&1)
OWNRC=$?
rm -f "$OWNFILE"
if [ "$OWNRC" -ne 0 ]; then
  echo "FAIL  ownership check did not elaborate"
  printf '%s\n' "$OWNOUT" | head -20
  fail=1
else
  own_line=$(printf '%s\n' "$OWNOUT" | grep '^OWNERSHIP ')
  if [ -z "$own_line" ]; then
    echo "FAIL  ownership check produced no verdict line"
    fail=1
  else
    own_bad=$(printf '%s\n' "$OWNOUT" | grep -c '^BAD ')
    if [ "$own_bad" -ne 0 ]; then
      printf '%s\n' "$OWNOUT" | grep '^BAD ' | head -20
      echo "FAIL  $own_bad certified names are not theorems of this library"
      fail=1
    else
      echo "ok    $own_line"
    fi
  fi
fi

if [ $fail -eq 0 ]; then echo "== AUDIT PASS =="; else echo "== AUDIT FAIL =="; fi
exit $fail
