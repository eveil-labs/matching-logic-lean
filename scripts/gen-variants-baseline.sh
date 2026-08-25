#!/usr/bin/env bash
# Regenerate gate/variants/*.txt: the printed claim and every definition each
# variant is about. Run after a deliberate change, then re-run audit-variants.sh.
set -uo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.elan/bin:$PATH"
while IFS=$'\t' read -r f ns side _rest; do
  case "$f" in ''|'#'*) continue ;; esac
  num=$(printf '%s' "$f" | sed -E 's|.*/V([0-9]+).*|\1|')
  tmp=$(mktemp /tmp/mlgen-XXXXXX.lean); cp "$f" "$tmp"
  { echo ""; echo "#print MatchingLogic.$ns.V${num}Claim"
    # every theorem in the file, so a documented control cannot be replaced by a
    # proof of True while the gate looks only at vN_fails
    for t in $(grep -oE "^(private )?theorem [A-Za-z_][^ :({]*" "$f" | sed -E 's/^(private )?theorem //'); do
      echo "#check @MatchingLogic.$ns.$t"
    done
    for d in $(grep -oE "^(private )?(def|abbrev) [A-Za-z_][A-Za-z0-9_₀-₉'.]*" "$f" | sed -E 's/^(private )?(def|abbrev) //'); do
      case "$d" in V${num}Claim) continue ;; esac
      echo "#print MatchingLogic.$ns.$d"
    done; } >> "$tmp"
  lake env lean "$tmp" 2>&1 \
    | grep -E "^(def|theorem|abbrev|private|@) ?MatchingLogic\.$ns\.|^@MatchingLogic\.$ns\.|^fun |^  " \
    | tr -s ' \n' ' \n' > "gate/variants/$(basename "$f" .lean).txt"
  rm -f "$tmp"
  echo "  $(basename "$f"): $(wc -l < "gate/variants/$(basename "$f" .lean).txt") lines"
done < gate/variants-expected.tsv
