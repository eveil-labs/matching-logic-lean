#!/usr/bin/env bash
# Statement gate. Compares the kernel's own printing of every pinned statement
# TYPE and definition BODY against gate/pinned-baseline.txt.
#
# Why bodies and not just types: the cheapest way to "prove" Lemma 11 is to
# weaken Definition 10 so that constants populate one copy only -- which the
# paper explicitly warns about, and which changes no type. Comparing only types
# passes that. Comparing bodies does not.
#
# Why this and not just the axiom gate: `#print axioms` accepts any declaration,
# including a DEFINITION with a certified theorem's name. This gate pins what
# each name actually says.
set -uo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.elan/bin:$PATH"
OUT=$(lake env lean gate/pinned.lean 2>&1) || { echo "FAIL: gate/pinned.lean did not elaborate"; printf '%s\n' "$OUT" | head -20; exit 1; }
printf '%s\n' "$OUT" | tr -s ' \n' ' \n' > /tmp/ml-pinned-now.$$
if diff -u gate/pinned-baseline.txt /tmp/ml-pinned-now.$$; then
  echo "== PINNED GATE PASS =="; rm -f /tmp/ml-pinned-now.$$; exit 0
else
  echo "== PINNED GATE FAIL: a pinned statement or definition changed =="
  rm -f /tmp/ml-pinned-now.$$; exit 1
fi
