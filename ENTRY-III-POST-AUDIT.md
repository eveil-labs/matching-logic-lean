# Entry point (iii): adversarial post-audit

This note records the second-pass audit performed after the completeness proof
first reached a green state.  The review deliberately examined proof shape,
dependency order, gate failure modes, and semantic non-vacuity rather than
merely rerunning the original scripts.

## Findings repaired

1. The aggregate axiom checker previously selected only the first physical
   line of each `#print axioms` result.  A forbidden dependency on a wrapped
   continuation line could therefore escape.  The checker now requests a very
   large `format.width`, accepts only one complete well-formed verdict, rejects
   wrapped or malformed output, and self-tests both an allowed list and a
   synthetic forbidden token.
2. The additive gate compared only tracked changes with `upstream/main`.
   Untracked EntryIII files were invisible to its addition count.  It now
   enumerates untracked files under `MatchingLogic`, `gate`, and `scripts` and
   reports them as additions while still rejecting modifications or deletions
   of the verified base.
3. The inherited coverage gate is intentionally scoped to the original root
   modules.  The EntryIII gate now performs its own module-local coverage scan:
   every public theorem, definition, abbreviation, structure, and inductive
   declaration must occur in the corresponding pin file, and every public
   theorem must resolve through that pin file to the certified-name manifest.
4. `lake build MatchingLogic` does not import additive subdirectories.  The new
   aggregate module `MatchingLogic.EntryIII.All` imports the final conclusion and
   regression suite and is discovered and built by the EntryIII gate.

## Proof and dependency simplifications

- `CanonicalExistenceProperty` now lives with `CanonicalExistence`, before the
  construction and Truth Lemma that respectively prove and consume it.
- MCS Boolean facts moved from `Truth` to `MCSAlpha`; the Truth module now owns
  the Truth Lemma rather than unrelated foundational closure facts.
- Low-level freshness and symbol-support modules use direct semantic or
  proof-system imports.  They no longer pull in variable-equivalence transport
  or embedding semantics transitively.
- General Hilbert lemmas `Provable.imp_of` and `Provable.imp_and` are shared by
  the finite-stage proofs instead of being reproved locally.
- The ordinary witnessed-extension results are wrappers around the stronger
  fresh-witnessed construction via `FreshWitnessed.toWitnessed`; the duplicate
  Lindenbaum construction was removed.
- Signature-extension denotation now reuses `Model.app_extendSignature` instead
  of unfolding and reproving its application case.
- The recursive canonical successor chooses a packed `StageData` invariant
  directly, and unused private tautology code and stale simplifier arguments
  were removed.

## Intentionally retained evidence

The generated-model, completion, and Truth modules remain separate because
their boundaries match distinct source lemmas.  The explicit nullary Existence
Lemma remains even though the uniform construction also covers arity zero.
The general alpha-equivalence substitution path and the independent raw trace
elimination API are retained: they are not needed by the final direct-vector
implementation, but they provide useful certified evidence that the raw named
syntax implements the source's modulo-alpha reasoning rather than assuming it.

## Non-vacuity suite

`MatchingLogic.EntryIII.Regression` supplies explicit countermodels and real
canonical roots.  It exercises false and non-tautological patterns, an
inhabited local-consequence antecedent, a provably nonempty completeness
witness, an actual finite-model point, nullary and unary canonical existence,
inhabited canonical/generated/completed carriers, and an arbitrary ambient
symbol type.  These are theorem-level regressions with the same kernel-axiom
boundary as the main development.
