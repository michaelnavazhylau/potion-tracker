#!/usr/bin/env bash

set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
override_path="$project_dir/override.cfg"

cd "$project_dir"

if [[ -e "$override_path" ]]; then
	echo "Refusing to replace existing override.cfg" >&2
	exit 1
fi

cleanup() {
	rm -f "$override_path"
}
trap cleanup EXIT

cp demos/portrait-recording.cfg "$override_path"

godot --path . \
	--write-movie demos/potion_solution.avi \
	--fixed-fps 30 \
	--script demos/solution_demo.gd

cleanup
trap - EXIT

ffmpeg -y \
	-i demos/potion_solution.avi \
	-map 0:v:0 \
	-c:v libx264 \
	-preset medium \
	-crf 22 \
	-pix_fmt yuv420p \
	-movflags +faststart \
	-an \
	demos/potion_solution.mp4

ffmpeg -y \
	-i demos/potion_solution.avi \
	-filter_complex \
	"[0:v]fps=15,scale=360:640:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=128:stats_mode=diff[p];[s1][p]paletteuse=dither=bayer:bayer_scale=3:diff_mode=rectangle" \
	-loop 0 \
	demos/potion_solution.gif
