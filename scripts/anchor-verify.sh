#!/usr/bin/env bash
# Check the statement surface against a digest published OUT OF BAND.
#
# WHAT THIS DOES AND DOES NOT DO. It does not make the anchors tamper-proof:
# anyone who can push can also publish a new anchor. What it removes is the
# QUIET path. Every other gate in this repository is regenerable -- a commit
# that weakens a definition and reruns the five generators passes all of them,
# because the baselines are rebuilt from the same tree they are meant to
# constrain. This check is the one that cannot be satisfied from inside the
# tree: the expected digest lives in an annotated, signed-where-possible git
# tag, so moving the statement surface requires deleting and re-publishing a
# tag that other people have already fetched. It converts a silent edit into a
# dated, attributable, visible act. That is the whole claim; do not read more
# into it.
set -uo pipefail
cd "$(dirname "$0")/.."

TAG="${ANCHOR_TAG:-statement-anchor}"

have=$(./scripts/anchor-digest.sh) || { echo "FAIL  could not compute the digest"; exit 1; }
have_sha=${have##*sha256=}

if ! git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
  echo "FAIL  no tag '$TAG' in this clone."
  echo "      CI must fetch tags (actions/checkout with fetch-depth: 0)."
  echo "      To publish the first anchor: ./scripts/anchor-publish.sh"
  exit 1
fi

# Read the tag OBJECT, not a file. An annotated tag's message is not part of
# the tree, so no generator can produce it.
msg=$(git for-each-ref --format='%(contents)' "refs/tags/$TAG")
want_sha=$(printf '%s\n' "$msg" | sed -n 's/^anchor-sha256: *//p' | head -1)

if [ -z "$want_sha" ]; then
  echo "FAIL  tag '$TAG' carries no 'anchor-sha256:' line"
  exit 1
fi

if [ "$have_sha" = "$want_sha" ]; then
  echo "ok    statement surface matches the anchor published at tag '$TAG'"
  echo "      $have"
  # Report signature status without requiring it: an unsigned anchor is still
  # dated and attributable, a signed one is also unforgeable.
  if git verify-tag "$TAG" >/dev/null 2>&1; then
    echo "      tag signature: verified"
  else
    echo "      tag signature: absent or unverifiable (anchor still binding)"
  fi
  exit 0
fi

echo "FAIL  the statement surface does not match the published anchor."
echo "      published at tag '$TAG': $want_sha"
echo "      computed from this tree: $have_sha"
echo
echo "      This is the intended behaviour when a claim changes. It is not a"
echo "      bug to be worked around by regenerating something. Either the"
echo "      change to what this library claims was unintended -- in which case"
echo "      revert it -- or it was intended, in which case publish a new anchor"
echo "      deliberately with ./scripts/anchor-publish.sh and say in the commit"
echo "      what claim moved and why."
echo
echo "      Files whose hash differs from the anchor cannot be listed here:"
echo "      the tag stores one digest, by design. Use git diff on gate/."
exit 1
