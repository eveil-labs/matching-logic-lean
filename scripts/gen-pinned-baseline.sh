#!/usr/bin/env bash
# Regenerate gate/pinned-baseline.txt: the kernel's own printing of every
# directive in gate/pinned.lean, normalized exactly as scripts/audit-pinned.sh
# normalizes the current run.
#
# Regenerating this file destroys the check it exists to provide, so it is a
# DELIBERATE act: run it only after an intended change to the library, and say
# in the commit what changed and why. CI never runs it.
set -uo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.elan/bin:$PATH"
OUT=$(lake env lean gate/pinned.lean 2>&1) || { echo "FAIL: gate/pinned.lean did not elaborate"; printf '%s\n' "$OUT" | head -20; exit 1; }
printf '%s\n' "$OUT" | tr -s ' \n' ' \n' > gate/pinned-baseline.txt
echo "gate/pinned-baseline.txt: $(wc -l < gate/pinned-baseline.txt | tr -d ' ') lines"
