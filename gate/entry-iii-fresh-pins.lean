-- Entry-point (iii), wave 1: finite-support statement types fixed before proofs.
import MatchingLogic.EntryIII.Fresh

#print MatchingLogic.Pattern.allVars
#check @MatchingLogic.Pattern.FV_subset_allVars
#print MatchingLogic.Pattern.fresh
#check @MatchingLogic.Pattern.fresh_not_mem_allVars
#check @MatchingLogic.Pattern.fresh_not_mem_FV
