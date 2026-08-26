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
#
# Round nine: this was the one gate with no plausibility floor. Truncating
# gate/pinned.lean to its `import` line and regenerating the baseline gave a
# one-line baseline, a one-line current run, and `== PINNED GATE PASS ==` --
# comparing nothing against nothing. The floors below say what a real run looks
# like; `scripts/audit-coverage.sh` independently requires the pin list to name
# at least 250 declarations.
set -uo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.elan/bin:$PATH"
TD=$(mktemp -d); trap 'rm -rf "$TD"' EXIT
n_dir=$(grep -cE '^#print |^#check @' gate/pinned.lean || true)
if [ "${n_dir:-0}" -lt 300 ]; then
  echo "FAIL: gate/pinned.lean has only ${n_dir:-0} directives; it has been truncated"
  echo "== PINNED GATE FAIL =="; exit 1
fi
n_base=$(grep -c . gate/pinned-baseline.txt || true)
if [ "${n_base:-0}" -lt 1000 ]; then
  echo "FAIL: gate/pinned-baseline.txt has only ${n_base:-0} lines; it has been truncated"
  echo "== PINNED GATE FAIL =="; exit 1
fi
OUT=$(lake env lean gate/pinned.lean 2>&1) || { echo "FAIL: gate/pinned.lean did not elaborate"; printf '%s\n' "$OUT" | head -20; exit 1; }
printf '%s\n' "$OUT" | tr -s ' \n' ' \n' > "$TD/now.txt"
n_now=$(grep -c . "$TD/now.txt" || true)
if [ "${n_now:-0}" -lt 1000 ]; then
  echo "FAIL: this run printed only ${n_now:-0} lines; nothing was compared"
  echo "== PINNED GATE FAIL =="; exit 1
fi
if diff -u gate/pinned-baseline.txt "$TD/now.txt"; then
  echo "== PINNED GATE PASS ($n_dir directives, $n_now lines) =="; exit 0
else
  echo "== PINNED GATE FAIL: a pinned statement or definition changed =="
  exit 1
fi
