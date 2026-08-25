/-
VARIANT 2 -- Definition 10 with mixed tuples ALLOWED.

Definition 10 reads

  σ_N((a₁,i₁), …, (aₙ,iₙ)) := (σ_M(a₁,…,aₙ) ∩ C) × {i}  if i₁ = ⋯ = iₙ = i,
                              ∅                          otherwise,

  "where the second case disallows a mixed tuple."

This variant drops the unmixedness requirement entirely, so a tuple drawn from
both copies still produces a value. The paper does not say what happens; the
question is whether Lemma 11 survives.
-/
import MatchingLogic.DoubleCover

namespace MatchingLogic
namespace VariantMixed

variable {S : Signature} {Var : Type} [DecidableEq Var]

/-- Definition 10's interpretation with the unmixedness condition removed. -/
def coverInterp₂ (M : Model S) (C : Set M.carrier)
    (σ : S.Sym) (A : Fin (S.arity σ) → (C × Bool)) : Set (C × Bool) :=
  {p | (p.1 : M.carrier) ∈ M.interp σ (fun j => ((A j).1 : M.carrier))}

def cover₂ (M : Model S) (C : Set M.carrier) (hne : C.Nonempty) : Model S where
  carrier := C × Bool
  nonempty := ⟨(⟨hne.choose, hne.choose_spec⟩, false)⟩
  interp := coverInterp₂ M C

def V2Claim : Prop :=
  ∀ (S : Signature) (Var : Type) (_ : DecidableEq Var) (M : Model S)
    (C : Set M.carrier) (_ : M.BackwardClosed C) (hne : C.Nonempty)
    (star : M.carrier) (_ : star ∉ C)
    (ψ : Pattern S Var) (ν : Var → (C × Bool)) (p : C × Bool),
      p ∈ (cover₂ M C hne).denote ν ψ ↔
        (p.1 : M.carrier) ∈ M.denote (fun x => proj M C star p.2 (ν x)) ψ

theorem v2_holds : V2Claim := by sorry

/-!
## The countermodel

Refuting `V2Claim` takes a binary symbol, a two-element carrier, and a pattern
that feeds one variable from each copy.

* `cmSig` has a single symbol `σ` of arity `2`.
* `cmModel` has carrier `Bool`, and `σ_M(a₀,a₁) = {false}` when `a₀ = a₁ = false`,
  and `∅` otherwise.
* `cmC = {false}`, which is backward closed (a point of `C` is produced only by
  the all-`false` tuple), and `star = true ∉ cmC`.
* `cmPat = σ(x₀, x₁)`, `cmVal` sends `x₀` to `(false, 0)` and `x₁` to
  `(false, 1)`, and the test point is `cmPt = (false, 0)`.

In `cover₂` the mixed tuple `((false,0),(false,1))` is legal, so it produces
`(false, 0)` and the left side holds.  On the right side the projection `π₀`
sends `(false,1)` to `star = true`, so the right side asks for
`false ∈ σ_M(false, true) = ∅` and fails.
-/

/-- One binary symbol. -/
abbrev cmSig : Signature where
  Sym := Unit
  arity := fun _ => 2

/-- `σ_M(a₀,a₁) = {false}` if `a₀ = a₁ = false`, and `∅` otherwise. -/
abbrev cmModel : Model cmSig where
  carrier := Bool
  nonempty := ⟨false⟩
  interp := fun _ a => {u | u = false ∧ a 0 = false ∧ a 1 = false}

/-- `C = {false}`. -/
abbrev cmC : Set cmModel.carrier := {b | b = false}

theorem cmC_nonempty : cmC.Nonempty := ⟨false, rfl⟩

theorem cmStar : (true : cmModel.carrier) ∉ cmC := by
  intro h; exact Bool.noConfusion h

theorem cmC_backwardClosed : cmModel.BackwardClosed cmC := by
  rintro u hu v ⟨σ, a, ⟨iv, hiv⟩, ⟨-, h0, h1⟩, rfl⟩
  have hiv2 : iv < 2 := hiv
  have hcase : iv = 0 ∨ iv = 1 := by omega
  rcases hcase with rfl | rfl
  · exact h0
  · exact h1

/-- The point `false`, as an element of `↥cmC`. -/
def cmFalse : cmC := ⟨false, rfl⟩

/-- The pattern `σ(x₀, x₁)`. -/
def cmPat : Pattern cmSig Nat := .app () (fun i => .var i.val)

/-- `x₀ ↦ (false, 0)`, `x₁ ↦ (false, 1)`: the two variables live in
*different* copies.  That is exactly what `coverInterp₂` newly allows. -/
def cmVal : Nat → (cmC × Bool) := fun n => (cmFalse, decide (n ≠ 0))

/-- The test point, in copy `0`. -/
def cmPt : cmC × Bool := (cmFalse, false)

theorem v2_fails : ¬ V2Claim := by
  intro h
  have hiff := h cmSig Nat inferInstance cmModel cmC cmC_backwardClosed
    cmC_nonempty true cmStar cmPat cmVal cmPt
  -- Left side: the mixed tuple `(cmVal 0, cmVal 1)` is admitted by `coverInterp₂`.
  have hL : cmPt ∈ (cover₂ cmModel cmC cmC_nonempty).denote cmVal cmPat := by
    refine ⟨fun i => cmVal i.val, fun i => rfl, ?_⟩
    exact ⟨rfl, rfl, rfl⟩
  -- Right side: `π₀` sends `cmVal 1` to `star = true`, killing the tuple.
  have hR := hiff.mp hL
  obtain ⟨a, ha, -, -, h1⟩ := hR
  have : a 1 = true := by
    have := ha 1
    simpa [cmVal, proj, cmPt, cmFalse] using this
  rw [this] at h1
  exact Bool.noConfusion h1


/-- **Control.**  The same data does *not* satisfy the left-hand side under the
paper's own `cover`: the unmixedness condition forces `(cmVal 0).2 = (cmVal 1).2`,
which is false.  So the refutation above is caused by dropping that condition and
by nothing else in the shared machinery -- under `cover` both sides are false at
`cmPt`, and Lemma 11 is undisturbed. -/
theorem cm_real_cover_excludes_it :
    cmPt ∉ (cover cmModel cmC cmC_nonempty).denote cmVal cmPat := by
  intro hbad
  obtain ⟨A, hA, hmix, -⟩ := hbad
  have h0 := hA 0
  have h1 := hA 1
  simp only [Model.denote] at h0 h1
  have e0 := hmix 0
  have e1 := hmix 1
  rw [h0] at e0
  rw [h1] at e1
  simp [cmVal, cmPt] at e0 e1

end VariantMixed
end MatchingLogic


