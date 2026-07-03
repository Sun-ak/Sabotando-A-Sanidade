class_name BedroomController
extends Node2D
## Root of bedroom.tscn. Owns all session state (Hope, Dark Energy, clock, resolution) and
## mediates the entire Resident <-> InteractableObject contest (research.md R11) -- Resident and
## InteractableObject never reference each other directly. Not an Autoload (research.md R7).

signal hope_changed(new_value: float)
signal energy_changed(new_value: float, state: EnergyState)
signal intent_resolved(intent: InteractableDefinition.IntentType, succeeded: bool)
signal session_resolved(resolution: ResolutionState)

enum EnergyState { READY, CRITICAL, RECHARGING }
enum ResolutionState { NONE, DEPRESSION_PREVAILS, RESIDENT_ENDURES }

const HOPE_START: float = 50.0
const HOPE_MAX: float = 100.0
const HOPE_MIN: float = 0.0
const ENERGY_MAX: float = 100.0
const ENERGY_CRITICAL_THRESHOLD: float = 20.0
const ENERGY_REGEN_PER_SECOND: float = 5.0
const SESSION_LENGTH_SECONDS: float = 300.0
const ATTEMPT_WINDOW_SECONDS: float = 6.0

## research.md R6: the "Depressão" custom cursor -- a purple lightning bolt pulled from the
## sabotage-themed sprite set (assets/sprites/ui/).
const CURSOR_TEXTURE: Texture2D = preload("res://assets/sprites/ui/cursor_bolt.png")

## Where the resident stands relative to the contested object's origin (screen px), clamped so
## wall-mounted objects still produce a stand spot on the floor area.
const WALK_TARGET_OFFSET: Vector2 = Vector2(0.0, 60.0)
const WALK_TARGET_MIN: Vector2 = Vector2(60.0, 170.0)
const WALK_TARGET_MAX: Vector2 = Vector2(1220.0, 640.0)

const TIER_COST: Dictionary[InteractableDefinition.CostTier, float] = {
	InteractableDefinition.CostTier.LOW: 10.0,
	InteractableDefinition.CostTier.MEDIUM: 20.0,
	InteractableDefinition.CostTier.HIGH: 35.0,
	InteractableDefinition.CostTier.VERY_HIGH: 50.0,
}

@onready var session_clock: Timer = $SessionClock
@onready var attempt_timer: Timer = $AttemptTimer
@onready var energy_regen_timer: Timer = $EnergyRegenTimer
@onready var resident: Resident = $Resident
@onready var hud: HUD = $HUD
@onready var resolution_overlay: ResolutionOverlay = $ResolutionOverlay
@onready var music: AudioStreamPlayer = $Music

var hope: float = HOPE_START
var dark_energy: float = ENERGY_MAX
var energy_state: EnergyState = EnergyState.READY
var resolution: ResolutionState = ResolutionState.NONE

var interactables_by_intent: Dictionary[InteractableDefinition.IntentType, InteractableObject] = {}

var _current_intent: InteractableDefinition.IntentType = InteractableDefinition.IntentType.CURTAINS
var _has_active_intent: bool = false

func _ready() -> void:
	_build_interactables_lookup()
	for obj: InteractableObject in interactables_by_intent.values():
		obj.sabotage_attempted.connect(_on_sabotage_attempted)
	resident.intent_selected.connect(_on_intent_selected)
	intent_resolved.connect(resident.on_intent_resolved)
	hope_changed.connect(resident.on_hope_changed)
	hope_changed.connect(hud.on_hope_changed)
	energy_changed.connect(hud.on_energy_changed)
	session_resolved.connect(resolution_overlay.on_session_resolved)
	session_clock.timeout.connect(_on_session_clock_timeout)
	attempt_timer.timeout.connect(_on_attempt_timer_timeout)
	energy_regen_timer.timeout.connect(_on_energy_regen_timer_timeout)
	_reset_session()

## research.md R3: the day-end decision is signal-driven (_on_session_clock_timeout); this is only
## the cosmetic HH:MM label's polling source.
func _process(_delta: float) -> void:
	if resolution != ResolutionState.NONE:
		return
	var elapsed_fraction: float = 1.0 - (session_clock.time_left / SESSION_LENGTH_SECONDS)
	hud.on_clock_fraction_elapsed(elapsed_fraction)

func _build_interactables_lookup() -> void:
	interactables_by_intent.clear()
	for child: Node in get_children():
		if child is InteractableObject:
			var obj: InteractableObject = child
			if obj.definition != null:
				interactables_by_intent[obj.definition.intent] = obj

## FR-019: every session starts from the same defined state.
func _reset_session() -> void:
	hope = HOPE_START
	dark_energy = ENERGY_MAX
	energy_state = EnergyState.READY
	resolution = ResolutionState.NONE
	_has_active_intent = false
	for obj: InteractableObject in interactables_by_intent.values():
		obj.reset_to_default()
	Input.set_custom_mouse_cursor(CURSOR_TEXTURE, Input.CURSOR_ARROW, Vector2(3.0, 2.0))
	_start_music()
	session_clock.start(SESSION_LENGTH_SECONDS)
	energy_regen_timer.start()
	hope_changed.emit(hope)
	energy_changed.emit(dark_energy, energy_state)

## Background music loops for the whole session. The loop flag lives on the stream, which the
## MP3 import does not set by default -- forcing it here keeps the .import files untouched.
func _start_music() -> void:
	if music == null or music.stream == null:
		return
	var mp3: AudioStreamMP3 = music.stream as AudioStreamMP3
	if mp3 != null:
		mp3.loop = true
	if not music.playing:
		music.play()

func _on_sabotage_attempted(definition: InteractableDefinition) -> void:
	if resolution != ResolutionState.NONE:
		return
	var cost: float = TIER_COST[definition.energy_cost_tier]
	if dark_energy < cost:
		return
	dark_energy -= cost
	_update_energy_state()
	var obj: InteractableObject = interactables_by_intent[definition.intent]
	obj.set_sabotaged(true)
	energy_changed.emit(dark_energy, energy_state)

func _on_intent_selected(intent: InteractableDefinition.IntentType) -> void:
	if resolution != ResolutionState.NONE:
		return
	_current_intent = intent
	_has_active_intent = true
	attempt_timer.start(ATTEMPT_WINDOW_SECONDS)
	# Mediation (research.md R11): only the controller knows both the resident and the target
	# object, so it resolves the intent to a floor-clamped stand spot next to that object.
	var target_obj: InteractableObject = interactables_by_intent[intent]
	var stand_spot: Vector2 = (target_obj.global_position + WALK_TARGET_OFFSET).clamp(WALK_TARGET_MIN, WALK_TARGET_MAX)
	resident.walk_to(stand_spot)

func _on_attempt_timer_timeout() -> void:
	if resolution != ResolutionState.NONE or not _has_active_intent:
		return
	var obj: InteractableObject = interactables_by_intent[_current_intent]
	var succeeded: bool = not obj.is_sabotaged
	if succeeded:
		hope += obj.definition.hope_gain_on_success
	else:
		hope -= obj.definition.hope_penalty_on_sabotage
	hope = clampf(hope, HOPE_MIN, HOPE_MAX)
	hope_changed.emit(hope)
	# Resolution MUST be evaluated before any flag is reset below. If this attempt is the Door
	# Key's own intent and the player just sabotaged it, the resolution check needs to see
	# is_sabotaged == true to correctly withhold the ending -- resetting first would make a
	# just-defended key look "available" to the very check it was meant to block (caught during
	# implementation review).
	_evaluate_resolution()
	# The resident's focus now shifts to a new target: EVERY object snaps back to its default
	# state (not just the resolved one), so the room visually recovers between attempts and no
	# object stays stuck in its sabotaged sprite. A sabotage therefore only counts within the
	# attempt window it was played in -- holding the key at 100% Hope requires actively
	# re-sabotaging it each attempt.
	for other: InteractableObject in interactables_by_intent.values():
		other.set_sabotaged(false)
	_has_active_intent = false
	intent_resolved.emit(_current_intent, succeeded)

## FR-014/FR-015/FR-016: precedence order matters -- Hope reaching 0 always wins first.
func _evaluate_resolution() -> void:
	if resolution != ResolutionState.NONE:
		return
	if hope <= HOPE_MIN:
		resolution = ResolutionState.DEPRESSION_PREVAILS
		session_resolved.emit(resolution)
		return
	if hope >= HOPE_MAX:
		var key_obj: InteractableObject = interactables_by_intent[InteractableDefinition.IntentType.DOOR_KEY]
		if not key_obj.is_sabotaged:
			resolution = ResolutionState.RESIDENT_ENDURES
			session_resolved.emit(resolution)
		# else: Hope holds at 100, no resolution yet (FR-016) -- re-evaluated on the next
		# resolved attempt, whichever object it is.

## FR-017: the day ends in the resident's favor once time runs out, whether Hope is sitting
## below 100 or held there by a currently-sabotaged key.
func _on_session_clock_timeout() -> void:
	if resolution != ResolutionState.NONE:
		return
	resolution = ResolutionState.RESIDENT_ENDURES
	session_resolved.emit(resolution)

func _on_energy_regen_timer_timeout() -> void:
	if resolution != ResolutionState.NONE or dark_energy >= ENERGY_MAX:
		return
	dark_energy = minf(dark_energy + ENERGY_REGEN_PER_SECOND * energy_regen_timer.wait_time, ENERGY_MAX)
	_update_energy_state()
	energy_changed.emit(dark_energy, energy_state)

func _update_energy_state() -> void:
	if dark_energy >= ENERGY_MAX:
		energy_state = EnergyState.READY
	elif dark_energy < ENERGY_CRITICAL_THRESHOLD:
		energy_state = EnergyState.CRITICAL
	else:
		energy_state = EnergyState.RECHARGING
