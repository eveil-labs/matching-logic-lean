# Independent second proofs

Each target was proved twice, by lanes in different model families working from
the same pinned statement in separate workspaces, with no visibility of each
other. The versions merged into `MatchingLogic/` are one of each pair; the other
member is kept here as the independent confirmation.

| Target | Merged | Kept here |
|---|---|---|
| Lemma 9 (`locality`) | in-house Sonnet 5 | codex `gpt-5.6-sol` (`Locality.codex.lean`) |
| Lemma 11 (`two_copies`) | codex `gpt-5.6-sol` | in-house Opus 5 (`DoubleCover.inhouse.lean`) |

Both members of each pair passed the same gates **at the time they were
written**: build clean, no `sorry` of their own, pinned statement types and
pinned definition bodies byte-identical to baseline as printed by the kernel,
and no edit outside the assigned file.

These files are not part of the build; they are evidence, and they have not been
maintained against later edits to `MatchingLogic/`. Concretely, as of now:

- `DoubleCover.inhouse.lean` **is** a drop-in: copy it over
  `MatchingLogic/DoubleCover.lean`, rebuild, and `scripts/audit-pinned.sh` and
  `scripts/audit.sh` both pass.
- `Locality.codex.lean` **is not**. It calls a certified helper
  `Model.app_inter_of_backwardClosed`, which the merged version names
  `Model.app_inter_backwardClosed`. Dropping it in leaves that certified name
  undefined, so `audit.sh`, `audit-pinned.sh` and `audit-coverage.sh` fail on a
  missing constant. The proof is what it claims to be; the file is not
  substitutable without renaming that one lemma.
- `V5SingleSheet.inhouse.lean` is not a drop-in for `variants/V5SingleSheet.lean`
  either — it is a self-contained second refutation with its own countermodel
  data (see `variants/RESULTS.md`), not a replacement.

All three compile standalone (`lake env lean alternates/<file>`), and
`scripts/audit-axiom-decls.sh` scans all three for `axiom`, `opaque` and private
definitions.

`V5SingleSheet.inhouse.lean` is a third: the in-house proof of the variant V5
refutation, whose merged counterpart came from the codex lane. Like the variant
files it carries the deliberate `v5_holds` stub — the refuted side — which is
the sixth `sorry` the README accounts for.
