/-
VARIANT 4 -- backward closure with the step direction reversed.

Definition 2 sets `⇝_e := {(u, aᵢ) | u ∈ σ_M(a₁,…,aₙ)}`: the step runs from a
symbol's OUTPUT to its ARGUMENT, and `C` is backward closed when `⇝[C] ⊆ C`.

This variant reverses the arrow -- closure under passing from an argument to a
value built from it -- and asks whether Lemma 9 survives. The direction is easy
to get wrong when reading the definition, so a refutation here is worth having
on the record.
-/
import MatchingLogic.Locality
import MatchingLogic.Necessity

namespace MatchingLogic
namespace VariantStepDirection

variable {S : Signature} {Var : Type} [DecidableEq Var]

/-- The reversed step: from an argument to a value built from it. -/
def StepRev (M : Model S) (u v : M.carrier) : Prop :=
  ∃ (σ : S.Sym) (a : Fin (S.arity σ) → M.carrier) (i : Fin (S.arity σ)),
    v ∈ M.interp σ a ∧ u = a i

/-- Closure under the reversed step. -/
def ForwardClosed (M : Model S) (C : Set M.carrier) : Prop :=
  ∀ ⦃u⦄, u ∈ C → ∀ ⦃v⦄, StepRev M u v → v ∈ C

def V4Claim : Prop :=
  ∀ (S : Signature) (Var : Type) (_ : DecidableEq Var) (M : Model S)
    (C : Set M.carrier) (_ : ForwardClosed M C)
    (ψ : Pattern S Var) (ρ ρ' : Var → M.carrier),
      AgreeOn C ρ ρ' → M.denote ρ ψ ∩ C = M.denote ρ' ψ ∩ C

theorem v4_holds : V4Claim := by sorry

/-! ### Refutation

**Step 1 -- the `Necessity` countermodel already transfers.**  There the
signature has one unary symbol `σ`, the carrier is `{0,1,2}`, and
`σ_M(a) = {0}` if `a = 1` and `∅` otherwise; the set is `C = {0}`.

`C` is *not* backward closed -- `0 ∈ σ_M(1)` gives `0 ⇝ 1` and `1 ∉ C` -- which
is exactly why Lemma 9 fails there.  But `C` *is* closed under the reversed
step, **vacuously**: the only element of `C` is `0`, and the only tuple whose
sole argument is `0` is `a = (0)`, on which `σ_M(0) = ∅`.  So no reversed step
leaves `0` at all, and `ForwardClosed M C` holds with nothing to check.

**Step 2 -- and the vacuity is inessential.**  A refutation whose hypothesis is
satisfied only because it quantifies over an empty set invites the objection
that it is degenerate, so the refutation below is carried by a second model in
which the reversed closure condition genuinely fires.  Keep the carrier
`{0,1,2}` and `C = {0}`, but interpret

    σ_N(a) = ∅ if a = 2, and {0} otherwise.

Now `0 ∈ σ_N(0)`, so `0` really does take a reversed step, and that step lands
back in `C`: the closure condition is checked and passes non-vacuously.  `C` is
still not backward closed, since `0 ∈ σ_N(1)` and `1 ∉ C`.

In both models the failure is witnessed the same way: `ψ := σ(x)` with the
valuations `ρ ≡ 1` and `ρ' ≡ 2`.  Both send every variable outside `C`, so
`AgreeOn C ρ ρ'` holds, yet `ρ(ψ) ∩ C = {0}` while `ρ'(ψ) ∩ C = ∅`. -/

/-- Step 1: `Necessity`'s `C` is forward closed, vacuously -- nothing is built
out of `0` there. -/
theorem necessity_C_forwardClosed : ForwardClosed Necessity.M Necessity.C := by
  rintro u hu v ⟨σ, a, i, hv, rfl⟩
  have hi : i = 0 := Subsingleton.elim i 0
  subst hi
  have ha0 : a 0 = 0 := hu
  rw [show Necessity.M.interp σ a = (if a 0 = 1 then ({0} : Set (Fin 3)) else ∅) from rfl,
    ha0] at hv
  simp at hv

/-! #### The non-vacuous countermodel -/

/-- One unary symbol, as in `Necessity`. -/
abbrev S' : Signature := ⟨Unit, fun _ => 1⟩

/-- Carrier `{0,1,2}`; the symbol sends `2` nowhere and everything else to `0`.
Unlike `Necessity.M` this makes `0` the value of a tuple built from `0`. -/
abbrev N : Model S' :=
  { carrier := Fin 3
    nonempty := ⟨0⟩
    interp := fun _ a => if a 0 = 2 then (∅ : Set (Fin 3)) else {0} }

/-- The same set `{0}`. -/
abbrev C' : Set (Fin 3) := {0}

theorem N_interp (a : Fin 1 → Fin 3) :
    N.interp () a = if a 0 = 2 then (∅ : Set (Fin 3)) else {0} := rfl

/-- The reversed closure condition genuinely fires here: `0` does take a
reversed step (to `0`, via `σ_N(0) = {0}`), and every such step stays in `C'`. -/
theorem C'_forwardClosed : ForwardClosed N C' := by
  rintro u hu v ⟨σ, a, i, hv, rfl⟩
  have hi : i = 0 := Subsingleton.elim i 0
  subst hi
  have ha0 : a 0 = 0 := hu
  rw [N_interp, ha0] at hv
  simpa using hv

/-- The step `0 ⇝ 0` is real, so `C'_forwardClosed` is not vacuous: there is an
element of `C'` for which the closure condition has something to check. -/
theorem C'_forwardClosed_nonvacuous :
    ∃ u ∈ C', ∃ v, StepRev N u v := by
  refine ⟨0, rfl, 0, (), fun _ => 0, 0, ?_, rfl⟩
  rw [N_interp]
  simp

/-- `C'` is still not backward closed, so this is a genuine test of the
direction of Definition 2's arrow and not of some other difference. -/
theorem C'_not_backwardClosed : ¬ N.BackwardClosed C' := by
  intro h
  have h1 : (1 : Fin 3) ∈ C' :=
    h (show (0 : Fin 3) ∈ C' from rfl) ⟨(), fun _ => 1, 0, by rw [N_interp]; simp, rfl⟩
  exact absurd h1 (by decide)

section Witness

variable {Var : Type} [DecidableEq Var]

/-- The witnessing pattern `σ(x)`. -/
def psi' (x : Var) : Pattern S' Var := .app () (fun _ => .var x)

/-- Both valuations send every variable outside `C'`. -/
def rho1 : Var → Fin 3 := fun _ => 1
def rho2 : Var → Fin 3 := fun _ => 2

omit [DecidableEq Var] in
theorem agree' : AgreeOn (M := N) C' (rho1 (Var := Var)) rho2 := by
  intro _
  refine Or.inr ⟨?_, ?_⟩ <;> simp [rho1, rho2, C']

theorem denote_rho1 (x : Var) : N.denote (rho1 (Var := Var)) (psi' x) = {0} := by
  ext u
  simp only [psi', denote_app, Model.app, denote_var, Set.mem_ofPred_eq]
  constructor
  · rintro ⟨a, ha, hu⟩
    have h0 : a 0 = 1 := ha 0
    simpa [h0] using hu
  · intro hu
    exact ⟨fun _ => 1, fun _ => rfl, by simpa using hu⟩

theorem denote_rho2 (x : Var) : N.denote (rho2 (Var := Var)) (psi' x) = ∅ := by
  ext u
  simp only [psi', denote_app, Model.app, denote_var, Set.mem_ofPred_eq,
    Set.mem_empty_iff_false, iff_false]
  rintro ⟨a, ha, hu⟩
  have h0 : a 0 = 2 := ha 0
  simp [h0] at hu

end Witness

/-- **Variant 4 is refuted.**  Reversing the arrow in Definition 2 destroys
Lemma 9.  Stated over `Nat` variables, the paper's own setting. -/
theorem v4_fails : ¬ V4Claim := by
  intro h
  have hd := h S' Nat inferInstance N C' C'_forwardClosed (psi' 0) rho1 rho2 agree'
  rw [denote_rho1, denote_rho2] at hd
  have h0 : (0 : Fin 3) ∈ ({0} : Set (Fin 3)) ∩ C' := ⟨rfl, rfl⟩
  rw [hd] at h0
  exact h0.1

end VariantStepDirection
end MatchingLogic
