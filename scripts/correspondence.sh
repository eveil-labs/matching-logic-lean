#!/usr/bin/env bash
# Generate the paper-to-Lean correspondence table from the CERTIFIED list and
# the kernel's own axiom output. Nothing here is hand-typed: a result appears
# only if it is in gate/certified.txt AND the kernel reports its axioms.
set -uo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.elan/bin:$PATH"
GEN=$(mktemp /tmp/ml-corr-XXXXXX.lean); trap 'rm -f "$GEN"' EXIT
echo "import MatchingLogic" > "$GEN"
grep -vE '^#|^$' gate/certified.txt | while read -r n; do echo "#print axioms $n"; done >> "$GEN"
OUT=$(lake env lean "$GEN" 2>&1)

printf '| Paper result | Lean | Axioms |\n|---|---|---|\n'
grep -vE '^#|^$' gate/paper-map.tsv | while IFS=$'\t' read -r name paper _sec; do
  line=$(printf '%s\n' "$OUT" | grep -F "'$name'" | tail -1)
  [ -z "$line" ] && continue                      # not certified yet: omit, never guess
  case "$line" in
    *"does not depend on any axioms"*) ax="none" ;;
    *) ax=$(printf '%s' "${line#*axioms: }" | tr -d '[]') ;;
  esac
  printf '| %s | `%s` | %s |\n' "$paper" "$name" "$ax"
done
