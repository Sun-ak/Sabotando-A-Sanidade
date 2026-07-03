extends TextureButton

func _ready() -> void:
	var mask = BitMap.new()
	mask.create_from_image_alpha(texture_normal.get_image())
	texture_click_mask = mask
