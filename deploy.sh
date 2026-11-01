#!/bin/bash
# Install the plugin into Omarchy's plugin folder (a copy: the shell does not
# follow a symlinked plugin folder) and switch the bar to it.
set -euo pipefail
src="$(cd "$(dirname "$0")" && pwd)/plugin"
id=$(jq -r .id "$src/manifest.json")
dest="$HOME/.config/omarchy/plugins/$id"
omarchy plugin validate "$src"
rm -rf "$dest.new"
cp -a "$src" "$dest.new"
rm -rf "$dest"
mv "$dest.new" "$dest"
omarchy-shell shell rescanPlugins >/dev/null
[[ ${1:-} == --no-enable ]] || omarchy plugin enable "$id"
