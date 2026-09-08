#!/usr/bin/env bash
set -euo pipefail

root_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
haxeon_root=${HAXEON_ROOT:-"$root_dir/../realtime-haxe"}

"$root_dir/scripts/build-sdl.sh"
(
	cd "$root_dir/out"
	LD_LIBRARY_PATH="$haxeon_root/vendor/hashlink${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
		xvfb-run -a ./pragtical-haxeon --smoke-frames=3
)
