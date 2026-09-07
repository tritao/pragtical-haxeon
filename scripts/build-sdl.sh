#!/usr/bin/env bash
set -euo pipefail

root_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
haxeon_root=${HAXEON_ROOT:-"$root_dir/../realtime-haxe"}
pragtical_root=${PRAGTICAL_ROOT:-"$root_dir/../pragtical"}
cc=${CC:-cc}

mkdir -p "$root_dir/out"
if [[ ! -f "$haxeon_root/out/realtime_runtime.hdll" ]]; then
	echo "missing Haxeon runtime bridge: $haxeon_root/out/realtime_runtime.hdll" >&2
	exit 1
fi

read -r -a sdl_cflags <<< "$(pkg-config --cflags sdl3)"
read -r -a sdl_libs <<< "$(pkg-config --libs sdl3)"
read -r -a font_cflags <<< "$(pkg-config --cflags freetype2)"
read -r -a font_libs <<< "$(pkg-config --libs freetype2)"
read -r -a shape_cflags <<< "$(pkg-config --cflags harfbuzz)"
read -r -a shape_libs <<< "$(pkg-config --libs harfbuzz)"
read -r -a lua_cflags <<< "$(pkg-config --cflags lua5.4)"
"$cc" -std=c11 -Wall -Wextra -Werror \
	-Wno-sign-compare -Wno-missing-field-initializers -Wno-ignored-qualifiers \
	-Wno-type-limits -Wno-unused-parameter \
	-fPIC -shared -DPHX_WITH_SDL -DPHX_WITH_FREETYPE \
	-I"$root_dir/include" -I"$haxeon_root/vendor/hashlink/src" -I"$pragtical_root/src" \
	"${sdl_cflags[@]}" "${font_cflags[@]}" "${shape_cflags[@]}" "${lua_cflags[@]}" \
	"$root_dir/native/headless/platform.c" \
	"$root_dir/native/hashlink/pragtical_hx.c" \
	"$root_dir/native/pragtical/renderer_backend.c" \
	"$pragtical_root/src/renderer/atlas.c" \
	"$pragtical_root/src/renderer/atlas_surface.c" \
	"$pragtical_root/src/renderer/backend/surface.c" \
	"$pragtical_root/src/renderer/cache.c" \
	"$pragtical_root/src/renderer/renderer.c" \
	"$pragtical_root/src/renderer/window.c" \
	-L"$haxeon_root/vendor/hashlink" -lhl "${sdl_libs[@]}" "${font_libs[@]}" "${shape_libs[@]}" -lm \
	-Wl,-rpath,"$haxeon_root/vendor/hashlink" \
	-o "$root_dir/out/pragtical_hx.hdll"
cp "$haxeon_root/out/realtime_runtime.hdll" "$root_dir/out/realtime_runtime.hdll"
cp "$root_dir/README.md" "$root_dir/out/README.md"
mkdir -p "$root_dir/out/data/fonts"
cp "$pragtical_root/data/fonts/JetBrainsMono-Regular.ttf" "$root_dir/out/data/fonts/"

mapfile -t sources < <(find "$root_dir/src" -type f -name '*.hx' -print | LC_ALL=C sort)
mapfile -t stdlib_sources < <(find "$haxeon_root/stdlib" -type f -name '*.hx' -print | LC_ALL=C sort)
mapfile -t compiler_sources < <(find "$haxeon_root/src/compiler" "$haxeon_root/src/runtime" -type f -name '*.hx' -print | LC_ALL=C sort)
"$root_dir/scripts/haxeon-compile.sh" \
	--output="$root_dir/out/pragtical-haxeon.hl" --entry=app.GraphicalMain \
	--root="$root_dir/src" --root="$haxeon_root/src" --root="$haxeon_root/stdlib" \
	"${sources[@]}" "${compiler_sources[@]}" "${stdlib_sources[@]}"
