#!/usr/bin/env bash
set -euo pipefail

root_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
haxeon_root=${HAXEON_ROOT:-"$root_dir/../realtime-haxe"}

"$root_dir/scripts/build-sdl.sh"
plugin_arguments=()
plugin_dirs=${PRAGTICAL_PLUGIN_DIRS:-"$root_dir/plugins"}
while IFS= read -r manifest; do
	plugin_arguments+=("--plugin=$manifest")
done < <(
	IFS=:
	for directory in $plugin_dirs; do
		if [[ -d "$directory" ]]; then
			find "$directory" -mindepth 2 -maxdepth 2 -type f -name plugin.conf -print
		fi
	done | LC_ALL=C sort
)
cd "$root_dir/out"
LD_LIBRARY_PATH="$haxeon_root/vendor/hashlink${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
	exec "$haxeon_root/vendor/hashlink/hl" pragtical-haxeon.hl "${plugin_arguments[@]}" "$@"
