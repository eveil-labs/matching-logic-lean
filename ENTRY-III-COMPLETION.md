# Entry point (iii): completion map

This note records the theorem scope and completed composition for entry point
(iii). It is additive documentation; the final section records the checks used
to substantiate the completion claim.

## The source-faithful variable scope

The source fixes a countably infinite supply of element variables. In this
development the canonical construction is therefore carried out over `Nat`.
The public source-faithful scope for another variable type is

```lean
[DecidableEq Var] [Denumerable Var]
```

rather than arbitrary `Var`. `MatchingLogic.strongLocalCompleteness_iff_nat`
proves the exact equivalence

```lean
StrongLocalCompleteness S Var ↔ StrongLocalCompleteness S Nat
```

using `Denumerable.eqv Var`. Its dependencies establish that renaming along a
variable equivalence preserves syntax, derivations, denotations, local
consequence, and the finite-list witness required by strong local
completeness. Thus proving the result over `Nat` is equivalent to proving it
at the source's intended variable scope. It does not imply the stronger and
generally unsupported statement for finite or empty variable types.

## Why canonical points are `FreshWitnessed`

The raw Lean syntax does not quotient patterns by alpha equivalence. A witness
name that is merely absent from the free variables of an existential body can
still collide with a binder in that body. The source presentation silently
renames binders when making substitutions, so that collision cannot be
ignored in a raw-syntax formalization.

The proved refinement is

```lean
def FreshWitnessed (Gamma : Set (Pattern S Nat)) : Prop :=
  ∀ {x p}, Pattern.ex x p ∈ Gamma →
    ∃ y, y ∉ p.allVars ∧
      Pattern.imp (Pattern.ex x p)
        (Pattern.captureAvoidingSubst x y p) ∈ Gamma
```

and canonical points are now represented by

```lean
{Gamma // IsMCS Gamma ∧ FreshWitnessed Gamma}
```

This is not a new assumption. The finite Henkin extension proves
`finite_locConsistent_extend_freshWitnessed_isMCS`: every locally consistent
finite list extends to an MCS satisfying the stronger invariant. The
simultaneous n-ary stage construction likewise proves
`NaryStageSystem.limit_freshWitnessed` for each limit component.

The refinement is source-faithful because it makes explicit, on raw names,
the freshness that the paper obtains from its infinite variable supply and
alpha-renaming convention. It implies the ordinary interface by
`FreshWitnessed.toWitnessed`. Consequently
`CanonicalCarrier.freshWitnessed` exposes the representation invariant while
`CanonicalCarrier.witnessed` remains available to the generated-model,
completion, and Truth Lemma layers.

Freshness over `allVars`, together with total capture-avoiding substitution,
also supports the exact raw normalization and elimination results in
`FreshWitnessElim.lean`. This is the bridge needed where a source proof moves
witness names through nested existentials modulo alpha equivalence.

## Arbitrary ambient symbol sets

The paper permits an arbitrary finitary symbol set; the canonical construction
should not impose countability on `S.Sym`. The additive reduction works one
finite countertheory at a time:

1. `Pattern.symbolSupportList` collects the finite set `F` of symbols occurring
   in the premise list.
2. `Pattern.restrictList` moves those patterns to `S.restrict F`, and
   `restrictList_locConsistent` preserves local consistency.
3. `restrictedPatternNatCountable F` supplies countability of
   `Pattern (S.restrict F) Nat`, because the restricted symbol type is finite.
4. The canonical model construction produces a pointed model for the
   restricted list.
5. `finiteLocalModelExistence_of_restricted` extends the restricted model to
   the ambient signature, interpreting symbols outside `F` by the empty set;
   the supporting denotation lemmas prove that the original list is still
   satisfied.

The reduction uses `[DecidableEq S.Sym]` to compute finite supports. A classical
instance can provide this in the final noncomputable proof; it is not a
finiteness or countability hypothesis on the ambient symbol type.

## The completed theorem pipeline

`canonicalExistence` proves `CanonicalExistenceProperty S`, the exact universal
statement of the paper's n-ary Existence Lemma.  It closes the previously
conditional downstream chain:

```text
canonicalExistence
  → finiteLocalModelExistence_of_canonicalExistence
  → finiteLocalCompleteness_of_canonicalExistence
  → strongLocalCompleteness_nat_of_canonicalExistence
```

The underlying construction is:

```text
finite locally consistent list
  → fresh-witnessed MCS root
  → canonical model
  → root-generated submodel
  → conditional-star completion and surjective valuation
  → completed_truth canonicalExistence
  → a point satisfying the input list
```

For an arbitrary ambient signature, the intended final composition first
applies the conditional model-existence theorem to every finite restriction,
using `restrictedPatternNatCountable`, and then applies
`finiteLocalModelExistence_of_restricted`. The generic conversions
`finiteLocalCompleteness_of_finiteLocalModelExistence` and
`strongLocalCompleteness_of_finiteLocalCompleteness` produce
`StrongLocalCompleteness S Nat`; `strongLocalCompleteness_iff_nat` transports
that result to any `[Denumerable Var]`.

The exported conclusion layer provides `finiteLocalModelExistence`,
`finiteLocalCompleteness`, `strongLocalCompleteness_nat`, and
`strongLocalCompleteness`.  The last theorem assumes `[Denumerable Var]`, which
is exactly the source scope, and carries no finiteness or countability
assumption on the ambient symbol type.  Finally,
`global_completeness_entryIII` applies the proved local theorem and soundness;
only the closedness premises intrinsic to the paper's global statement remain.

`MatchingLogic.EntryIII.All` is the aggregate import for the completed development.
It imports both the conclusion layer and the adversarial regression suite, so a
single `lake build MatchingLogic.EntryIII.All` checks the full EntryIII dependency
closure rather than only the repository's pre-existing top-level library.

## Adversarial non-vacuity checks

`MatchingLogic.EntryIII.Regression` specializes the result to an explicit
two-point Boolean model with a nullary and a unary symbol.  Its kernel-checked
regressions establish, among other things, that:

- bottom, an open variable, a closed constant application, and an open unary
  application are not accidental empty-theory theorems;
- the final global-completeness equivalence at bottom has two genuinely false
  sides;
- the local antecedent `{x} ⊨loc x` is inhabited and its completeness witness
  cannot use an empty finite premise list;
- finite model existence returns an actual model, valuation, and carrier point
  for a consistent nonempty list;
- canonical existence is invoked from actual MCS membership in both arity zero
  and positive arity; and
- the final reduction instantiates at an ambient signature with symbol type
  `Set Nat`, without a countability or decidable-equality premise on that type.

## Verification criteria

The completion audit checks all of the following:

- every additive EntryIII module builds from the current source tree;
- every pin file elaborates and exactly matches its checked-in baseline;
- the certified-name audit includes the fresh-witness carrier accessor, the
  fresh-witness extension, the fresh stage-limit theorem, the Existence Lemma,
  the Truth Lemma, and the final completeness compositions;
- `#print axioms` for the final exported results reports only `propext`,
  `Classical.choice`, and `Quot.sound`;
- no EntryIII source contains `sorry`, a new `axiom`, or `native_decide`;
- the final theorem has no `CanonicalExistenceProperty` hypothesis, assumes
  `[Denumerable Var]` rather than arbitrary `Var`, and does not assume the
  ambient symbol type is finite or countable;
- the finite-signature reduction and variable-equivalence transport are part
  of the checked theorem chain, not only prose arguments; and
- the repository's additive and upstream-preservation gates pass.

## Verification result

The completed tree was checked on 2026-08-25.  `lake build MatchingLogic`,
`lake build MatchingLogic.EntryIII.All`, all seven inherited audit gates,
and `audit-entry-iii.sh` pass. (`audit-additive.sh` was a check on the
development BRANCH: it compares against `upstream/main`, cannot run in a
standalone clone, and is not in CI.)
The EntryIII audit verifies exact statement-pin baselines, rejects `sorry`, new
axiom declarations, and `native_decide`, checks every public declaration is
pinned and every public theorem is certified, and checks every certified
theorem's kernel dependencies.  Its axiom parser fails closed on wrapped or
malformed output and includes positive and negative parser self-tests.  In
particular, `canonicalExistence`,
`strongLocalCompleteness`, and `global_completeness_entryIII` depend only on
`propext`, `Classical.choice`, and `Quot.sound`.
