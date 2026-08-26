/-
Definition 10 (the double cover) and Lemma 11 (two copies) of
arXiv:2608.13306v1, Section 4.

DEFINITION 10 AND THE STATEMENT OF LEMMA 11 ARE PINNED BEFORE ANY PROOF WAS ATTEMPTED.  A lane may
add auxiliary lemmas and must replace the `sorry`s, but may NOT change `cover`,
`proj`, or the statements of `two_copies` / `two_copies_set`.

Note on the constant case.  Definition 10 gives constants `σ_N := (σ_M ∩ C) × {0,1}`,
i.e. the SAME subset in both copies; the paper warns that assigning it to one
copy only would break Lemma 11 at `ψ = σ`.  The uniform clause below reproduces
this automatically: the unmixedness condition `∀ j, (A j).2 = p.2` is vacuous
when the arity is `0`, so both copies are populated.
-/
import MatchingLogic.Locality

namespace MatchingLogic

variable {S : Signature} {Var : Type} [DecidableEq Var]

section Cover

variable (M : Model S) (C : Set M.carrier)

/-- The interpretation of Definition 10: a tuple contributes only when it is
unmixed, and then it contributes `σ_M(ā) ∩ C` in its own copy. -/
def coverInterp (σ : S.Sym) (A : Fin (S.arity σ) → (C × Bool)) : Set (C × Bool) :=
  {p | (∀ j, (A j).2 = p.2) ∧
       ((p.1 : M.carrier) ∈ M.interp σ (fun j => ((A j).1 : M.carrier)))}

/-- **Definition 10.**  The double cover `N := C × {0,1}`. -/
def cover (hne : C.Nonempty) : Model S where
  carrier := C × Bool
  nonempty := ⟨(⟨hne.choose, hne.choose_spec⟩, false)⟩
  interp := coverInterp M C

/-- The projections `π_i : N → M` of Definition 10: keep copy `i`, and send the
other copy to a fixed `star ∈ M \ C`. -/
def proj (star : M.carrier) (i : Bool) (p : C × Bool) : M.carrier :=
  if p.2 = i then (p.1 : M.carrier) else star

/-! ### Auxiliary lemmas for Lemma 11

Lane-authored scaffolding.  None of it changes Definition 10 or either pinned
statement below. -/

/-- `π_i(a, i) = a`: on its own copy `π_i` is the first projection. -/
private theorem proj_same (star : M.carrier) (i : Bool) (c : C) :
    proj M C star i (c, i) = (c : M.carrier) := by
  simp [proj]

/-- `π_i(a, 1−i) = ∗`: on the other copy `π_i` is constantly `star`. -/
private theorem proj_other (star : M.carrier) (i : Bool) (c : C) :
    proj M C star i (c, !i) = star := by
  cases i <;> simp [proj]

/-- `π_i(ν[n/x]) = π_i(ν)[π_i(n)/x]` — the paper's displayed identity in the
existential case of Lemma 11. -/
private theorem proj_update (star : M.carrier) (i : Bool) (ν : Var → (C × Bool))
    (y : Var) (n : C × Bool) :
    (fun z => proj M C star i (Function.update ν y n z)) =
      Function.update (fun z => proj M C star i (ν z)) y (proj M C star i n) := by
  funext z
  by_cases h : z = y
  · subst h; simp
  · simp [h]

/-- Two valuations differing only at `y`, where both values lie outside `C`,
satisfy the agreement condition of Lemma 9.  This is the hypothesis fed to
`locality` in the existential case. -/
private theorem agree_update_out (ρ : Var → M.carrier) (y : Var)
    {a b : M.carrier} (ha : a ∉ C) (hb : b ∉ C) :
    AgreeOn C (Function.update ρ y a) (Function.update ρ y b) := by
  intro z
  by_cases h : z = y
  · subst h; right; simp [ha, hb]
  · simp only [Function.update_apply, if_neg h]
    by_cases hc : ρ z ∈ C
    · exact Or.inl ⟨by trivial, hc⟩
    · exact Or.inr ⟨hc, hc⟩

/-- Membership in the interpretation of Definition 10, unfolded. -/
private theorem mem_cover_interp (hne : C.Nonempty) (σ : S.Sym)
    (A : Fin (S.arity σ) → (C × Bool)) (p : C × Bool) :
    p ∈ (cover M C hne).interp σ A ↔
      (∀ j, (A j).2 = p.2) ∧
        (p.1 : M.carrier) ∈ M.interp σ (fun j => ((A j).1 : M.carrier)) :=
  Iff.rfl

/-- Membership in a cover denotation at an implication, unfolded. -/
private theorem mem_cover_denote_imp (hne : C.Nonempty) (ν : Var → (C × Bool))
    (φ χ : Pattern S Var) (p : C × Bool) :
    p ∈ (cover M C hne).denote ν (Pattern.imp φ χ) ↔
      (¬ (p ∈ (cover M C hne).denote ν φ) ∨ p ∈ (cover M C hne).denote ν χ) :=
  Iff.rfl

/-- Membership in a cover denotation at an existential, unfolded. -/
private theorem mem_cover_denote_ex (hne : C.Nonempty) (ν : Var → (C × Bool))
    (y : Var) (φ : Pattern S Var) (p : C × Bool) :
    p ∈ (cover M C hne).denote ν (Pattern.ex y φ) ↔
      ∃ n : C × Bool, p ∈ (cover M C hne).denote (Function.update ν y n) φ := by
  constructor
  · intro h
    have h' : p ∈ ⋃ n : (cover M C hne).carrier,
        (cover M C hne).denote (Function.update ν y n) φ := h
    exact Set.mem_iUnion.mp h'
  · rintro ⟨n, hn⟩
    show p ∈ ⋃ n : (cover M C hne).carrier,
        (cover M C hne).denote (Function.update ν y n) φ
    exact Set.mem_iUnion.mpr ⟨n, hn⟩

/-- **Lemma 11 (two copies)**, in membership form.  Equivalent to the display in
the paper (see `two_copies_set`); this form is the one to prove by induction. -/
theorem two_copies (hC : M.BackwardClosed C) (hne : C.Nonempty)
    (star : M.carrier) (hstar : star ∉ C)
    (ψ : Pattern S Var) (ν : Var → (C × Bool)) (p : C × Bool) :
    p ∈ (cover M C hne).denote ν ψ ↔
      (p.1 : M.carrier) ∈ M.denote (fun x => proj M C star p.2 (ν x)) ψ := by
  induction ψ generalizing ν p with
  | var y =>
      -- Paper, "Variable": the copy-`i` part of `ν(x)_N` is `{(a,i)}` if `ν x = (a,i)`
      -- and `∅` otherwise, the latter because then `π_i(ν x) = star ∉ C`.
      simp only [denote_var, Set.mem_singleton_iff, proj]
      constructor
      · rintro rfl
        simp
      · intro h
        by_cases hb : (ν y).2 = p.2
        · rw [if_pos hb] at h
          exact Prod.ext_iff.mpr ⟨Subtype.ext h, hb.symm⟩
        · rw [if_neg hb] at h
          exfalso
          have hp : (p.1 : M.carrier) ∈ C := p.1.2
          rw [h] at hp
          exact hstar hp
  | app σ f ih =>
      -- Paper, "Symbol, n ≥ 1" and "Constant": arity `0` is the constant case and
      -- needs no index, so the two are one argument here.
      simp only [denote_app, Model.app, Set.mem_setOf_eq]
      constructor
      · rintro ⟨A, hA, hun, hint⟩
        refine ⟨fun j => ((A j).1 : M.carrier), fun j => ?_, hint⟩
        have hj := (ih j ν (A j)).mp (hA j)
        rwa [hun j] at hj
      · rintro ⟨a, ha, hint⟩
        -- backward closure: every component of a tuple producing `↑p.1 ∈ C` is in `C`
        have hmemC : ∀ j, a j ∈ C := fun j => Model.BackwardClosed.mem_of_interp M hC p.1.2 hint j
        refine ⟨fun j => (⟨a j, hmemC j⟩, p.2), fun j => ?_, fun j => rfl, hint⟩
        exact (ih j ν (⟨a j, hmemC j⟩, p.2)).mpr (ha j)
  | imp φ χ ihφ ihχ =>
      -- Paper, "Implication": complementation in `N` restricted to copy `i` is
      -- complementation in `C`.
      rw [mem_cover_denote_imp]
      simp only [denote_imp, Set.mem_union, Set.mem_compl_iff, ihφ, ihχ]
  | bot => exact Iff.rfl
  | ex y φ ih =>
      -- Paper, "Existential".
      rw [mem_cover_denote_ex]
      simp only [denote_ex, Set.mem_iUnion]
      constructor
      · rintro ⟨n, hn⟩
        refine ⟨proj M C star p.2 n, ?_⟩
        have h := (ih (Function.update ν y n) p).mp hn
        rwa [proj_update] at h
      · rintro ⟨a, ha⟩
        by_cases haC : a ∈ C
        · -- `a ∈ C`: realize it in copy `p.2`.
          refine ⟨(⟨a, haC⟩, p.2), ?_⟩
          refine (ih (Function.update ν y (⟨a, haC⟩, p.2)) p).mpr ?_
          rw [proj_update, proj_same]
          exact ha
        · -- `a ∉ C`: LEMMA 9 replaces `a` by `star`, and the other copy supplies a
          -- witness realizing `star` because `C` is nonempty.
          have hloc := locality M hC φ _ _
            (agree_update_out M C (fun x => proj M C star p.2 (ν x)) y haC hstar)
          have hp : (p.1 : M.carrier) ∈
              M.denote (Function.update (fun x => proj M C star p.2 (ν x)) y star) φ := by
            have hmem : (p.1 : M.carrier) ∈
                M.denote (Function.update (fun x => proj M C star p.2 (ν x)) y a) φ ∩ C :=
              ⟨ha, p.1.2⟩
            rw [hloc] at hmem
            exact hmem.1
          refine ⟨(⟨hne.choose, hne.choose_spec⟩, !p.2), ?_⟩
          refine (ih (Function.update ν y (⟨hne.choose, hne.choose_spec⟩, !p.2)) p).mpr ?_
          rw [proj_update, proj_other]
          exact hp

/-- **Lemma 11 (two copies)**, in the paper's displayed set form:
`ν(ψ)_N = (π₀(ν)(ψ)_M ∩ C) × {0} ∪ (π₁(ν)(ψ)_M ∩ C) × {1}`.
The `∩ C` is absorbed by the subtype `↥C`. -/
theorem two_copies_set (hC : M.BackwardClosed C) (hne : C.Nonempty)
    (star : M.carrier) (hstar : star ∉ C)
    (ψ : Pattern S Var) (ν : Var → (C × Bool)) :
    (cover M C hne).denote ν ψ =
      {p : C × Bool | p.2 = false ∧
        (p.1 : M.carrier) ∈ M.denote (fun x => proj M C star false (ν x)) ψ} ∪
      {p : C × Bool | p.2 = true ∧
        (p.1 : M.carrier) ∈ M.denote (fun x => proj M C star true (ν x)) ψ} := by
  refine Set.ext (fun p : C × Bool => ?_)
  refine Iff.trans (two_copies M C hC hne star hstar ψ ν p) ?_
  constructor
  · intro h
    cases hp : p.2
    · exact Or.inl ⟨hp, by rw [hp] at h; exact h⟩
    · exact Or.inr ⟨hp, by rw [hp] at h; exact h⟩
  · rintro (⟨hp, h⟩ | ⟨hp, h⟩) <;> rw [hp] <;> exact h

end Cover

end MatchingLogic
