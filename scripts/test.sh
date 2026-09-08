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
mapfile -t compiler_sources < <(find "$haxeon_root/src/compiler" "$haxeon_root/src/runtime" -type f -name '*.hx' -print | LC_ALL=C sort)

configuration_root="$root_dir/build/configuration-test"
configuration_project="$configuration_root/project"
mkdir -p "$configuration_project"
printf 'version=1\neditor.fontSize=16\nworkbench.sidebarWidth=240\nkeybinding=Ctrl+A|doc:undo\n' > "$configuration_root/user.conf"
printf 'version=1\neditor.fontSize=18\neditor.insertSpaces=false\nworkbench.sidebarWidth=280\nkeybinding=Ctrl+A|doc:redo\n' > "$configuration_root/project.conf"
"$root_dir/scripts/haxeon-compile.sh" \
	--output="$root_dir/out/configuration-test.hl" --entry=app.ConfigurationTestMain \
	--root="$root_dir/src" --root="$haxeon_root/src" --root="$haxeon_root/stdlib" \
	"${sources[@]}" "${compiler_sources[@]}" "${stdlib_sources[@]}"
(
	cd "$root_dir/out"
	LD_LIBRARY_PATH="$haxeon_root/vendor/hashlink${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
		"$haxeon_root/vendor/hashlink/hl" configuration-test.hl "$configuration_root/user.conf" "$configuration_root/project.conf" \
		"$configuration_project" "$configuration_root/user.conf"
)
"$root_dir/scripts/haxeon-compile.sh" \
	--output="$root_dir/out/command-test.hl" --entry=app.CommandTestMain \
	--root="$root_dir/src" --root="$haxeon_root/src" --root="$haxeon_root/stdlib" \
	"${sources[@]}" "${compiler_sources[@]}" "${stdlib_sources[@]}"
(
	cd "$root_dir/out"
	LD_LIBRARY_PATH="$haxeon_root/vendor/hashlink${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
		"$haxeon_root/vendor/hashlink/hl" command-test.hl
)

"$root_dir/scripts/haxeon-compile.sh" \
	--output="$root_dir/out/editor-view-test.hl" --entry=app.EditorViewTestMain \
	--root="$root_dir/src" --root="$haxeon_root/src" --root="$haxeon_root/stdlib" \
	"${sources[@]}" "${compiler_sources[@]}" "${stdlib_sources[@]}"
(
	cd "$root_dir/out"
	LD_LIBRARY_PATH="$haxeon_root/vendor/hashlink${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
		"$haxeon_root/vendor/hashlink/hl" editor-view-test.hl
)

"$root_dir/scripts/haxeon-compile.sh" \
	--output="$root_dir/out/application-test.hl" --entry=app.ApplicationTestMain \
	--root="$root_dir/src" --root="$haxeon_root/src" --root="$haxeon_root/stdlib" \
	"${sources[@]}" "${compiler_sources[@]}" "${stdlib_sources[@]}"
(
	cd "$root_dir/out"
	LD_LIBRARY_PATH="$haxeon_root/vendor/hashlink${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
		"$haxeon_root/vendor/hashlink/hl" application-test.hl
)

"$root_dir/scripts/haxeon-compile.sh" \
	--output="$root_dir/out/document-test.hl" --entry=app.DocumentTestMain \
	--root="$root_dir/src" --root="$haxeon_root/src" --root="$haxeon_root/stdlib" \
	"${sources[@]}" "${compiler_sources[@]}" "${stdlib_sources[@]}"
(
	printf 'saved by Haxeon\n' > "$root_dir/build/document-save-smoke.txt"
	chmod 640 "$root_dir/build/document-save-smoke.txt"
	cd "$root_dir/out"
	LD_LIBRARY_PATH="$haxeon_root/vendor/hashlink${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
		"$haxeon_root/vendor/hashlink/hl" document-test.hl "$root_dir/build/document-save-smoke.txt"
	[[ $(stat -c '%a' "$root_dir/build/document-save-smoke.txt") == 640 ]]
)

"$root_dir/scripts/haxeon-compile.sh" \
	--output="$root_dir/out/plugin-test.hl" --entry=app.PluginTestMain \
	--root="$root_dir/src" --root="$haxeon_root/src" --root="$haxeon_root/stdlib" \
	"${sources[@]}" "${compiler_sources[@]}" "${stdlib_sources[@]}"
(
	cd "$root_dir/out"
	LD_LIBRARY_PATH="$haxeon_root/vendor/hashlink${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
		"$haxeon_root/vendor/hashlink/hl" plugin-test.hl
)

workspace_root="$root_dir/build/workspace-test"
workspace_other="$root_dir/build/workspace-test-other"
mkdir -p "$workspace_root/src" "$workspace_root/.git" "$workspace_root/.cache"
mkdir -p "$workspace_other"
rm -f "$workspace_root/created.txt" "$workspace_root/moved.txt"
printf 'alpha\n' > "$workspace_root/alpha.txt"
printf 'class Main {}\n' > "$workspace_root/src/Main.hx"
printf 'ignored\n' > "$workspace_root/.git/ignored"
printf 'ignored\n' > "$workspace_root/.cache/ignored"
printf 'needle in second project\n' > "$workspace_other/second.txt"
"$root_dir/scripts/haxeon-compile.sh" \
	--output="$root_dir/out/workspace-test.hl" --entry=app.WorkspaceTestMain \
	--root="$root_dir/src" --root="$haxeon_root/src" --root="$haxeon_root/stdlib" \
	"${sources[@]}" "${compiler_sources[@]}" "${stdlib_sources[@]}"
(
	cd "$root_dir/out"
	LD_LIBRARY_PATH="$haxeon_root/vendor/hashlink${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
		"$haxeon_root/vendor/hashlink/hl" workspace-test.hl "$workspace_root" "$workspace_other"
)

dynamic_plugin_dir="$root_dir/build/dynamic-plugin"
mkdir -p "$dynamic_plugin_dir"
cp "$root_dir/plugins/example/plugin.conf" "$root_dir/plugins/example/Main.hx" "$dynamic_plugin_dir/"
"$root_dir/scripts/haxeon-compile.sh" \
	--output="$root_dir/out/dynamic-plugin-test.hl" --entry=app.DynamicPluginTestMain \
	--root="$root_dir/src" --root="$haxeon_root/src" --root="$haxeon_root/stdlib" \
	"${sources[@]}" "${compiler_sources[@]}" "${stdlib_sources[@]}"
(
	cd "$root_dir/out"
	LD_LIBRARY_PATH="$haxeon_root/vendor/hashlink${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
		"$haxeon_root/vendor/hashlink/hl" dynamic-plugin-test.hl \
		"$dynamic_plugin_dir/plugin.conf" "$dynamic_plugin_dir/Main.hx"
)
