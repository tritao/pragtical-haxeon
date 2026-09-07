#!/usr/bin/env bash
set -euo pipefail

root_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
haxeon_root=${HAXEON_ROOT:-"$root_dir/../realtime-haxe"}

exec "$haxeon_root/.tools/haxe/haxe" --cwd "$haxeon_root" -cp src \
	--run compiler.tools.BootstrapCompiler "$@"
