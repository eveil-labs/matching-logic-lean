#!/usr/bin/env bash
# Regenerate gate/variants/*.txt: the printed claim, every theorem's type, and
# every definition each variant is about. Run after a deliberate change, then
# re-run audit-variants.sh.
#
# The print block and the slice both live in scripts/variant-common.sh, shared
# with the gate, so the two cannot disagree about what is being recorded.
set -uo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.elan/bin:$PATH"
. scripts/variant-common.sh
TD=$(mktemp -d); trap 'rm -rf "$TD"' EXIT
n=0
while IFS=$'\t' read -r f ns side _rest; do
  case "$f" in ''|'#'*) continue ;; esac
  [ -f "$f" ] || { echo "FAIL  $f -- listed but missing"; exit 1; }
  num=$(printf '%s' "$f" | sed -E 's|.*/V([0-9]+).*|\1|')
  tmp="$TD/$(basename "$f")"; cp "$f" "$tmp"
  { echo ""; variant_decls; } >> "$tmp"
  out=$(lake env lean "$tmp" 2>&1)
  # A file that failed to elaborate prints errors and no sentinel. Writing that
  # to the baseline would pin an empty surface, which every later run matches.
  if ! printf '%s\n' "$out" | grep -qF "$VARIANT_SENTINEL"; then
    echo "FAIL  $f -- no surface marker in Lean's output; nothing was printed"
    printf '%s\n' "$out" | grep -i error | head -5; exit 1
  fi
  if printf '%s\n' "$out" | grep -q "error"; then
    echo "FAIL  $f -- Lean reported an error; a baseline must not record error text"
    printf '%s\n' "$out" | grep error | head -5; exit 1
  fi
  dest="gate/variants/$(basename "$f" .lean).txt"
  printf '%s\n' "$out" | variant_surface > "$dest"
  lines=$(wc -l < "$dest" | tr -d ' ')
  [ "$lines" -ge 5 ] || { echo "FAIL  $f -- surface is only $lines lines"; exit 1; }
  echo "  $(basename "$f"): $lines lines"
  n=$((n+1))
done < gate/variants-expected.tsv
echo "-- $n variant baselines written --"
[ "$n" -eq 5 ] || { echo "FAIL  wrote $n baselines, expected 5"; exit 1; }
