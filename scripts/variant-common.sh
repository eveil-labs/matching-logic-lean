# Sourced by scripts/audit-variants.sh and scripts/gen-variants-baseline.sh.
#
# Both must append the SAME commands and slice the SAME region out of Lean's
# output, or the gate compares one thing against a baseline that recorded
# another. They used to hold two copies of both, and round eight found a defect
# living in both copies at once. One copy now, here.
#
# ROUND EIGHT fixed the SLICE. It had been a line-prefix filter keeping a
# continuation line only if it began with `fun ` or two spaces, so of the 144
# lines the five variants print, 92 were recorded and 52 were not -- every
# theorem's type, and every `@[reducible]` model definition the countermodels
# rest on. The slice is now sentinel-delimited and drops nothing.
#
# ROUND NINE found the same defect one level up, in what was being printed. The
# block was built by grepping `^(private )?theorem ` and `^(private )?(def|
# abbrev) `, while the comment above it claimed "every theorem in the file, so a
# documented control cannot be replaced by a proof of `True`". Both reviewers
# added undocumented public declarations to a variant that the gate did not see:
# `lemma`, `@[simp] theorem`, `noncomputable def`, `instance`, `structure`.
#
# So nothing is selected by line shape any more. The block below asks LEAN which
# declarations the file introduced -- every constant the environment reports no
# module for, which is exactly what this file declared -- and elaborates a
# `#print` or `#check` for each. A declaration cannot hide from it by being
# spelled differently, attributed, or put in another namespace.

VARIANT_SENTINEL='@@VARIANT-SURFACE@@'

# variant_decls -- the shared print block. Must be the LAST thing appended to
# the file under test, so that everything after the sentinel is the surface.
# `logInfo` rather than `IO.println`: elaborated commands write to the message
# log, and only a log message is ordered with them.
variant_decls () {
  cat <<'LEAN'
open Lean Elab Command in
run_cmd do
  let env ← getEnv
  let mut ds := #[]   -- definitions: print the BODY
  let mut ts := #[]   -- theorems and axioms: print the TYPE
  let mut is := #[]   -- inductive types: print the RECURSOR's type, i.e. the
                      -- constructor set, so a case cannot be added or reshaped
  let mut np := 0     -- private declarations: unreachable by `#print`, so
                      -- counted instead, which still makes an addition visible
  for (n, ci) in env.constants.toList do
    -- Declared HERE: the environment has no module for it. Not a name test.
    if (env.getModuleIdxFor? n).isSome then continue
    let user := (privateToUserName? n).getD n
    if user.isInternal then continue
    let s := user.toString
    -- compiler-generated equation lemmas, match auxiliaries, proof terms
    if (s.splitOn ".eq_").length > 1 || (s.splitOn ".match_").length > 1
       || (s.splitOn ".proof_").length > 1 || s.endsWith ".splitter"
       || s.endsWith ".eq_def" || s.endsWith ".sizeOf_spec"
       || s.endsWith ".congr_simp" || s.endsWith ".brecOn.eq" then continue
    if (privateToUserName? n).isSome then np := np + 1; continue
    match ci with
    | .defnInfo _   => ds := ds.push n
    | .thmInfo _    => ts := ts.push n
    | .axiomInfo _  => ts := ts.push n
    | .inductInfo _ => is := is.push n
    | _ => pure ()
  logInfo "@@VARIANT-SURFACE@@"
  logInfo s!"declared here: {ds.size} definitions, {ts.size} theorems, {is.size} types, {np} private"
  for n in ds.qsort (fun a b => a.toString < b.toString) do
    elabCommand (← `(command| #print $(mkIdent n)))
  for n in ts.qsort (fun a b => a.toString < b.toString) do
    elabCommand (← `(command| #check @$(mkIdent n)))
  for n in is.qsort (fun a b => a.toString < b.toString) do
    elabCommand (← `(command| #check @$(mkIdent (n ++ `rec))))
LEAN
}

# variant_surface -- stdin is Lean's whole output; stdout is the pinned surface.
# Everything after the sentinel, with runs of spaces and blank lines collapsed
# so that re-indentation alone is not a diff. No line is dropped.
variant_surface () {
  sed -n "/^${VARIANT_SENTINEL}\$/,\$p" | tail -n +2 | tr -s ' \n' ' \n'
}
