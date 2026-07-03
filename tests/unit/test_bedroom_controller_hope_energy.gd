extends GutTest
## Covers FR-002-FR-006/FR-008/FR-009 by driving BedroomController's handlers directly (bypassing
## real Area2D clicks and real Timer waits), per quickstart.md section 1's stated approach.

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

func test_session_starts_at_defined_values() -> void:
	assert_eq(_controller.hope, 50.0, "Hope must start at 50 (FR-019, sourced from the GDD)")
	assert_eq(_controller.dark_energy, 100.0)
	assert_eq(_controller.resolution, BedroomController.ResolutionState.NONE)

func test_unsabotaged_curtains_intent_increases_hope_by_gain() -> void:
	var starting_hope: float = _controller.hope
	_controller._on_intent_selected(InteractableDefinition.IntentType.CURTAINS)
	_controller._on_attempt_timer_timeout()
	assert_almost_eq(_controller.hope, starting_hope + 10.0, 0.001, "Curtains success grants +10 Hope")

func test_sabotaged_curtains_intent_decreases_hope_and_costs_energy() -> void:
	var starting_hope: float = _controller.hope
	var starting_energy: float = _controller.dark_energy
	var curtains_def: InteractableDefinition = _obj(InteractableDefinition.IntentType.CURTAINS).definition
	_controller._on_sabotage_attempted(curtains_def)
	_controller._on_intent_selected(InteractableDefinition.IntentType.CURTAINS)
	_controller._on_attempt_timer_timeout()
	assert_almost_eq(_controller.hope, starting_hope - 15.0, 0.001, "Curtains sabotage costs -15 Hope")
	assert_almost_eq(_controller.dark_energy, starting_energy - 10.0, 0.001, "Curtains is Low tier (10)")

func test_sabotaged_thoughts_intent_decreases_hope_by_penalty_and_costs_very_high_tier() -> void:
	var starting_hope: float = _controller.hope
	var starting_energy: float = _controller.dark_energy
	var thoughts_def: InteractableDefinition = _obj(InteractableDefinition.IntentType.THOUGHTS).definition
	_controller._on_sabotage_attempted(thoughts_def)
	_controller._on_intent_selected(InteractableDefinition.IntentType.THOUGHTS)
	_controller._on_attempt_timer_timeout()
	assert_almost_eq(_controller.hope, starting_hope - 30.0, 0.001)
	assert_almost_eq(_controller.dark_energy, starting_energy - 50.0, 0.001)

func test_sabotaged_phone_intent_denies_gain_without_extra_hope_penalty() -> void:
	var starting_hope: float = _controller.hope
	var phone_def: InteractableDefinition = _obj(InteractableDefinition.IntentType.PHONE).definition
	_controller._on_sabotage_attempted(phone_def)
	_controller._on_intent_selected(InteractableDefinition.IntentType.PHONE)
	_controller._on_attempt_timer_timeout()
	assert_almost_eq(_controller.hope, starting_hope, 0.001, "Phone sabotage denies the +8 gain but adds no separate penalty")

func test_unaffordable_sabotage_gesture_has_no_effect() -> void:
	var thoughts_obj: InteractableObject = _obj(InteractableDefinition.IntentType.THOUGHTS)
	_controller.dark_energy = 10.0 # below Thoughts' Very High (50) cost
	var starting_energy: float = _controller.dark_energy
	_controller._on_sabotage_attempted(thoughts_obj.definition)
	assert_false(thoughts_obj.is_sabotaged, "Refused gesture must not set is_sabotaged")
	assert_almost_eq(_controller.dark_energy, starting_energy, 0.001, "Refused gesture must not deduct Energy")

func test_dark_energy_regenerates_over_simulated_time() -> void:
	_controller.dark_energy = 50.0
	_controller._update_energy_state()
	for i in range(3):
		_controller._on_energy_regen_timer_timeout()
	assert_almost_eq(_controller.dark_energy, 65.0, 0.001, "3 ticks at +5/s (1s timer) = +15")

func test_energy_state_thresholds() -> void:
	_controller.dark_energy = 100.0
	_controller._update_energy_state()
	assert_eq(_controller.energy_state, BedroomController.EnergyState.READY)
	_controller.dark_energy = 19.0
	_controller._update_energy_state()
	assert_eq(_controller.energy_state, BedroomController.EnergyState.CRITICAL)
	_controller.dark_energy = 50.0
	_controller._update_energy_state()
	assert_eq(_controller.energy_state, BedroomController.EnergyState.RECHARGING)
