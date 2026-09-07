# Pragtical Haxeon

A new editor implementation with its application core written in Haxeon. The
native host owns platform lifecycle and resources; reloadable Haxeon domains own
editor behavior.

The graphical backend compiles Pragtical's renderer sources directly and uses
its font shaping, glyph atlas, dirty-region cache, and SDL surface backend behind
the platform ABI. The editor core never receives SDL or renderer pointers.

## Build and test

```sh
./scripts/test.sh
```

By default the build uses sibling checkouts at `../realtime-haxe` and
`../pragtical`. Override them with `HAXEON_ROOT` and `PRAGTICAL_ROOT`.

See [the platform boundary decision](docs/architecture/0001-platform-boundary.md).
