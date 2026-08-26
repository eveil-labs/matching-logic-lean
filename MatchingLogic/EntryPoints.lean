/-
Where the mechanization actually stands against the paper's challenge.

`global_completeness` (in `Completeness.lean`) is entry point (ii) verbatim:
Corollary 15 with (L) and (S) assumed. But (S) is not an assumption in this
development -- `soundness` (in `Soundness.lean`) proves it -- so it can be
supplied rather than hypothesised. That is what this file records.
-/
import MatchingLogic.Soundness
import MatchingLogic.Completeness

namespace MatchingLogic

variable {S : Signature} {Var : Type} [DecidableEq Var]

/-- **Corollary 15 with (S) discharged.**

Entry point (ii) of the paper's challenge is Corollary 15 *with (L) and (S)
assumed*, which is `global_completeness` above. But (S) is not an assumption
here — `soundness` proves it — so it can be supplied rather than hypothesised,
leaving (L) as the only remaining black box.

This is the honest statement of how far the mechanization gets: entry point (ii)
in full, plus (S) discharged -- which (ii) permitted us to assume, so it is
beyond (ii) rather than part of (iii). Entry point (iii) asks only for (L) to be
discharged, and is not attempted here. Doing so would
require the canonical-model construction that the paper cites to its references
[3], [4] and [5], and which appears nowhere in the paper itself. -/
theorem global_completeness_of_localCompleteness
    (hL : StrongLocalCompleteness S Var)
    {Γ : Set (Pattern S Var)} {φ : Pattern S Var}
    (hΓ : ∀ γ ∈ Γ, Closed γ) (hφ : Closed φ) :
    GlobalCons Γ φ ↔ Provable Γ φ :=
  global_completeness hL soundness hΓ hφ

end MatchingLogic
