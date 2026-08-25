/-
VARIANT 1 (the control) -- Definition 10 with a constant's subset placed in one
copy only.

The paper, Section 4, immediately after Definition 10:

  "The same subset σ_M ∩ C serves in both copies, vacuously when it is empty.
   This symmetry is necessary because assigning the subset to only one copy
   would break Lemma 11 at ψ = σ for every constant with σ_M ∩ C ≠ ∅."

So the paper PREDICTS that `V1Claim` is false. Proving `v1_fails` reproduces a
failure the authors assert, and is therefore a check on whether our encoding is
sensitive where they say it should be.
-/
import MatchingLogic.DoubleCover

namespace MatchingLogic
namespace VariantOneCopy

variable {S : Signature} {Var : Type} [DecidableEq Var]

/-- Definition 10's interpretation, altered so that a CONSTANT (arity `0`) is
placed in copy `false` only. Positive arities are untouched. -/
def coverInterp₁ (M : Model S) (C : Set M.carrier)
    (σ : S.Sym) (A : Fin (S.arity σ) → (C × Bool)) : Set (C × Bool) :=
  {p | (∀ j, (A j).2 = p.2) ∧ (S.arity σ = 0 → p.2 = false) ∧
       ((p.1 : M.carrier) ∈ M.interp σ (fun j => ((A j).1 : M.carrier)))}

def cover₁ (M : Model S) (C : Set M.carrier) (hne : C.Nonempty) : Model S where
  carrier := C × Bool
  nonempty := ⟨(⟨hne.choose, hne.choose_spec⟩, false)⟩
  interp := coverInterp₁ M C

/-- Lemma 11, stated for the variant cover. -/
def V1Claim : Prop :=
  ∀ (S : Signature) (Var : Type) (_ : DecidableEq Var) (M : Model S)
    (C : Set M.carrier) (_ : M.BackwardClosed C) (hne : C.Nonempty)
    (star : M.carrier) (_ : star ∉ C)
    (ψ : Pattern S Var) (ν : Var → (C × Bool)) (p : C × Bool),
      p ∈ (cover₁ M C hne).denote ν ψ ↔
        (p.1 : M.carrier) ∈ M.denote (fun x => proj M C star p.2 (ν x)) ψ

theorem v1_holds : V1Claim := by sorry

theorem v1_fails : ¬ V1Claim := by
  intro h
  let S₀ : Signature :=
    { Sym := Unit
      arity := fun _ => 0 }
  let M₀ : Model S₀ :=
    { carrier := Bool
      nonempty := inferInstance
      interp := fun _ _ => {false} }
  let C₀ : Set M₀.carrier := {false}
  have hC₀ : M₀.BackwardClosed C₀ := by
    intro u hu v hv
    obtain ⟨σ, a, i, hi, rfl⟩ := hv
    exact Fin.elim0 i
  have hne₀ : C₀.Nonempty := ⟨false, rfl⟩
  have hstar₀ : true ∉ C₀ := by
    simp [C₀]
  let ψ₀ : Pattern S₀ Unit := .app () (fun i => Fin.elim0 i)
  let ν₀ : Unit → (C₀ × Bool) := fun _ => (⟨false, rfl⟩, false)
  let p₀ : C₀ × Bool := (⟨false, rfl⟩, true)
  have hiff := h S₀ Unit inferInstance M₀ C₀ hC₀ hne₀ true hstar₀ ψ₀ ν₀ p₀
  have hrhs :
      (p₀.1 : M₀.carrier) ∈
        M₀.denote (fun x => proj M₀ C₀ true p₀.2 (ν₀ x)) ψ₀ := by
    simp [ψ₀, Model.denote, Model.app, M₀, S₀, p₀]
  have hp := hiff.mpr hrhs
  simp only [ψ₀, Model.denote, Model.app, cover₁, coverInterp₁] at hp
  obtain ⟨A, hA, hmix, hcopy, hinterp⟩ := hp
  have : p₀.2 = false := hcopy (by simp [S₀])
  simp [p₀] at this

end VariantOneCopy
end MatchingLogic

#print axioms MatchingLogic.VariantOneCopy.v1_fails
