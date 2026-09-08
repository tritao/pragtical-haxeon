# Plugin API

Plugin manifests and the editor capability API are independently versioned. A
manifest must declare both versions explicitly:

```text
manifestVersion=1
apiVersion=1
id=example
version=1.0.0
entry=Main
source=Main.hx
```

Unsupported or missing versions reject the plugin before compilation and produce
an editor diagnostic. Plugin IDs own a namespace: commands use `id:name`, while
panel and syntax registrations carry the owner separately. Duplicate plugin IDs,
commands, or owner-local panel IDs are rejected. Registration order is load order;
configured user keybindings take precedence over plugin and built-in bindings.

## Host capabilities

`PluginContext.api` is the typed in-process API. API version 1 provides:

- active-document text and transactional replacement of all selections;
- current layered configuration snapshots;
- rendered sidebar panels and panel updates;
- active-document change events;
- cooperative scheduled jobs.

Commands and syntax contributions remain methods on `PluginContext`. Every event
subscription, job, panel, command, binding, and syntax contribution is owned by the
context. Failed activation and unload dispose owned resources in reverse order;
intentional document edits remain in normal undo history.

Dynamically compiled plugins import `pragtical.Editor`, an SDK module supplied by
the host compiler. They call `Editor.connect(id)` during `activate`, then use the
same document, panel, event, and configuration capabilities through an opaque
context token. Tokens cannot name another plugin's registrations and are retired
before its runtime module is disposed.

## Reload state

Dynamic plugins export `stateVersion():Int`, `saveState():String` and
`restoreState(String)`. Compatible body patches keep live runtime state and owned
host resources. A structural reload creates a replacement runtime domain; the host
transfers the opaque saved payload only when the old and replacement
`stateVersion()` values are equal. A changed state version starts with replacement
defaults, preventing an old payload from being interpreted as a new shape.

Compilation runs away from the event loop. Completed artifacts are published only
from an editor update safe point. Obsolete results are rejected by compiler
generation, and unloading retires an unpublished build before disposing its runtime
module.
