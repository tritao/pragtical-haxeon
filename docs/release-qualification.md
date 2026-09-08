# Release qualification

This document records evidence for the release-quality claims. Measurements are
local development gates, not promises for other hardware or operating systems.

## Performance and endurance

Recorded 2026-09-08 on Linux 6.8.0-59-generic x86_64, an Intel Core i5-13600K
(14 cores, 20 logical CPUs, up to 5.1 GHz) with 31 GiB RAM. The repository was at
`6a605d7` after the performance fixes in `2130565`; Haxeon was at `21a996b`.

Run the fixed fixtures from the repository root:

```sh
./scripts/benchmark-release.sh
./scripts/benchmark-project-index.sh
```

The release benchmark constructs a small Haxe source, exactly 10 MiB of text, a
single 1 MiB line, 200 typing-to-present samples, 500 idle update samples, 200
scroll-to-present samples, 50 open/edit/atomic-save/close cycles and 20 live
plugin recompilation/reload cycles. It measures a complete first-document frame,
uses a one-second sleeping service-idle interval for CPU time, and records process
peak RSS with `/usr/bin/time`. The project benchmark creates 100 directories with
100 files each, cancels and replaces both indexing and search generations, and
runs the same 32-step scheduler request used by the application.

Observed result:

```text
startup 0.618 ms; first usable document 0.077 ms
typing-to-frame p95 0.051 ms; service idle p95 0.0012 ms; idle CPU 2.00%
10 MiB open 618.9 ms; 1 MiB line open 21.85 ms; scroll-to-frame p95 0.052 ms
50 document lifecycle cycles 571.2 ms; first/last ten p95 11.32/12.38 ms
20 plugin reloads p95 31.55 ms; first/last five median 6.44/5.55 ms
peak RSS 170,708 KiB
10,000-file index: 6 turns, maximum turn 6.37 ms
cancelled/replacement 10,000-file search: maximum turn 0.98 ms
```

The executable gates require scheduling turns below 8 ms, typing and large-file
scroll p95 below 50 ms, service-idle CPU below 5%, and no greater than a bounded
twofold-plus-2-ms median increase in the final document/plugin soak windows.
Rendering and service-idle timings are reported separately.

Profiling found and removed repeated whole-document work: visual-row lookup is
now logarithmic, maximum line width is cached by visual-map revision, collapsed
status selections do not calculate absolute offsets, highlight validation starts
at its known-valid frontier, and project snapshots use linear assembly. The shared
job scheduler enforces a six-millisecond wall-clock slice in addition to its step
limit.

There is no configured hard editor document-size limit; 10 MiB documents and a
1 MiB line are qualified here, while larger inputs remain unclaimed and memory
scales with buffer and visual-row count. Workspace search deliberately skips
individual files larger than 4 MiB and caps retained results at the caller's
configured maximum. These limits are surfaced as search diagnostics.

The full headless suite and SDL artifact compile passed after these changes. Peak
RSS is a whole-run high-water mark; the chronological first/last soak comparisons
show no progressive latency in the exercised cycles.

## Platform matrix

Platform input and packaging evidence is recorded here as M7.2 and M7.3 close.
Only Linux is currently under qualification. Windows and macOS remain unclaimed
until native build and execution evidence exists.
