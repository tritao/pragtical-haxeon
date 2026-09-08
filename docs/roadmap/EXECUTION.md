# Execution contract

## Scope and repository ownership

Implementation covers this editor and necessary compiler/runtime/stdlib fixes
in the checkout selected by `HAXEON_ROOT` (default `../realtime-haxe`). Read
applicable repository instructions before editing either repository. Inspect
`git status --short` and diffs in both at the start and preserve existing work.
The planning inspection found extensive editor changes and an untracked
`tests/driver/TestCatalog.hx` in the compiler repository; do not assume authorship.

Treat `PRAGTICAL_ROOT` (default `../pragtical`) as renderer/reference input.
Do not alter it unless a demonstrated backend defect requires separately scoped
work. No publishing, pushes, PR mutations or destructive cleanup are part of
this plan. No commit is required for a checkpoint. If commits are separately
authorized, stage only owned hunks and record both repositories' commit IDs.

## Work loop

1. Read STATUS and select the first uncompleted task whose prerequisites pass.
2. Inspect its actual implementation and tests; adapt proposed class names to
   existing abstractions. Record meaningful design choices before broad edits.
3. Implement one coherent behavior through model, command and UI as applicable.
4. When compilation exposes a language issue, follow COMPILER-TYPING immediately.
5. Run focused behavioral checks, then the applicable integration gate.
6. Review the diff for regressions, unrelated edits and temporary workarounds.
7. Update STATUS with evidence, remaining limitations and the next exact action.
8. Continue to the next ready task. Do not stop merely because a milestone ended.

If blocked, record the exact failed command, diagnosis and required dependency;
continue independent ready work. Do not simulate unavailable capabilities or
claim completion because the UI displays a placeholder. Stop dependent work
when a real product decision or unavailable authority is required.

## Engineering rules

- Keep document changes transactional and notify all consumers with revisions.
- Use typed editor APIs. Native resources remain opaque generation-checked handles.
- Add ABI functions consistently to the C header, bridge, Haxe externs and backend;
  define failure semantics and update version checks when compatibility changes.
- Bound work per event-loop turn; cancel obsolete jobs and retire callbacks.
- Use deterministic headless services for clocks, file failures and asynchronous
  completion where practical. Test externally observable behavior, not getters.
- Keep application errors visible and recoverable. Do not swallow failures to
  make smoke tests pass.
- Do not undertake speculative rewrites of the buffer, compiler or renderer.
  Use measurements and reduced failures to justify architectural changes.

## Verification commands

Run from the editor root:

```sh
./scripts/test.sh
./scripts/build-sdl.sh
./scripts/run.sh /absolute/path/to/a/disposable/project
```

The test script builds a headless application and exercises platform, command,
view, application, document, plugin, workspace and dynamic-plugin entry points.
The graphical build overwrites the shared output backend; run it after headless
tests before interactive checking. `run.sh` rebuilds and discovers plugin manifests.
Serialize builds/tests that share `out` or `build`; do not race them.

Run `./scripts/test.sh` from the compiler root after a core compiler change.
Its current stages include formatting, runtime bridge build, differential tests
and the test driver. Inspect current scripts before selecting focused cases.
Do not skip format checks or remove cases to obtain a green result.

Capture exit codes and concise results. Classify pre-existing failures with
baseline evidence. A graphical compile is not evidence of working mouse input,
IME, font shaping or a usable screen. If no display is available, mark those
checks pending and continue work that can be validated headlessly.

## Definition of done for a task

Acceptance scenarios pass; user-facing behavior is wired up; regressions have
focused coverage where warranted; relevant integration checks pass; compiler
fixes satisfy their own gate; no unexplained failures or workaround debt are
hidden. Record unperformed platform/manual checks explicitly. Later milestones
may proceed around independent pending checks, but milestone completion cannot
be claimed until its required checks pass.
