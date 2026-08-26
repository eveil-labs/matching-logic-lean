# Basic matching logic in Lean 4

A mechanization of results from

> Xiaohong Chen and Grigore Roșu, *Completeness and incompleteness of basic
> matching logic*, [arXiv:2608.13306v1](https://arxiv.org/abs/2608.13306),
> 13 August 2026.

Section 10 of that paper proposes mechanizing its Corollary 15 as an open
challenge, in three entry points of increasing ambition:

> (i) mechanize Lemmas 9 and 11 alone. This consists of two five-case structural
> inductions, uses no fixpoints or canonical model, and captures the entire
> model-theoretic content of the paper. (ii) mechanize Corollary 15 with (L) and
> (S) assumed. […] (iii) discharge (L) as well, yielding a self-contained
> machine-checked global completeness theorem for matching logic.

The paper adds that, to its authors' knowledge, the definedness-free system it
studies has not been mechanized.

## Status

Everything below is proved with no `sorry`, and depends only on
`propext`, `Classical.choice`, `Quot.sound` — many on strictly fewer.
`gate/certified.txt` is the enforced list; `scripts/audit.sh` fails if any entry
acquires a `sorry` or any other axiom. The five variant refutations in
`variants/` are claimed too, and are enforced separately by
`scripts/audit-variants.sh`. **Nothing outside those two is claimed.** CI runs
every gate on every push.

[`CORRESPONDENCE.md`](CORRESPONDENCE.md) is a convenience index: for results
that have been mapped to the paper, it gives the Lean name and the axioms the
kernel reports. Membership and the axiom column are generated, and CI
regenerates and diffs the file.

**It is not an inventory of claims.** It omits definitions, supporting lemmas,
controls, and the variant refutations — all of which are certified — and it
carries rows marked BEYOND for results proved on top of the paper. The English
description in each row comes from the hand-maintained `gate/paper-map.tsv`,
which CI cannot check for faithfulness.

**The list of what is claimed is `gate/certified.txt`** (checked by
`scripts/audit.sh` and `scripts/audit-pinned.sh`), together with the five variant
refutations (checked by `scripts/audit-variants.sh`).

### Entry point (i) — complete

| Result | Lean |
|---|---|
| Lemma 9 (locality) | `locality` |
| Definition 10 (double cover) | `cover`, `coverInterp`, `proj` |
| Lemma 11 (two copies) | `two_copies`, `two_copies_set` |

### Entry point (ii), semantic half — complete

| Result | Lean |
|---|---|
| Definition 1 (three consequence relations) | `Model.Sat`, `LocalCons`, `GlobalCons` |
| Definitions 2–3 (coordinates, boxes, reachability) | `Coord`, `dia`, `box`, `boxes`, `Model.reachWord` |
| Lemma 4 (box semantics) | `denote_boxes` |
| Definition 6 (localization) | `localize` |
| Lemma 7 | `globalCons_of_localCons_localize` |
| Lemma 8 | `denoteSet_localize` and two companions |
| Corollary 12 | `cover_denote_closed`, `cover_sat_iff` |
| **Theorem 13 (semantic localization)** | **`semantic_localization`** |
| Section 6 (applicative matching logic) | `Applicative.*` |

### Entry point (ii), proof-theoretic half — complete

| Result | Lean |
|---|---|
| Figure 2 | `Provable` |
| Lemma 5 (necessitation) | `necessitation` |
| **(S) Soundness — proved, not assumed** | `soundness` |
| Theorem 14 (proof-theoretic localization) | `proof_theoretic_localization` |
| **Corollary 15 (global completeness)** | **`global_completeness`** |
| Corollary 15 with (S) discharged | `global_completeness_of_localCompleteness` |

(L) and (S) are `Prop` hypotheses, never Lean axioms, so the dependence stays
visible in the statement and the axiom gate stays meaningful. **(S) is
discharged**: every rule of Figure 2 is proved sound, so
`global_completeness_of_localCompleteness` needs only (L). That is entry
point (ii) in full, plus (S) discharged — which (ii) permitted us to assume, so
that is *beyond* (ii) rather than part of (iii). **Entry point (iii) asks for one
thing, discharging (L), and is not attempted.**

### Also complete

| Result | Lean |
|---|---|
| Corollary 16 (conservativity of definedness) — carries `(hL : StrongLocalCompleteness S Var)`, inherited from Corollary 15 | `definedness_conservative` |
| Remark 17 (free set variables do not come along) | `SetVariables.set_variable_is_not_a_constant` |
| Proposition 30, satisfiability and entailment | `Sorted.Γ3_satisfiable`, `Sorted.Γ3_entails_φ3` |

### Proposition 30 — complete

| Result | Lean |
|---|---|
| Γ is satisfiable | `Sorted.Γ3_satisfiable` |
| Γ ⊨ φ | `Sorted.Γ3_entails_φ3` |
| **Γ ⊬ φ** | **`Sorted.Γ3_not_derives_φ3`** |
| the sort-feeding induction | `Sorted.mprovable_empty_of_not_feeds` |
| Corollary 31, at this data | `Sorted.no_faithful_translation` |

So global completeness **holds for one sort and fails at three**, which is what
makes Corollary 15 sharp. The many-sorted Figure 2 is written out in full rather
than abstracted behind a sort-feeding hypothesis, since the paper's argument is
that Figure 2 *has* that property. Many-sorted soundness is a hypothesis, as the
paper treats it — it cites (S) at many sorts to [3, Thm. 13] — whereas our
one-sorted `soundness` is proved.

Corollary 31 is stated at the Proposition 30 data: it is the counterexample
instance, not the paper's general claim about all translations. A full rendering
would define a translation on the whole source language. This is flagged in the
docstring rather than filed as done.

### Not attempted

**(L)**, strong local completeness. The paper cites it to a canonical-model
construction in its references — correctly located at Theorem 3.7 of [4], not
Theorem 3.8; see `FINDINGS.md`. Discharging it is entry point
(iii) and means taking on the expensive construction the rest of the paper is
designed to avoid; we estimate several thousand lines.

**Theorem 19** (Section 7), validity not r.e. with fixpoints, which routes
through Hilbert's tenth problem.

## Beyond the paper

These are not in the paper. They exist because a mechanized theorem is worth
what it forbids.

**Hypotheses that are not needed.** `Closed φ` can be dropped from Theorem 13
and from Lemma 7. `M ⊨ Γ ⟺ M ⊨ Δ_Γ` needs no closedness at all — and, more
substantially, follows from Lemma 4 alone. The paper obtains it from Lemma 5
(necessitation) together with soundness, i.e. through the proof system.
**Consequently the entire semantic half of the argument, up to and including
Theorem 13, depends on neither black box (L) nor (S).**

**Hypotheses that are needed.** `Closed γ` for `γ ∈ Γ` cannot be dropped from
Theorem 13 (`semantic_localization_needs_closed_Γ`). Lemma 9's backward-closure
hypothesis cannot be dropped (`Necessity.lean`), and the countermodel is stated
at `ℕ` variables, the paper's own setting.

**Localizing is not decoration.** `Γ ⊨ φ ⟺ Γ ⊨loc φ` is *false* for closed `Γ`
and closed `φ` (`localize_not_redundant`), so Theorem 13's `Δ_Γ` is
load-bearing.

**Five neighbouring readings of the definitions, all refuted.** See
[`variants/RESULTS.md`](variants/RESULTS.md). Each is settled by a
kernel-checked countermodel, never by a failed proof attempt. Two are worth
singling out:

- **V1** is a control: the paper *predicts* that placing a constant's subset in
  one copy only breaks Lemma 11. It does, which is evidence our Definition 10 is
  sensitive exactly where the authors say it must be.
- **V5** is one the paper does not settle. It argues in prose that the generated
  submodel `C` alone will not serve once element variables and `∃` are present —
  that this is *why* Definition 10 doubles it — but gives no counterexample.
  Refuted: a closed pattern can detect the cardinality of the carrier, and
  passing from `M` to `C` changes it.

## Building

Lean 4.33.0 with Mathlib v4.33.0, pinned to a public tag.

```bash
lake exe cache get      # first run downloads Mathlib oleans: minutes, then seconds
lake build MatchingLogic
./scripts/audit-files.sh      # no sorry in files claimed complete
./scripts/audit.sh            # axiom gate over gate/certified.txt
./scripts/audit-variants.sh   # each variant settled, and settled honestly
./scripts/audit-pinned.sh     # every certified statement type and pinned definition body unchanged
./scripts/audit-manifest.sh   # the manifests those gates read have not been shrunk
./scripts/audit-coverage.sh   # Lean's own declaration list is fully pinned
./scripts/audit-axiom-decls.sh # no `axiom`, `opaque`, or private definition
```

## Layout

    MatchingLogic/Core.lean          syntax, models, denotation, backward closure
    MatchingLogic/Sanity.lean        controls on Core
    MatchingLogic/Locality.lean      Lemma 9
    MatchingLogic/DoubleCover.lean   Definition 10, Lemma 11
    MatchingLogic/Necessity.lean     Lemma 9's hypothesis is load-bearing
    MatchingLogic/Semantics.lean     free variables, closedness, Definition 1
    MatchingLogic/Boxes.lean         Definitions 2-3, Lemma 4
    MatchingLogic/BoxesControl.lean  controls on Definitions 2-3
    MatchingLogic/Localization.lean  Definition 6, Lemmas 7-8
    MatchingLogic/Composite.lean     Corollary 12, Theorem 13
    MatchingLogic/Independence.lean  which hypotheses do work
    MatchingLogic/Applicative.lean   Section 6
    MatchingLogic/ProofSystem.lean   Figure 2, Lemma 5, and the two black boxes
    MatchingLogic/Soundness.lean     (S), proved
    MatchingLogic/Completeness.lean  Theorem 14, Corollary 15
    MatchingLogic/EntryPoints.lean   Corollary 15 with (S) discharged
    MatchingLogic/Sorted.lean        many-sorted syntax, Proposition 30 (semantic)
    MatchingLogic/SortedProof.lean   many-sorted Figure 2, Proposition 30, Corollary 31
    MatchingLogic/Definedness.lean   Corollary 16
    MatchingLogic/SetVariables.lean  Remark 17
    variants/                        five neighbouring readings, all refuted
    alternates/                      the independent second proof of a target
    gate/                            the enforced lists the gates read
    scripts/                         the gates
    FINDINGS.md                      what the mechanization surfaced, for the authors
    CORRESPONDENCE.md                generated: paper result -> Lean name -> axioms

## Representation choices

1. **Named variables, and no syntactic substitution** outside rule (3) of
   Figure 2. Lemmas 9 and 11 and Theorem 13 are purely semantic: they speak only
   of valuation update `ρ[a/x]`. Capture-avoidance is therefore needed in
   exactly one place, where it is a *side condition* (`CaptureFree`) rather than
   a renaming — which keeps α-conversion out of the development.
2. **`Fin (arity σ) → Pattern` for symbol arguments**, giving a usable
   structural recursor: `denote` compiles via `brecOn` and its equation lemmas
   hold by `rfl`.
3. **Denotations as `Set M`**, classically.

`Var` is an arbitrary type with decidable equality rather than a fixed countably
infinite set. That is a generalization: instantiating at `ℕ` gives the paper's
setting, so a countermodel there would refute these statements too.

*If you build a concrete model, declare it as an `abbrev`.* `Model.carrier` is a
semireducible projection; with a `def` it will not unfold at `instances`
transparency and later `rw`s fail with a misleading "did not find an occurrence".

## How this is checked

Statements are pinned *before* any proof is attempted, so independent provers
cannot each drift toward a statement they find convenient. Definitions are
audited against the paper before proofs are commissioned — by several readers in
parallel, one of whom is asked not whether the definitions match the paper but
whether any pinned statement could be **true for the wrong reason**.

Every proof was verified rather than trusted. `scripts/audit-pinned.sh`
compares the kernel's own printing of every pinned statement **type** and
definition **body** against `gate/pinned-baseline.txt` — including
`Provable.rec`, which pins the *constructor set*, so no rule of Figure 2 can be
added or reshaped to make a target go through. You can run it yourself.

A type-level check would not be enough: the cheapest way to "prove" Lemma 11 is
to weaken Definition 10 so constants populate one copy only — which the paper
explicitly warns about, and which changes no type. Nor is the axiom gate enough:
`#print axioms` accepts any declaration, including a *definition* carrying a
theorem's name. Each gate was fire-tested against a deliberately broken tree, and
running each against real data found a defect in it.

Statements were pinned before proofs were attempted, results were proved twice in
different model families where `alternates/` shows it, and the development was
cross-checked on a second Lean service. Those are project records: the artifacts
behind them are not in this repository, so treat them as claims about how the
work was done rather than as something you can reproduce from what is here. The
gates, the baseline and `alternates/` you can check directly.

**What the gates do not protect against.** They read `gate/`, so a coordinated
edit that weakens something *and* regenerates the baseline is not detectable from
inside the repository. `scripts/audit-manifest.sh` raises the cost by requiring
the documented results to stay listed, but its list of required names is itself a
file in `gate/`. These gates defend against accident, drift, and a shortcut taken
somewhere in the development; they are **not** a defence against the
repository's own authors, and no in-repository check could be. The trust root for
that is review of the diff.

Every gate here was fire-tested by being attacked. **Nine rounds of adversarial
review broke earlier versions**, each by a route the previous round had not
considered:

1. swapping a certified theorem for `def X : True`;
2. replacing a variant refutation with an unrelated theorem of the same name;
3. shrinking the manifests, then leaving the orphaned theorem unproved;
4. changing an unpinned *definition*, so a theorem kept its type and its proof
   while its meaning moved — needing no access to `gate/` at all;
5. the same again, against definitions a hand-written pin list had omitted:
   `Pattern.or`, turning Figure 2's rule (6) into an identity, and `Srt3`,
   checking a "three-sort" theorem over four sorts;
6. a coverage check that shared the pin generator's regex, so it compared the
   generator against itself and reported "91 of 91" while a dozen names were
   unpinned;
7. the same check reporting "0/0 PASS" when its own enumeration failed — a
   check that cannot fail is not a check;
8. an `axiom` declaration, which every gate accepted because the pin list
   enumerated definitions and inductive types only; and a line-prefix filter in
   the variant gate that recorded 92 of the 144 lines the variants print, losing
   every theorem's type and every `@[reducible]` model definition;
9. **the repair of round eight, in four places.** Three of them were the same
   mistake — *identifying our own declarations by how their names are spelled*:
   an axiom outside the namespace, an axiom made `private` (whose real name
   begins `_private.`), and a coverage check comparing final name segments so
   that `Unpinned.soundness` was matched by the pin for `soundness`. The fourth
   was the round-eight defect one level up: the variant gate's *slice* had been
   fixed, but what it printed was still chosen by grepping for `theorem` and
   `def` at the start of a line, so a `lemma`, an `@[simp] theorem` or a
   `noncomputable def` was invisible.

**Nothing in these gates now identifies our own code by name.** Round nine is
the reason. `scripts/gen-pinned.sh` **asks Lean's environment** which
declarations exist, so the pin list cannot miss one because of how its name is
spelled — the failure the regex version had, which silently dropped every name
containing a dot or a Greek letter (`Model.Sat`, `AppCtx.plug`, `Γ3`). It
enumerates the environment under `MatchingLogic`, discards compiler-generated
names (recursors, `.injEq`, `.eq_def`, match and proof auxiliaries), and emits a
directive for every remaining **definition** (its body), **inductive type** (its
recursor's type), **theorem** and **axiom** (its type).

`scripts/audit-axiom-decls.sh` is what makes (L) and (S) hypotheses rather than
axioms, and it does not ask what anything is called. It asks Lean for every
declaration whose **declaring module** is one of ours — or which has no module,
meaning the file being compiled declared it — and rejects any `axiom`, any
`opaque`, and any private *definition*. Keying on the module rather than the
name is what closes round nine: an axiom at the root of a file, or a `private`
one, is still declared in `MatchingLogic.EntryPoints`. Every compilable file
this repository ships is scanned this way, `alternates/` included, since nothing
imports those. A line-oriented source grep runs as well, and is the weaker of
the two — a declaration written after `in` on a `set_option` line is invisible
to it, which is precisely why the kernel scan cannot be a name test.

Private *theorems* are permitted, and there are 32: a theorem's type is not part
of anything public, only its proof, and the kernel checks that. Private
*definitions* are not, because no pin list built from the environment can reach
one while it can still appear inside a public statement's type.

`scripts/audit-coverage.sh` checks coverage by the **opposite** method — it
reads the source text, tracking `namespace`, `section` and `end`, and requires
each declaration it finds to appear in the pin list **by fully qualified name**.
The two disagreeing in either direction is the signal. It currently reports
**205 of 205** public source-written declarations pinned, against 269 names in
the pin list, and fails if either scan comes back implausibly small. Since round
eight it counts the iterations of its own comparison loop and requires that
count to equal the number of declarations found; its predecessor read a
here-string, and with the here-string empty the loop ran zero times and it
printed "106/106 PASS" having compared nothing. Since round nine it compares
qualified names rather than final segments, sorts under `LC_ALL=C` — the
previous version dropped four declarations from its own expectation under
`en_US.UTF-8` and still reported success — and recognizes `instance`, `class`,
`partial` and `unsafe` declarations, five of which it had been blind to.

The variant gate pins a surface chosen the same way. `scripts/variant-common.sh`
asks Lean which declarations the variant file introduced and prints each one;
nothing is selected by line shape, in either the gate or the generator that
writes its baseline.

A green `lake build` is **not** evidence: the build succeeds with `sorry`s
present, emitting only warnings. That is why the gates above exist and why CI
runs them rather than grepping the build.

**Where the `sorry`s are.** Six, all deliberate and none reachable from any
claimed result: the five `vN_holds` stubs in `variants/` — the *refuted* side of
each prove-or-refute pair — and one in `alternates/V5SingleSheet.inhouse.lean`,
which is a second, independent proof of the same variant and carries the same
stub. `alternates/` is evidence, not part of the build; nothing imports it.

The development is also checked on an independent Lean service (AXLE) at
`lean-4.33.0`: zero errors and zero incomplete declarations across the library,
with the same axiom verdict.

## Attribution

The Lean was written by AI agents under direction — Claude Opus 5 and Sonnet 5,
and OpenAI `gpt-5.6-sol` — with an orchestrating session writing the definitions
and pinned statements, commissioning the proofs, and re-running every claim
rather than accepting an agent's report. Where a result was proved twice,
the two proofs came from different model families working in separate workspaces
with no sight of each other. Audits were run in a different family from the code
under audit wherever possible. Errors are ours.

## License

Apache 2.0, matching Mathlib, so the code here can be upstreamed without
friction.

**Exception.** The comments and docstrings quote passages of arXiv:2608.13306 —
definitions, lemma statements, and short proof sketches — to pin exactly what is
being formalized. Those passages remain the copyright of Xiaohong Chen and
Grigore Roșu, are included as scholarly quotation with attribution, and are not
covered by the Apache grant.
