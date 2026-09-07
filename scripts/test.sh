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

mapfile -t sources < <(find "$root_dir/src" -type f -name '*.hx' -print | LC_ALL=C sort)
mapfile -t stdlib_sources < <(find "$haxeon_root/stdlib" -type f -name '*.hx' -print | LC_ALL=C sort)
"$root_dir/scripts/haxeon-compile.sh" \
	--output="$root_dir/out/command-test.hl" --entry=app.CommandTestMain \
	--root="$root_dir/src" --root="$haxeon_root/stdlib" \
	"${sources[@]}" "${stdlib_sources[@]}"
(
	cd "$root_dir/out"
	LD_LIBRARY_PATH="$haxeon_root/vendor/hashlink${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
		"$haxeon_root/vendor/hashlink/hl" command-test.hl
)

"$root_dir/scripts/haxeon-compile.sh" \
	--output="$root_dir/out/editor-view-test.hl" --entry=app.EditorViewTestMain \
	--root="$root_dir/src" --root="$haxeon_root/stdlib" \
	"${sources[@]}" "${stdlib_sources[@]}"
(
	cd "$root_dir/out"
	LD_LIBRARY_PATH="$haxeon_root/vendor/hashlink${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
		"$haxeon_root/vendor/hashlink/hl" editor-view-test.hl
)

"$root_dir/scripts/haxeon-compile.sh" \
	--output="$root_dir/out/application-test.hl" --entry=app.ApplicationTestMain \
	--root="$root_dir/src" --root="$haxeon_root/stdlib" \
	"${sources[@]}" "${stdlib_sources[@]}"
(
	cd "$root_dir/out"
	LD_LIBRARY_PATH="$haxeon_root/vendor/hashlink${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
		"$haxeon_root/vendor/hashlink/hl" application-test.hl
)

"$root_dir/scripts/haxeon-compile.sh" \
	--output="$root_dir/out/document-test.hl" --entry=app.DocumentTestMain \
	--root="$root_dir/src" --root="$haxeon_root/stdlib" \
	"${sources[@]}" "${stdlib_sources[@]}"
(
	cd "$root_dir/out"
	LD_LIBRARY_PATH="$haxeon_root/vendor/hashlink${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
		"$haxeon_root/vendor/hashlink/hl" document-test.hl "$root_dir/build/document-save-smoke.txt"
)

"$root_dir/scripts/haxeon-compile.sh" \
	--output="$root_dir/out/plugin-test.hl" --entry=app.PluginTestMain \
	--root="$root_dir/src" --root="$haxeon_root/stdlib" \
	"${sources[@]}" "${stdlib_sources[@]}"
(
	cd "$root_dir/out"
	LD_LIBRARY_PATH="$haxeon_root/vendor/hashlink${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
		"$haxeon_root/vendor/hashlink/hl" plugin-test.hl
)
