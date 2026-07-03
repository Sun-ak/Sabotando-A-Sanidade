# Contract: Signals

Per constitution Principle III, signals — not direct method calls or `get_parent()`/`get_node()`
traversal — are the interface between components. This is the binding contract for every signal
this feature introduces. Any task implementing a listed emitter or listener MUST match this
contract exactly (name, payload types, firing conditions).

**Amendment note**: rewritten for the corrected tug-of-war mechanic (research.md R11). Two new
signals (`Resident.intent_selected`, `BedroomController.intent_resolved`) mediate the
resident-vs-player contest; `InteractableObject.sabotage_attempted` no longer directly causes a
Hope change (see below).

## `InteractableObject.sabotage_attempted`

```gdscript
signal sabotage_attempted(definition: InteractableDefinition)
```

- **Emitter**: any `InteractableObject`, once its `definition.gesture` input pattern completes
  (click, repeated click, or drag-release over a valid drop target).
- **Listener**: `BedroomController` (the only listener; connected when the object is instanced as
  a child).
- **Firing guarantee**: emitted on *every* completed gesture, even if the controller will end up
  refusing it for insufficient Dark Energy or because the session is already resolved. The object
  does not pre-check affordability — that decision belongs solely to `BedroomController`.
- **Effect on receipt** (changed from the pre-amendment version): sets `is_sabotaged = true` on the
  emitting object (subject to the affordability/resolution checks) and deducts Dark Energy. **It
  does NOT change Hope.** Hope only changes when the resident's attempt on that object resolves
  (`attempt_timer.timeout` — see `intent_resolved` below). A sabotage gesture can be — and often
  will be — triggered with no resident intent currently active on that object at all (preemptive
  sabotage, spec.md FR-002); in that case `is_sabotaged` simply stays `true`, visually reflected,
  until the resident's next attempt on that specific object consumes it.

## `InteractableObject.state_changed`

```gdscript
signal state_changed(new_state: StringName)
```

- **Emitter**: `InteractableObject`, whenever `current_state` is written.
- **Listener**: the object's own child `AnimatedSprite2D`/`Sprite2D` (internal to the same scene).

## `Resident.intent_selected` (new)

```gdscript
signal intent_selected(intent: IntentType)
```

- **Emitter**: `Resident`, the moment its `pick_intent_timer` fires and a new `IntentType` is
  chosen (weighted-random among the 5 defined intents).
- **Listener**: `BedroomController`, which looks up the matching `InteractableObject` via
  `interactables_by_intent[intent]` and restarts `attempt_timer` (research.md R11 step 2).
- **Firing guarantee**: exactly one `intent_selected` is outstanding at a time — `Resident` MUST
  NOT emit a new one before the previous intent has resolved (`intent_resolved` received).
- **Side effect on emission**: `Resident` shows its own thought bubble for that intent in the same
  call (no separate signal needed for the bubble — it's the resident's own concern, per Principle
  I, not something `BedroomController` needs to orchestrate).

## `BedroomController.intent_resolved` (new)

```gdscript
signal intent_resolved(intent: IntentType, succeeded: bool)
```

- **Emitter**: `BedroomController`, on `attempt_timer.timeout`, immediately after applying the
  Hope change and resetting the target object's `is_sabotaged` flag (research.md R11 step 4).
- **Listener**: `Resident` — drives its success/thwarted reaction animation and (on failure) the
  `BUBBLE_SEARCHING` thought bubble (FR-012), then its return to `IDLE` and the next
  `pick_intent_timer` countdown.
- **Contract**: `succeeded == !obj.is_sabotaged` at the instant of resolution — `Resident` does not
  need to know *why* it failed (which object, what sabotage), only whether it did.

## `BedroomController.hope_changed`

```gdscript
signal hope_changed(new_value: float)
```

- **Emitter**: `BedroomController`, immediately after `hope` is mutated during attempt resolution
  (either the gain-on-success or the penalty-on-sabotage branch — never on `sabotage_attempted`
  directly, per the amendment above).
- **Listeners**: `Resident` (to re-evaluate its idle-mood bias, FR-011), the Hope `ResourceBar`
  instance.
- **Firing guarantee**: fired at most once per resolved attempt; never fired after `resolution !=
  NONE`.

## `BedroomController.energy_changed`

```gdscript
signal energy_changed(new_value: float, state: EnergyState)
```

- **Emitter**: `BedroomController`, after any Dark Energy mutation (spend on an accepted sabotage
  gesture, or passive regen tick).
- **Listener**: the Dark Energy `ResourceBar` instance, and the per-object affordability-hint UI
  (SC-006).

## `BedroomController.session_resolved`

```gdscript
signal session_resolved(resolution: ResolutionState)
```

- **Emitter**: `BedroomController`, exactly once per session, the instant `resolution` transitions
  away from `NONE` — from the resolution check order in data-model.md (Hope ≤ 0; or Hope ≥ 100 with
  the key available; or clock timeout with Hope < 100).
- **Listener**: `ResolutionOverlay`.
- **Post-condition**: after this fires, `BedroomController` MUST reject all further
  `sabotage_attempted` events and MUST stop the `pick_intent_timer`/`attempt_timer` cycle — a hard
  invariant, not a suggestion.

## `session_clock.timeout` / `attempt_timer.timeout` (built-in `Timer` signals)

- **Emitters**: the two `Timer` children owned by `BedroomController`.
- **Listener**: `BedroomController` itself connects to its own children — the one place a "self"
  connection is expected, not a violation of Principle III, which governs cross-node communication.
- **`session_clock.timeout` contract**: if `resolution == NONE`, resolve as `RESIDENT_ENDURES`
  regardless of the current Hope value (FR-017; see data-model.md's note on the held-at-100 edge
  case).
- **`attempt_timer.timeout` contract**: always resolves the current intent (there is no "no active
  intent" state once a session has started — `Resident` immediately begins its first
  `pick_intent_timer` countdown in `_ready()`).
