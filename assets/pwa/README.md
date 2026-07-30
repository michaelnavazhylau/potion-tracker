# PWA logo options

All three concepts are original SVG artwork designed around the game's existing
glass, liquid, and cork palette. Each source is rendered with Inkscape at the
three sizes expected by Godot's PWA export.

1. **Prism Flask** (`logo-1-prism-flask.svg`) — the clearest small-screen icon;
   a single bottle with the game's layered-liquid mechanic and a bright sparkle.
2. **Pour Loop** (`logo-2-pour-loop.svg`) — emphasizes the interaction by
   showing two bottles and a visible stream.
3. **Corked Victory** (`logo-3-corked-victory.svg`) — emphasizes completion with
   a corked bottle and magical starburst.

The current export provisionally uses **Prism Flask**. To choose another option,
change the three `progressive_web_app/icon_*` paths in `export_presets.cfg` to
the matching PNG files and export again.

Regenerate every PNG and the comparison sheet with:

```sh
./scripts/render_pwa_icons.sh
```

The script defaults to `/opt/homebrew/bin/inkscape` and accepts an alternate
executable through `INKSCAPE_BIN`. It uses commands equivalent to:

```sh
inkscape source.svg --export-area-page --export-width=144 \
  --export-height=144 --export-background-opacity=0 \
  --export-filename=icon-144.png
```
