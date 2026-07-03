class_name ResolutionOverlay
extends CanvasLayer
## Shown when BedroomController.session_resolved fires (connected TO by BedroomController,
## Principle III). Displays the matching pt-BR resolution text.
##
## Actual input-blocking (the hard invariant from contracts/signals.md) is enforced in
## BedroomController itself (T035: sabotage_attempted/intent_selected become no-ops once
## resolution != NONE) rather than here -- that is a robust code-level guarantee independent of
## whether a full-screen Control can intercept Area2D physics-picking, which Godot does not
## uniformly guarantee. This overlay's mouse_filter is set only as a UX nicety.

@onready var panel: Control = $Panel
@onready var title_label: Label = $Panel/TitleLabel
@onready var play_again_button: Button = $Panel/PlayAgainButton

func _ready() -> void:
	panel.visible = false
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_again_button.text = tr("UI_PLAY_AGAIN")
	play_again_button.pressed.connect(_on_play_again_pressed)

## Reloading the whole scene restarts the session from its defined starting values (FR-019) --
## BedroomController._reset_session runs again on the fresh instance.
func _on_play_again_pressed() -> void:
	get_tree().reload_current_scene()

func on_session_resolved(resolution: BedroomController.ResolutionState) -> void:
	var key: String = "RES_DEPRESSION_PREVAILS_TITLE"
	if resolution == BedroomController.ResolutionState.RESIDENT_ENDURES:
		key = "RES_RESIDENT_ENDURES_TITLE"
	title_label.text = tr(key)
	panel.visible = true
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
