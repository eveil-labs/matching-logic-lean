#!/usr/bin/env bash
# Axiom gate. Fails if any certified theorem is missing, uses `sorry`, or
# depends on an axiom outside the standard three.
#
#   scripts/audit.sh
#
# Run from the repository root. Used by CI and by the desk after every merge.
set -uo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.elan/bin:$PATH"

LIST=${1:-gate/certified.txt}   # read-only; overridable so the gate itself can be tested
GEN=$(mktemp /tmp/ml-audit-XXXXXX.lean)
trap 'rm -f "$GEN"' EXIT

echo "import MatchingLogic" > "$GEN"
NAMES=()
while IFS= read -r line; do
  case "$line" in ''|'#'*) continue ;; esac
  NAMES+=("$line")
  echo "#print axioms $line" >> "$GEN"
done < "$LIST"

echo "== auditing ${#NAMES[@]} certified theorems =="
OUT=$(lake env lean "$GEN" 2>&1)
RC=$?
if [ $RC -ne 0 ]; then
  echo "FAIL: the audit file did not elaborate (a certified name may not exist)"
  echo "$OUT"
  exit 1
fi

fail=0
for n in "${NAMES[@]}"; do
  line=$(printf '%s\n' "$OUT" | grep -F "'$n' ")
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
if printf '%s\n' "$OUT" | grep -q sorryAx; then
  echo "FAIL: sorryAx reachable from a certified theorem"; fail=1
fi

if [ $fail -eq 0 ]; then echo "== AUDIT PASS =="; else echo "== AUDIT FAIL =="; fi
exit $fail
