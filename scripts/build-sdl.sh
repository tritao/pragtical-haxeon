#!/usr/bin/env bash
set -euo pipefail

root_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
haxeon_root=${HAXEON_ROOT:-"$root_dir/../realtime-haxe"}
cc=${CC:-cc}

mkdir -p "$root_dir/out"
if [[ ! -f "$haxeon_root/out/realtime_runtime.hdll" ]]; then
	echo "missing Haxeon runtime bridge: $haxeon_root/out/realtime_runtime.hdll" >&2
	exit 1
fi

read -r -a sdl_cflags <<< "$(pkg-config --cflags sdl3)"
read -r -a sdl_libs <<< "$(pkg-config --libs sdl3)"
"$cc" -std=c11 -Wall -Wextra -Werror -fPIC -shared -DPHX_WITH_SDL \
	-I"$root_dir/include" -I"$haxeon_root/vendor/hashlink/src" \
	"${sdl_cflags[@]}" "$root_dir/native/headless/platform.c" \
	"$root_dir/native/hashlink/pragtical_hx.c" \
	-L"$haxeon_root/vendor/hashlink" -lhl "${sdl_libs[@]}" \
	-Wl,-rpath,"$haxeon_root/vendor/hashlink" \
	-o "$root_dir/out/pragtical_hx.hdll"
cp "$haxeon_root/out/realtime_runtime.hdll" "$root_dir/out/realtime_runtime.hdll"

mapfile -t sources < <(find "$root_dir/src" -type f -name '*.hx' -print | LC_ALL=C sort)
mapfile -t stdlib_sources < <(find "$haxeon_root/stdlib" -type f -name '*.hx' -print | LC_ALL=C sort)
"$root_dir/scripts/haxeon-compile.sh" \
	--output="$root_dir/out/pragtical-haxeon.hl" --entry=app.GraphicalMain \
	--root="$root_dir/src" --root="$haxeon_root/stdlib" \
	"${sources[@]}" "${stdlib_sources[@]}"
