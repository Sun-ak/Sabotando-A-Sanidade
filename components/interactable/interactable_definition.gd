class_name InteractableDefinition
extends Resource
## Static data for one of the five contested room objects. See
## specs/001-core-sabotage-loop/contracts/interactable-definition-schema.md for the concrete
## values each of the five .tres instances must hold, and data-model.md for validation rules.

## Single source of truth for the resident's five possible intents (research.md R11).
## InteractableObject/BedroomController/Resident all reference this enum rather than redeclaring it.
enum IntentType { CURTAINS, PHONE, LAUNDRY, DOOR_KEY, THOUGHTS }

enum GestureType { CLICK_REPEAT, CLICK_ONCE, DRAG }

enum CostTier { LOW, MEDIUM, HIGH, VERY_HIGH }

@export var id: StringName = &""
@export var intent: IntentType = IntentType.CURTAINS
## Translation key for this object's display name (contracts/localization-keys.md).
@export var display_name_key: String = ""
@export var gesture: GestureType = GestureType.CLICK_ONCE
## Hope points added when the resident's intent on this object resolves unsabotaged (FR-008).
@export var hope_gain_on_success: float = 0.0
## Hope points subtracted when this object's sabotage causes the resident's intent to fail
## (FR-009). Zero for every object except Curtains/Thoughts, whose sabotage effect is denying
## hope_gain_on_success with no additional debit.
@export var hope_penalty_on_sabotage: float = 0.0
@export var energy_cost_tier: CostTier = CostTier.LOW
## Visual/animation state key while is_sabotaged == true (e.g. &"closed", &"hidden").
@export var sabotaged_state_key: StringName = &""
## Visual/animation state key while is_sabotaged == false (e.g. &"open", &"visible").
@export var default_state_key: StringName = &""
## true only for the door key; gates BedroomController's 100%-Hope resolution (FR-015/FR-016).
@export var blocks_door_resolution: bool = false
## Sprite shown while current_state == default_state_key (FR-010).
@export var default_texture: Texture2D
## Sprite shown while current_state == sabotaged_state_key (FR-010).
@export var sabotaged_texture: Texture2D
## Horizontal frame count shared by both textures (1 = static sprite; >1 animates, e.g. the
## spinning door key's 24-frame strip).
@export var texture_frame_count: int = 1
@export var texture_frames_per_second: float = 12.0
## Played once when a sabotage gesture on this object is accepted by BedroomController.
@export var sabotage_sound: AudioStream
