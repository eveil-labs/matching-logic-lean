-- Entry-point (iii): conditional-star completion and completed valuation.
import MatchingLogic.EntryIII.Completion

#print MatchingLogic.Missing
#print MatchingLogic.CompletedCarrier
#print MatchingLogic.CompletedCarrier.isStar
#print MatchingLogic.completedEmbed
#print MatchingLogic.completedStar
#check @MatchingLogic.completedEmbed_injective
#check @MatchingLogic.completedStar_ne_embed
#check @MatchingLogic.exists_completedStar_iff_missing
#check @MatchingLogic.completedCarrier_cases
#print MatchingLogic.completedInterp
#print MatchingLogic.completedModel
#check @MatchingLogic.mem_completedInterp
#check @MatchingLogic.completedModel_interp
#check @MatchingLogic.mem_completedModel_interp
#check @MatchingLogic.completedInterp_eq_empty_of_input_star
#check @MatchingLogic.completedEmbed_mem_completedInterp_iff
#check @MatchingLogic.completedStar_mem_completedInterp_iff
#print MatchingLogic.completedValuation
#check @MatchingLogic.completedValuation_isStar_iff
#check @MatchingLogic.completedValuation_eq_embed_iff
#check @MatchingLogic.completedValuation_surjective
#print axioms MatchingLogic.completedStar_mem_completedInterp_iff
#print axioms MatchingLogic.completedValuation_eq_embed_iff
#print axioms MatchingLogic.completedValuation_surjective
