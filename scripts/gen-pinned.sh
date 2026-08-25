#!/usr/bin/env bash
# Regenerate gate/pinned.lean.
#
# The pin list is DERIVED FROM THE SOURCE, not hand-maintained. Five rounds of
# adversarial review broke earlier versions, twice by changing a definition that
# a hand-written list happened to omit -- `Pattern.or`, so that Figure 2's rule
# (6) became an identity, and `Srt3`, so that a "three-sort" theorem was checked
# over four sorts. Both left every gate green. A hand list converges on nothing;
# coverage has to be a property of the code.
#
# So: every def, abbrev, structure and inductive under MatchingLogic/ is pinned
# -- bodies for definitions, constructor sets for types -- plus the type of every
# certified statement.
set -uo pipefail
cd "$(dirname "$0")/.."
python3 scripts/gen_pinned.py > gate/pinned.lean
echo "gate/pinned.lean: $(grep -c '^#print' gate/pinned.lean) bodies, $(grep -cE '^#check @.*\.(rec|mk)$' gate/pinned.lean) constructor sets, $(grep -cE '^#check @' gate/pinned.lean) type checks total"
