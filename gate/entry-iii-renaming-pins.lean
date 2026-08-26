-- Entry-point (iii), wave 0: public statement types fixed before proofs.
import MatchingLogic.EntryIII.Renaming

#print MatchingLogic.Pattern.rename
#print MatchingLogic.AppCtx.rename
#check @MatchingLogic.Pattern.rename_id
#check @MatchingLogic.Pattern.rename_comp
#check @MatchingLogic.Pattern.mem_FV_renameEquiv
#check @MatchingLogic.Pattern.substVar_renameEquiv
#check @MatchingLogic.Pattern.captureFree_renameEquiv
#check @MatchingLogic.Pattern.rename_update
#check @MatchingLogic.PForm.subst_rename
#check @MatchingLogic.AppCtx.plug_renameEquiv
#check @MatchingLogic.rename_conj
#check @MatchingLogic.Model.denote_renameEquiv
#check @MatchingLogic.Model.denoteSet_renameEquiv
#check @MatchingLogic.Provable.renameEquiv
#check @MatchingLogic.localCons_renameEquiv
#check @MatchingLogic.strongLocalCompleteness_congr
#check @MatchingLogic.strongLocalCompleteness_iff_nat
