# Overnight implementation handoff

This file is a prompt to launch a future implementation run. Creating this plan
does not start an agent, install an automation or assert that a run will last
all night. The roadmap exceeds one night's work; resume from the ledger.

## Launch prompt

> Implement the roadmap in `docs/roadmap/README.md`. First read
> `docs/roadmap/EXECUTION.md`, `docs/roadmap/COMPILER-TYPING.md` and
> `docs/roadmap/STATUS.md`, along with applicable repository instructions.
>
> Start at the first ready unfinished task and continue through successive tasks
> for the available run. Deliver working, verified slices; do not stop at another
> plan or at the first milestone. Preserve the existing dirty work in both the
> editor and the Haxeon compiler checkout. Necessary compiler/runtime/stdlib fixes
> are in scope. When valid code hits a typing defect, reduce it, add regressions
> and fix the general core typing rule. Never evade the problem with weakened
> application types, casts, special cases or disabled diagnostics.
>
> Use the detailed milestone files for task order and acceptance criteria.
> Maintain the execution ledger after each coherent slice, including commands,
> outcomes, compiler fixes and an exact resume instruction. If blocked, record
> the evidence and continue independent ready work. Keep unavailable GUI/platform
> checks pending rather than claiming they passed. Serialize builds sharing output
> directories. Do not push, publish, mutate PRs or discard existing work.
>
> At the end report completed task IDs, verification, unresolved failures, compiler
> changes in the other repository and the next ready task. Leave changes reviewable.

## Suggested first-run target

Complete M0 and proceed into M1 in order. Prioritize correct search revision
handling, durable saving and unified close/quit behavior over checking off more
milestones. A compiler fix may consume the run; leave its reproducer, regression
tests and root-cause explanation so the next run continues without guesswork.

## Morning review

Read STATUS first, inspect diffs in both repositories, review compiler regressions
and perform outstanding graphical checks. Resume with the same launch prompt;
the ledger chooses the next task. Do not rerun already-passing broad checks unless
new changes or unresolved concerns warrant them.
