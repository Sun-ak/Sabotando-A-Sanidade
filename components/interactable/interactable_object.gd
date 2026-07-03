class_name InteractableObject
extends Area2D
## One of the five contested room objects. Behavior is entirely data-driven via `definition`
## (research.md R2) — this same script/scene is instanced 5 times with a different
## InteractableDefinition .tres each. Has no reference to Resident or BedroomController beyond
## emitting signals upward (research.md R11) — BedroomController is the sole listener and the
## sole caller of set_sabotaged().

signal sabotage_attempted(definition: InteractableDefinition)
signal state_changed(new_state: StringName)

@export var definition: InteractableDefinition

var is_sabotaged: bool = false
var current_state: StringName = &""

@onready var _visual: Sprite2D = $Visual
@onready var _sfx: AudioStreamPlayer = $SfxPlayer

## Drag-gesture bookkeeping for Phone/Door Key (research.md R1). Not used by click-based objects.
var _drag_active: bool = false

## Accumulated animation time for multi-frame textures (definition.texture_frame_count > 1).
var _frame_time: float = 0.0

func _ready() -> void:
	input_pickable = true
	input_event.connect(_on_input_event)
	state_changed.connect(_on_state_changed)
	if _visual != null and definition != null:
		_visual.hframes = maxi(definition.texture_frame_count, 1)
	reset_to_default()

## Drives multi-frame textures (e.g. the spinning door key). Static sprites early-out.
func _process(delta: float) -> void:
	if _visual == null or definition == null or definition.texture_frame_count <= 1:
		return
	_frame_time += delta * definition.texture_frames_per_second
	_visual.frame = int(_frame_time) % definition.texture_frame_count

## FR-010: swap this object's sprite between its definition-supplied default/sabotaged textures.
func _on_state_changed(_new_state: StringName) -> void:
	if _visual == null or definition == null:
		return
	_visual.texture = definition.sabotaged_texture if is_sabotaged else definition.default_texture

## Restores this object to its definition-implied default (non-sabotaged) state. Called by
## BedroomController on session start (FR-019) and after this object's flag is consumed at
## attempt resolution (research.md R11 step 4).
func reset_to_default() -> void:
	is_sabotaged = false
	_drag_active = false
	if definition != null:
		current_state = definition.default_state_key
		state_changed.emit(current_state)

## Called by BedroomController only (parent-to-child, Principle III) when a sabotage gesture is
## accepted. Encapsulates the current_state lookup so the controller never needs to know about
## state keys.
func set_sabotaged(value: bool) -> void:
	var was_sabotaged: bool = is_sabotaged
	is_sabotaged = value
	if definition == null:
		return
	if value and not was_sabotaged and _sfx != null and definition.sabotage_sound != null:
		_sfx.stream = definition.sabotage_sound
		_sfx.play()
	current_state = definition.sabotaged_state_key if value else definition.default_state_key
	state_changed.emit(current_state)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if definition == null or not (event is InputEventMouseButton):
		return
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return

	match definition.gesture:
		InteractableDefinition.GestureType.CLICK_REPEAT, InteractableDefinition.GestureType.CLICK_ONCE:
			if mouse_event.pressed:
				sabotage_attempted.emit(definition)
		InteractableDefinition.GestureType.DRAG:
			if mouse_event.pressed:
				_drag_active = true
			elif _drag_active:
				_drag_active = false
				sabotage_attempted.emit(definition)
