-- Entry point (iii), round-ten follow-up: the separation results.
-- Generated to match the pin-file convention; these three modules were
-- silently skipped by the gate until the subshell fail-open was fixed.
import MatchingLogic.EntryIII.WitnessSupply

#print MatchingLogic.InfiniteWitnessSupply
#print MatchingLogic.InfiniteFreshVariableSupply
#check @MatchingLogic.freshWitnessed_of_witnessed_of_supply
#check @MatchingLogic.locConsistent_extend_freshWitnessed_isMCS
#check @MatchingLogic.locConsistent_extend_freshWitnessed_isMCS_unrestricted_refuted
