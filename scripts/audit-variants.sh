#!/usr/bin/env bash
# Variant gate. For each variant, four things must hold:
#
#   1. the file compiles and leaves exactly ONE `sorry` -- the unsettled side;
#   2. the side that is settled is the one gate/variants-expected.tsv expects,
#      and the other side is NOT also proved;
#   3. that side genuinely has the type it should -- `vN_fails : ¬ VNClaim`,
#      checked by elaborating an `example` against it;
#   4. the claim, every theorem's type and every definition the claim is ABOUT
#      print exactly what gate/variants/<name>.txt recorded.
#
# Point 3 exists because two independent audits broke an earlier version of this
# gate by replacing a refutation with an unrelated theorem of the same name
# (`theorem v1_fails : True := ...`). Counting stubs and axioms is not enough:
# the gate has to pin what the settled side SAYS.
#
# Point 4's SLICE is the round-eight repair. It used to keep a continuation line
# only if it began with `fun ` or two spaces, so four definition bodies -- among
# them V2's test point `cmPt`, printed at column zero starting with `(` -- were
# never recorded at all. A reviewer moved that test point from copy 0 to copy 1,
# falsifying the variant's own documentation, and regenerated a byte-identical
# baseline. The print block and the slice now live in scripts/variant-common.sh,
# shared with the generator, and the slice drops nothing.
set -uo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.elan/bin:$PATH"
. scripts/variant-common.sh
TD=$(mktemp -d); trap 'rm -rf "$TD"' EXIT
fail=0; settled=0
while IFS=$'\t' read -r f ns side _lemma; do
  case "$f" in ''|'#'*) continue ;; esac
  [ -f "$f" ] || { echo "FAIL  $f -- listed but missing"; fail=1; continue; }
  other=$([ "$side" = "fails" ] && echo holds || echo fails)
  num=$(printf '%s' "$f" | sed -E 's|.*/V([0-9]+).*|\1|')
  tmp="$TD/$(basename "$f")"
  cp "$f" "$tmp"
  {
    echo ""
    echo "namespace MatchingLogic.$ns"
    # (3) the settled side must have the intended type
    if [ "$side" = "fails" ]; then
      echo "example : ¬ V${num}Claim := v${num}_fails"
    else
      echo "example : V${num}Claim := v${num}_holds"
    fi
    echo "end MatchingLogic.$ns"
    echo "#print axioms MatchingLogic.$ns.v${num}_${side}"
    echo "#print axioms MatchingLogic.$ns.v${num}_${other}"
    # (4) the pinned surface. LAST, so that everything after the sentinel is it.
    variant_decls "$f" "$ns" "$num"
  } >> "$tmp"
  out=$(lake env lean "$tmp" 2>&1); rc=$?
  if [ $rc -ne 0 ] || printf '%s\n' "$out" | grep -q "error"; then
    echo "FAIL  $f -- does not compile, or the settled side does not have the intended type"
    printf '%s\n' "$out" | grep error | head -3; fail=1; continue
  fi
  stubs=$(printf '%s\n' "$out" | grep -c "declaration uses" || true)
  if [ "$stubs" -ne 1 ]; then echo "FAIL  $f -- expected exactly 1 sorry, found $stubs"; fail=1; continue; fi
  sline=$(printf '%s\n' "$out" | grep -F "'MatchingLogic.$ns.v${num}_${side}'" | tail -1)
  oline=$(printf '%s\n' "$out" | grep -F "'MatchingLogic.$ns.v${num}_${other}'" | tail -1)
  case "$sline" in *sorryAx*) echo "FAIL  $f -- the expected settled side ($side) rests on sorry"; fail=1; continue ;; esac
  case "$oline" in *sorryAx*) : ;; *) echo "FAIL  $f -- the other side ($other) is ALSO proved; the variant statement is inconsistent"; fail=1; continue ;; esac
  # "does not depend on any axioms" is the STRONGEST outcome, not a missing one.
  case "$sline" in
    *"does not depend on any axioms"*) ax="" ;;
    *) ax=$(printf '%s' "${sline#*axioms: }" | tr -d '[]' | tr ',' '\n' | sed 's/ //g' \
            | grep -vE '^(propext|Classical\.choice|Quot\.sound)$' | grep -v '^$' || true) ;;
  esac
  if [ -n "$ax" ]; then echo "FAIL  $f -- disallowed axioms: $(echo $ax | tr '\n' ' ')"; fail=1; continue; fi
  # Compare the whole printed surface against this variant's baseline.
  base="gate/variants/$(basename "$f" .lean).txt"
  if [ ! -f "$base" ]; then echo "FAIL  $f -- no pinned baseline at $base"; fail=1; continue; fi
  # An absent sentinel would make the surface empty, and an empty surface must
  # never read as "nothing changed".
  if ! printf '%s\n' "$out" | grep -qF "$VARIANT_SENTINEL"; then
    echo "FAIL  $f -- no surface marker in Lean's output; nothing was compared"; fail=1; continue
  fi
  now="$TD/now.txt"
  printf '%s\n' "$out" | variant_surface > "$now"
  nlines=$(wc -l < "$now" | tr -d ' ')
  blines=$(wc -l < "$base" | tr -d ' ')
  if [ "$nlines" -lt 5 ] || [ "$blines" -lt 5 ]; then
    echo "FAIL  $f -- surface is $nlines lines against a $blines-line baseline; one of them is empty"; fail=1; continue
  fi
  if ! diff -q "$base" "$now" >/dev/null; then
    echo "FAIL  $f -- a pinned definition, theorem or the claim changed"; diff "$base" "$now" | head -8
    fail=1; continue
  fi
  echo "ok    $f -- $side, intended type, $nlines lines of claim, theorems and definitions pinned"
  settled=$((settled+1))
done < gate/variants-expected.tsv
echo "-- $settled settled --"
[ "$settled" -eq 5 ] || { echo "FAIL  $settled variants settled, expected 5"; fail=1; }
[ $fail -eq 0 ] && echo "== VARIANT GATE PASS ==" || echo "== VARIANT GATE FAIL =="
exit $fail
