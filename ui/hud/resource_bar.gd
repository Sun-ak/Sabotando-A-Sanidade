class_name ResourceBar
extends Control
## Pure display component -- no gameplay logic (Principle I). Two instances of this same scene
## are used for Hope and Dark Energy (data-model.md); `HUD` sets `current_value` in response to
## BedroomController's signals.

@export var label_key: String = ""
@export var max_value: float = 100.0
## Pixel-art bar sprites (research.md R9). Stretched via nine-patch so the rounded pill ends
## survive the bar's on-screen width. Falls back to flat placeholder textures when unset.
@export var under_texture: Texture2D
@export var progress_texture: Texture2D

@onready var _bar: TextureProgressBar = $TextureProgressBar
@onready var _label: Label = $Label

var current_value: float = 0.0:
	set(value):
		current_value = value
		if _bar != null:
			_bar.value = value
		_update_label()

func _ready() -> void:
	_bar.texture_under = under_texture if under_texture != null else _build_bar_texture(Color(0.2, 0.2, 0.22, 1.0))
	_bar.texture_progress = progress_texture if progress_texture != null else _build_bar_texture(Color(0.6, 0.5, 0.8, 1.0))
	_bar.nine_patch_stretch = true
	_bar.stretch_margin_left = 4
	_bar.stretch_margin_top = 4
	_bar.stretch_margin_right = 4
	_bar.stretch_margin_bottom = 4
	_bar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_bar.max_value = max_value
	_bar.value = current_value
	_update_label()

## The "X/Y" numeric readout is not itself translated text (plain numbers), so it can be composed
## with the translated label without needing a dedicated format-string translation key. Gives the
## player an at-a-glance affordability read (SC-006) without new hardcoded UI copy.
func _update_label() -> void:
	if _label != null:
		_label.text = "%s: %d/%d" % [tr(label_key), roundi(current_value), roundi(max_value)]

## research.md R9 commits to TextureProgressBar; no art exists yet (tasks.md Placeholder art
## note), so a small solid-color texture stands in for the real pixel-art fill.
func _build_bar_texture(color: Color) -> ImageTexture:
	var image: Image = Image.create(64, 16, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)
