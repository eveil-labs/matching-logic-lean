/-
VARIANT 3 -- Lemma 9's agreement condition, weakened.

The paper's Lemma 9 requires, for every x, EITHER `ρ(x) = ρ'(x) ∈ C` OR both
`ρ(x) ∉ C` and `ρ'(x) ∉ C`. The second disjunct constrains ρ' even where ρ
leaves C.

This variant keeps only the first half of the condition -- "if ρ(x) is in C
then the two agree" -- and says nothing when ρ(x) is outside C. That is a
strictly weaker hypothesis, so Lemma 9 under it is a strictly stronger claim.
The question is whether the second disjunct is load-bearing.
-/
import MatchingLogic.Locality

namespace MatchingLogic
namespace VariantWeakAgree

variable {S : Signature} {Var : Type} [DecidableEq Var]

/-- The weakened agreement condition. -/
def AgreeOnWeak {M : Model S} (C : Set M.carrier) (ρ ρ' : Var → M.carrier) : Prop :=
  ∀ x, ρ x ∈ C → ρ x = ρ' x

def V3Claim : Prop :=
  ∀ (S : Signature) (Var : Type) (_ : DecidableEq Var) (M : Model S)
    (C : Set M.carrier) (_ : M.BackwardClosed C)
    (ψ : Pattern S Var) (ρ ρ' : Var → M.carrier),
      AgreeOnWeak C ρ ρ' → M.denote ρ ψ ∩ C = M.denote ρ' ψ ∩ C

theorem v3_holds : V3Claim := by sorry

theorem v3_fails : ¬ V3Claim := by
  intro h
  let S : Signature := {
    Sym := Empty
    arity := fun σ => nomatch σ
  }
  let M : Model S := {
    carrier := Bool
    nonempty := ⟨false⟩
    interp := fun σ => nomatch σ
  }
  let C : Set M.carrier := {true}
  have hC : M.BackwardClosed C := by
    intro u hu v hstep
    rcases hstep with ⟨σ, a, i, huσ, hv⟩
    exact nomatch σ
  let ρ : Unit → M.carrier := fun _ => false
  let ρ' : Unit → M.carrier := fun _ => true
  have hagree : AgreeOnWeak C ρ ρ' := by
    intro x hx
    simp [C, ρ] at hx
  have heq := h S Unit inferInstance M C hC (.var ()) ρ ρ' hagree
  simp [M, C, ρ, ρ'] at heq

end VariantWeakAgree
end MatchingLogic
