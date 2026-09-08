# M6 — Develop this repository in the editor

Depends on M5. Extend syntax/highlighting and the plugin/process surfaces; avoid
embedding optional tool integrations directly in Document or RootView.

## M6.1 — Syntax and presentation

- [x] Expand syntax definitions for Haxe/Haxeon, C/C++, Lua, JSON, Markdown and
  shell using reference fixtures; support multiline states and bounded invalidation.
- [x] Add bracket matching, wrapping and folding with explicit visual-line mapping.
  Keep buffer positions stable and define caret behavior inside collapsed regions.
- [x] Add basic word completion through the extension API before language services.

Acceptance: edits near multiline syntax boundaries repair highlighting; wrapped
movement, selection and search reveal the correct physical document positions.

## M6.2 — Background processes and output

- [x] Add owned process handles, argument arrays, cwd/env, nonblocking output,
  cancellation, exit status and shutdown cleanup across platform backends.
- [x] Bound output queues and UI retention; avoid shell interpolation for paths.
- [x] Implement build tasks and an output panel with clickable file/line diagnostics.
  Require a deliberate user command before running project-defined tasks.

Acceptance: run editor tests/build from a task; handle spaces in paths, output
floods, nonzero exit, cancellation and editor shutdown without hanging.

## M6.3 — Language service plugin

- [ ] Build framed JSON-RPC transport on M6.2, with cancellation/timeouts and bounded
  buffers. Start with Haxeon using the available language server after inspection.
- [ ] Implement initialize/shutdown, document open/change/close synchronization,
  versioned diagnostics, hover, completion and go-to-definition.
- [ ] Convert protocol position encoding explicitly; reject stale edits and map
  workspace edits through M1/M2 transactions and conflict handling.
- [ ] Handle server failure/restart, unsupported capabilities and user diagnostics.

Acceptance: a deterministic fake server covers framing, out-of-order replies,
Unicode positions, stale diagnostics and restart; a real Haxeon server smoke test
supports an edit/build/fix cycle in this repository.

Exit: document the self-development route and gaps. Additional language servers,
terminal, SCM and debugger UI remain follow-on work unless separately scheduled.
