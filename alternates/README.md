# Independent second proofs

Each target was proved twice, by lanes in different model families working from
the same pinned statement in separate workspaces, with no visibility of each
other. The versions merged into `MatchingLogic/` are one of each pair; the other
member is kept here as the independent confirmation.

| Target | Merged | Kept here |
|---|---|---|
| Lemma 9 (`locality`) | in-house Sonnet 5 | codex `gpt-5.6-sol` (`Locality.codex.lean`) |
| Lemma 11 (`two_copies`) | codex `gpt-5.6-sol` | in-house Opus 5 (`DoubleCover.inhouse.lean`) |

Both members of each pair passed the same desk checks: build clean, no `sorry`
of their own, pinned statement types and pinned definition bodies byte-identical
to baseline as printed by the kernel, and no edit outside the assigned file.

These files are not part of the build; they are evidence. To check one, drop it
over the corresponding file in `MatchingLogic/` and rebuild.
