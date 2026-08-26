#!/usr/bin/env bash
# Print the digest of this repository's STATEMENT SURFACE, and the listing it
# covers. Pure function of the working tree; writes nothing.
#
# The statement surface is every file that decides WHAT IS CLAIMED: the certified
# lists, the pin files and their kernel baselines, the paper map, and the variant
# baselines. Proof bodies are deliberately NOT in it -- a proof may be rewritten
# freely, and the kernel is what judges it. What must not move quietly is the
# set of statements those proofs are about.
#
# The file set is named in gate/anchor-manifest.txt, an explicit list rather
# than a glob: a glob silently covers less when a file is deleted. The manifest
# is itself digested, so shrinking it changes the digest. Count and identity are
# joined -- the listing carries both the number of files and each one's hash.
set -uo pipefail
cd "$(dirname "$0")/.."

MANIFEST=gate/anchor-manifest.txt
[ -f "$MANIFEST" ] || { echo "FAIL  no $MANIFEST" >&2; exit 2; }

listing=$(mktemp "${TMPDIR:-/tmp}/ml-anchor.XXXXXX") || exit 2
trap 'rm -f "$listing"' EXIT

# The manifest first, so that editing the manifest moves the digest.
printf 'MANIFEST %s\n' "$(shasum -a 256 "$MANIFEST" | cut -d' ' -f1)" >> "$listing"

n=0
while IFS= read -r f; do
  case "$f" in ''|\#*) continue ;; esac
  if [ ! -f "$f" ]; then
    echo "FAIL  $MANIFEST names '$f', which does not exist" >&2
    exit 2
  fi
  printf '%s  %s\n' "$(shasum -a 256 "$f" | cut -d' ' -f1)" "$f" >> "$listing"
  n=$((n + 1))
done < "$MANIFEST"

[ "$n" -gt 0 ] || { echo "FAIL  $MANIFEST names no files" >&2; exit 2; }

# The manifest must be COMPLETE, or a new anchor file could be introduced and
# left unanchored -- the digest would cover a set that no longer describes the
# surface. Every gate/ file of an anchored kind must be listed. This is the
# check that makes "explicit list, not a glob" safe rather than merely tidy.
missing=0
for f in gate/*.txt gate/*.lean gate/*.tsv; do
  [ -f "$f" ] || continue
  case "$f" in "$MANIFEST") continue ;; esac
  if ! grep -qxF "$f" "$MANIFEST"; then
    echo "FAIL  $f exists but is not named in $MANIFEST" >&2
    missing=$((missing + 1))
  fi
done
[ "$missing" -eq 0 ] || { echo "FAIL  $missing anchor-eligible file(s) unlisted" >&2; exit 2; }

# Sort so the digest does not depend on manifest ORDER, only on content and set.
sorted=$(LC_ALL=C sort "$listing")
digest=$(printf '%s\n' "$sorted" | shasum -a 256 | cut -d' ' -f1)

if [ "${1:-}" = "--listing" ]; then
  printf '%s\n' "$sorted"
fi
printf 'ANCHOR files=%s sha256=%s\n' "$n" "$digest"
