#!/usr/bin/env bash
# Publish the current statement surface as the anchor. Deliberate act only.
set -uo pipefail
cd "$(dirname "$0")/.."

TAG="${ANCHOR_TAG:-statement-anchor}"
have=$(./scripts/anchor-digest.sh) || exit 1
sha=${have##*sha256=}

if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
  old=$(git for-each-ref --format='%(contents)' "refs/tags/$TAG" | sed -n 's/^anchor-sha256: *//p' | head -1)
  if [ "$old" = "$sha" ]; then
    echo "ok    anchor '$TAG' already records this statement surface; nothing to do"
    exit 0
  fi
  echo "The anchor '$TAG' already exists and records a DIFFERENT statement surface."
  echo "  published: $old"
  echo "  current:   $sha"
  echo
  echo "Re-publishing replaces a tag other people may already have fetched."
  echo "That is the cost of moving a claim, and it is meant to be paid visibly."
  echo "If you mean it:"
  echo "  git tag -d $TAG && git push origin :refs/tags/$TAG"
  echo "  ./scripts/anchor-publish.sh && git push origin refs/tags/$TAG"
  exit 1
fi

msg="Statement anchor for eveil-labs/matching-logic-lean

anchor-sha256: $sha
$have

This tag pins what this library CLAIMS, not how it proves it. The digest covers
every file named in gate/anchor-manifest.txt: the certified lists, the pin files
and their kernel baselines, the paper map, and the variant baselines. Proof
bodies are excluded on purpose -- the kernel judges those.

scripts/anchor-verify.sh recomputes the digest and compares it to this message.
Every other gate in the repository is regenerable from the tree it constrains;
this one is not, because a tag object is not part of any tree. Changing what is
claimed therefore requires deleting and re-publishing this tag in public."

if git tag -s -m "$msg" "$TAG" 2>/dev/null; then
  echo "ok    published SIGNED anchor tag '$TAG'"
else
  git tag -a -m "$msg" "$TAG" || { echo "FAIL  could not create tag"; exit 1; }
  echo "ok    published annotated anchor tag '$TAG' (unsigned: no GPG key configured)"
fi
echo "      $have"
echo "      push it: git push origin refs/tags/$TAG"
