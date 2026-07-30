#!/bin/sh
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
options_dir="$project_dir/assets/pwa/options"
inkscape_bin=${INKSCAPE_BIN:-/opt/homebrew/bin/inkscape}

if [ ! -x "$inkscape_bin" ]; then
  echo "Inkscape CLI is required at '$inkscape_bin'." >&2
  echo "Set INKSCAPE_BIN to use a different executable." >&2
  exit 1
fi

for option in logo-1-prism-flask logo-2-pour-loop logo-3-corked-victory; do
  for size in 144 180 512; do
    "$inkscape_bin" "$options_dir/$option.svg" \
      --export-area-page \
      --export-width="$size" \
      --export-height="$size" \
      --export-background-opacity=0 \
      --export-filename="$options_dir/$option-$size.png"
  done
done

"$inkscape_bin" "$project_dir/assets/pwa/logo-options.svg" \
  --export-area-page \
  --export-width=1104 \
  --export-height=430 \
  --export-filename="$project_dir/assets/pwa/logo-options.png"

echo "Rendered PWA icon options with Inkscape"
