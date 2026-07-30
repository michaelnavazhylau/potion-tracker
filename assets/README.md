# Potion bottle assets

`potion_bottle_empty.svg` is the transparent glass overlay. Draw liquid below
it so the glass rim, outline, and highlights remain visible.

`potion_bottle_fill_mask.svg` is the matching interior mask. White pixels are
the area where liquid may appear. A progressive fill can move a colored
rectangle upward behind this mask, or use the mask as the alpha texture in a
Godot shader.

`FluidPotion.tscn` uses the rendered mask as its liquid sprite texture and
`potion_fill.gdshader` reveals up to four colored layers from bottom to top.

The PNG files in this folder are deterministic ImageMagick renders of the SVG
sources at their native 180 x 270 size.

To regenerate them:

```sh
magick -background none potion_bottle_empty.svg -depth 8 potion_bottle_empty.png
magick -background none potion_bottle_fill_mask.svg -depth 8 potion_bottle_fill_mask.png
```
