# Implementation roadmap

Planning baseline: 2026-09-08. This is an execution plan, not a claim that the
current tests pass. The source inspection includes uncommitted changes.

## Destination

Deliver a lightweight, responsive, configurable desktop coding editor with
Pragtical-like editing, project navigation, search, extensibility and polish.
Keep the Haxeon application core and the platform boundary in
[ADR 0001](../architecture/0001-platform-boundary.md). Reuse the sibling
Pragtical renderer. Lua plugin binary/source compatibility is not assumed.

## Execution order

| Stage | Plan | Depends on | Result |
| --- | --- | --- | --- |
| M0 | [Baseline](00-baseline.md) | None | Verified starting point |
| M1 | [File safety](01-file-safety.md) | M0 | Safe real-file editing |
| M2 | [Editing](02-editing.md) | M1 | Complete everyday editing |
| M3 | [Editor shell](03-editor-shell.md) | M2 | Discoverable, usable interface |
| M4 | [Projects and search](04-projects-search.md) | M3 | Responsive project workflows |
| M5 | [Configuration and plugins](05-configuration-plugins.md) | M4 | Useful, reloadable extensions |
| M6 | [Coding tools](06-coding-tools.md) | M5 | Develop this project in this editor |
| M7 | [Release quality](07-release-quality.md) | M6 | Reproducible standalone release |

Read [the execution contract](EXECUTION.md) and
[the compiler policy](COMPILER-TYPING.md) before implementing any stage.
Record progress in [STATUS.md](STATUS.md). Use [OVERNIGHT.md](OVERNIGHT.md)
as the launch handoff. Task IDs are stable; check a task only after its
acceptance criteria have evidence. Each numbered task is a bounded delivery
unit, not a promise that a whole milestone fits in one night.

## Observed foundation

- Platform ABI, native/headless backend and Pragtical-backed rendering.
- Text buffer, undo/redo, save, selection, scrolling and measured caret placement.
- Document manager, tabs, pane layout, focus, named commands and keybindings.
- Project roots, directory tree, file command view, syntax registry/highlighter.
- In-progress document/workspace search and replacement.
- Plugin registration, dynamic compilation, patching and module reload.
- Native tests and Haxeon application test entry points.

Important gaps observed: quit bypasses dirty-document resolution; saving writes
directly to the destination; workspace search reads files synchronously;
plugin refresh rereads source files every update; cursor/anchor live in the buffer.
Validate these observations again before changing their implementation.

## Scope after M7

Terminal/PTY, SCM and diff UI, control CLI, workbench/agent features, web target
and Lua compatibility are separate follow-on plans. The sibling Pragtical
checkout includes features beyond the initial destination. Record additions
explicitly instead of silently expanding a milestone.

## Release gates

M1: file-safety scenarios pass. M4: daily text/project workflows are usable.
M6: an edit/build/diagnose cycle works on this repository. M7: packaged build
works outside the checkout, with measured performance and platform evidence.
Carry correctness and performance checks through all stages; M7 consolidates them.
