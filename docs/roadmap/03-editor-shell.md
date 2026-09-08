# M3 — Complete the editor shell

Depends on M2. Files: `src/commandview/`, `src/view/`, `src/core/FocusManager.hx`,
`src/command/`, `src/style/Theme.hx` and graphical input routing.

## M3.1 — Reusable command input

- [x] Give command input normal caret/selection/clipboard editing, history and
  completion, reusing editing primitives without creating a fake file document.
- [x] Add deterministic fuzzy ranking with exact/prefix preference, path-aware
  scoring and stable tie-breaking. Preserve selection as providers update.
- [x] Implement go-to-line/column and path completion; route picker shortcuts
  through the named registry instead of hardcoded application branches.

Acceptance: keyboard-only file open, command execution, cancellation and go-to
work; empty/no-match/long Unicode queries behave predictably.

## M3.2 — Layout and navigation

- [x] Add directional pane focus, move tab between panes, reorder tabs and close
  controls that use M1 lifecycle handling.
- [ ] Add scrollbars, sidebar resizing/toggling, overflow behavior and minimum
  pane sizes. Keep hit testing consistent with clipping and display scale.
- [x] Restore prior focus after transient UI; scope commands by active context.

Acceptance: nested splits survive resize and collapse; narrow windows stay
operable; sidebar/prompt input cannot mutate an inactive document unexpectedly.

## M3.3 — Status and feedback

- [ ] Surface path, dirty state, line/column, selection, indentation and encoding.
- [ ] Provide reusable confirmations, notifications and an inspectable error log;
  integrate file failures and plugin diagnostics. Bound message retention.
- [ ] Provide consistent theme roles and focus/hover/disabled states rather than
  scattered hardcoded colors and dimensions.

Acceptance: each failure is actionable from the UI; prompt cancellation restores
focus; keyboard and mouse routes work at multiple window sizes and DPI settings.
Exit: core actions are discoverable through commands and visible feedback.
