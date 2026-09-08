# Execution ledger

Last updated: 2026-09-08.

## Current checkpoint

- Active task: M5.2, stable editor API and owned extension capabilities.
- Completed tasks: M0.1, M0.2, M1.1–M1.4, M2.1–M2.4, M3.1–M3.3, M4.1–M4.3 and M5.1.
- M0.3 headless routes are covered; the interactive graphical smoke route remains pending.
- Next action: define the versioned M5.2 host API, registration ownership and an
  example plugin that edits a document, contributes a panel and observes events.
- Editor HEAD: `edeaaa0`. Haxeon HEAD observed: `37c062a`.
- Compiler changes remain separate from editor commits and must pass their own gate.

## Milestones

| Milestone | State | Evidence / remaining gate |
| --- | --- | --- |
| M0 | In progress | M0.1/M0.2 complete; interactive M0.3 smoke pending |
| M1 | Complete headlessly | Stable pathless identity, atomic persistence, Save As, unified close/quit, external conflicts and bounded recovery pass; graphical prompt smoke remains in the M0.3 manual route |
| M2 | Complete headlessly | Everyday editing, clipboard/navigation, coding transformations and normalized multiple selections pass; graphical keyboard/mouse smoke remains in M0.3 |
| M3 | Complete headlessly | Reusable command input, pane/tab/sidebar navigation, logical-point DPI routing, status, bounded feedback, error inspection and centralized UI roles pass; interactive M0.3 smoke remains |
| M4 | Complete headlessly | Responsive index/search, safe replacement, recoverable file operations and defensive sessions pass; graphical smoke remains in M0.3 |
| M5 | In progress | M5.1 complete; stable editor API and reload reliability remain |
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

### M1 — safe file lifecycle

- `b294ba2` added pathless, uniquely identified untitled documents and Save As,
  with duplicate-open and overwrite collision handling.
- `840781f` made backing paths explicitly optional throughout the document and
  versioned recovery models.
- `38328ca` unified tab close, pane close and native quit behind one
  Save/Discard/Cancel coordinator, including shared-document and failed-save cases.
- `91b0234` bounded recovery retention to the newest 50 snapshots and retires an
  accepted snapshot before regenerating state for documents that remain dirty.
- Existing atomic persistence, external-change reconciliation, BOM/newline
  round-trips, missing/corrupt recovery and injected failure cases complete the M1
  headless acceptance routes.
- `./scripts/test.sh` exited 0 at editor HEAD `91b0234`; interactive prompt behavior
  remains part of the pending M0.3 graphical smoke route.

### M2.1 — positions, transactions and view ownership

- `9d5ddf3` replaced the single buffer callback with structured, independently
  releasable change subscriptions and documented UTF-16 code-unit positions at
  Unicode scalar boundaries.
- `942fdbc` began transforming inactive-pane ranges through shared edits.
- `ec158d3` removed caret and selection state from `TextBuffer`; every editor view
  now owns its selection while documents share text and history. View teardown
  releases subscriptions.
- `98a0109` added explicit multi-replacement transactions, adjacent typing groups,
  movement boundaries, redo invalidation and initiating-view selection restoration.
- Tests cover emoji surrogate boundaries, the declared combining-mark behavior,
  independent split-pane cursors, passive range transformation, grouped typing,
  overlapping-transaction rejection and transaction undo/redo.
- `./scripts/test.sh` and `./scripts/build-sdl.sh` both exited 0 at `98a0109`.

### M2.2 — clipboard and navigation

- `a6b5cf8` added platform ABI v5 clipboard read/write with deterministic headless
  storage, SDL integration, HashLink UTF-8 conversion and Ctrl+C/X/V editing.
  Paste normalizes CRLF/CR to the buffer's logical LF representation and remains
  one undo unit.
- `d61c88a` added selection collapse, word/page/document movement and selection,
  double/triple-click selection, SDL click-count forwarding and bounded drag
  autoscroll driven by an injectable clock. Page keys are covered by ABI v6.
- Tests cover multiline/non-ASCII clipboard round-trips, cut/paste undo, viewport
  page movement, word/document ranges, click selection and timed outside-viewport
  dragging.
- `./scripts/test.sh` and `./scripts/build-sdl.sh` both exited 0 at `d61c88a`.

### M2.3–M2.4 — coding edits and multiple selections

- `f16a506` added single-transaction indent/unindent, autoindent, duplicate/move/
  delete/join line and syntax-driven comment commands. Typed `editor.tabWidth` and
  `editor.insertSpaces` settings select spaces or tabs per project.
- `e9d42aa` introduced normalized selection sets, stable primary selection,
  document-order clipboard distribution, next-occurrence selection, selection-set
  history snapshots and rendering for every caret/range.
- `b5be0c3` extended movement, insertion/deletion, indentation, comments and line
  transformations across multiple selections. `4987556` covers blank, partial and
  trailing-newline indentation semantics.
- Tests cover reversed/overlapping ranges, multiple insertions and deletions,
  distributed copy/paste, next occurrence, undo/redo range restoration, mixed
  indentation, blank/final/trailing lines and one-transaction command behavior.
- `./scripts/test.sh` and `./scripts/build-sdl.sh` both exited 0 at `4987556`.

### M3.1 — reusable command input

- `d10ddf8` gives command input its own reusable text buffer and selection,
  clipboard editing, undo/redo, history traversal and completion without creating
  a document.
- Command results use deterministic exact/prefix/path-aware fuzzy ranking with
  stable tie-breaking and preserve the selected identity across provider updates.
- Named commands provide keyboard-only command execution, file opening and
  go-to-line/column behavior; file completion operates on workspace paths.
- Headless application and command-view tests cover empty, unmatched and Unicode
  queries, completion, cancellation, history and navigation.

### M3.2 — layout and navigation

- `86dd34e` adds directional pane focus, tab movement and reordering, lifecycle-
  coordinated close controls, sidebar toggle/resize, active-tab overflow,
  physical split clamps and draggable editor scrollbars.
- Modal command input owns pointer and wheel routing without moving editor focus,
  preventing an inactive document from being changed through prompt input.
- Headless tests cover focus, tab movement/reordering, narrow layouts, close
  routing, modal input isolation and scrollbar dragging; the SDL artifact builds.
- `8e56b15` makes the platform coordinate contract explicit: window dimensions,
  pointer events, clipping and drawing all use logical points while display-scale
  changes update the backing renderer and propagate through ABI v11. Headless
  tests preserve logical hit-test/layout coordinates at a synthetic 1.75 scale.

### M3.3 — status and feedback

- `c8004f4` adds a reusable status view with path, dirty state, caret, selection,
  indentation, UTF-8/BOM and newline details; bounded notification and error
  histories; an inspectable error command; and reusable typed confirmations.
- File, recovery, configuration and plugin failures feed actionable notifications
  and the retained error log. Escape now cancels the lifecycle transaction behind
  a close confirmation instead of merely hiding its prompt.
- `8e56b15` centralizes shell/editor colors into semantic theme roles, including
  focused, hovered, selected, muted and disabled states.
- `73517b6` covers bounded retention, plugin diagnostics, status transitions,
  Escape cancellation/re-entry and the inspectable log. `./scripts/test.sh` and
  `./scripts/build-sdl.sh` both exited 0 at that editor HEAD.

### M4.1 — scheduling and project index

- `970aee6` introduces a cooperative round-robin scheduler with stable job IDs,
  replacement generations, stale-handle rejection, cancellation and an exact
  per-update step budget. `76a301a` moves project enumeration and bounded polling
  onto those jobs and gives the tree, file picker and search one indexed file set.
- Scans publish the initial tree incrementally and publish later reconciliations
  only from the current generation. Exclusions apply before descent; canonical
  directory identities prevent the benchmark's symlink cycle from recurring.
  Removing a project cancels its scan and retired state rejects later publication.
- `11dcc5c` adds `scripts/benchmark-project-index.sh`. On 2026-09-08, a 10,000-file
  fixture (100 directories × 100 files plus a root symlink cycle) completed in
  100 one-directory updates, with 100 simulated input-service ticks and a maximum
  observed update of 40.499 ms on an Intel Core i5-13600K with 31 GiB RAM.
- The full headless suite and SDL artifact build passed at `76a301a`; the dedicated
  benchmark passed at `11dcc5c` including cancel/reopen stale-result checks.

### M4.2 — search and replacement

- `00340f2` moves workspace search onto debounced, generation-cancelled scheduler
  jobs. Results stream in bounded batches with caps and preview limits; dirty open
  buffers take precedence over disk. Binary, oversized and unreadable files become
  retained partial-result diagnostics rather than aborting the query.
- `c0acd51` adds case, whole-word, path and PCRE2 regular-expression searches,
  including capture-aware replacement, invalid-pattern reporting and scalar-safe
  progression after zero-width matches. Document replacement remains one undoable,
  revision-checked buffer transaction.
- `1460df1` adds an explicit project replacement preview/apply route. Every file is
  revalidated after preview; open documents receive independent undoable edits and
  disk files use atomic M1 publication with per-file applied/conflict/failure
  outcomes. The complete previous contents and expected post-write contents of the
  latest disk batch are retained at `replacement-backup.conf`; restore is explicitly
  best-effort per file and refuses subsequently changed files, not a cross-file undo.
- `20b95b0` proves binary, 5 MiB oversized and permission-denied inputs as distinct
  partial failures. Rapid replacement generations, result caps, dirty precedence,
  filters, regex captures/zero-width/invalid cases, disk conflicts, backup restore
  conflicts and preview/apply equality are covered headlessly.
- The complete headless suite and SDL artifact build passed after the final M4.2
  implementation. Interactive confirmation behavior remains in the M0.3 smoke route.

### M4.3 — file operations and sessions

- `c5543c0` centralizes collision-checked file/folder creation, rename/move and
  recoverable deletion. Directory moves rewrite every nested open-document path;
  dirty documents save only to the new location. Deletion moves entries into the
  application state trash and detaches affected buffers as dirty pathless documents
  so recovery and Save As remain available.
- `7c2c6bf` introduces session v2 and recovery v3. Pane tabs reference clean paths
  or stable recovery identities, allowing multi-root split layouts, active views,
  caret/scroll state and dirty/pathless contents to survive restart without embedding
  recovery text in the session. Missing projects/files/recovery entries and malformed
  layout records are skipped. Session writes settle behind a 750 ms debounce and
  flush explicitly during graphical shutdown.
- Headless coverage exercises file and folder collisions, nested directory moves,
  dirty saves after rename, recoverable deletion, missing project/tab entries,
  malformed sessions, stable untitled recovery, debounced publication and shutdown
  flush. The complete headless suite and SDL artifact build passed at `7c2c6bf`.
- The 10,000-file project benchmark was rerun at the M4 exit gate: 100 updates and
  100 input ticks, with a maximum observed update of 51.621 ms on the previously
  recorded Intel Core i5-13600K / 31 GiB host.

### M5.1 — configuration

- Haxeon `37c062a` adds the standard `Sys.systemName()` platform boundary and a
  runtime regression; the compiler/runtime gate passed all 201 tests.
- `edeaaa0` makes configuration subscriptions independently disposable, converts
  read failures into retained diagnostics, preserves last-good settings across
  invalid bytes and detects restoration of previously accepted bytes.
- Every semantic theme role, font, indentation, keybinding, exclusion and search
  setting participates in defaults < user < active-project layering. Changes apply
  live; project disposal releases its subscription, keymaps replace configured
  bindings, and font replacement destroys the retired native handle.
- Project files remain versioned data and unknown keys reject the complete layer.
  Linux/BSD XDG, macOS, Windows and authoritative portable locations are defined in
  `docs/configuration.md` and selected using the host system name.
- Headless acceptance covers precedence, invalid rollback/recovery, visible project
  diagnostics, project switching, default reset, subscription cleanup, live theme,
  single keybinding installation and stale font-handle rejection. The complete
  headless suite and SDL artifact build passed at `edeaaa0`.

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
- Haxeon `7598300` preserves nullable narrowing for captured locals in callbacks;
  positive and negative regressions pass with the full compiler suite.
- Haxeon `4bd73cf` compares runtime strings by value in statement switches rather
  than relying on pointer identity; its runtime-created-string regression passes.
- Haxeon `14eeadd` propagates assignment and refinement facts from completing block
  expressions, fixing concise try-expression narrowing without weakening nullable
  field access. Accepted class/interface and rejected continuing-catch cases pass.
- Haxeon `73c7ca3` replaces substring-emulated `EReg` with HashLink's PCRE2 engine,
  including captures, invalid-pattern exceptions and terminating zero-width global
  replacement. Haxeon `1512bc7` captures the receiver for implicit instance-field
  assignment in lambdas instead of emitting an invalid raw `this` local.
- Reinspect repository ownership and run the compiler gate before further compiler edits.

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
