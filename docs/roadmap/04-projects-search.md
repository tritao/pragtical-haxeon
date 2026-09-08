# M4 — Responsive project workflows

Depends on M3. Files: `src/workspace/`, `src/search/`, command-view providers,
sidebars, Application update loop and platform services as needed.

## M4.1 — Scheduling and project index

- [ ] Introduce cancellable jobs with stable IDs, generations and bounded work per
  update. Keep editor mutation on its owning thread. Start cooperatively where
  adequate; blocking I/O needs a worker/native service when measurements require it.
- [ ] Share an index between tree, file picker and search. Incrementally enumerate
  directories; publish batches; enforce exclusion rules and symlink-cycle safety.
- [ ] Add change watching or a bounded polling fallback, refresh and reconciliation.
  Retire jobs when projects close; ignore stale completion events.

Acceptance: a disposable 10,000-file tree indexes while input events are serviced;
cancel/reopen does not publish old results; create/rename/delete becomes visible.
Record hardware, dataset and observed maximum update duration in STATUS.

## M4.2 — Search and replacement

- [ ] Debounce queries, cancel previous generations, stream results and cap retained
  results/preview lengths. Search dirty open buffers in preference to disk versions.
- [ ] Skip or explicitly handle binary, unreadable and oversized files; expose
  partial-result/error state. Add case, whole-word, regex and path filters.
- [ ] Handle zero-width regex progression, capture replacement and invalid patterns.
  Keep document replacements transactional and revision checked.
- [ ] Add project replacement preview and explicit apply, revalidate disk/document
  versions, use M1 writes and report per-file outcomes. Never promise atomic undo
  across arbitrary disk files; define recovery/backup behavior before enabling it.

Acceptance: rapid query changes cannot show stale results; disk conflicts block
affected writes; regex edge cases terminate; replace preview matches applied edits.

## M4.3 — File operations and sessions

- [ ] Expose create/rename/move/delete with collision handling and confirmations;
  reconcile open document paths and dirty buffers. Prefer recoverable deletion.
- [ ] Persist versioned project roots, pane tree, tabs, active view, carets and scroll
  state. Keep recovery contents in M1's recovery store, referenced by stable ID.
- [ ] Restore defensively when files/plugins are missing or state is corrupt;
  debounce writes and flush at controlled shutdown points.

Acceptance: session round-trip restores a multi-root split layout; missing files
do not abort startup; rename of an open dirty file cannot save to the old path.
Exit: benchmark/search evidence and full daily project smoke route recorded.
