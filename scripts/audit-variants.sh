#!/usr/bin/env bash
# Variant gate. For each variant, three things must hold:
#
#   1. the file compiles and leaves exactly ONE `sorry` -- the unsettled side;
#   2. the side that is settled is the one gate/variants-expected.tsv expects;
#   3. that side genuinely has the type it should -- `vN_fails : ¬ VNClaim`,
#      checked by elaborating an `example` against it.
#
# Point 3 exists because two independent audits broke an earlier version of this
# gate by replacing a refutation with an unrelated theorem of the same name
# (`theorem v1_fails : True := ...`). Counting stubs and axioms is not enough:
# the gate has to pin what the settled side SAYS.
set -uo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.elan/bin:$PATH"
fail=0; settled=0
while IFS=$'\t' read -r f ns side _lemma; do
  case "$f" in ''|'#'*) continue ;; esac
  [ -f "$f" ] || { echo "FAIL  $f -- listed but missing"; fail=1; continue; }
  other=$([ "$side" = "fails" ] && echo holds || echo fails)
  num=$(printf '%s' "$f" | sed -E 's|.*/V([0-9]+).*|\1|')
  tmp=$(mktemp /tmp/mlvar-XXXXXX.lean)
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
    # Pin the CLAIM itself. Refuting a claim that has been weakened to `False`
    # would be worthless, and the type check above would still pass.
    echo "#print MatchingLogic.$ns.V${num}Claim"
    # ...and every definition the claim is ABOUT. An audit changed a variant's
    # own definitions while the claim's type and text stayed identical, so the
    # refutation became a refutation of something else.
    for d in $(grep -oE "^(private )?(def|abbrev) [A-Za-z_][A-Za-z0-9_₀-₉'\.]*" "$f" \
               | sed -E 's/^(private )?(def|abbrev) //'); do
      case "$d" in V${num}Claim) continue ;; esac
      echo "#print MatchingLogic.$ns.$d"
    done
  } >> "$tmp"
  out=$(lake env lean "$tmp" 2>&1); rc=$?
  rm -f "$tmp"
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
  # Compare the whole printed surface -- claim and every definition it is about --
  # against this variant's baseline.
  base="gate/variants/$(basename "$f" .lean).txt"
  printf '%s\n' "$out" | grep -E "^(def|theorem|abbrev|private) MatchingLogic\.$ns\.|^fun |^  " \
    | tr -s ' \n' ' \n' > /tmp/mlvarnow.$$
  if [ ! -f "$base" ]; then echo "FAIL  $f -- no pinned baseline at $base"; rm -f /tmp/mlvarnow.$$; fail=1; continue; fi
  if ! diff -q "$base" /tmp/mlvarnow.$$ >/dev/null; then
    echo "FAIL  $f -- a pinned definition or the claim changed"; diff "$base" /tmp/mlvarnow.$$ | head -6
    rm -f /tmp/mlvarnow.$$; fail=1; continue
  fi
  rm -f /tmp/mlvarnow.$$
  echo "ok    $f -- $side, intended type, claim and definitions pinned"; settled=$((settled+1))
done < gate/variants-expected.tsv
echo "-- $settled settled --"
[ $fail -eq 0 ] && echo "== VARIANT GATE PASS ==" || echo "== VARIANT GATE FAIL =="
exit $fail
