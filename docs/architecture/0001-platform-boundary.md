# ADR 0001: Own the platform API and adapt Pragtical's native backend

Status: accepted

## Decision

Pragtical Haxeon defines a small platform-neutral Haxe API and a versioned flat
C ABI. Its initial graphical backend will adapt Pragtical's SDL3 platform and
renderer implementation. SDL structures, constants, and pointers do not cross
the ABI. Lime is a design reference and a possible future backend, not a core
dependency.

The native host owns the outer application loop and durable resources. Haxeon
owns editor state and behavior. Native resources cross the boundary as opaque,
generation-checked integer handles. Events cross through a pull queue as
normalized value records. Rendering will use a command buffer once the minimal
API is proven.

## Why

Depending on Lime would first require Haxeon to support Lime's macros, build
tooling, broad standard library usage, CFFI conventions, and unrelated asset,
audio, and rendering facilities. Raw SDL externs would instead leak pointer
lifetimes, structure layouts, backend choices, and platform-specific main-loop
rules into reloadable editor code.

This boundary permits a deterministic headless backend, protects native objects
from stale references after domain reloads, and leaves the renderer replaceable.

## Ownership

- The native host owns windows, renderers, fonts, processes, and OS objects.
- Haxeon code borrows opaque handles and never receives native pointers.
- Destroying a resource invalidates its handle generation.
- Body patches retain host resources.
- Domain reload retires callbacks before state restoration.
- Events are copied into a host queue and pulled at a Haxeon safe point.

## Main-loop contract

The graphical host will translate `SDL_AppInit`, `SDL_AppEvent`,
`SDL_AppIterate`, and `SDL_AppQuit` into stable Haxeon entry calls. Patch
publication occurs between event delivery and the next update, never while a
domain call is active.
