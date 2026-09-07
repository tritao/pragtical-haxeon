#!/usr/bin/env bash
set -euo pipefail

root_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
haxeon_root=${HAXEON_ROOT:-"$root_dir/../realtime-haxe"}
cc=${CC:-cc}

mkdir -p "$root_dir/build"
"$cc" -std=c11 -Wall -Wextra -Werror \
	-I"$root_dir/include" \
	"$root_dir/native/headless/platform.c" \
	"$root_dir/tests/platform_test.c" \
	-o "$root_dir/build/platform-test"
"$root_dir/build/platform-test"

"$root_dir/scripts/build.sh"
(
	cd "$root_dir/out"
	LD_LIBRARY_PATH="$haxeon_root/vendor/hashlink${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
		"$haxeon_root/vendor/hashlink/hl" pragtical-haxeon.hl
)
echo "PASS: Haxeon application exercised the platform ABI"
