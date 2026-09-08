# M5 — Configuration and useful extensions

Depends on M4. Files: `src/plugin/`, `src/style/`, command registry/keymap,
Application and `plugins/example/`. Add typed services where needed.

## M5.1 — Configuration

- [x] Define versioned typed settings with defaults < user < project precedence,
  schema validation and visible diagnostics. Invalid reload retains last good values.
- [x] Expose fonts, theme, indentation, keybindings, exclusions and search limits.
  Apply changes through subscriptions with explicit resource cleanup.
- [x] Treat project settings as data; do not autoexecute arbitrary project code.
  Define platform user-data locations and portable-mode behavior.

Acceptance: layered overrides, invalid values, live font/theme changes and reset
to defaults work without leaked resources or duplicate bindings.

## M5.2 — Stable editor API

- [x] Define typed capabilities for documents/transactions, selection, commands,
  views/panels, events, scheduling, configuration and syntax contributions.
- [x] Ensure dynamically compiled plugins can actually invoke host capabilities;
  current manifest-exported void commands alone are not a full editor API.
- [x] Own registrations by plugin identity and dispose all subscriptions, commands,
  jobs and views on unload. Specify ordering and conflict handling.
- [x] Version manifests/API compatibility and report missing/incompatible plugins.

Acceptance: an example plugin performs a real document edit, contributes a panel
and observes an event; unload removes all effects except intentional text edits.

## M5.3 — Reload reliability

- [ ] Replace source rereads each frame with M4 change detection/debouncing.
- [ ] Compile changes without unbounded UI stalls; stage publication at safe points.
- [ ] Retain last working plugin on compile failure. Define rollback or safe
  deactivation on activation failure; never leave half-registered behavior.
- [ ] Specify versioned state transfer for incompatible reloads and retirement of
  old callbacks. Preserve document/native resources across compatible body patches.
- [ ] Expose enable/disable/reload and diagnostics in the editor.

Acceptance: repeatedly patch and structurally reload the example; inject compile,
activation and removal failures; assert no duplicate commands or stale callbacks.
Exit: document plugin API and local development workflow with runnable examples.
