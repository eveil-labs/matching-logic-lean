# Variant readings

A definition is under-determined by prose. These files take deliberately
*different* plausible readings of the paper's definitions and ask whether the
paper's lemmas survive them.

Each file pins a variant definition and two mutually exclusive targets:

    def   VnClaim : Prop := <the paper's lemma, stated for the variant>
    theorem vn_holds : VnClaim   := sorry   -- prove this, OR
    theorem vn_fails : ¬ VnClaim := sorry   -- prove this

Exactly one is expected to land. **Failing to find a proof is not a
refutation**: a variant is recorded as refuted only when `¬ VnClaim` is proved
and passes the axiom gate. `INCONCLUSIVE` is a real and reportable outcome.

The point is not to improve the development. It is to establish which readings
the paper's results actually depend on, so that the discrimination can be shown
to the authors: where a lemma fails under a neighbouring reading, that reading
is excluded and the paper's intent is pinned; where it survives, the result is
robust to that choice.

`V1` is the control. The paper predicts its outcome in so many words: the same
subset `σ_M ∩ C` must serve in both copies, because "assigning the subset to
only one copy would break Lemma 11 at ψ = σ for every constant with
σ_M ∩ C ≠ ∅". If our encoding is faithful, `V1` must be refutable — and if it
is not, our encoding is insensitive somewhere it should not be.
