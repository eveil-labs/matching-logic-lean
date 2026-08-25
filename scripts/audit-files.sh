#!/usr/bin/env bash
# Fails if any file listed in gate/complete-files.txt contains a `sorry`.
set -uo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.elan/bin:$PATH"
fail=0
while IFS= read -r f; do
  case "$f" in ''|'#'*) continue ;; esac
  if [ ! -f "$f" ]; then echo "FAIL  $f -- listed but missing"; fail=1; continue; fi
  out=$(lake env lean "$f" 2>&1); rc=$?
  # Lean's EXIT STATUS, not just its output. An audit found that a file which
  # exits nonzero while printing neither "error" nor "declaration uses" passed
  # the text-only version of this check.
  if [ $rc -ne 0 ]; then echo "FAIL  $f -- lean exited $rc"; fail=1; continue; fi
  # A file that does not COMPILE emits errors and no sorry warnings, so a
  # sorry-only check passes it. Measured: a file with an unknown identifier
  # sailed through the first version of this gate.
  e=$(printf '%s\n' "$out" | grep -c "error" || true)
  n=$(printf '%s\n' "$out" | grep -c "declaration uses" || true)
  if [ "$e" -ne 0 ]; then echo "FAIL  $f -- $e compile error(s)"; fail=1
  elif [ "$n" -ne 0 ]; then echo "FAIL  $f -- $n sorry"; fail=1
  else echo "ok    $f"; fi
done < gate/complete-files.txt
[ $fail -eq 0 ] && echo "== FILE GATE PASS ==" || echo "== FILE GATE FAIL =="
exit $fail
