/-
Lemma 9 (locality) of arXiv:2608.13306v1, Section 4.

  "Let ρ, ρ' : Var → M satisfy, for every x: either ρ(x) = ρ'(x) ∈ C, or
   ρ(x) ∉ C and ρ'(x) ∉ C.  Then ρ(ψ) ∩ C = ρ'(ψ) ∩ C for every pattern ψ."

Throughout, C is backward closed (Definition 2).

STATEMENT PINNED BEFORE ANY PROOF WAS ATTEMPTED -- a lane may add auxiliary lemmas above it and
must replace the `sorry`, but may NOT weaken, restate, or add hypotheses to
`locality` itself.
-/
import MatchingLogic.Core

namespace MatchingLogic

variable {S : Signature} {Var : Type} [DecidableEq Var]

/-- The agreement condition of Lemma 9: on `C` the two valuations coincide, and
off `C` they are both off `C`. -/
def AgreeOn {M : Model S} (C : Set M.carrier) (ρ ρ' : Var → M.carrier) : Prop :=
  ∀ x, (ρ x = ρ' x ∧ ρ x ∈ C) ∨ (ρ x ∉ C ∧ ρ' x ∉ C)

/-- Backward closure lets an application be computed after restricting every
argument set to `C`, as long as the result is also restricted to `C`. -/
theorem Model.app_inter_of_backwardClosed (M : Model S) {C : Set M.carrier}
    (hC : M.BackwardClosed C) (σ : S.Sym)
    (A : Fin (S.arity σ) → Set M.carrier) :
    M.app σ A ∩ C = M.app σ (fun i => A i ∩ C) ∩ C := by
  ext u
  constructor
  · rintro ⟨⟨a, ha, hu⟩, huC⟩
    exact ⟨⟨a, fun i => ⟨ha i, Model.BackwardClosed.mem_of_interp M hC huC hu i⟩, hu⟩, huC⟩
  · rintro ⟨⟨a, ha, hu⟩, huC⟩
    exact ⟨⟨a, fun i => (ha i).1, hu⟩, huC⟩

/-- Updating both valuations with the same value preserves agreement on `C`. -/
theorem AgreeOn.update {M : Model S} {C : Set M.carrier}
    {ρ ρ' : Var → M.carrier} (h : AgreeOn C ρ ρ') (x : Var)
    (a : M.carrier) :
    AgreeOn C (Function.update ρ x a) (Function.update ρ' x a) := by
  intro y
  by_cases hy : y = x
  · subst y
    by_cases ha : a ∈ C
    · exact Or.inl ⟨by simp, by simpa using ha⟩
    · exact Or.inr ⟨by simpa using ha, by simpa using ha⟩
  · simpa [Function.update, hy] using h y

/-- **Lemma 9 (locality).**  A backward-closed `C` together with one bit per
variable -- whether that variable's value lies in `C` -- determines truth on `C`. -/
theorem locality (M : Model S) {C : Set M.carrier} (hC : M.BackwardClosed C)
    (ψ : Pattern S Var) (ρ ρ' : Var → M.carrier) (h : AgreeOn C ρ ρ') :
    M.denote ρ ψ ∩ C = M.denote ρ' ψ ∩ C := by
  induction ψ generalizing ρ ρ' with
  | var x =>
      rcases h x with ⟨hEq, _hMem⟩ | ⟨hNotMem, hNotMem'⟩
      · simp [hEq]
      · simp [hNotMem, hNotMem']
  | app σ f ih =>
      simp only [denote_app]
      have hArgs :
          (fun i => M.denote ρ (f i) ∩ C) =
            (fun i => M.denote ρ' (f i) ∩ C) := by
        funext i
        exact ih i ρ ρ' h
      calc
        M.app σ (fun i => M.denote ρ (f i)) ∩ C =
            M.app σ (fun i => M.denote ρ (f i) ∩ C) ∩ C :=
          M.app_inter_of_backwardClosed hC σ _
        _ = M.app σ (fun i => M.denote ρ' (f i) ∩ C) ∩ C := by rw [hArgs]
        _ = M.app σ (fun i => M.denote ρ' (f i)) ∩ C :=
          (M.app_inter_of_backwardClosed hC σ _).symm
  | imp φ ψ ihφ ihψ =>
      apply Set.ext
      intro u
      by_cases huC : u ∈ C
      · have hφu : u ∈ M.denote ρ φ ↔ u ∈ M.denote ρ' φ := by
          have hu := Set.ext_iff.mp (ihφ ρ ρ' h) u
          simpa [huC] using hu
        have hψu : u ∈ M.denote ρ ψ ↔ u ∈ M.denote ρ' ψ := by
          have hu := Set.ext_iff.mp (ihψ ρ ρ' h) u
          simpa [huC] using hu
        simp [huC, hφu, hψu]
      · simp [huC]
  | bot => simp
  | ex x φ ih =>
      apply Set.ext
      intro u
      by_cases huC : u ∈ C
      · constructor
        · rintro ⟨hu, -⟩
          rcases Set.mem_iUnion.mp hu with ⟨a, hua⟩
          refine ⟨Set.mem_iUnion.mpr ⟨a, ?_⟩, huC⟩
          have huEq := Set.ext_iff.mp
            (ih (Function.update ρ x a) (Function.update ρ' x a) (h.update x a)) u
          have huIff :
              u ∈ M.denote (Function.update ρ x a) φ ↔
                u ∈ M.denote (Function.update ρ' x a) φ := by
            simpa [huC] using huEq
          exact huIff.mp hua
        · rintro ⟨hu, -⟩
          rcases Set.mem_iUnion.mp hu with ⟨a, hua⟩
          refine ⟨Set.mem_iUnion.mpr ⟨a, ?_⟩, huC⟩
          have huEq := Set.ext_iff.mp
            (ih (Function.update ρ x a) (Function.update ρ' x a) (h.update x a)) u
          have huIff :
              u ∈ M.denote (Function.update ρ x a) φ ↔
                u ∈ M.denote (Function.update ρ' x a) φ := by
            simpa [huC] using huEq
          exact huIff.mpr hua
      · simp [huC]

end MatchingLogic
