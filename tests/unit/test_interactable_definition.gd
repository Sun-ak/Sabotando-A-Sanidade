extends GutTest
## Validates the 5 InteractableDefinition .tres resources against
## specs/001-core-sabotage-loop/contracts/interactable-definition-schema.md's cross-checks.

const CURTAINS_PATH := "res://resources/interactables/curtains.tres"
const PHONE_PATH := "res://resources/interactables/phone.tres"
const LAUNDRY_PATH := "res://resources/interactables/laundry_basket.tres"
const DOOR_KEY_PATH := "res://resources/interactables/door_key.tres"
const THOUGHTS_PATH := "res://resources/interactables/thoughts.tres"

var _all_paths: Array[String] = [CURTAINS_PATH, PHONE_PATH, LAUNDRY_PATH, DOOR_KEY_PATH, THOUGHTS_PATH]
var _definitions: Array[InteractableDefinition] = []

func before_each() -> void:
	_definitions.clear()
	for path: String in _all_paths:
		var definition: InteractableDefinition = load(path)
		_definitions.append(definition)

func test_all_five_resources_load() -> void:
	for i in range(_definitions.size()):
		assert_not_null(_definitions[i], "Expected %s to load" % _all_paths[i])

func test_tier_costs_strictly_increase() -> void:
	var tier_cost: Dictionary = {
		InteractableDefinition.CostTier.LOW: 10,
		InteractableDefinition.CostTier.MEDIUM: 20,
		InteractableDefinition.CostTier.HIGH: 35,
		InteractableDefinition.CostTier.VERY_HIGH: 50,
	}
	assert_lt(tier_cost[InteractableDefinition.CostTier.LOW], tier_cost[InteractableDefinition.CostTier.MEDIUM])
	assert_lt(tier_cost[InteractableDefinition.CostTier.MEDIUM], tier_cost[InteractableDefinition.CostTier.HIGH])
	assert_lt(tier_cost[InteractableDefinition.CostTier.HIGH], tier_cost[InteractableDefinition.CostTier.VERY_HIGH])

func test_exactly_one_blocks_door_resolution() -> void:
	var blockers: int = 0
	for definition: InteractableDefinition in _definitions:
		if definition.blocks_door_resolution:
			blockers += 1
	assert_eq(blockers, 1, "Exactly one InteractableDefinition must block door resolution")

func test_hope_penalty_is_zero_except_curtains_and_thoughts() -> void:
	for definition: InteractableDefinition in _definitions:
		var is_penalized_intent: bool = definition.intent == InteractableDefinition.IntentType.CURTAINS \
			or definition.intent == InteractableDefinition.IntentType.THOUGHTS
		if is_penalized_intent:
			assert_gt(definition.hope_penalty_on_sabotage, 0.0, "%s must have a nonzero penalty" % definition.id)
		else:
			assert_eq(definition.hope_penalty_on_sabotage, 0.0, "%s must have a zero penalty" % definition.id)

func test_hope_gain_on_success_is_positive_for_all() -> void:
	for definition: InteractableDefinition in _definitions:
		assert_gt(definition.hope_gain_on_success, 0.0, "%s must have a positive hope_gain_on_success" % definition.id)

func test_intents_form_a_complete_unique_set() -> void:
	var seen: Dictionary = {}
	for definition: InteractableDefinition in _definitions:
		assert_false(seen.has(definition.intent), "Duplicate intent found: %s" % definition.intent)
		seen[definition.intent] = true
	var expected: Array[InteractableDefinition.IntentType] = [
		InteractableDefinition.IntentType.CURTAINS,
		InteractableDefinition.IntentType.PHONE,
		InteractableDefinition.IntentType.LAUNDRY,
		InteractableDefinition.IntentType.DOOR_KEY,
		InteractableDefinition.IntentType.THOUGHTS,
	]
	for intent: InteractableDefinition.IntentType in expected:
		assert_true(seen.has(intent), "Missing intent: %s" % intent)

func test_only_curtains_uses_click_repeat_gesture() -> void:
	for definition: InteractableDefinition in _definitions:
		if definition.gesture == InteractableDefinition.GestureType.CLICK_REPEAT:
			assert_eq(definition.intent, InteractableDefinition.IntentType.CURTAINS)
