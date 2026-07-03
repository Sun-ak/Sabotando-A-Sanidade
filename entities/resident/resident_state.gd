class_name ResidentState
extends RefCounted
## Namespace holder for the Resident's animation/mood state enum. Never instantiated.
## IntentType lives in InteractableDefinition instead (single source of truth, research.md R11) --
## this file only holds the animation-facing state, which has no 1:1 relationship to objects.

enum State { IDLE, WALKING, REACHING, SITTING_SAD, CRYING }
