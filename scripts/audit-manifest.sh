#!/usr/bin/env bash
# Manifest gate. The other gates check the things the manifests LIST; this one
# checks the manifests themselves have not been shrunk.
#
# An audit removed one name from gate/certified.txt and one file from
# gate/complete-files.txt, then replaced that theorem's proof with `sorry`.
# Every other gate stayed green, and the repository's stated inventory became
# false. This closes that.
set -uo pipefail
cd "$(dirname "$0")/.."
fail=0
# every result the documentation claims must still be certified
while IFS= read -r n; do
  case "$n" in ''|'#'*) continue ;; esac
  grep -qxF "$n" gate/certified.txt || { echo "FAIL  required but not certified: $n"; fail=1; }
done < gate/required.txt
# every library module must be claimed complete -- RECURSIVELY. `MatchingLogic/*`
# does not descend, and a whole subdirectory of new proof would be invisible to
# every gate that globs that way. Measured on the entry-point-(iii) branch: 29
# modules and 6,628 lines under `MatchingLogic/EntryIII/`, with four gates
# reporting `ok` because none of them looked there.
LIBFILES=$(find MatchingLogic -name '*.lean' | sort)
for f in $LIBFILES; do
  grep -qxF "$f" gate/complete-files.txt || { echo "FAIL  library module not claimed complete: $f"; fail=1; }
done

# EVERY Lean file this repository ships must be accounted for by some gate.
# Nothing is allowed to sit in the tree unexamined.
for f in $(find . -name '*.lean' -not -path './.lake/*' | sed 's|^\./||' | sort); do
  case "$f" in
    MatchingLogic.lean) continue ;;
    # gate/*.lean are PIN FILES -- lists of `#print`/`#check` directives, no
    # declarations of their own. gate/pinned.lean is elaborated by
    # audit-pinned.sh, the gate/entry-iii-*-pins.lean by audit-entry-iii.sh,
    # and all of them are scanned for axioms by audit-axiom-decls.sh.
    gate/*.lean) continue ;;
    MatchingLogic/*) grep -qxF "$f" gate/complete-files.txt && continue ;;
    variants/*)  grep -qF "$f" gate/variants-expected.tsv && continue
                 case "$f" in variants/README*|variants/RESULTS*) continue ;; esac ;;
    alternates/*) continue ;;   # scanned by audit-axiom-decls.sh, not built
  esac
  echo "FAIL  Lean file examined by no gate: $f"; fail=1
done

# The library ROOT must import every library module, or `import MatchingLogic`
# -- which is how the pin generator, the axiom audit and CI's build all reach
# the code -- silently covers less than the tree contains. On the entry-point-
# (iii) branch `lake build MatchingLogic` completed 616 jobs and produced ZERO
# oleans for 29 modules and 6,628 lines, because nothing imported them.
#
# This is NOT checked here. `lake exe mk_all --check` is the standard tool for
# it, it comes free with the Mathlib dependency, and CI runs it. Measured on
# that branch: mk_all adds all 29 missing imports. A hand-rolled loop lived here
# briefly and was deleted in favour of it.

n_cert=$(grep -cvE '^#|^$' gate/certified.txt)
n_var=$(grep -cvE '^#|^$' gate/variants-expected.tsv)
n_req=$(grep -cvE '^#|^$' gate/required.txt)
[ "$n_cert" -eq "$n_req" ] || { echo "FAIL  certified ($n_cert) and required ($n_req) disagree"; fail=1; }
[ "$n_var" -eq 5 ] || { echo "FAIL  expected 5 variants, found $n_var"; fail=1; }
# Round nine: this was the one gate with no floor. Emptying BOTH manifests left
# `n_cert -eq n_req` true at 0 and it reported `-- 0 certified -- MANIFEST GATE
# PASS`. A gate over an empty list is not a gate; the round-seven "0/0 PASS"
# shape had survived here.
n_mod=$(printf '%s\n' "$LIBFILES" | grep -c . || true)
# Round twelve: these floors were 90 and 15 against actuals of 369 and 53, so a
# coordinated shrink to a fifth of the library passed. Raised to just under the
# current values -- high enough that a truncation is caught, low enough that
# removing a handful of results legitimately does not trip the gate. They are a
# tripwire, not a census: audit-coverage.sh is what proves nothing was dropped.
[ "$n_cert" -ge 350 ] || { echo "FAIL  only $n_cert certified names; the manifest has been truncated"; fail=1; }
[ "$n_mod" -ge 50 ] || { echo "FAIL  only $n_mod library modules; the tree has been truncated"; fail=1; }
n_cf=$(grep -cvE '^#|^$' gate/complete-files.txt)
[ "$n_cf" -ge "$n_mod" ] || { echo "FAIL  complete-files lists $n_cf of $n_mod modules"; fail=1; }
echo "-- $n_cert certified, $n_var variants, $n_mod modules, all imported by the root --"
[ $fail -eq 0 ] && echo "== MANIFEST GATE PASS ==" || echo "== MANIFEST GATE FAIL =="
exit $fail
