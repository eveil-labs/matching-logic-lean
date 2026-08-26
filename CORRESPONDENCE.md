| Paper result | Lean | Axioms |
|---|---|---|
| Section 6 (explicit formula for [1]psi) | `MatchingLogic.Applicative.box_coord₁` | propext, Quot.sound |
| Section 6 (explicit formula for [2]psi) | `MatchingLogic.Applicative.box_coord₂` | propext, Quot.sound |
| Section 6 ("it has two coordinates") | `MatchingLogic.Applicative.coord_eq` | propext, Quot.sound |
| Section 6 ("everything above applies unchanged") | `MatchingLogic.Applicative.semantic_localization_applicative` | propext, Classical.choice, Quot.sound |
| Section 6 (a.b ~>1 a) | `MatchingLogic.Applicative.stepAt_coord₁` | propext, Quot.sound |
| Section 6 (a.b ~>2 b) | `MatchingLogic.Applicative.stepAt_coord₂` | propext, Quot.sound |
| (beyond the paper: boxing is binder-free) | `MatchingLogic.FV_boxes` | propext, Classical.choice, Quot.sound |
| (supporting: word concatenation) | `MatchingLogic.Model.reachWord_append` | propext, Quot.sound |
| Definition 2 (reachability, transitive closure) | `MatchingLogic.Model.reflTransGen_step_iff_exists_word` | propext |
| Section 2, "Closed patterns" | `MatchingLogic.Model.sat_iff_denote_eq_univ` | propext, Quot.sound |
| Definition 2 (reachability) | `MatchingLogic.Model.step_iff_exists_coord` | none |
| BEYOND: Lemma 9's hypothesis is load-bearing | `MatchingLogic.Necessity.locality_needs_backwardClosed_nat` | propext, Quot.sound |
| Remark 17 (free set variables do not come along) | `MatchingLogic.SetVariables.set_variable_is_not_a_constant` | propext, Classical.choice, Quot.sound |
| Section 8 (sort a feeds only itself) | `MatchingLogic.Sorted.feedsStar_a_only_a` | none |
| Section 8 (the sort-feeding induction) | `MatchingLogic.Sorted.mprovable_empty_of_not_feeds` | propext, Quot.sound |
| Corollary 31, at the Proposition 30 data | `MatchingLogic.Sorted.no_faithful_translation` | propext, Classical.choice, Quot.sound |
| (supporting: heterogeneous theories, Section 8) | `MatchingLogic.Sorted.satSetHet_homogeneous` | none |
| Proposition 30, second claim (entailment) | `MatchingLogic.Sorted.Γ3_entails_φ3` | propext, Classical.choice, Quot.sound |
| Proposition 30, third claim (non-derivability) | `MatchingLogic.Sorted.Γ3_not_derives_φ3` | propext, Classical.choice, Quot.sound |
| Proposition 30, first claim (satisfiability) | `MatchingLogic.Sorted.Γ3_satisfiable` | propext, Classical.choice, Quot.sound |
| Lemma 8 (backward closed, contained) | `MatchingLogic.backwardClosed_denoteSet_localize` | propext, Classical.choice, Quot.sound |
| (supporting: word concatenation) | `MatchingLogic.boxes_append` | propext |
| Definition 6 (closedness of Delta_Gamma) | `MatchingLogic.closed_of_mem_localize` | propext, Classical.choice, Quot.sound |
| Corollary 12 | `MatchingLogic.cover_denote_closed` | propext, Classical.choice, Quot.sound |
| Corollary 12 (second half) | `MatchingLogic.cover_sat_iff` | propext, Classical.choice, Quot.sound |
| Corollary 16 (conservativity of definedness) | `MatchingLogic.definedness_conservative` | propext, Classical.choice, Quot.sound |
| Lemma 8 | `MatchingLogic.denoteSet_localize` | propext, Classical.choice, Quot.sound |
| Lemma 8 (largest such set) | `MatchingLogic.denoteSet_localize_greatest` | propext, Classical.choice, Quot.sound |
| Lemma 4 (box semantics) | `MatchingLogic.denote_boxes` | propext, Classical.choice, Quot.sound |
| (supporting: closed patterns are valuation-independent) | `MatchingLogic.denote_closed` | propext, Quot.sound |
| (supporting: denotation depends only on FV) | `MatchingLogic.denote_congr` | propext, Quot.sound |
| Section 2 (semantics of definedness), as a control | `MatchingLogic.denote_defined` | propext, Classical.choice, Quot.sound |
| (supporting: semantics of the diamond) | `MatchingLogic.denote_dia` | propext, Classical.choice, Quot.sound |
| Lemma 7 | `MatchingLogic.globalCons_of_localCons_localize` | propext, Classical.choice, Quot.sound |
| BEYOND: Lemma 7 with no closedness | `MatchingLogic.globalCons_of_localCons_localize_general` | propext, Classical.choice, Quot.sound |
| Corollary 15 (global completeness) | `MatchingLogic.global_completeness` | propext, Classical.choice, Quot.sound |
| Corollary 15 with (S) discharged: only (L) assumed | `MatchingLogic.global_completeness_of_localCompleteness` | propext, Classical.choice, Quot.sound |
| Lemma 9 (locality) | `MatchingLogic.locality` | propext, Classical.choice, Quot.sound |
| BEYOND: localizing is not decoration | `MatchingLogic.localize_not_redundant` | propext, Classical.choice, Quot.sound |
| Lemma 5 (necessitation) | `MatchingLogic.necessitation` | propext, Quot.sound |
| Theorem 14 (proof-theoretic localization) | `MatchingLogic.proof_theoretic_localization` | propext, Classical.choice, Quot.sound |
| Section 3 (M models Gamma iff M models Delta_Gamma) | `MatchingLogic.satSet_localize_iff` | propext, Classical.choice, Quot.sound |
| BEYOND: independent of (L) and (S) | `MatchingLogic.satSet_localize_iff_general` | propext, Classical.choice, Quot.sound |
| Theorem 13 (semantic localization) | `MatchingLogic.semantic_localization` | propext, Classical.choice, Quot.sound |
| BEYOND: Closed gamma is load-bearing | `MatchingLogic.semantic_localization_needs_closed_Γ` | propext, Classical.choice, Quot.sound |
| BEYOND: Theorem 13 without Closed phi | `MatchingLogic.semantic_localization_of_closed_Γ` | propext, Classical.choice, Quot.sound |
| (S) Soundness -- DISCHARGED, not assumed | `MatchingLogic.soundness` | propext, Classical.choice, Quot.sound |
| Definition 6 (Gamma subset of Delta_Gamma) | `MatchingLogic.subset_localize` | none |
| Lemma 11 (two copies), membership form | `MatchingLogic.two_copies` | propext, Classical.choice, Quot.sound |
| Lemma 11 (two copies), displayed form | `MatchingLogic.two_copies_set` | propext, Classical.choice, Quot.sound |
| n-ary Existence Lemma (Section 3.7 of [4]); the engine of (L) | `MatchingLogic.canonicalExistence` | propext, Classical.choice, Quot.sound |
| finite local model existence, arbitrary ambient signature | `MatchingLogic.finiteLocalModelExistence` | propext, Classical.choice, Quot.sound |
| finite-list local completeness over the source variable type | `MatchingLogic.finiteLocalCompleteness` | propext, Classical.choice, Quot.sound |
| (L) strong local completeness, at Var = Nat | `MatchingLogic.strongLocalCompleteness_nat` | propext, Classical.choice, Quot.sound |
| ENTRY POINT (iii): (L), at any countably infinite Var | `MatchingLogic.strongLocalCompleteness` | propext, Classical.choice, Quot.sound |
| Corollary 15 with (L) and (S) both discharged | `MatchingLogic.global_completeness_entryIII` | propext, Classical.choice, Quot.sound |
| BEYOND: Witnessed does not imply FreshWitnessed for an MCS (raw syntax) | `MatchingLogic.witnessed_freshWitnessed_of_isMCS_refuted` | propext, Classical.choice, Quot.sound |
| BEYOND: that failure is not stable under alpha-renaming | `MatchingLogic.alpha_variant_has_a_fresh_witness` | propext, Classical.choice, Quot.sound |
