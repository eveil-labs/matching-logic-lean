-- Entry point (iii), round-ten follow-up: the separation results.
-- Generated to match the pin-file convention; these three modules were
-- silently skipped by the gate until the subshell fail-open was fixed.
import MatchingLogic.EntryIII.AlphaFreshWitnessed

#print MatchingLogic.AlphaFreshWitnessed
#check @MatchingLogic.fvBlocked_has_alpha_fresh_witness
#check @MatchingLogic.AlphaWitnessSym.rec
#print MatchingLogic.AlphaWitnessSig
#print MatchingLogic.pairArgs
#check @MatchingLogic.pairArgs_zero
#check @MatchingLogic.pairArgs_one
#print MatchingLogic.alphaWitnessModel
#print MatchingLogic.alphaWitnessRho
#print MatchingLogic.alphaWitnessTheory
#check @MatchingLogic.alphaWitnessTheory_isMCS
#check @MatchingLogic.alphaWitnessTheory_witnessed
#print MatchingLogic.alphaBlocked
#check @MatchingLogic.alphaBlocked_mem
#print MatchingLogic.alphaUnitEmptyModel
#print MatchingLogic.alphaUnitFullModel
#print MatchingLogic.alphaUnitRho
#print MatchingLogic.alphaFirstSelectorModel
#print MatchingLogic.alphaCornerSelectorModel
#check @MatchingLogic.alphaWitnessTheory_not_alphaFreshWitnessed
#check @MatchingLogic.witnessed_alphaFreshWitnessed_of_isMCS_counterexample
#check @MatchingLogic.witnessed_alphaFreshWitnessed_of_isMCS_refuted
