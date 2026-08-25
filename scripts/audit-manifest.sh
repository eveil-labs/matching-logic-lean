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
# every library module must be claimed complete
for f in MatchingLogic/*.lean; do
  grep -qxF "$f" gate/complete-files.txt || { echo "FAIL  library module not claimed complete: $f"; fail=1; }
done
# every variant on disk must be listed for the variant gate
for f in variants/V*.lean; do
  grep -qF "$f" gate/variants-expected.tsv || { echo "FAIL  variant not listed: $f"; fail=1; }
done
n_cert=$(grep -cvE '^#|^$' gate/certified.txt)
n_var=$(grep -cvE '^#|^$' gate/variants-expected.tsv)
n_req=$(grep -cvE '^#|^$' gate/required.txt)
[ "$n_cert" -eq "$n_req" ] || { echo "FAIL  certified ($n_cert) and required ($n_req) disagree"; fail=1; }
[ "$n_var" -eq 5 ] || { echo "FAIL  expected 5 variants, found $n_var"; fail=1; }
echo "-- $n_cert certified, $n_var variants, $(ls MatchingLogic/*.lean | wc -l | tr -d ' ') modules --"
[ $fail -eq 0 ] && echo "== MANIFEST GATE PASS ==" || echo "== MANIFEST GATE FAIL =="
exit $fail
