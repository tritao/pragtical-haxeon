# Execution ledger

Last updated: 2026-09-08.

## Current checkpoint

- Active task: M1.1, document identity and persistence service.
- Completed tasks: M0.1 and M0.2.
- M0.3 headless routes are covered; the interactive graphical smoke route remains pending.
- Next action: introduce pathless, uniquely identified untitled documents and separate display titles from backing paths, then implement Save As.
- Editor HEAD: `35d73f0`. Haxeon HEAD observed: `cb1aa65`.
- Concurrent compiler work remains outside editor commits and must be reinspected before compiler edits.

## Milestones

| Milestone | State | Evidence / remaining gate |
| --- | --- | --- |
| M0 | In progress | M0.1/M0.2 complete; interactive M0.3 smoke pending |
| M1 | In progress | Atomic persistence, conflicts and recovery exist; untitled/Save As and unified close/quit remain |
| M2 | Partial foundation | Unicode-safe surrogate movement and per-view cursor snapshots exist; transactions, clipboard, coding edits and multiple selections remain |
| M3 | Partial foundation | Command view and split shell exist; navigation, reusable feedback and theme roles remain |
| M4 | Partial foundation | Bounded polling, multi-root search, file operations and sessions exist; scheduling/scale and replacement remain |
| M5 | Partial foundation | Layered typed settings and plugin reload exist; subscriptions and stable editor API remain |
| M6 | Pending | Development workflow |
| M7 | Pending | Packaging, performance and platform checks |

## Completed records

### M0.1 — trustworthy baseline

- Native platform tests, every Haxeon application test entry, and the SDL graphical artifact build successfully.
- `./scripts/test.sh` exited 0; `./scripts/build-sdl.sh` exited 0.
- The pre-existing top-level `README.md` edit remains outside implementation commits.
- A graphical compile does not prove mouse, IME, DPI or screen usability; the interactive M0.3 route remains pending.

### M0.2 — current search slice

- Commit: `35d73f0 Bind document search results to revisions`.
- Matches carry document identity, buffer state and matched text. Selection and replacement reject stale ranges. Editing, undo and active-document changes refresh or invalidate results.
- Replace-all is one buffer edit and therefore one undo operation. Cancelling find clears transient highlights across views. A named command returns workspace search to the project sidebar.
- Coverage reproduces edit-after-find, undo refresh, document switching, replace-all/undo, cancelled highlighting and multi-project result activation.
- `./scripts/test.sh` exited 0 after the final changes.

## Previously delivered roadmap foundations

- `028c7fa`: safe file lifecycle, recovery, project polling and restorable split workspaces.
- `21ba9de`: exception-based atomic write integration and embedded-NUL byte test.
- Haxeon `e573f8f`: byte-oriented, error-reporting atomic publication with POSIX durability and Windows replacement support.
- `e9b47c2`: layered configuration and workspace sessions.
- `e08b0e4`: command-view document/workspace search.

These commits satisfy only the behaviors evidenced by their tests; they do not mark an entire later milestone complete.

## Compiler issue register

- Lambda bodies were previously pretyped outside their flow context. Haxeon `0643a3c` removed that unsound pass and added accepted callback/interface cases.
- Atomic publication required a runtime/stdlib facility rather than weakened editor persistence. Haxeon `e573f8f` owns that platform boundary.
- Additional compiler changes are concurrent. Reinspect ownership and run the compiler gate before attributing compiler files.

## Blockers and pending manual checks

- Interactive M0.3 graphical smoke route is pending.
- Windows atomic publication is implemented but has not been executed on Windows; do not claim platform qualification before M7 evidence.
- No current blocker prevents headless roadmap implementation.

## Record template

```text
Task ID and state:
Timestamp:
Repository HEADs and pre-existing changes:
Behavior delivered:
Design decisions and rationale:
Files / owned hunks changed:
Commands, exit codes and observed results:
Manual checks performed / still pending:
Compiler issue ID, reduced case, root cause and regression evidence:
Failures classified as introduced / baseline / environment:
Remaining work and exact next action:
```
