#!/usr/bin/env bash
# Variant gate. Each variant file must compile, must leave exactly one `sorry`
# (the side that was NOT settled), and the side that WAS settled must depend
# only on the standard axioms -- never on `sorryAx`.
#
#   scripts/audit-variants.sh
#
# A variant still being worked on reports UNSETTLED, which is not a failure of
# the gate; it is the honest state. Only a compile error, or a settled side that
# leans on `sorry`, is a failure.
set -uo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.elan/bin:$PATH"
fail=0; settled=0; unsettled=0
for f in variants/V*.lean; do
  names=$(grep -oE '^theorem v[0-9]+_(holds|fails)' "$f" | sed 's/^theorem //')
  ns=$(grep -oE '^namespace [A-Za-z0-9_.]+' "$f" | tail -1 | sed 's/^namespace //')
  tmp=$(mktemp /tmp/mlvar-XXXXXX.lean)
  cp "$f" "$tmp"
  for n in $names; do echo "#print axioms MatchingLogic.$ns.$n" >> "$tmp"; done
  out=$(lake env lean "$tmp" 2>&1); rm -f "$tmp"
  if printf '%s\n' "$out" | grep -q "error"; then
    echo "FAIL  $f -- compile error"; printf '%s\n' "$out" | grep error | head -3; fail=1; continue
  fi
  proved=""; bad=""
  for n in $names; do
    # take the LAST match: a variant file may contain its own #print axioms,
    # which would otherwise concatenate two lines into one unparseable string
    line=$(printf '%s\n' "$out" | grep -F "'MatchingLogic.$ns.$n'" | tail -1)
    case "$line" in
      *sorryAx*) ;;                                   # this side is the open stub
      *) proved="$proved $n"
         ax=$(printf '%s' "${line#*axioms: }" | tr -d '[]' | tr ',' '\n' | sed 's/ //g' \
              | grep -vE '^(propext|Classical\.choice|Quot\.sound)$' | grep -v '^$' || true)
         [ -n "$ax" ] && bad="$bad $n:$ax" ;;
    esac
  done
  cnt=$(printf '%s' "$proved" | wc -w | tr -d ' ')
  # Exactly one `sorry` is expected: the side that was NOT settled. More than
  # that means an auxiliary lemma was left open and the file is claiming more
  # than it proves.
  stubs=$(printf '%s\n' "$out" | grep -c "declaration uses" || true)
  if [ -n "$bad" ]; then echo "FAIL  $f -- disallowed axioms:$bad"; fail=1
  elif [ "$stubs" -ne 1 ]; then echo "FAIL  $f -- expected exactly 1 sorry, found $stubs"; fail=1
  elif [ "$cnt" -eq 1 ]; then echo "ok    $f -- settled:$proved"; settled=$((settled+1))
  elif [ "$cnt" -eq 0 ]; then
    # An earlier version reported this and still exited 0, so CI stayed green if
    # a refutation was replaced by `sorry`. A variant in the repository is a
    # variant we claim to have settled.
    echo "FAIL  $f -- UNSETTLED: neither side proved"; fail=1
  else echo "FAIL  $f -- BOTH sides proved:$proved (the variant statement is inconsistent)"; fail=1; fi
done
echo "-- $settled settled, $unsettled unsettled --"
[ $fail -eq 0 ] && echo "== VARIANT GATE PASS ==" || echo "== VARIANT GATE FAIL =="
exit $fail
