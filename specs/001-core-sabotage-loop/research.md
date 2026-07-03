# Research: Core Sabotage Loop

**Input**: Technical Context unknowns and technology/pattern choices from [plan.md](./plan.md),
grounded in `Sabotando a Sanidade - Design Guide.html` and the project constitution.

All items below were resolved without blocking `[NEEDS CLARIFICATION]` markers — the design guide
and constitution together supplied enough concrete detail to make a reasoned default choice in
every case. Numeric values are explicitly flagged as tunable defaults, not final balance.

## R1: Click/drag input detection for room objects

**Decision**: Each sabotageable object is an `Area2D` (component root of `InteractableObject`)
with `input_pickable = true`, using the node's `input_event(viewport, event, shape_idx)` signal to
detect clicks, and tracking `InputEventMouseButton` press+motion+release for the two objects that
need drag (Phone, Key) rather than a single click (Curtains, Basket, Thoughts).

**Rationale**: `Area2D.input_event` gives per-object hit detection for free (Godot already does
the shape-vs-cursor test), which is exactly what "click this specific object" needs, and it keeps
each `InteractableObject` self-contained per Principle I — the object knows when it was clicked
without the scene root polling anything.

**Alternatives considered**:
- `Control`-based clickable regions (`_gui_input`) — rejected: the room is a 2D scene with
  overlapping/rotated/irregular object shapes; `Area2D` + `CollisionShape2D` fits pixel-art hit
  regions better than rectangular `Control` nodes.
- A single `_unhandled_input` handler on `BedroomController` doing manual raycasts against all
  objects — rejected: centralizes logic that belongs to each object, violating Principle I's
  self-contained-component rule, and would force the controller to know about every object type.

## R2: Data-driven interactable definition

**Decision**: One `InteractableDefinition` (`class_name`, `extends Resource`) holds each object's
static data (gesture type, Hope effect, energy cost tier/value, sabotaged-state key). One generic
`InteractableObject` component script reads an `@export var definition: InteractableDefinition`
and behaves identically for all five objects; the five `.tres` files under
`resources/interactables/` are the only per-object "code."

**Rationale**: Satisfies Principle I directly (one component, not five near-duplicate scripts) and
means adding a 6th sabotage object later (out of this feature's scope, but a likely next feature)
is a new `.tres` file, not new GDScript.

**Alternatives considered**:
- Five separate scripts (`curtains.gd`, `phone.gd`, ...) each hardcoding its own effect/cost —
  rejected: violates Principle I (near-duplicate single-purpose scripts) and constitution
  Principle VI's "no duplicated logic" spirit.
- A single JSON/dictionary table loaded at runtime instead of typed `Resource` files — rejected:
  loses Godot's editor-side Inspector authoring and, more importantly, cannot satisfy Principle V's
  static-typing requirement as cleanly as a typed `Resource` class can.

## R3: Day-cycle clock

**Decision**: A `Timer` node (`wait_time` = the session length constant, `one_shot = true`) owned
by `BedroomController`, plus a `_process(delta)` accumulator only for the HUD's cosmetic HH:MM
display. The `Timer.timeout` signal is what actually triggers end-of-day evaluation — not a
polled comparison in `_process` — so the "did we hit the threshold" check cannot be missed by a
dropped frame.

**Rationale**: Matches Principle III (signal-driven, not polling, for the state-changing event)
while still allowing a smoothly-updating clock label for player feedback.

**Alternatives considered**: Pure `_process(delta)` accumulation with a manual threshold
comparison every frame — rejected as the sole mechanism because it re-introduces a polling check
for a one-time terminal event where a `Timer` signal is the more direct, idiomatic Godot fit;
kept only as the cosmetic display layer on top of the `Timer`.

## R4: Resident behavior state machine & thought-bubble telegraph (amended by R11)

**Decision**: A single `resident.gd` script with a typed `enum ResidentState { IDLE, WALKING,
REACHING, SITTING_SAD, CRYING }` and a typed `enum IntentType { CURTAINS, PHONE, LAUNDRY, DOOR_KEY,
THOUGHTS }` (corrected to a clean 1:1 mapping with the five objects — see R11), driven by a
`Timer`-based "pick next intent" loop. No formal State pattern (separate State resource/class per
state) is introduced. `ResidentState` now serves two purposes layered together: `WALKING`/
`REACHING` reflect the current attempt (intent-driven, R11), while `IDLE`/`SITTING_SAD`/`CRYING`
reflect mood between attempts (Hope-driven, R10's idle-mood threshold) — the two are not mutually
exclusive state-machine branches, they're composed (e.g., a low-Hope resident still walks to
attempt its next intent, just with a sadder idle look between attempts).

**Rationale**: Five behavior states and five intents is well within what a single well-typed
enum-driven script can hold clearly (Principle I's "single responsibility" is about the
component's scope — resident behavior — not about forcing one class per enum value). A formal
State-object pattern would add indirection with no payoff at this scale, and the 32-hour budget
(Technical Context Constraints) argues against it. The intent enum's 1:1 correspondence with
objects (rather than the original four narrative-ish intents) is what makes R11's dictionary-lookup
resolution algorithm possible without a translation table between "what the resident wants" and
"which object that means."

**Alternatives considered**: Per-state `Resource`/`Node` State-pattern objects — rejected as
premature structure for 5 states/5 intents; revisit only if a future feature grows the resident's
behavior significantly (e.g., multiple NPCs, branching dialogue).

## R5: Localization file format

**Decision**: CSV, per the constitution's Principle VII ("CSV or `.po` files"). One file,
`localization/strings.csv`, columns `keys, pt_BR` (single-locale for this feature).

**Rationale**: Godot imports translation CSVs natively (no gettext toolchain needed), and a
single flat CSV is the fastest to hand-edit for a solo/small jam team shipping one locale. `.po`
earns its keep once multiple locales and translator tooling are in play — not this feature's
scope (spec.md Assumptions: "Single locale").

**Alternatives considered**: `.po`/gettext — rejected for now as unnecessary process overhead for
a single-locale, time-boxed feature; the constitution leaves the door open to switch later since
it names both formats as acceptable.

## R6: Custom cursor ("Depressão")

**Decision**: `Input.set_custom_mouse_cursor()` with the design guide's "Cursor (Depressão)"
texture, set once when the bedroom scene loads.

**Rationale**: The asset is a static icon (not an animated multi-frame sprite like the resident's
walk cycle), so Godot's native cursor replacement is the simplest correct tool — one API call,
zero extra nodes, no risk of the cursor visually lagging the OS pointer.

**Alternatives considered**: A `Control`/`Sprite2D` that follows `get_global_mouse_position()` —
rejected for this feature since it adds an extra node and a per-frame position sync for no
functional gain over the native cursor; worth revisiting only if a future feature needs the cursor
to *animate* (e.g., a charge-up effect on hover), which is out of this feature's scope.

## R7: Autoload / cross-scene state — deliberately deferred

**Decision**: No Autoload is added by this feature. `BedroomController` (a plain node at the root
of the one and only scene) owns Hope, Dark Energy, clock, and resolution state directly. The
resolution outcome (win/lose) is shown as an in-scene `CanvasLayer` overlay
(`resolution_overlay.tscn`), not a scene transition — so no cross-scene signaling is needed at all
for this feature.

**Rationale**: Constitution Principle III reserves Autoloads for "genuine cross-scene services and
state" and explicitly warns against gameplay rules living in an Autoload. This feature has exactly
one scene. Adding an `EventBus`/`GameState` Autoload now would be architecture for a multi-scene
game this feature doesn't build yet — premature per Principle I's anti-"God object" spirit applied
to Autoloads. The constitution's own Project Layout example (`autoloads/ # EventBus, GameState...`)
describes a destination for the *project*, not a mandatory scaffold every feature must pre-build.

**Alternatives considered**: Add an `EventBus` Autoload now "to be ready" for a future main
menu/results scene — rejected: no current signal needs to cross a scene boundary, so this would be
unused indirection the moment it's written, violating Principle I. **Trigger for revisiting**: the
first future feature that adds a second scene (e.g., a title screen) should introduce the Autoload
then, as part of that feature's own plan.

## R8: Target platform / export template

**Decision** (amended — now confirmed, not speculative): the GDD (`gdd-sabotando-a-sanidade.html`)
explicitly states the target platform as "PC (Web/Desktop)". Desktop (Linux/Windows/macOS) remains
the primary development target; the GL Compatibility renderer — already mandated by the
constitution — is also Godot 4's requirement for an HTML5/Web export, so a browser export stays
available without rework when the team is ready for it.

**Rationale**: what R8 originally flagged as an educated guess turned out to be exactly right once
the GDD was read in full. No change to the renderer decision was needed — it was already correct.

**Alternatives considered**: N/A. **Follow-up**: an actual Web export build (`export_presets.cfg`,
HTML shell, icon) remains a release-prep task outside this feature's scope, but is now a confirmed
eventual requirement rather than a maybe.

## R11: Intent → attempt-window → resolution algorithm (amended mechanic)

**Context**: the GDD describes a real-time tug-of-war ("cabo de guerra"), not a one-way drain — the
resident actively pursues Hope-raising intents that the player must sabotage in time. This
research entry (added during the post-`/speckit-specify` correction) documents the concrete
algorithm chosen to implement that contest.

**Decision**: `BedroomController` mediates the entire cycle; `Resident` and `InteractableObject`
never reference each other directly.
1. `Resident` periodically picks a next `IntentType` (renamed to exactly mirror the five objects:
   `CURTAINS`, `PHONE`, `LAUNDRY`, `DOOR_KEY`, `THOUGHTS` — see the correction note below) and
   emits `intent_selected(intent_type)`. It shows its own telegraph thought bubble immediately.
2. `BedroomController` (which owns all 5 `InteractableObject` children plus `Resident` as direct
   children — Principle II) receives `intent_selected`, looks up the matching `InteractableObject`
   via a typed `Dictionary[IntentType, InteractableObject]` built once in `_ready()`, and starts a
   shared `AttemptTimer` for the attempt-window duration.
3. At any point before or during that window, the player may trigger the target (or any other)
   object's sabotage gesture; `InteractableObject` emits `sabotage_attempted`, which
   `BedroomController` turns into `is_sabotaged = true` on that object (independent of whether it
   is the current intent's target — satisfies "sabotage anytime," spec.md FR-002).
4. When `AttemptTimer` fires, `BedroomController` reads the target `InteractableObject.
   is_sabotaged` (a direct child-property read — allowed under Principle III, since
   `BedroomController` is that object's owner, not an unrelated node reaching across the tree),
   applies the corresponding Hope change (FR-008/FR-009), resets that object's `is_sabotaged` back
   to `false` (the flag is consumed exactly once, at resolution — spec.md's "Sabotage persistence"
   assumption), and emits `intent_resolved(intent_type, succeeded)`. `Resident` listens to this to
   drive its own success/thwarted animation and thought bubble, then returns to idle and — after a
   short pause — repeats from step 1.

**Rationale**: this keeps `Resident` and `InteractableObject` fully decoupled from each other
(neither imports or references the other's type), consistent with constitution Principle I/III.
`BedroomController` already owns both as children and already owns Hope/Energy state, so it is the
natural, single place resolution logic belongs — no new Autoload needed (R7 still holds).

**Alternatives considered**:
- Let `Resident` hold direct references to the 5 `InteractableObject` nodes and query
  `is_sabotaged` itself — rejected: couples the resident script to the interactable component's
  API, which Principle III's "a child MUST NOT assume anything about [other nodes'] type or API"
  guards against; `Resident` isn't even that object's parent, so a direct reference would be a
  lateral reach, not a parent-to-child call.
- Model "sabotage during the window" as a literal race resolved by whichever signal fires first
  (sabotage vs. timer) — rejected as equivalent in outcome to the "check state at timer end"
  approach above, but harder to reason about and test (order-of-signal-arrival edge cases) for no
  behavioral difference, since either way the player has the whole window to act.

**Correction to data-model.md's original `IntentType` enum**: the pre-amendment data model used
`{OPEN_WINDOW, USE_PHONE, FOLD_LAUNDRY, LEAVE_VIA_DOOR}` — four values, invented before the GDD was
read, missing a `THOUGHTS` intent entirely and not in 1:1 correspondence with the five
`InteractableDefinition` rows. The corrected enum is `{CURTAINS, PHONE, LAUNDRY, DOOR_KEY,
THOUGHTS}` — exactly one value per object, which is what the resolution algorithm above requires
(step 2's dictionary lookup needs a clean 1:1 mapping). "Wants to open the window" is now understood
as the Curtains intent's flavor text (window and curtains are the same interaction point), not a
separate intent.

## R12: Hope gain-on-success values (new, provisional)

**Decision**: since neither source document gives numeric Hope-gain values (only the
sabotage-penalty side has sourced numbers), the following are proposed defaults, recorded here
rather than left as a spec-blocking gap:

| Object | Hope gain on unsabotaged success | Hope penalty on sabotage |
|---|---|---|
| Curtains | +10% | −15% (sourced) |
| Phone | +8% | 0% (deny-only, sourced qualitative) |
| Laundry | +8% | 0% (deny-only, sourced qualitative) |
| Door Key | +5% | 0% (deny-only; its real effect is blocking the 100%-Hope resolution, sourced) |
| Thoughts | +15% | −30% (sourced) |

**Rationale**: gain values are set below their corresponding penalty (where one exists) so that
successfully sabotaging an object is always at least as valuable to the player as letting it
succeed was costly — this keeps active play (User Story 1) meaningfully better than passive play
(spec.md SC-002 vs. SC-003) without the exact ratio being load-bearing for any FR.

**Alternatives considered**: mirroring the penalty value exactly (e.g., Curtains ±15% symmetric) —
rejected as a starting point because a purely symmetric tug-of-war risks a session that hovers near
50% for a long time if the player sabotages roughly as often as they miss, which works against
SC-005's ≤10-minute session target; asymmetric-but-related values bias the system toward resolving.

## R9: Hope / Dark Energy bar rendering

**Decision**: `TextureProgressBar` for both bars (Hope and Dark Energy), skinned with pixel-art
fill textures matching the design guide's segmented-bar look, wrapped by the shared
`resource_bar.tscn` component (Principle I: one component, two instances/themes).

**Rationale**: `TextureProgressBar` is a built-in Godot `Control` node purpose-built for exactly
this (percentage-driven fill, texture-skinnable, no custom drawing code needed) — fastest path to
the design guide's visual within the 32-hour budget.

**Alternatives considered**: A custom `_draw()`-based segmented bar for a more precise pixel-art
segment look — rejected as a first pass (more implementation time for a purely cosmetic gain);
worth revisiting as a polish task if time remains after the core loop is verified.

## R10: Initial tuning constants (explicitly provisional, amended)

**Decision** (all values live as typed constants in `bedroom_controller.gd` / the five `.tres`
resources, not hardcoded inline, so they are one-place-to-tune):

| Constant | Proposed default | Source |
|---|---|---|
| Hope starting value | **50%** | **Sourced directly from the GDD** ("Início da partida: 50% de Esperança") — supersedes this research entry's original 100% guess, made before the GDD was found |
| Hope win/lose thresholds | 0% = Depression prevails; 100% (+ key available) = Resident endures | Sourced from the GDD |
| Dark Energy max / starting | 100 | Round baseline for percentage-like reasoning |
| Cost tier — Low (Curtains, Phone) | 10 | Strictly increasing per FR-004 |
| Cost tier — Medium (Basket) | 20 | Strictly increasing per FR-004 |
| Cost tier — High (Key) | 35 | Strictly increasing per FR-004 |
| Cost tier — Very High (Thoughts) | 50 | Strictly increasing per FR-004 |
| Hope gain/penalty per object | See R12's table | Gains proposed; Curtains/Thoughts penalties sourced |
| Energy regen rate | +5/second while below max | Full refill from empty in 20s — meaningful within a ~5 min session |
| Energy "critical" threshold | < 20 | Comfortably below the cheapest (Low=10) action's cost |
| **Attempt-window duration** (new — R11) | 6 seconds from intent selection to resolution | Long enough to read a thought bubble and react (supports SC-001's 60s discoverability without requiring twitch reflexes), short enough that a full session (R11's cycle) plays out several times within the 300s session length |
| **Inter-attempt idle pause** (new — R11) | 2 seconds between one intent resolving and the next being selected | Gives the resident's success/thwarted animation a moment to read before the next thought bubble appears |
| Session length (real time) | 300s (5 min) | Mid-point of SC-005's ≤10 min ceiling, leaving headroom |
| In-fiction clock mapping | 21:00 → 22:00 | Cosmetic only; anchors the design guide's visible "21:40" mockup state within the session |
| Resident idle-mood threshold | Hope < 50 → idle/walking-between-attempts trends sad; Hope < 20 → trends crying | Applies only to the resident's *between-attempts* idle animation (FR-011); `WALKING`/`REACHING` during an active attempt are intent-driven regardless of Hope, per R11's corrected behavior model |

**Rationale**: Every downstream artifact (data-model.md, tasks.md) needs *some* concrete number to
build and test against; spec.md's Assumptions explicitly deferred exact tuning to this phase. The
two new R11-driven constants (attempt-window, inter-attempt pause) exist because the corrected
tug-of-war mechanic didn't exist when this table was first written — a click-to-effect model had
no "window" to size.

**Alternatives considered**: Leaving these as open `[NEEDS CLARIFICATION]` — rejected: none of
these choices affect scope, security, or the shape of the UX (per spec.md's clarification-limiting
guidance) — they are balance numbers, changeable in minutes post-playtest without touching any
FR, node structure, or contract. The Hope starting value is the one exception that *was* sourced
rather than guessed, once the GDD was located.
