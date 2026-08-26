# Sourced by scripts/audit-variants.sh and scripts/gen-variants-baseline.sh.
#
# Both scripts must append the SAME commands and slice the SAME region out of
# Lean's output, or the gate compares one thing against a baseline that recorded
# another. They used to hold two copies of both, and round eight found a defect
# living in both copies at once.
#
# THE ROUND-EIGHT DEFECT. The old slice was a line-prefix filter: it kept a
# continuation line only if it began with `fun ` or two spaces. Round eight
# reported one consequence -- Lean prints `cmPt`'s body at column zero, starting
# with `(`, so only that definition's HEADER was recorded, and a reviewer moved
# V2's test point between copies and regenerated a baseline that did not change.
#
# Measured while repairing it, the hole was much larger: of the 144 lines the
# five variants print, the old slice recorded 92. The 52 it dropped included
# EVERY theorem's type in every variant -- so the comment below about a
# documented control not being replaceable by a proof of `True` described
# something the gate was not doing -- and every `@[reducible]` model definition
# the countermodels are built from. Adding an undocumented theorem to
# `V2MixedTuples.lean` passed the old gate and fails this one.
#
# The fix is to stop selecting lines by what they look like. `variant_decls`
# emits a sentinel and then the print block; `variant_surface` takes everything
# after the sentinel, whatever it looks like. Because the print block is the
# LAST thing appended in both scripts, "everything after the sentinel" is
# exactly the printed surface and nothing else.

VARIANT_SENTINEL='@@VARIANT-SURFACE@@'

# variant_decls <lean-file> <namespace> <n> -- the shared print block.
# Must be the LAST thing appended to the file under test.
variant_decls () {
  local f=$1 ns=$2 num=$3 t d
  echo "#eval IO.println \"${VARIANT_SENTINEL}\""
  # The claim itself. Refuting a claim weakened to `False` would be worthless.
  echo "#print MatchingLogic.$ns.V${num}Claim"
  # Every theorem in the file, so a documented control cannot be replaced by a
  # proof of `True` while the gate looks only at vN_fails.
  for t in $(grep -oE "^(private )?theorem [A-Za-z_][^ :({]*" "$f" | sed -E 's/^(private )?theorem //'); do
    echo "#check @MatchingLogic.$ns.$t"
  done
  # ...and every definition the claim is ABOUT. An audit changed a variant's own
  # definitions while the claim's type and text stayed identical, so the
  # refutation became a refutation of something else.
  for d in $(grep -oE "^(private )?(def|abbrev) [A-Za-z_][A-Za-z0-9_₀-₉'.]*" "$f" \
             | sed -E 's/^(private )?(def|abbrev) //'); do
    case "$d" in "V${num}Claim") continue ;; esac
    echo "#print MatchingLogic.$ns.$d"
  done
}

# variant_surface -- stdin is Lean's whole output; stdout is the pinned surface.
# Everything after the sentinel, with runs of spaces and blank lines collapsed
# so that re-indentation alone is not a diff. No line is dropped.
variant_surface () {
  sed -n "/^${VARIANT_SENTINEL}\$/,\$p" | tail -n +2 | tr -s ' \n' ' \n'
}
