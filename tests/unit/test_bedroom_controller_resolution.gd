extends GutTest
## Covers FR-014/FR-015/FR-016/FR-017 -- the full resolution check order from data-model.md,
## including a regression test for an ordering bug caught during implementation review (resolving
## the door key's own attempt must not reset its sabotage flag before the resolution check reads
## it, or a successfully-defended key would look "available" to the very check it should block).

var _controller: BedroomController

func before_each() -> void:
	var scene: PackedScene = load("res://levels/bedroom/bedroom.tscn")
	_controller = scene.instantiate()
	add_child(_controller)
	await wait_process_frames(1)

func after_each() -> void:
	_controller.queue_free()

func _obj(intent: InteractableDefinition.IntentType) -> InteractableObject:
	return _controller.interactables_by_intent[intent]

func _key() -> InteractableObject:
	return _obj(InteractableDefinition.IntentType.DOOR_KEY)

func test_hope_reaching_zero_resolves_depression_prevails() -> void:
	_controller.hope = 15.0
	var curtains: InteractableObject = _obj(InteractableDefinition.IntentType.CURTAINS)
	_controller._on_sabotage_attempted(curtains.definition)
	_controller._on_intent_selected(InteractableDefinition.IntentType.CURTAINS)
	_controller._on_attempt_timer_timeout() # -15 -> hope = 0
	assert_eq(_controller.resolution, BedroomController.ResolutionState.DEPRESSION_PREVAILS)

func test_hope_reaching_100_with_key_available_resolves_resident_endures() -> void:
	_controller.hope = 95.0
	_controller._on_intent_selected(InteractableDefinition.IntentType.CURTAINS)
	# No sabotage -- let it succeed (+10 -> 105, clamped to 100).
	_controller._on_attempt_timer_timeout()
	assert_eq(_controller.resolution, BedroomController.ResolutionState.RESIDENT_ENDURES)

func test_hope_reaching_100_with_key_sabotaged_holds_without_resolving() -> void:
	_controller.hope = 95.0
	_key().set_sabotaged(true)
	_controller._on_intent_selected(InteractableDefinition.IntentType.CURTAINS)
	_controller._on_attempt_timer_timeout() # +10 -> would be 105, clamped to 100
	assert_eq(_controller.hope, 100.0)
	assert_eq(_controller.resolution, BedroomController.ResolutionState.NONE, "Key sabotage must block the 100%% resolution (FR-016)")

func test_successfully_defending_the_keys_own_attempt_does_not_falsely_resolve() -> void:
	_controller.hope = 100.0
	_key().set_sabotaged(true) # held from an earlier cycle
	_controller._on_intent_selected(InteractableDefinition.IntentType.DOOR_KEY)
	_controller._on_sabotage_attempted(_key().definition) # player re-defends during this window
	_controller._on_attempt_timer_timeout()
	assert_eq(_controller.resolution, BedroomController.ResolutionState.NONE, "A successfully-defended key must not trigger Resident Endures")

func test_clock_timeout_with_hope_below_100_resolves_resident_endures() -> void:
	_controller.hope = 60.0
	_controller._on_session_clock_timeout()
	assert_eq(_controller.resolution, BedroomController.ResolutionState.RESIDENT_ENDURES)

func test_clock_timeout_with_hope_held_at_100_still_resolves_resident_endures() -> void:
	_controller.hope = 100.0
	_key().set_sabotaged(true)
	_controller._on_session_clock_timeout()
	assert_eq(_controller.resolution, BedroomController.ResolutionState.RESIDENT_ENDURES, "FR-017: clock timeout resolves regardless of the key's state")

func test_resolution_is_terminal_and_locks_out_further_sabotage() -> void:
	_controller.hope = 0.0
	_controller._evaluate_resolution()
	assert_eq(_controller.resolution, BedroomController.ResolutionState.DEPRESSION_PREVAILS)
	var curtains: InteractableObject = _obj(InteractableDefinition.IntentType.CURTAINS)
	var energy_before: float = _controller.dark_energy
	_controller._on_sabotage_attempted(curtains.definition)
	assert_almost_eq(_controller.dark_energy, energy_before, 0.001, "Post-resolution sabotage attempts must be ignored (T035)")
