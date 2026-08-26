# Variant readings — results

Every definition in a paper is under-determined by its prose. These five files
take *neighbouring* readings of the paper's definitions — ones a careful person
might also have chosen — and ask whether the paper's lemmas survive them.

**All five are refuted, each by a kernel-checked countermodel.** No reading here
was recorded as refuted on the strength of a failed proof attempt; `¬ VnClaim`
is proved in each case and passes `scripts/audit-variants.sh`.

| | Reading | Lemma tested | Verdict |
|---|---|---|---|
| **V1** | a constant's subset placed in **one copy only** | Lemma 11 | **REFUTED** |
| **V2** | mixed tuples **allowed** to produce values | Lemma 11 | **REFUTED** |
| **V3** | agreement weakened to "if `ρx ∈ C` then `ρx = ρ'x`" | Lemma 9 | **REFUTED** |
| **V4** | closure under the **reversed** step arrow | Lemma 9 | **REFUTED** |
| **V5** | the **single sheet** `N := C`, no second copy | Corollary 12 | **REFUTED** |

## V1 is the control, and it passed

The paper predicts this one. Immediately after Definition 10 it says the same
subset `σ_M ∩ C` must serve in both copies, because assigning it to one copy
only "would break Lemma 11 at ψ = σ for every constant with σ_M ∩ C ≠ ∅".

The refutation is exactly that: signature with one nullary `σ`, carrier `Bool`,
`σ_M = {false}`, `C = {false}`, `star = true`, pattern the bare constant `σ`,
tested at `p = (false, true)` — the copy the variant leaves empty. The
variant's cover side is false there; the `M` side is true.

This matters beyond V1. It is evidence that our encoding is *sensitive* at the
place the authors say it should be. Had `v1_holds` been provable instead, our
Definition 10 would have been blind to a distinction the paper says is
necessary, and the whole mechanization would have been in question.

## V2 — mixed tuples

Signature with one binary `σ`; carrier `Bool`; `σ_M(a₀,a₁) = {false}` iff both
arguments are `false`; `C = {false}`, `star = true`. Take `ψ = σ(x₀,x₁)` and
`ν(x₀) = (false,0)`, `ν(x₁) = (false,1)` — one variable per copy. At
`p = (false,0)` the variant's cover admits the mixed tuple, so the left side
holds; but `π₀` sends `x₁` to `star`, and `σ_M(false, true) = ∅`, so the right
side fails. The **left-to-right** direction of Lemma 11 is what breaks, and
arity ≥ 2 is essential — at arity 0 and 1 no tuple can be mixed.

The lane also proved a **control**: under the paper's own `cover`, both sides
are false at that point, so Lemma 11 is undisturbed. The failure is caused by
dropping unmixedness and by nothing else in the shared machinery.

## V3 — weakened agreement

Empty signature, carrier `Bool`, `C = {true}`, `ρ x = false`, `ρ' x = true`,
`ψ = x`. Weak agreement holds vacuously because `ρ x ∉ C`. But `ρ(ψ) ∩ C = ∅`
while `ρ'(ψ) ∩ C = {true}`. So Lemma 9's second disjunct — that when `ρx` leaves
`C`, `ρ'x` must leave it too — is load-bearing, and it is load-bearing already
at the variable case.

## V4 — reversed step arrow

Definition 2 runs the step from a symbol's **output** to its **argument**. This
variant closes `C` under the reverse arrow.

One unary `σ`; carrier `{0,1,2}`; `σ_N(2) = ∅` and `σ_N(a) = {0}` for `a ∈ {0,1}`;
`C = {0}`. Then `ψ = σ(x)` with `ρ ≡ 1`, `ρ' ≡ 2` separates the two sides at the
point `0`.

The lane rejected the obvious shortcut. `Necessity.lean`'s existing model is
also closed under the reversed step — but only **vacuously**, because there the
relevant interpretation is empty, so the hypothesis quantifies over nothing. A
refutation resting on that would be open to the objection that it satisfies the
variant's hypothesis only by emptiness. The model above satisfies it with the
condition genuinely firing, and that is the one carrying `v4_fails`.

## V5 — the second sheet is necessary

This is the one the paper does not settle. Section 4 argues in prose that the
generated submodel `C` alone will not serve once element variables and `∃` are
present — that this is *why* Definition 10 doubles `C` — but gives no
counterexample.

Both lanes that were given it, in different model families, refuted it, and
converged on the same mechanism: **a closed pattern can detect the cardinality
of the carrier**, and passing from `M` to `C` changes it.

Empty signature — so every subset is backward closed and the hypotheses cost
nothing. The two lanes chose different data, and **both files are in the
repository**, so check the one you are reading:

| file | `C` | `star` | `ψ` |
|---|---|---|---|
| `variants/V5SingleSheet.lean` (the gated one) | `{false}` | `true` | `∀x. x` |
| `alternates/V5SingleSheet.inhouse.lean` | `{true}` | `false` | `∀x. ∀y. (x → y)` |

Each `ψ` is total exactly on a one-element carrier. The single sheet has carrier
`↥C`, a singleton, so it satisfies `ψ`. But `⟦ψ⟧_M = ∅` because `M` has two
elements, so `C ⊆ ⟦ψ⟧_M` fails. Corollary 12's left-to-right direction breaks.

Both lanes also recorded the fix at the same data: the real cover `↥C × Bool`
has two elements, so by the proved `cover_sat_iff` it does **not** satisfy `ψ` —
it agrees with `M`, which is what Corollary 12 needs. The second sheet's whole
job, right here, is to restore an element the generated part had lost.

One lane added the observation that the direction which fails is precisely the
one Theorem 13 uses to transfer the local refutation of `φ`. A single-sheet `N`
would spuriously *satisfy* `φ`, and Theorem 13 would collapse at that step —
not at the `Γ` step.

## What this is for

Where a lemma fails under a neighbouring reading, that reading is excluded and
the authors' intent is pinned. Where it survives, the result is robust to the
choice. Five refutations mean these five neighbouring readings are excluded: each of
them breaks a lemma the paper states. That is weaker than saying the paper's
choices are the only ones that could work, which these countermodels do not
show.
