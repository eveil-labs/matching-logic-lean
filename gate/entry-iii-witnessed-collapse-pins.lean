-- Entry point (iii), round-ten follow-up: the separation results.
-- Generated to match the pin-file convention; these three modules were
-- silently skipped by the gate until the subshell fail-open was fixed.
import MatchingLogic.EntryIII.WitnessedCollapse

#print MatchingLogic.WitnessCollapseSig
#print MatchingLogic.witnessCollapseModel
#print MatchingLogic.witnessCollapseRho
#print MatchingLogic.witnessCollapseTheory
#check @MatchingLogic.witnessCollapseTheory_isMCS
#check @MatchingLogic.witnessCollapseTheory_witnessed
#check @MatchingLogic.witnessCollapseTheory_not_freshWitnessed
#check @MatchingLogic.witnessed_freshWitnessed_of_isMCS_counterexample
#check @MatchingLogic.witnessed_freshWitnessed_of_isMCS_refuted
#check @MatchingLogic.alpha_variant_has_a_fresh_witness
