import MatchingLogic
-- Entry point (i): statement TYPES and definition BODIES.
#check @MatchingLogic.locality
#check @MatchingLogic.two_copies
#check @MatchingLogic.two_copies_set
#print MatchingLogic.coverInterp
#print MatchingLogic.cover
#print MatchingLogic.proj
#print MatchingLogic.AgreeOn
#print MatchingLogic.Model.app
#print MatchingLogic.Model.BackwardClosed
#print MatchingLogic.Model.denote
-- Entry point (ii), wave 2: definitions desk-authored from the paper.
#print MatchingLogic.FV
#print MatchingLogic.Closed
#print MatchingLogic.Model.Total
#print MatchingLogic.Model.Sat
#print MatchingLogic.Model.SatSet
#print MatchingLogic.Model.denoteSet
#print MatchingLogic.LocalCons
#print MatchingLogic.GlobalCons
#print MatchingLogic.Coord
#print MatchingLogic.dia
#print MatchingLogic.box
#print MatchingLogic.boxes
#print MatchingLogic.Model.stepAt
#print MatchingLogic.Model.reachWord
#print MatchingLogic.localize
-- Wave-2 pinned statements.
#check @MatchingLogic.denote_congr
#check @MatchingLogic.denote_boxes
#check @MatchingLogic.denoteSet_localize
#check @MatchingLogic.globalCons_of_localCons_localize
#check @MatchingLogic.cover_denote_closed
#check @MatchingLogic.cover_sat_iff
#check @MatchingLogic.semantic_localization
-- Figure 2: the proof system. Definitions pinned so no lane can adjust the
-- system it is proving things about.
#print MatchingLogic.substVar
#print MatchingLogic.CaptureFree
#print MatchingLogic.PForm.eval
#print MatchingLogic.PForm.subst
#print MatchingLogic.AppCtx.plug
#print MatchingLogic.conj
#print MatchingLogic.StrongLocalCompleteness
#print MatchingLogic.Soundness
#check @MatchingLogic.Provable.rec
#check @MatchingLogic.necessitation
#check @MatchingLogic.soundness
#check @MatchingLogic.proof_theoretic_localization
#check @MatchingLogic.global_completeness
