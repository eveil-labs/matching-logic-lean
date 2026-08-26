# Notes for the authors

Everything here came out of mechanizing the paper in Lean 4. Each item says what
we checked and how, so nothing has to be taken on trust. Where a claim is about
our development rather than the paper, it says so.

We are not proposing any of this as a correction to the mathematics. The one
item that is an actual erratum is a citation, item 1.

---

## 1. A citation slip: (L) is Theorem 3.7, not Theorem 3.8

Section 2 states

> **(L) Strong local completeness.** If Δ ⊨loc φ then ⊢ (⋀Δ₀) → φ for some
> finite Δ₀ ⊆ Δ.

and then says

> (L) is Definition 3.3 and **Theorem 3.8** of [4] and is also proved in [5].

Definition 3.3 is right. The theorem number is not. In the thesis [4], p. 68-69:

- **Theorem 3.7.** "For any Γ and φ, Γ ⊨loc φ implies Γ ⊢loc_H φ."
- **Theorem 3.8.** "For any φ, ∅ ⊨ φ implies ∅ ⊢_H φ."

(thesis pp. 68–69, `https://xchen.page/assets/thesis.pdf`), and immediately
after Theorem 3.8:

> "In the literature, both Theorem 3.7 and Theorem 3.8 are called local
> completeness. To distinguish them, Theorem 3.7 is called **strong** local
> completeness while Theorem 3.8 is called **weak** local completeness."

So (L), which the paper itself labels *strong*, is Theorem 3.7. Theorem 3.8 is
the empty-theory case that the same paragraph goes on to describe separately
("In [3], it yields Theorem 16, the weak completeness statement"). In the technical report [5]
(`https://fsl.cs.illinois.edu/publications/chen-rosu-2019-tr.pdf`) the
corresponding numbers are **Theorem 83 (strong)** and **Theorem 16 (weak)** —
and the paper already cites Theorem 16 correctly, in the same paragraph, as the
weak statement.

*Checked by downloading the thesis and reading pp. 68-69 directly.*

---

## 2. Theorem 13 does not depend on (L) or (S)

Lemma 7's proof obtains `M ⊨ Γ iff M ⊨ Δ_Γ` from Lemma 5 (necessitation)
together with soundness — that is, through the proof system. The same
equivalence follows semantically from Lemma 4 alone: if `γ` is total then
`⟦[p]γ⟧ = {u | ⇝_p[u] ⊆ ⟦γ⟧}` is everything.

Consequently the whole semantic half of the argument — Lemmas 7 and 8,
Corollary 12, and **Theorem 13** — needs neither black box.

In our development this is enforced by the module graph rather than merely
observed: `ProofSystem.lean` imports `Composite.lean`, not the other way round,
so `semantic_localization` *cannot* depend on anything proof-theoretic. Theorem 13
is proved before the proof system exists.

`satSet_localize_iff_general`, `Independence.lean`.

---

## 3. Which hypotheses are doing work

- **`Closed φ` is not needed**, in Theorem 13 or in Lemma 7. Both hold for an
  arbitrary, possibly open conclusion. (`semantic_localization_of_closed_Γ`,
  `globalCons_of_localCons_localize_general`.)
- **`Closed γ` for γ ∈ Γ is needed** in Theorem 13, and the countermodel is
  small: over the empty signature, Γ = {x} forces the carrier to be a singleton
  through the valuation quantifier hidden in totality, which localization cannot
  see. (`semantic_localization_needs_closed_Γ`.)
- **Lemma 9's backward-closure hypothesis is needed**, on a three-element model.
  `M \ C` must have two points, since `AgreeOn` forces `ρ = ρ'` when the common
  value lies in `C`. (`Necessity.lean`, stated at ℕ variables.)

---

## 4. Localizing is not a convenience

`Γ ⊨ φ ⟺ Γ ⊨loc φ` is **false** for closed Γ and closed φ, so the `Δ_Γ` in
Theorem 13 is load-bearing rather than a normalization. Two unary symbols
suffice. (`localize_not_redundant`.)

---

## 5. Five neighbouring readings of the definitions, all refuted

Prose under-determines definitions, so we took neighbouring readings and asked
whether the paper's lemmas survive. Each is settled by a kernel-checked
countermodel, never by a failed proof attempt.

| Reading | Lemma | Verdict |
|---|---|---|
| a constant's subset in one copy only | 11 | refuted |
| mixed tuples allowed to produce values | 11 | refuted |
| agreement weakened to "if ρx ∈ C then ρx = ρ'x" | 9 | refuted |
| closure under the reversed step arrow | 9 | refuted |
| the single sheet `N := C` | Cor. 12 | refuted |

Two are worth singling out.

**The first is your own prediction, and it holds.** Section 4 says assigning a
constant's subset to one copy only "would break Lemma 11 at ψ = σ for every
constant with σ_M ∩ C ≠ ∅". It does. We used this as a control on ourselves: had
it turned out provable, our Definition 10 would have been blind to a distinction
you say matters.

**The last is one the paper argues but does not prove.** Section 4 explains that
the generated submodel C alone will not serve once element variables and ∃ are
present — that this is *why* Definition 10 doubles it — without giving a
counterexample. Here is one. Over the empty signature with C = {true} ⊆ Bool,
take ψ = ∀x∀y.(x → y), which is total exactly on a one-element carrier. The
single sheet is a singleton and satisfies ψ; but ⟦ψ⟧_M = ∅, so C ⊄ ⟦ψ⟧_M and
Corollary 12 fails left-to-right. The double cover has two elements and agrees
with M, which is what Corollary 12 needs. The mechanism is that **a closed
pattern can detect the cardinality of the carrier**, and passing from M to C
changes it.

Note the direction that fails is the one Theorem 13 uses to transfer the local
refutation of φ. A single-sheet N would spuriously *satisfy* φ, so Theorem 13
would collapse at that step rather than at the Γ step.

`variants/RESULTS.md`.

---

## 6. Lemma 4 needs no closedness hypothesis

Stated for closed ψ because both sides are written with `⟦·⟧`. With the
valuation carried explicitly on both sides it holds for arbitrary ψ, because
boxing is binder-free: `FV([p]ψ) = FV ψ`. (`denote_boxes`, `FV_boxes`.)

---

## 7. What is mechanized

Throughout: the paper's own fragment — one-sorted, definedness-free,
fixpoint-free — except where a result is explicitly about extending it.

Entry point (i) and entry point (ii) of the Section 10 challenge, plus
Corollary 16, the **counterexample of Remark 17**, and the **applicative
specialization of Section 6** (Remark 18's currying discussion is not
formalized). **One-sorted (S) is discharged rather than assumed** — every rule of
Figure 2 is proved sound — so Corollary 15 is available with (L) as the only
remaining black-box input. Proposition 30's many-sorted soundness input remains
assumed, as in the paper.

See `CORRESPONDENCE.md`. It is a convenience index from a paper result to the
Lean name that carries it, with the axioms the kernel reports; membership and the
axiom column are generated. **It is not an inventory of claims and should not be
read as one** — it omits supporting lemmas, controls, definitions, and the
variant refutations, all of which are certified. `gate/certified.txt` is the
list of what is claimed.

Proposition 30 is complete, including the non-derivability half and Corollary 31
at that data. (L) is not attempted; we estimate discharging it at several
thousand lines, since it is the canonical-model construction that the rest of the
paper is designed to avoid.

---

## 8. Questions where we had to choose, and would rather you decided

Mechanizing forces a reading of things prose leaves open. For the definitional
ones below we picked a reading and checked it does not break your lemmas — and
for some, checked that the alternatives do. Items 3, 4 and 6 are not of that
kind: they are places where we narrowed the statement, or where we may simply be
wrong. In every case the choice is yours, and we would like to correct anything
we have misread.

1. **Definition 10's constant clause.** We encoded unmixedness uniformly, as
   `∀ j, (A j).2 = p.2`, which is vacuously true at arity `0` and therefore
   populates *both* copies for a constant — matching your sentence that "the
   same subset `σ_M ∩ C` serves in both copies". Is the uniform clause the
   intended reading, or do you think of the constant case as a separate
   stipulation? (We checked the alternative breaks Lemma 11, as you predict.)

2. **Application contexts.** We read `C ::= □ | σ(φ₁,…,C,…,φₙ)` as: a symbol, a
   position, the *full* argument tuple, and a subcontext, with the hole
   overriding that position. Is that the intended grammar, or should the other
   arguments be a separate list excluding the hole position?

3. **Corollary 31.** We proved it at the Proposition 30 data — no target
   signature and pair of translations works for that Γ and φ. Your statement is
   general: no translation *at all* preserves global consequence and reflects
   derivability. To render that we would need a notion of translation on the
   whole source language. Should it be an arbitrary function on patterns, or
   compositional/homomorphic in the symbols? The choice changes what the theorem
   says.

4. **Many-sorted (S).** We take it as a hypothesis, as you do. Ours quantifies
   only over theories all of whose members share a sort, which is what
   Proposition 30 needs. Is [3, Thm. 13] stated for heterogeneous theories, and
   should we widen ours to match?

5. **The closedness conventions.** You assume Γ and φ closed throughout, without
   loss of generality. We found `Closed φ` is never needed and `Closed γ` is,
   with the countermodel in item 3 above. Would you want the paper's statements
   as they stand, or the sharper ones?

6. **The erratum in item 1.** Please confirm — we may have misread the
   numbering in a revision of [4] different from the one we downloaded.

---

## Reproducibility

| | |
|---|---|
| commit | see `git log` |
| toolchain | Lean 4.33.0 |
| Mathlib | pinned to the public tag `v4.33.0` |
| build | `lake exe cache get && lake build MatchingLogic` — about 90 s from a clean clone |
| gates | `scripts/audit-manifest.sh`, `scripts/audit-files.sh`, `scripts/audit.sh`, `scripts/audit-variants.sh`, `scripts/audit-pinned.sh`, `scripts/audit-coverage.sh`, `scripts/audit-axiom-decls.sh` — all seven run in CI |
| independent check | the `MatchingLogic` library also compiles on a second Lean service at `lean-4.33.0`: 0 errors, 0 incomplete declarations, same axiom verdict. The deliberate stubs in `variants/` and `alternates/` are outside that library. |

`CORRESPONDENCE.md` lists each result that is **mapped to the paper** against
its Lean name and the axioms the kernel reports; membership and the axiom column
are generated. It is not the full inventory: supporting lemmas and controls are
certified without appearing in it. **The full list of what is claimed is
`gate/certified.txt`** (checked by `scripts/audit.sh`), together with the five
variant refutations (checked by `scripts/audit-variants.sh`), and
`scripts/audit-manifest.sh` checks that neither list has been shrunk.
`gate/required.txt` is **generated from `gate/certified.txt`** by
`scripts/gen-required.sh`, so it is a snapshot guard and not an independent
source of truth: it stops `gate/certified.txt` being shrunk on its own, and it
does not stop the two being regenerated together.

The hypotheses (L) and (S) are `Prop` arguments of the theorems that use them,
never axioms; `scripts/audit-axiom-decls.sh` fails if any `axiom` or `opaque`
declaration exists under `MatchingLogic/` or `variants/`. Before round eight
nothing checked this, and an `axiom` passed every gate.

There are six `sorry`s, all deliberate and none reachable from any claimed
result: the five `vN_holds` stubs in `variants/`, which are the *refuted* side of
each prove-or-refute pair, and one in `alternates/V5SingleSheet.inhouse.lean`,
a second independent proof of the same variant carrying the same stub.
`alternates/` is evidence and is not part of the build.

## What we did not look at

Sections 7 and 9 are not mechanized. Theorem 19 routes through Hilbert's tenth
problem, which is a project of its own. Section 9's obstruction theorem is
formalizable and we simply did not get to it.

We also did not attempt (L). Having read the proof — Theorem 3.7 of [4],
pp. 58–69 — we estimate three to four thousand lines of Lean, dominated by the
n-ary Existence Lemma. Nothing existing transfers: the closest mechanized
completeness proof for a neighbouring logic uses nominals as its Henkin
witnesses, and this fragment has none.

