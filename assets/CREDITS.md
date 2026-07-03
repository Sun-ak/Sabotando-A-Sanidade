# Asset Credits

## Midnight Lilac Tileset (assets/tileset/)

- Author: **S Frisk** — https://sarahfrisk.com/
- Source: `sprites/S_Frisk _Midnight_Lilac_Tileset/` (raw pack, ignored by Godot via `.gdignore`)
- License: **non-commercial use only**; may be modified; may NOT be resold/redistributed, even
  modified. Credit "S Frisk" or link the site above in the game's credits.

## Gameplay sprites (assets/sprites/, entities/resident/sprites/)

Extracted programmatically from `sprites/Sprite_sheet_asset_preparation/sprites_padded/`
(the padded 44x44 grid slices were misaligned relative to the original sheet, so each sprite was
isolated via alpha connected-component analysis). Same art style/palette family as the tileset.
`key_32x32_24f_hidden.png` is a darkened derivative of the user-supplied spinning-key sheet
`key_32x32_24f.png`, generated during extraction.
