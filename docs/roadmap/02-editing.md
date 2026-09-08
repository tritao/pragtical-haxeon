# M2 — Everyday editing semantics

Depends on M1. Files: `src/editor/`, `src/view/DocumentView.hx`,
`src/command/EditorCommands.hx`, platform header/bridge/externs and editor tests.

## M2.1 — Positions, transactions and view ownership

- [x] Document string-index units across Haxeon strings, buffer positions and
  renderer measurement. Add shared boundary conversion helpers; never assume
  UTF-8 bytes, code units and user-visible characters are interchangeable.
- [x] Specify caret/selection per view and shared text/history per document.
  Migrate buffer-owned cursor/anchor deliberately; transform every view's ranges
  through edits and define which view receives restored selection on undo.
- [x] Introduce edit transactions for multiple replacements and history grouping.
  Define typing-group boundaries, redo invalidation and save-point identity.
- [x] Replace single-consumer change notification with owned subscriptions or
  equivalent fanout for highlighting, views, search and future plugins.

Acceptance: edits in one pane update another without moving its caret arbitrarily;
undo restores text and intended selection; Unicode edits never split encoded
characters. Include combining marks and emoji in the declared boundary policy.

## M2.2 — Clipboard and navigation

- [x] Add clipboard read/write through the ABI and deterministic headless storage.
- [x] Wire cut/copy/paste; normalize pasted newlines consistently with M1.
- [x] Add word/page/document movement and selection, selection-collapse behavior,
  double/triple-click selection and drag autoscroll with an injectable clock.

Acceptance: multiline and non-ASCII clipboard round-trip; paste is one undo unit;
page movement respects viewport; drag outside the viewport remains bounded.

## M2.3 — Coding edits

- [x] Implement selection indent/unindent, autoindent, duplicate/move/delete line,
  join lines and comment toggling using syntax metadata.
- [x] Preserve selection direction and trailing-newline behavior. Expose tab width
  and tabs/spaces through typed defaults ready for M5 configuration.

Acceptance: partial-line and multiline selections, blank lines, final line and
mixed indentation fixtures produce expected text with one undo per command.

## M2.4 — Multiple selections

- [x] Add normalized selection sets, overlap merging and stable primary selection.
- [x] Apply edits in a deterministic order with one transaction; define clipboard
  distribution, next-occurrence selection and undo selection restoration.
- [x] Render all carets/selections and keep commands correct for one or many.

Acceptance: overlapping and reversed ranges do not duplicate changes; multiple
insertions/deletions and undo/redo preserve content and selection invariants.
Exit: everyday keyboard/mouse route passes and M1 safety remains intact.
