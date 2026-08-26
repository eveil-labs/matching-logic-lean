# How this was built, and the one thing it found

A companion to `README.md`, which says *what* is proved, and `FINDINGS.md`,
which is addressed to the paper's authors. This one is the argument: why the
development is shaped the way it is, what that shape cost, and what it bought.

---

## 1. The challenge

Section 10 of Chen and Roșu, *Completeness and incompleteness of basic matching
logic* (arXiv:2608.13306), proposes mechanizing its Corollary 15 in three entry
points of increasing ambition. Entry point (i) is Lemmas 9 and 11 alone.
Entry point (ii) is Corollary 15 with (L) strong local completeness and (S)
soundness assumed. Entry point (iii) discharges (L) as well, "yielding a
self-contained machine-checked global completeness theorem".

All three are discharged here. (S) is proved rather than assumed, which (ii)
permitted us to skip. (iii) is proved at the paper's own variable scope, a
countably infinite element-variable type, and that qualification is stated
wherever the claim is made.

## 2. One early choice decided everything after it

Patterns are raw named syntax. `Pattern` is an inductive type over named
variables, and it is not quotiented by α-equivalence. Substitution is a function
on that type. Capture-avoidance is a side condition, not a convention.

The source does the opposite and says so: it regards α-equivalent patterns as
the same and lets substitution rename binders implicitly. That is the standard
and entirely sound thing to do.

For entry points (i) and (ii) our choice was free. Lemmas 9 and 11 and Theorem
13 are purely semantic. They speak only of valuation update `ρ[a/x]`, so
substitution appears in exactly one place, rule (3) of Figure 2, where the paper
itself writes "capture-avoiding" as a side condition. Nothing had to be
quotiented because nothing was substituted.

Entry point (iii) is where the bill came due. A canonical-model construction
needs Henkin witnesses, and Henkin witnesses are substitution. About 2,700 of
the 6,616 lines of the construction are α-equivalence, capture-avoidance and
witness plumbing, machinery the source needs none of because its convention
supplies it.

The obvious hypothesis, and the one we started from, was that this was waste. A
better definition, or the quotient, would make it go away.

## 3. It is not waste

The construction carries a stronger invariant than the source states. Where the
source's witnessed condition asks for some Henkin witness, and its Lemma 3.22
picks one not occurring free in the theory so far and the body, ours,
`FreshWitnessed`, demands a witness avoiding every variable of the body,
bound ones included. Five steps. Four are settled by machine-checked proof; the fourth is a reading
of the source and is marked as one.

**The two conditions do differ.** `witnessed_freshWitnessed_of_isMCS_refuted`
exhibits a maximal locally consistent set that is witnessed and not
fresh-witnessed. Take the empty signature, carrier `Bool`, a valuation naming
`true` by the variable 0 and everything else by `false`, and the complete theory
of the point `true`. It is witnessed because that valuation is surjective, so
every satisfied existential has some name for its witness. It is not
fresh-witnessed because `∃0. var 0` belongs to it while 0 is the only name for
`true`, and 0 occurs in the body. Maximality is discharged, not assumed.

**That is not an artifact of refusing the quotient.**
`witnessed_alphaFreshWitnessed_of_isMCS_refuted` allows the witness to be fresh
for any α-variant, and the separation still stands. Over a signature with one
binary symbol, `∃1. pair(var 1, var 0)` blocks every representative: the
application depends on both arguments, so there is no vacuously quantified
equivalent to escape into. Quotienting by α would not remove the need for the
stronger invariant.

**What repairs it is the supply.** By
`freshWitnessed_of_witnessed_of_supply`, if every existential has infinitely
many usable Henkin names then fresh-witnessedness follows, because the body has
only finitely many variables. The proof is three lines. Its value is not
technical. It names the mechanism, and the mechanism is not α.

**The source gets that supply from its variable extension.** Lemma 3.22 begins
by extending the variable set `V` to `V⁺` with countably many new variables and
draws every witness from `V⁺ \ V`. We mechanized Lemma 3.22 at the paper's
generality, arbitrary locally consistent sets, as
`locConsistent_extend_freshWitnessed_isMCS`. Because our variables are already
all of `ℕ` and cannot be extended, the hypothesis has to appear explicitly, as
`InfiniteFreshVariableSupply`. It translates the extension step rather than
correcting it.

**And the hypothesis is load-bearing.** This is the sharp end.
`locConsistent_extend_freshWitnessed_isMCS_unrestricted_refuted` shows that
dropping it makes the statement false. Feed the extension the
witnessed-but-not-fresh MCS from the first result. It is already maximal, so any
locally consistent extension equals it, so it would have to be fresh-witnessed
itself, which the first result refutes.

## 4. What that adds up to

Nothing above corrects the source. Its Definition 3.5 needs no freshness
condition and its Lemma 3.22 is correct, because both live in the α-quotient and
Lemma 3.22 performs the variable extension in its own statement.

The need for the extension is not news either. The paragraph above Lemma 3.22
gives a counterexample of its own, `Γ = {¬x | x ∈ V}`, consistent and not
extendable to a witnessed MCS without new variables.

What the mechanization adds is a sharper form of the same phenomenon. The
source's counterexample is consistent but not maximal, and adding variables
repairs it. Ours is already an MCS, so there is nothing left to add. Once the
target is fresh-witnessedness on raw syntax, the supply has to appear as a
hypothesis on the starting theory rather than as a step in the construction, and
dropping it makes the statement false.

One concrete suggestion follows, and it is the only thing we ask the authors
about. Lemma 3.22's side condition can be strengthened from *does not occur
free* to *does not occur*, at no cost, since the paper's own justification (only
finitely many variables of `V⁺ \ V` are in play at each stage) already delivers
it.

What that buys needs stating carefully, because the first version of this
paragraph got it wrong and this repository refutes it. The strengthening does
not make the α-renaming step unnecessary. `∃xᵢ.(ψ[xᵢ/x])` and `∃x.ψ` are still
different raw patterns, and our own mechanization of that step assumes the
strengthened condition and renames anyway. What changes is the step's status.
Under the weaker condition the identification is a meta-level appeal to the
quotient. Under the stronger one the renaming is capture-free and the
implication is derivable inside Figure 2, from rules (3) and (4). The
construction transfers to raw syntax with α-conversion as a derived rule instead
of a convention. That is a smaller claim than the one first written here, and a
true one.

There is a general moral, for mechanizers rather than for the authors. A
convention that is sound and invisible in prose becomes a proof obligation the
moment you refuse it, and the obligation is not always where you expect. Here it
was not α at all. It was the supply of names.

## 5. How any of this is believed

The Lean kernel settles one question: is this proof valid. That turned out to be
the question we were least likely to get wrong, because a bad proof does not
compile and gets fixed within the minute.

Everything else we got wrong at least once. Across the development and ten
rounds of adversarial review, twenty-seven real defects were recorded, and the
kernel caught none of them. They were wrong statements, wrong prose, wrong
claims about what had been proved, and most often wrong instruments: gates that
could not fail, gates that verified themselves, gates that reported success
having compared nothing. Round eight found an `axiom` declaration that passed
every check in the repository. Round nine found that the repair to round eight
had, in three separate places, gone on to identify our own code by its name, and
was walked past by writing the same declaration outside the namespace or marking
it `private`. Round ten found two gates that printed FAIL and exited 0.

The response is that the checks in `scripts/` are adversarial artifacts in their
own right, each fire-tested against the attack that motivated it, and that two
of the most important checks are not ours at all: `lake exe axiom-audit` from
leanprover-community, and `lake exe mk_all --check`, which comes with Mathlib.
`lake env leanchecker`, the kernel replay built into the toolchain, replays the
whole library independently. Preferring maintained tools to hand-rolled ones was
not modesty. The hand-rolled ones had the worse defect record.

`INCIDENTS.md` in the working repository is the full list, kept as the work
happened rather than reconstructed.

## 6. What we got wrong in this note's own subject

Three times while establishing the results in section 3, we generalized past
what a probe had actually checked.

Once, from a single countermodel, to the conclusion that quotienting by α would
collapse the machinery. That claim is false. It survives in an immutable commit
message and, until round ten pointed it out, in a docstring inside
`WitnessedCollapse.lean` that ships with this repository. The docstring is now
corrected. The commit message cannot be.

Once, to a proposed countermodel of our own, `∃1.(var 1 ∧ var 0)`, on the
reasoning that its only usable witness is a free variable and therefore beyond
α's reach. That reasoning assumed α renames only bound names, which is true of
syntactic α and false of the coarser proof-theoretic relation this development
uses in its place, under which the pattern is equivalent to a vacuously
quantified one. An independent lane refuted it and found the countermodel that
does work.

Once, in the sentence this note offers the authors, which claimed the
construction "transfers to raw named syntax unchanged". Our own mechanization of
that step performs the renaming it says is unnecessary. Round ten caught it
before the note was sent.

All three were caught before anything shipped, and all three have the same
shape. It seemed worth writing down, in a document whose subject is a
distinction that took four independent attempts to state correctly.
