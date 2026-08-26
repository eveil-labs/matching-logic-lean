# Notes for the authors

Everything here came out of mechanizing the paper in Lean 4. Each item says what
we checked and how, so nothing has to be taken on trust. Where a claim is about
our development rather than the paper, it says so.

We are not proposing any of this as a correction to the mathematics. The one
item that is an actual erratum is a citation, item 1. Item 7 is the one we would
most like your view on: it does not correct anything, but it isolates the
hypothesis your `V → V⁺` extension supplies, shows it cannot be dropped even
from a theory that is already maximal, and suggests a strengthening of Lemma
3.22's side condition that costs nothing and turns an appeal to the α-quotient
into a derivation inside Figure 2.

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
counterexample. Here are two, proved independently in different model families.
`variants/V5SingleSheet.lean` takes the empty signature, carrier Bool,
C = {false}, star = true, and ψ = ∀x. x;
`alternates/V5SingleSheet.inhouse.lean` takes C = {true}, star = false, and
ψ = ∀x∀y.(x → y). In both, ψ is total exactly on a one-element carrier: the
single sheet is a singleton and satisfies ψ, but ⟦ψ⟧_M = ∅, so C ⊄ ⟦ψ⟧_M and
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

## 7. Isolating what the V → V⁺ extension supplies

This one came out of mechanizing (L) and is, we think, the most interesting
thing we can report. It is not a correction — nothing below says anything of
yours is wrong, and the one place we thought it did turned out to be our own
error. What it does is isolate the hypothesis your variable extension supplies,
and show it is load-bearing in a case the extension itself cannot repair.

**The setting.** Your Definition 3.5 asks that a witnessed MCS have, for each
`∃x.φ ∈ Γ`, *some* `y` with `(∃x.φ) → φ[y/x] ∈ Γ`. Lemma 3.22 then builds one,
choosing `y` from `V⁺ \ V` — a set of countably many *new* variables — subject
to it not occurring **free** in `Γₙ₋₁` and `ψ`. All of this is correct in your
setting, where α-equivalent patterns are identified and substitution renames
implicitly.

**And you already say why the extension is needed.** The paragraph above Lemma
3.22 gives the counterexample: `Γ = {¬x | x ∈ V}` is consistent and cannot be
extended to a witnessed MCS without new variables. Nothing below is news to you
on that point. What is different here is the target — not *witnessed* but a
strictly stronger condition — and the fact that the obstruction survives in a
form your extension does not reach.

Our formalization does not quotient: `Pattern` is raw named syntax. So we had to
carry a stronger invariant, `FreshWitnessed`, in which the witness avoids **all**
variables of the body, bound ones included. The natural question is whether that
strengthening is an artifact of our representation. It is not.

**1. The two conditions genuinely separate**
(`witnessed_freshWitnessed_of_isMCS_refuted`). There is a maximal locally
consistent set that is witnessed and not fresh-witnessed. The empty signature,
carrier `Bool`, valuation naming `true` by variable `0` and everything else by
`false`, and the complete theory of the point `true`. It is witnessed because
that valuation is surjective; it is not fresh-witnessed because `∃0. var 0` is
in it while `0` is the only name for `true` and `0` occurs in the body.
Maximality is discharged, not assumed.

**2. The separation is not an α artifact**
(`witnessed_alphaFreshWitnessed_of_isMCS_refuted`). Allowing the witness to be
fresh for *any* α-variant does not repair it. Over a signature with one binary
symbol, `∃1. pair(var 1, var 0)` blocks every representative, because the
application depends on both arguments and so has no vacuously quantified
equivalent to escape into. Quotienting by α would therefore not remove the need
for the stronger invariant.

**3. What does repair it is the supply of witnesses**
(`freshWitnessed_of_witnessed_of_supply`). If every existential in Γ has
*infinitely many* usable Henkin names, fresh-witnessedness follows immediately,
because the body has only finitely many variables. The proof is three lines. Its
value is that it identifies the mechanism: not α-equivalence, but the supply.

**4. And that is exactly what V → V⁺ provides.** We mechanized Lemma 3.22 at
your level of generality — arbitrary locally consistent sets, not just finite
lists — as `locConsistent_extend_freshWitnessed_isMCS`. Because our variables
are already all of `ℕ` and cannot be extended, the hypothesis appears explicitly
as `InfiniteFreshVariableSupply`: infinitely many names free in no member of Γ.
That is the raw-syntax translation of your extension step.

**5. The hypothesis is necessary**
(`locConsistent_extend_freshWitnessed_isMCS_unrestricted_refuted`). Drop it and
the statement is false. Feed the extension the witnessed-but-not-fresh MCS from
(1): it is already maximal, so any locally consistent extension equals it, so it
would have to be fresh-witnessed itself, which (1) refutes. Note the difference
from your `{¬x | x ∈ V}`: that set is consistent but not maximal, and the repair
is to add variables. Ours is *already an MCS*, so there is nothing left to add —
which is why the supply has to be a hypothesis on the starting theory rather
than a step in the construction.

**The concrete suggestion.** Lemma 3.22's side condition can be strengthened
from *does not occur free in* `Γₙ₋₁` *and* `ψ` to *does not occur in* them at
all, at no cost: your own justification — that only finitely many variables of
`V⁺ \ V` are in play at each stage — already delivers it.

What that buys is worth stating precisely, because our first attempt at this
sentence was wrong and our own development refutes it. It does **not** make the
α-renaming step unnecessary. `∃xᵢ.(ψ[xᵢ/x])` and `∃x.ψ` remain different raw
patterns whenever `xᵢ ≠ x`, and our mechanization of exactly this step
(`locConsistent_insert_captureAvoidingWitness`) assumes the strengthened
condition and still performs the renaming.

What changes is the *status* of that step. Under the weaker side condition the
identification `∃xᵢ.(ψ[xᵢ/x]) ≡ ∃x.ψ` is a meta-level appeal to the α-quotient.
Under the strengthened one the renaming is capture-free, and the implication
becomes **derivable inside your own proof system**, from rules (3) and (4) of
Figure 2 — we prove it as `Provable.alphaEx_forward`. So the construction
transfers to raw named syntax with α-conversion as a *derived rule* rather than
as a convention on the syntax. That is the whole content of the suggestion, and
we would be glad to know whether you think it is worth stating.

## 8. What is mechanized

Throughout: the paper's own fragment — one-sorted, definedness-free,
fixpoint-free — except where a result is explicitly about extending it.

**All three entry points of the Section 10 challenge** — (i), (ii), and (iii),
the last by the canonical-model construction in `MatchingLogic/EntryIII/` — plus
Corollary 16, the **counterexample of Remark 17**, and the **applicative
specialization of Section 6** (Remark 18's currying discussion is not
formalized). **One-sorted (S) is discharged rather than assumed** — every rule of
Figure 2 is proved sound — and **(L) is discharged too**, so Corollary 15 is
available with no black-box input at all at the source's variable scope; that is
`global_completeness_entryIII`. `global_completeness_of_localCompleteness`
remains stated with (L) as a hypothesis, because it holds for an arbitrary
element-variable type whereas the discharge is at a countably infinite one.
Proposition 30's many-sorted soundness input remains assumed, as in the paper.

See `CORRESPONDENCE.md`. It is a convenience index from a paper result to the
Lean name that carries it, with the axioms the kernel reports; membership and the
axiom column are generated. **It is not an inventory of claims and should not be
read as one** — it omits supporting lemmas, controls, definitions, and the
variant refutations, all of which are certified. `gate/certified.txt` is the
list of what is claimed.

Proposition 30 is complete, including the non-derivability half and Corollary 31
at that data. **(L) is discharged** — the canonical-model construction the rest
of the paper is designed to avoid is in `MatchingLogic/EntryIII/`, and
`global_completeness_entryIII` is Corollary 15 with both (L) and (S) supplied by
the development, at a countably infinite element-variable type.

---

## 9. Questions where we had to choose, and would rather you decided

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
| gates | `scripts/audit-manifest.sh`, `scripts/audit-files.sh`, `scripts/audit.sh`, `scripts/audit-variants.sh`, `scripts/audit-pinned.sh`, `scripts/audit-coverage.sh`, `scripts/audit-axiom-decls.sh`, `scripts/audit-entry-iii.sh` — all eight run in CI, alongside `lake exe axiom-audit` and `lake exe mk_all --check` |
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
never axioms. `scripts/audit-axiom-decls.sh` asks Lean for every declaration
whose declaring module is one of ours — or which has no module, meaning the file
being compiled declared it — and rejects any `axiom`, any `opaque`, and any
private definition, in the library, in each variant, and in each file under
`alternates/`. It identifies our declarations by module, never by name: before
round eight nothing checked this at all and an `axiom` passed every gate, and
the first repair still let one through when it was written outside the namespace
or marked `private`, because it tested the name.

There are six `sorry`s, all deliberate and none reachable from any claimed
result: the five `vN_holds` stubs in `variants/`, which are the *refuted* side of
each prove-or-refute pair, and one in `alternates/V5SingleSheet.inhouse.lean`,
a second independent proof of the same variant carrying the same stub.
`alternates/` is evidence and is not part of the build.

## What we did not look at

Sections 7 and 9 are not mechanized. Theorem 19 routes through Hilbert's tenth
problem, which is a project of its own — though the pattern this development
already uses would apply: carry H10 as a `Prop` hypothesis, prove Theorem 19
around it, and discharge it separately, exactly as (L) was carried and then
discharged. Section 9's obstruction theorem is formalizable and we simply did
not get to it.

**(L) is no longer among these.** It is discharged — see
`MatchingLogic/EntryIII/` and `ENTRY-III-COMPLETION.md` — at the source's
variable scope, a countably infinite element-variable type. We had estimated
three to four thousand lines from reading Theorem 3.7 of [4]; the construction
came to 6,616 lines in 30 modules, dominated as expected by the n-ary Existence
Lemma. (`MatchingLogic/EntryIII/` also holds a further 941 lines in three
modules that are *not* part of the construction: they are the separation results
described below.) Nothing existing
transferred: the closest mechanized completeness proof for a neighbouring logic
uses nominals as its Henkin witnesses, and this fragment has none.

Two things in that construction are worth your attention, because they are
places where the raw formalization had to say more than the paper does.

*Fresh witnesses on raw names.* The Lean syntax does not quotient patterns by
α-equivalence, and a witness name merely absent from the free variables of an
existential body can still collide with a binder inside it. The paper renames
binders silently when substituting, so the collision cannot be ignored on raw
names. Canonical points therefore carry a stronger invariant, `FreshWitnessed`,
demanding a witness avoiding *all* variables of the body rather than only its
free ones. This is not an extra assumption: the finite Henkin extension proves
every locally consistent finite list extends to an MCS satisfying it.

*Arbitrary symbol sets without countability.* The canonical construction wants a
countable pattern type, and the paper permits an arbitrary finitary symbol set.
Rather than assume countability, each finite countertheory is moved to the
finite sub-signature its premises generate, the model is built there, and it is
extended back to the ambient signature by interpreting the absent symbols as
empty. So no finiteness or countability hypothesis is imposed on `S.Sym`.

