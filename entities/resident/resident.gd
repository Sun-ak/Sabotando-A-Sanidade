class_name Resident
extends CharacterBody2D
## The AI agent contesting Hope with the player. Has no reference to InteractableObject or
## BedroomController's Hope/Energy fields (research.md R11) -- it only emits intent_selected and
## exposes on_intent_resolved()/on_hope_changed()/walk_to(), all connected/called TO by
## BedroomController in its own _ready() (Principle III: a child never reaches for its parent).
##
## Movement: walk_to() receives a world-space stand spot from BedroomController (the mediator is
## the only party that knows where the target InteractableObject lives). The resident moves there
## during WALKING and switches to REACHING on arrival; WalkToReachTimer stays as a fallback so the
## state machine still advances if walk_to() is never called (e.g. headless logic tests).

signal intent_selected(intent: InteractableDefinition.IntentType)

const INTER_ATTEMPT_PAUSE_SECONDS: float = 2.0
const MAX_WALK_SECONDS: float = 4.0
const REACTION_BEAT_SECONDS: float = 1.0
const WALK_SPEED: float = 240.0
const ARRIVAL_DISTANCE: float = 8.0

const BUBBLE_KEY_BY_INTENT: Dictionary[InteractableDefinition.IntentType, String] = {
	InteractableDefinition.IntentType.CURTAINS: "BUBBLE_CURTAINS",
	InteractableDefinition.IntentType.PHONE: "BUBBLE_PHONE",
	InteractableDefinition.IntentType.LAUNDRY: "BUBBLE_LAUNDRY",
	InteractableDefinition.IntentType.DOOR_KEY: "BUBBLE_DOOR_KEY",
	InteractableDefinition.IntentType.THOUGHTS: "BUBBLE_THOUGHTS",
}

const STATE_ANIMATION: Dictionary[ResidentState.State, StringName] = {
	ResidentState.State.IDLE: &"idle",
	ResidentState.State.WALKING: &"walking",
	ResidentState.State.REACHING: &"reaching",
	ResidentState.State.SITTING_SAD: &"sitting_sad",
	ResidentState.State.CRYING: &"crying",
}

@onready var pick_intent_timer: Timer = $PickIntentTimer
@onready var walk_to_reach_timer: Timer = $WalkToReachTimer
@onready var reaction_timer: Timer = $ReactionTimer
@onready var visual: AnimatedSprite2D = $Visual
@onready var bubble: Node2D = $ThoughtBubble
@onready var bubble_label: Label = $ThoughtBubble/Label

var behavior_state: ResidentState.State = ResidentState.State.IDLE
var current_intent: InteractableDefinition.IntentType = InteractableDefinition.IntentType.CURTAINS

var _last_known_hope: float = 50.0
var _move_target: Vector2 = Vector2.ZERO
var _is_moving: bool = false

func _ready() -> void:
	pick_intent_timer.wait_time = INTER_ATTEMPT_PAUSE_SECONDS
	pick_intent_timer.one_shot = true
	pick_intent_timer.timeout.connect(_on_pick_intent_timer_timeout)
	walk_to_reach_timer.wait_time = MAX_WALK_SECONDS
	walk_to_reach_timer.one_shot = true
	walk_to_reach_timer.timeout.connect(_on_walk_to_reach_timer_timeout)
	reaction_timer.wait_time = REACTION_BEAT_SECONDS
	reaction_timer.one_shot = true
	reaction_timer.timeout.connect(_on_reaction_timer_timeout)
	bubble.visible = false
	_set_state(ResidentState.State.IDLE)
	pick_intent_timer.start()

func _physics_process(_delta: float) -> void:
	if not _is_moving or behavior_state != ResidentState.State.WALKING:
		velocity = Vector2.ZERO
		return
	var to_target: Vector2 = _move_target - global_position
	if to_target.length() <= ARRIVAL_DISTANCE:
		_arrive()
		return
	velocity = to_target.normalized() * WALK_SPEED
	if absf(velocity.x) > 1.0:
		visual.flip_h = velocity.x > 0.0  # base side frames face left
	move_and_slide()

## Called by BedroomController only (parent-to-child, Principle III) right after this resident
## telegraphs an intent -- the controller resolves the intent to a stand spot near its object.
func walk_to(target: Vector2) -> void:
	_move_target = target
	_is_moving = true

func _arrive() -> void:
	_is_moving = false
	velocity = Vector2.ZERO
	walk_to_reach_timer.stop()
	_set_state(ResidentState.State.REACHING)

func _on_pick_intent_timer_timeout() -> void:
	current_intent = _pick_random_intent()
	_set_state(ResidentState.State.WALKING)
	_show_bubble(BUBBLE_KEY_BY_INTENT[current_intent])
	intent_selected.emit(current_intent)
	walk_to_reach_timer.start()

## Fallback so the WALKING -> REACHING transition still happens when no walk target was given
## (or the spot is unreachable) -- keeps the attempt readable within its 6s window.
func _on_walk_to_reach_timer_timeout() -> void:
	if behavior_state == ResidentState.State.WALKING:
		_arrive()

func _pick_random_intent() -> InteractableDefinition.IntentType:
	var options: Array[InteractableDefinition.IntentType] = BUBBLE_KEY_BY_INTENT.keys()
	return options[randi() % options.size()]

## Connected TO by BedroomController.intent_resolved (Principle III) -- BedroomController wires
## this in its own _ready(), Resident never looks up its parent to find BedroomController.
func on_intent_resolved(_intent: InteractableDefinition.IntentType, succeeded: bool) -> void:
	walk_to_reach_timer.stop()
	_is_moving = false
	velocity = Vector2.ZERO
	if succeeded:
		_hide_bubble()
	else:
		_show_bubble("BUBBLE_SEARCHING")
	_apply_idle_mood()
	reaction_timer.start()

func _on_reaction_timer_timeout() -> void:
	_hide_bubble()
	pick_intent_timer.start()

## Connected TO by BedroomController.hope_changed (Principle III).
func on_hope_changed(new_value: float) -> void:
	_last_known_hope = new_value
	var is_between_attempts: bool = behavior_state == ResidentState.State.IDLE \
		or behavior_state == ResidentState.State.SITTING_SAD \
		or behavior_state == ResidentState.State.CRYING
	if is_between_attempts:
		_apply_idle_mood()

## research.md R10's idle-mood threshold -- applies only between attempts (FR-011); WALKING/
## REACHING during an active attempt are intent-driven regardless of Hope.
func _apply_idle_mood() -> void:
	if _last_known_hope < 20.0:
		_set_state(ResidentState.State.CRYING)
	elif _last_known_hope < 50.0:
		_set_state(ResidentState.State.SITTING_SAD)
	else:
		_set_state(ResidentState.State.IDLE)

func _set_state(new_state: ResidentState.State) -> void:
	behavior_state = new_state
	if visual != null and STATE_ANIMATION.has(new_state):
		visual.play(STATE_ANIMATION[new_state])

func _show_bubble(key: String) -> void:
	bubble_label.text = tr(key)
	bubble.visible = true

func _hide_bubble() -> void:
	bubble.visible = false
