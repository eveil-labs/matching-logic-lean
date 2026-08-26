#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")/.."
{ echo "# Every certified result. Generated FROM gate/certified.txt by"
  echo "# scripts/gen-required.sh, which is what this list can and cannot do."
  echo "#"
  echo "# CAN: the manifest gate requires every name here to still be certified,"
  echo "# so gate/certified.txt cannot be shrunk on its own and the orphaned"
  echo "# theorem then left unproved. An audit removed 38 names while an earlier,"
  echo "# partial required-list still passed; that is what this closes."
  echo "#"
  echo "# CANNOT: it is derived from the list it is checked against, so it is a"
  echo "# snapshot guard, not an independent source of truth. Regenerating both"
  echo "# together defeats it. CI reruns this script and diffs the committed file"
  echo "# (the 'Pinned files are regenerable' step), which catches hand-edits only."
  grep -vE '^#|^$' gate/certified.txt; } > gate/required.txt
echo "gate/required.txt: $(grep -cvE '^#|^$' gate/required.txt) required"
