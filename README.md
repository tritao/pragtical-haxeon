# Pragtical Haxeon

A new editor implementation with its application core written in Haxeon. The
native host owns platform lifecycle and resources; reloadable Haxeon domains own
editor behavior.

The first milestone is a deterministic headless platform backend implementing
the same ABI that the Pragtical SDL3 renderer will implement next.

## Build and test

```sh
./scripts/test.sh
```

By default the build uses sibling checkouts at `../realtime-haxe` and
`../pragtical`. Override them with `HAXEON_ROOT` and `PRAGTICAL_ROOT`.

See [the platform boundary decision](docs/architecture/0001-platform-boundary.md).
