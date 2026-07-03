# Data Model: Core Sabotage Loop

Source: spec.md Key Entities, formalized per research.md decisions R1–R12. Field types follow
constitution Principle V (static typing mandatory). This document describes shape and behavior
contracts, not full method bodies — implementation lives in tasks.md/the codebase.

**Amendment note**: this document was rewritten to match the corrected tug-of-war mechanic
(research.md R11/R12). The most significant structural change from the original version: `Resident`
no longer reads Hope directly to decide its whole behavior, and never references
`InteractableObject`/`InteractableDefinition` at all — `BedroomController` mediates the entire
intent → attempt → resolution cycle, per R11.

## InteractableDefinition

`class_name InteractableDefinition extends Resource` — one `.tres` instance per sabotageable
object (5 total, under `resources/interactables/`). Pure data; no behavior.

| Field | Type | Notes |
|---|---|---|
| `id` | `StringName` | Unique identifier, e.g. `&"curtains"`, `&"phone"`, `&"laundry_basket"`, `&"door_key"`, `&"thoughts"` |
| `intent` | `IntentType` (enum: `CURTAINS`, `PHONE`, `LAUNDRY`, `DOOR_KEY`, `THOUGHTS`) | The 1:1 intent this object corresponds to (research.md R11) — used as the dictionary key `BedroomController` builds to route `Resident.intent_selected` to the right object. `IntentType` is declared **inside this class** (`InteractableDefinition.IntentType`) as its single source of truth; `Resident`/`resident_state.gd` reference it rather than redeclaring it, avoiding a duplicate/drifting enum |
| `display_name_key` | `String` | Translation key, e.g. `"OBJ_CURTAINS_NAME"` (see contracts/localization-keys.md) |
| `gesture` | `GestureType` (enum: `CLICK_REPEAT`, `CLICK_ONCE`, `DRAG`) | Curtains=`CLICK_REPEAT`; Laundry, Thoughts=`CLICK_ONCE`; Phone, Key=`DRAG` |
| `hope_gain_on_success` | `float` | Hope points **added** when the resident's intent on this object resolves unsabotaged (FR-008). Proposed values in research.md R12: Curtains +10, Phone +8, Laundry +8, Door Key +5, Thoughts +15 |
| `hope_penalty_on_sabotage` | `float` | Hope points **subtracted** when the resident's intent on this object resolves sabotaged (FR-009). Non-zero (sourced) only for Curtains (15) and Thoughts (30); zero for Phone/Laundry/Door Key, whose sabotage effect is denying `hope_gain_on_success` with no additional debit |
| `energy_cost_tier` | `CostTier` (enum: `LOW`, `MEDIUM`, `HIGH`, `VERY_HIGH`) | Drives the numeric cost (via `BedroomController`'s tier→value map) and the UI's affordability indicator (SC-006). Curtains/Phone=LOW, Laundry=MEDIUM, Door Key=HIGH, Thoughts=VERY_HIGH |
| `sabotaged_state_key` | `StringName` | Which visual/animation state the paired `InteractableObject` switches to while `is_sabotaged == true`, e.g. `&"closed"`, `&"hidden"`, `&"fallen"` |
| `default_state_key` | `StringName` | Which visual/animation state the object shows while `is_sabotaged == false`, e.g. `&"open"`, `&"visible"`, `&"standing"` (added during implementation — the original draft of this table implied a default existed without naming a field for it) |
| `blocks_door_resolution` | `bool` | `true` only for Door Key; while `is_sabotaged == true` on this object, `BedroomController` MUST NOT fire the 100%-Hope "Resident endures" resolution (FR-016) |

**Validation rules** (enforced at load time by `BedroomController`, checked by
`test_interactable_definition.gd`):
- `energy_cost_tier` → numeric cost must strictly increase LOW < MEDIUM < HIGH < VERY_HIGH
  (FR-004), a property of the tier→value map, cross-checked against each resource's assignment.
- `hope_penalty_on_sabotage` MUST be `0` for every object except Curtains/Thoughts.
- `hope_gain_on_success` MUST be `> 0` for all five objects (every intent is worth *something* to
  the resident if it succeeds — FR-008 applies uniformly).
- Exactly one row has `blocks_door_resolution == true` (`door_key`).
- The five `intent` values, taken together, MUST be exactly `{CURTAINS, PHONE, LAUNDRY, DOOR_KEY,
  THOUGHTS}` with no duplicates and no omissions (required for `BedroomController`'s dictionary
  lookup in R11 to always resolve).

## InteractableObject

`class_name InteractableObject extends Area2D` — runtime component, one instance per object in
`bedroom.tscn`, each with a distinct `InteractableDefinition` wired via `@export`.

| Field | Type | Notes |
|---|---|---|
| `definition` | `InteractableDefinition` | `@export`, assigned per-instance in the editor |
| `current_state` | `StringName` | Starts at a definition-implied default (e.g. `&"open"`, `&"visible"`, `&"standing"`); becomes `definition.sabotaged_state_key` while `is_sabotaged == true` |
| `is_sabotaged` | `bool` | `false` at session start (FR-019). Set to `true` the instant the object's gesture completes (FR-002/FR-003), **regardless of whether the resident currently has an intent on this object**. Reset to `false` by `BedroomController` exactly once — when this object is the target of an intent that resolves (research.md R11 step 4). Not reset by anything else: a sabotage applied with no active intent on the object simply waits, visually reflected, until the resident's next attempt on it |

**Signals**:
- `sabotage_attempted(definition: InteractableDefinition)` — emitted on every valid input gesture
  completion. `BedroomController` listens and immediately sets `is_sabotaged = true` on the
  emitting object (subject to the Dark Energy affordability check, FR-005 — a refused gesture does
  not emit this signal at all, per contracts/signals.md).
- `state_changed(new_state: StringName)` — emitted whenever `current_state` changes, for the
  object's own sprite/animation to react to (self-contained per Principle I).

**Relationship**: 5 `InteractableObject` instances each reference exactly one
`InteractableDefinition` (1:1 for this feature). `InteractableObject` has **no reference to, and no
knowledge of, `Resident`** — per research.md R11, only `BedroomController` connects the two.

## BedroomController

`class_name BedroomController extends Node2D` — root node of `bedroom.tscn`; owns all session
state and mediates the Resident ↔ InteractableObject relationship. Not an Autoload (research.md R7).

| Field | Type | Notes |
|---|---|---|
| `hope` | `float` | 0.0–100.0, **starts at 50.0** (research.md R10, sourced from the GDD) |
| `dark_energy` | `float` | 0.0–100.0 (max), starts at 100.0 |
| `energy_state` | `EnergyState` (enum: `READY`, `CRITICAL`, `RECHARGING`) | Derived each time `dark_energy` changes: `READY` if `== max`; `CRITICAL` if `< 20`; else `RECHARGING` |
| `session_clock` | `Timer` (child node) | One-shot, `wait_time = 300.0` (research.md R10) |
| `attempt_timer` | `Timer` (child node) | One-shot, `wait_time = 6.0` (research.md R10), restarted each time a new intent is selected |
| `interactables_by_intent` | `Dictionary[IntentType, InteractableObject]` | Built once in `_ready()` from the 5 children, per research.md R11 step 2 |
| `resolution` | `ResolutionState` (enum: `NONE`, `DEPRESSION_PREVAILS`, `RESIDENT_ENDURES`) | Starts `NONE`; terminal once set — no further Hope/Energy mutation accepted after resolution |

**Signals**:
- `hope_changed(new_value: float)`
- `energy_changed(new_value: float, state: EnergyState)`
- `intent_resolved(intent: IntentType, succeeded: bool)` — new (R11): fired after every attempt
  resolution, consumed by `Resident` for its animation/bubble reaction
- `session_resolved(resolution: ResolutionState)`

**Behavior contracts** (validated by `test_bedroom_controller_hope_energy.gd` and
`test_bedroom_controller_resolution.gd`):

- On `InteractableObject.sabotage_attempted`: if `resolution != NONE`, ignore. Else if
  `dark_energy < tier_cost(definition.energy_cost_tier)`, refuse — no state change (FR-005). Else
  deduct cost, set `is_sabotaged = true` and `current_state = definition.sabotaged_state_key` on
  the object, emit `energy_changed`. **This does not by itself change Hope** — Hope only changes at
  attempt resolution (below), which is what makes "sabotage anytime, resolve later" (FR-002/FR-003)
  work.
- On `Resident.intent_selected(intent)`: look up `interactables_by_intent[intent]`, restart
  `attempt_timer`.
- On `attempt_timer.timeout`: let `obj = interactables_by_intent[current_intent]`. If
  `obj.is_sabotaged`: apply `hope -= obj.definition.hope_penalty_on_sabotage` (FR-009); else apply
  `hope += obj.definition.hope_gain_on_success` (FR-008). Clamp `hope` to `[0, 100]`. Reset
  `obj.is_sabotaged = false`, `obj.current_state` back to its default (R11 step 4's flag
  consumption). Emit `hope_changed`, then `intent_resolved(current_intent, succeeded)`. Then run
  the **resolution check order** below.
- **Resolution check order** (evaluated after every Hope change, both from sabotage-penalty and
  from resident-success — spec.md Edge Cases):
  1. If `hope <= 0`: `resolution = DEPRESSION_PREVAILS`, emit `session_resolved`, stop (FR-014).
  2. Else if `hope >= 100` AND `interactables_by_intent[DOOR_KEY].is_sabotaged == false`:
     `resolution = RESIDENT_ENDURES`, emit `session_resolved`, stop (FR-015).
  3. Else if `hope >= 100` AND the door key **is** sabotaged: do nothing further this check — Hope
     holds at 100 (clamped), no resolution fires (FR-016). The next time the `DOOR_KEY` intent
     specifically resolves (whether it succeeds, clearing the key's `is_sabotaged` flag as a side
     effect of resolution, or the player re-sabotages it again beforehand), this check re-runs.
- On `session_clock.timeout`: if `resolution == NONE` and `hope < 100`: `resolution =
  RESIDENT_ENDURES`, emit `session_resolved` (FR-017). If `hope` happens to already be `>= 100` at
  this instant (held there by a sabotaged key per case 3 above), the session has not naturally
  resolved yet — timeout in that specific edge case still resolves as `RESIDENT_ENDURES` too, since
  the resident's hope was clearly sufficient; the key's block only delays, it doesn't permanently
  prevent, this particular path once time is up.
- Dark Energy regenerates via a second, repeating `Timer` (or `_process` accumulation) at
  +5/second while `dark_energy < 100` and `resolution == NONE`.

## Resident

`class_name Resident extends CharacterBody2D` — the only "actor" per constitution vocabulary in
this feature (see plan.md's Constitution Check note). **Has no reference to `InteractableObject`,
`InteractableDefinition`, or `BedroomController`'s Hope/Energy fields** — it only emits
`intent_selected` and listens to `hope_changed` (for idle mood) and `intent_resolved` (for its own
reaction), both connections made *by* `BedroomController` (Principle III: the child never reaches
upward to ask who its parent is).

| Field | Type | Notes |
|---|---|---|
| `behavior_state` | `ResidentState` (enum: `IDLE`, `WALKING`, `REACHING`, `SITTING_SAD`, `CRYING`) | `WALKING`/`REACHING` driven by the current attempt's lifecycle (R11); `IDLE`/`SITTING_SAD`/`CRYING` driven by the last-known `hope` value when between attempts (research.md R10's idle-mood threshold) |
| `current_intent` | `IntentType?` | `null` between attempts; set the instant a new intent is picked |
| `pick_intent_timer` | `Timer` (child node) | Drives the `IDLE` → pick-next-intent loop; `wait_time` = research.md R10's inter-attempt pause (2.0s) after each `intent_resolved` |

**Signals**: `intent_selected(intent: IntentType)` — emitted the moment a new `IntentType` is
chosen (weighted-random among the 5, e.g. excluding immediate repeats of the just-resolved intent
for variety). Shows the matching thought bubble (`BUBBLE_*` key, contracts/localization-keys.md)
in the same call.

**State transition table** (composed, not exclusive — research.md R4 amendment):

| Trigger | `behavior_state` |
|---|---|
| `pick_intent_timer` fires → `intent_selected` emitted | `WALKING` (toward the object) |
| A short fixed delay after `intent_selected` (arrival) | `REACHING` (attempting), held until `intent_resolved` arrives |
| `intent_resolved(intent, succeeded=false)` received | brief reaction beat, then `IDLE`; thought bubble switches to `BUBBLE_SEARCHING` (FR-012) |
| `intent_resolved(intent, succeeded=true)` received | brief reaction beat, then `IDLE` |
| While `IDLE` (between attempts) and `hope_changed` last reported `< 20` | `CRYING` bias |
| While `IDLE` and `hope_changed` last reported `20 ≤ hope < 50` | `SITTING_SAD` bias |
| While `IDLE` and `hope_changed` last reported `hope ≥ 50` | plain `IDLE`/ambient-walk bias |

## ResourceBar (UI component)

`class_name ResourceBar extends Control` — one scene (`resource_bar.tscn`), instanced twice (Hope,
Dark Energy) per Principle I. **Unchanged from the pre-amendment design** — it only ever displays a
`current_value`/`max_value` pair regardless of which direction the value is currently moving.

| Field | Type | Notes |
|---|---|---|
| `label_key` | `String` | `@export`, translation key for the bar's caption (`"UI_HOPE_LABEL"` / `"UI_ENERGY_LABEL"`) |
| `current_value` | `float` | Set externally by `HUD` in response to `BedroomController` signals |
| `max_value` | `float` | `@export`, `100.0` for both bars |

No signals — this is a pure display component (Principle I: single responsibility, no gameplay
logic).

## Session Resolution (embedded enum, not a separate node)

Already modeled as `BedroomController.resolution : ResolutionState`. `resolution_overlay.tscn`
binds its two display variants to this enum's two non-`NONE` values. Note that `RESIDENT_ENDURES`
now covers **two distinct triggers** (Hope reaches 100% with the key available; OR the clock times
out with Hope short of 0%) but a single shared resolution text (`RES_RESIDENT_ENDURES_TITLE`) —
per spec.md's Assumptions, this is a deliberate simplification (jam-scope, anti-feature-creep) over
giving the two triggers separate narrative beats.

## Entity relationship summary

```text
BedroomController (Node2D, root)
├── owns state: hope, dark_energy, energy_state, session_clock, attempt_timer, resolution
├── owns: interactables_by_intent (Dictionary built from the 5 children below)
├── 5× InteractableObject (Area2D)         each --references--> 1 InteractableDefinition (Resource)
├── 1× Resident (CharacterBody2D)          emits intent_selected; listens to hope_changed, intent_resolved
├── 1× HUD (CanvasLayer/Control)
│   └── 2× ResourceBar (Control)           listens to hope_changed / energy_changed
└── 1× ResolutionOverlay (CanvasLayer/Control)   listens to session_resolved
```

`Resident` and `InteractableObject` do **not** have an edge directly connecting them — every
interaction between "what the resident wants" and "what the player sabotaged" passes through
`BedroomController`. All arrows are signal listens or one-way `@export` data references — no node
reaches upward via `get_parent()`/`get_node("..")`, per constitution Principle II/III.
