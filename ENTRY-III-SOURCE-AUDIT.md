# Entry point (iii): source-scope audit

This is a separate finding about the verified base.  It is not folded into the
canonical-model development because the project's working rules requires any suspected
mis-encoding of an existing statement to be reported explicitly.

## Finding: the source does not quantify over arbitrary variable types

The paper fixes the element-variable set to be countably infinite in Section 2:

> Element variables `Var` are countably infinite.

The cited technical report likewise builds countable infinitary variable sets
into its definition of a matching-logic signature.  Its Extension Lemma then
uses that supply twice: it adjoins countably many Henkin variables, and it
replays a finite extended-language derivation after replacing each alien name
by an unused old name of the same sort.

Sources:

- Chen and Rosu, *Completeness and incompleteness of basic matching logic*,
  Section 2, pp. 5-7: <https://arxiv.org/pdf/2608.13306>
- Chen and Rosu, *Matching mu-Logic*, Definition 1 and Lemma 71:
  <https://fsl.cs.illinois.edu/publications/chen-rosu-2019-tr.pdf>

By contrast, `StrongLocalCompleteness S Var` is well-formed for every
`Var : Type` with `DecidableEq Var`, and `README.md` calls this a harmless
generalization.  Instantiating a polymorphic statement at `Nat` would recover
the paper's setting, but the converse is not automatic: a theorem at `Nat`
does not prove the proposition for finite or empty `Var`.

The source-faithful target for entry point (iii) is therefore:

```lean
theorem strongLocalCompleteness
    [DecidableEq Var] [Denumerable Var] :
    StrongLocalCompleteness S Var
```

Equivalently, prove `StrongLocalCompleteness S Nat` and transport it along the
equivalence supplied by `Denumerable.eqv Var`.  The additive module
`MatchingLogic/EntryIII/Renaming.lean` now proves this transport at the levels
of syntax, proof, semantics, local consequence, and strong local completeness.

## Arbitrary symbols are intentional

The same paper explicitly allows an arbitrary, possibly infinite finitary
symbol set.  It extends the countable-signature completeness theorem by:

1. translating local consequence to first-order consequence;
2. applying first-order compactness to obtain a finite premise set;
3. restricting to the finite symbol support of those premises and the
   conclusion;
4. replaying the resulting derivation in the original signature.

Thus the source-faithful correction is a countably infinite variable supply,
not a countability assumption on `S.Sym`.

The additive theorem `MatchingLogic.localCons_compact` now checks this first
reduction directly through the paper's relational first-order translation.  It
extracts a finite premise list without assuming either `S.Sym` or `Var` is
countable.  Consequently, the canonical-model proof starts from a finite
countertheory and its finite variable support.  This avoids treating the
technical report's arbitrary-theory variable-extension argument as if it were
already valid for the raw Lean calculus; it does not remove the alpha/substitution
obligation inside the canonical Truth Lemma.

## Raw syntax also needs an alpha bridge

The sources identify alpha-equivalent patterns and use capture-avoiding
substitution with implicit binder renaming.  The verified base instead uses raw
named syntax, naive `substVar`, and a `CaptureFree` side condition.

This distinction is observable for finite names.  With `Var = Fin 2`, `x = 0`,
`y = 1`, and `phi = exists 1. 0`, the source instance of Rule (3) must rename
the inner binder to a third fresh name before substituting `y` for `x`.  There
is no such raw name in `Fin 2`; the Lean `CaptureFree` premise rejects the
naive, capturing substitution.  This is evidence that the finite-variable raw
calculus is not simply the source calculus under another presentation.

For the countably infinite development, the repair is additive: define finite
support containing both free and bound names, choose genuinely fresh witnesses,
and prove derived alpha-conversion implications using Rules (3) and (4).  No
existing verified definition needs to be weakened.

There is a second place where merely choosing fresh Henkin witnesses is not
enough.  In the reverse existential case of the source's Truth Lemma 81, the
completed valuation supplies an arbitrary variable naming a semantic witness.
That name can already occur as a binder in the body, so the source silently
alpha-renames before substituting.  The raw Lean operation `substVar` may
capture it and `CaptureFree` may reject the corresponding Rule (3) instance.
Accordingly, the canonical-model layer must expose a total capture-avoiding
substitution relation (or prove an equivalent normalization theorem), and then
prove that it agrees with raw `substVar` when the chosen name is genuinely
fresh.  The truth lemma may not use naive substitution directly.

## Addendum: the raw representative invariant is now proved

The additive development resolves the representative issue by strengthening
canonical points from ordinary `Witnessed` theories to `FreshWitnessed`
theories. For every `Pattern.ex x p` in such a theory, the Henkin implication
uses a name `y` satisfying `y ∉ p.allVars`, not merely `y ∉ FV p`, and its
consequent is formed with the total `Pattern.captureAvoidingSubst` operation.

This strengthening is a theorem-backed representation choice, not an extra
semantic or proof-theoretic premise:

- `finite_locConsistent_extend_freshWitnessed_isMCS` constructs a
  fresh-witnessed MCS from every locally consistent finite list;
- `NaryStageSystem.limit_freshWitnessed` proves the same invariant for the
  simultaneous n-ary construction's limit components; and
- `FreshWitnessed.toWitnessed` forgets the freshness evidence, so every new
  canonical point satisfies the paper's ordinary witnessed condition.

Requiring freshness from all raw occurrences is the direct named-syntax
counterpart of the source's alpha-renaming convention. It allows the later
fresh-witness elimination and substitution-composition proofs to state exact
raw equalities while leaving the ordinary `Witnessed` API available wherever
freshness is irrelevant. This proves the refinement needed by the raw Lean
presentation; it does not assert that arbitrary-variable syntax is equivalent
to the paper's countably infinite setting.

The overall scope therefore remains:

- variables: `Nat`, or equivalently any `[Denumerable Var]` via
  `strongLocalCompleteness_iff_nat`;
- symbols: arbitrary in the ambient signature, reduced per finite list to
  `S.restrict F` and lifted back by `finiteLocalModelExistence_of_restricted`;
  and
- canonical completeness: `canonicalExistence` discharges the Existence Lemma;
  `finiteLocalModelExistence`, `finiteLocalCompleteness`,
  `strongLocalCompleteness_nat`, and `strongLocalCompleteness` compose the
  unconditional result, and `global_completeness_entryIII` supplies the final
  global theorem without a local-completeness premise.

The corresponding completion and verification checklist is recorded in
`ENTRY-III-COMPLETION.md`.
