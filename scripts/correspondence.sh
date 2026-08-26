#!/usr/bin/env bash
# Generate the paper-to-Lean correspondence table from the CERTIFIED list and
# the kernel's own axiom output. Nothing here is hand-typed: a result appears
# only if it is in gate/certified.txt AND the kernel reports its axioms.
set -uo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.elan/bin:$PATH"
TD=$(mktemp -d); trap 'rm -rf "$TD"' EXIT
GEN="$TD/corr.lean"
echo "import MatchingLogic" > "$GEN"
grep -vE '^#|^$' gate/certified.txt | while read -r n; do echo "#print axioms $n"; done >> "$GEN"
OUT=$(lake env lean "$GEN" 2>&1) || {
  echo "correspondence: lean failed to elaborate the certified list" >&2
  printf '%s\n' "$OUT" >&2
  exit 1
}


# `#print axioms` WRAPS. The kernel breaks a long axiom list across physical
# lines, and reading only the first line stops at "[propext," -- so a forbidden
# axiom on a continuation line is invisible. Measured on this tree: 33 of the
# 369 certified names wrap. `scripts/audit-entry-iii.sh` found and repaired this
# for its own gate; the repair was never carried here until round ten said so.
#
# Emit the whole stanza for $1, joined onto one line.
axiom_stanza () {
  # The name must be followed by a SPACE: `denote_rho` is a prefix of
  # `denote_rho'`, and a prefix test swallowed the following stanza --
  # caught by running this against the real 369-name output, not a sample.
  # The quote character is passed in as a variable so the awk program itself
  # contains none, which is what the shell quoting requires.
  awk -v want="'$1'" -v q="'" '
    substr($0, 1, length(want) + 1) == want " " { inb = 1 }
    inb {
      if (started && substr($0, 1, 1) == q) exit
      gsub(/^[[:space:]]+|[[:space:]]+$/, "")
      if (started) printf " "
      printf "%s", $0
      started = 1
    }
    END { if (started) print "" }
  '
}

# The table body goes to a temp file first (not a $(...) capture: bash 3.2
# cannot parse a case statement inside command substitution) so the row count
# can be asserted before anything is emitted.
BODY="$TD/body"
grep -vE '^#|^$' gate/paper-map.tsv | while IFS=$'\t' read -r name paper _sec; do
  line=$(printf '%s\n' "$OUT" | axiom_stanza "$name")
  [ -z "$line" ] && continue                      # not certified yet: omit, never guess
  case "$line" in
    *"does not depend on any axioms"*) ax="none" ;;
    *) ax=$(printf '%s' "${line#*axioms: }" | tr -d '[]') ;;
  esac
  printf '| %s | `%s` | %s |\n' "$paper" "$name" "$ax"
done > "$BODY"

# An uncertified or misspelled paper-map name would be silently OMITTED above
# (the committed-file diff in CI is the only thing that would notice). Fail
# loudly here instead: every paper-map row must have produced a table row.
expected=$(grep -cvE '^#|^$' gate/paper-map.tsv)
rows=$(grep -c '^|' "$BODY")
# `-eq ... ||` rather than `-ne ... then`: if $expected is EMPTY (paper-map
# missing or unreadable), the test itself errors, and that must fail the gate
# too, not slide through an if that treats a test error as false.
[ "$rows" -eq "$expected" ] 2>/dev/null || {
  echo "correspondence: emitted $rows rows for ${expected:-unreadable} paper-map entries" >&2
  exit 1
}

printf '| Paper result | Lean | Axioms |\n|---|---|---|\n'
cat "$BODY"
