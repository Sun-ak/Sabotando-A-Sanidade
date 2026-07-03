---
description: "Task list for Core Sabotage Loop implementation"
---

# Tasks: Core Sabotage Loop

**Input**: Design documents from `/specs/001-core-sabotage-loop/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md,
data-model.md, contracts/, quickstart.md — all present, all amended for the corrected tug-of-war
mechanic, and read in full.

**Amendment note**: this task list was regenerated after spec.md/plan.md/research.md/
data-model.md/contracts/quickstart.md were corrected to match the authoritative GDD's real-time
tug-of-war (research.md R11/R12), replacing the original one-way-drain design. Task count grew from
39 to 44 — mainly because the corrected mechanic requires a minimal `Resident` intent-picker to
exist before User Story 1's contest is even testable (moved into Foundational, below), and because
the resolution algorithm itself (sabotage sets a flag; a timer later checks it) is a genuinely new
piece of logic that didn't exist in the old click-to-effect design.

**Tests**: Included, scoped narrowly. The project constitution's Principle IV mandates automated
GUT tests for pure-logic systems (no render/physics dependency) and manual verification for
everything feel-dependent. This list implements three specific GUT files — no more. Animation,
drag-feel, and thought-bubble timing are deliberately **not** unit-tested; they're covered by the
manual quickstart.md walkthrough in the Polish phase instead.

**Organization**: Tasks are grouped by user story (spec.md's US1/US2/US3, priority order) so each
story is independently demonstrable, per spec.md's own Independent Test criteria. One honest
caveat carried over from the amendment: User Story 1's "independent" test requires a *minimal*
Resident to exist (it picks intents; User Story 1 is literally the contest over those intents) —
that minimal piece lives in Foundational, below, precisely so User Story 1 doesn't have to
build it itself. User Story 2 then *enriches* that same Resident (real animations, real thought
bubbles) rather than creating it from scratch.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: US1, US2, or US3 — omitted for Setup, Foundational, and Polish tasks
- Every task names its exact file path(s)

## Path Conventions (Godot `res://`-rooted project, per plan.md's Project Structure)

- Scenes/scripts: `levels/`, `entities/`, `components/`, `ui/`, `resources/`, `localization/`,
  `addons/` (all under the repository root, i.e. `res://`)
- Tests: `tests/unit/` (GUT convention, per plan.md's Structure Decision)
- No `autoloads/` folder — deliberately not introduced by this feature (research.md R7)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project scaffolding all later phases write into. Unchanged by the mechanic amendment.

- [X] T001 Create folder skeleton `levels/bedroom/`, `entities/resident/`, `components/interactable/`, `resources/interactables/`, `ui/hud/`, `localization/`, `tests/unit/` per plan.md's Project Structure
- [X] T002 [P] Install the GUT addon into `addons/gut/`, enable it under Project Settings → Plugins, and add `.gutconfig.json` at the repo root pointing its test dir at `res://tests/unit` (constitution Principle IV, research.md Testing) — vendored GUT v9.7.0 from upstream
- [X] T003 [P] Create `localization/strings.csv` (columns `keys,pt_BR`) seeded with every Required row from `specs/001-core-sabotage-loop/contracts/localization-keys.md` (now including `BUBBLE_THOUGHTS`), and register it under Project Settings → Localization → Translations
- [X] T004 [P] Set the project's base viewport to 1280×720 in Project Settings → Display → Window (design guide reference resolution), confirming `project.godot`'s GL Compatibility renderer and `canvas_items` stretch mode remain unchanged

**Checkpoint**: Folders, test runner, localization file, and window size exist. Nothing playable
yet.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The shared data class, node skeletons, and scene wiring every user story builds on —
**including a minimal, non-animated `Resident` intent-picker**, since the corrected mechanic's
contest cannot be tested without something picking intents to contest.

**⚠️ CRITICAL**: No user story task can start until this phase is complete.

- [X] T005 Create `InteractableDefinition` (`class_name InteractableDefinition extends Resource`) in `components/interactable/interactable_definition.gd` with all typed fields (`id`, `intent`, `display_name_key`, `gesture`, `hope_gain_on_success`, `hope_penalty_on_sabotage`, `energy_cost_tier`, `sabotaged_state_key`, `blocks_door_resolution`) and the `GestureType`/`CostTier`/**`IntentType`** enums (this file is `IntentType`'s single source of truth — `resident_state.gd` references it, does not redeclare it), per data-model.md — also added `default_state_key`, a small gap caught during implementation (see data-model.md's amendment note)
- [X] T006 [P] Write `tests/unit/test_interactable_definition.gd` (GUT) asserting the five cross-check rules from `contracts/interactable-definition-schema.md` (strictly-increasing tier costs; exactly one `blocks_door_resolution` row; `hope_penalty_on_sabotage == 0` except Curtains/Thoughts; `hope_gain_on_success > 0` for all five; the five `intent` values form a complete `{CURTAINS,PHONE,LAUNDRY,DOOR_KEY,THOUGHTS}` set) — expected to fail until T007
- [X] T007 [P] Populate the five `.tres` files in `resources/interactables/` (`curtains.tres`, `phone.tres`, `laundry_basket.tres`, `door_key.tres`, `thoughts.tres`) with the exact field values from `contracts/interactable-definition-schema.md`'s table — makes T006 pass
- [X] T008 [P] Create the `InteractableObject` component skeleton (`class_name InteractableObject extends Area2D`) in `components/interactable/interactable_object.tscn` + `components/interactable/interactable_object.gd`: `CollisionShape2D` + `AnimatedSprite2D` placeholder children, `@export var definition: InteractableDefinition`, `is_sabotaged: bool`, and the `sabotage_attempted`/`state_changed` signal declarations from `contracts/signals.md` (no gesture-detection body yet — that's US1) — used a `Polygon2D` placeholder instead of `AnimatedSprite2D` since no art exists (tasks.md Placeholder art note); gesture detection (T013/T014) implemented alongside since it's the same file
- [X] T009 [P] Create the `BedroomController` skeleton (`class_name BedroomController extends Node2D`) in `levels/bedroom/bedroom_controller.gd`: typed `hope`/`dark_energy`/`energy_state`/`resolution` fields, `interactables_by_intent: Dictionary` field, the `hope_changed`/`energy_changed`/`intent_resolved`/`session_resolved` signal declarations from `contracts/signals.md`, and the tier→cost constant map from research.md R10 (LOW=10, MEDIUM=20, HIGH=35, VERY_HIGH=50) — no behavior methods yet — full resolution logic (T015-T018, T020, T031-T035) implemented alongside in the same file; see the ordering-bug note in the file's own comments (resolution must be evaluated before the resolving object's sabotage flag is reset, caught during review)
- [X] T010 [P] Create the **minimal** `Resident` skeleton (`class_name Resident extends CharacterBody2D`) in `entities/resident/resident.tscn` + `entities/resident/resident.gd`, plus `entities/resident/resident_state.gd` holding only the `ResidentState` enum (`IDLE`,`WALKING`,`REACHING`,`SITTING_SAD`,`CRYING`); include a single placeholder static visual (e.g., a plain `ColorRect` or one-frame `Sprite2D` — no animation, no thought-bubble UI yet, both are US2), a `pick_intent_timer: Timer` child (`wait_time` = research.md R10's 2.0s inter-attempt pause, starts on `_ready()`), a `current_intent: InteractableDefinition.IntentType?` field, and the `intent_selected(intent)` signal from `contracts/signals.md`. On `pick_intent_timer.timeout`, pick a weighted-random `IntentType` and emit `intent_selected` — this is the entire behavior for this task; no animation or bubble logic — implemented complete through US2 (T025-T029) in the same pass since it's one script; used `Polygon2D` instead of `AnimatedSprite2D`, no real movement (cosmetic state only, see file header comment)
- [X] T011 Create `levels/bedroom/bedroom.tscn`: root `BedroomController` running `bedroom_controller.gd`; 5 child `InteractableObject` instances, each with `definition` assigned to its matching `.tres` from T007; the `Resident` instance from T010 (already usable, not a placeholder slot); placeholder empty child slots named `HUD` and `ResolutionOverlay` (populated in later phases); a `session_clock` `Timer` child (`wait_time = 300.0`, `one_shot = true`) and an `attempt_timer` `Timer` child (`wait_time = 6.0`, `one_shot = true`, per research.md R10) — depends on T007, T008, T009, T010 — verified loading with zero parser/resource errors via `run_project`/`get_debug_output` after two real issues surfaced and were fixed: the global script class cache and the CSV→Translation import both needed the editor to actually scan the project (triggered via a `--headless --editor --quit` pass), and `project.godot`'s `locale/translations` needed to point at the generated `.translation` file, not the source `.csv`

**Checkpoint**: `bedroom.tscn` opens in the editor and shows five (inert) objects plus a
placeholder resident that silently emits `intent_selected` on a timer with nothing listening yet.
No visible behavior — that begins with User Story 1.

---

## Phase 3: User Story 1 - Contest the Resident's Actions to Control Hope (Priority: P1) 🎯 MVP

**Goal**: The resident's telegraphed intents resolve correctly against player sabotage: an
unsabotaged intent raises Hope by the object's defined amount; a sabotaged Curtains/Thoughts
intent lowers Hope; a sabotaged Phone/Laundry/Door Key intent denies the gain with no extra
penalty. Dark Energy is spent, refused-when-unaffordable, and regenerates.

**Independent Test**: quickstart.md §2 (7 conditional steps, since the resident's intent order is
random) — run from a fresh scene load.

### Tests for User Story 1

- [X] T012 [P] [US1] Write `tests/unit/test_bedroom_controller_hope_energy.gd` (GUT) covering FR-002–FR-009: driving `BedroomController`'s resolution method directly (stubbing the target `InteractableObject`'s `is_sabotaged`) to assert the correct `hope_gain_on_success` / `hope_penalty_on_sabotage` / deny-only branch per object; an unaffordable sabotage gesture changes neither `is_sabotaged` nor Dark Energy; Dark Energy regenerates over simulated time — expected to fail until T015–T018

### Implementation for User Story 1

- [X] T013 [US1] Implement gesture detection in `components/interactable/interactable_object.gd` (`Area2D.input_event`, research.md R1): repeated-click for Curtains, single-click for Laundry/Thoughts, press+motion+release drag for Phone/Key; emit `sabotage_attempted(definition)` on a completed gesture
- [X] T014 [US1] Implement the `state_changed` visual reaction in `components/interactable/interactable_object.gd` (same file, after T013): swap the `AnimatedSprite2D` frame/animation to match `current_state` — FR-010 — implemented as a color swap on the `Polygon2D` placeholder (default vs. sabotaged color), not a real sprite animation (no art)
- [X] T015 [US1] Implement `BedroomController`'s `sabotage_attempted` handler in `levels/bedroom/bedroom_controller.gd`: ignore if `resolution != NONE`; refuse with no state change if `dark_energy` is below the tier cost (FR-005); otherwise deduct cost, set `is_sabotaged = true` and `current_state = definition.sabotaged_state_key` on the emitting object, emit `energy_changed`. **Does not touch `hope`** — that only happens at attempt resolution (T017)
- [X] T016 [US1] Implement `BedroomController`'s `intent_selected` handler in `levels/bedroom/bedroom_controller.gd` (same file, after T015): populate `interactables_by_intent` from the 5 children in `_ready()` if not already done; on the signal, look up the target `InteractableObject` and restart `attempt_timer` (research.md R11 step 2)
- [X] T017 [US1] Implement `BedroomController`'s `attempt_timer.timeout` resolution handler in `levels/bedroom/bedroom_controller.gd` (same file, after T016): read the current target's `is_sabotaged`; apply `hope -= definition.hope_penalty_on_sabotage` if sabotaged, else `hope += definition.hope_gain_on_success`; clamp `hope` to `[0,100]`; reset the target's `is_sabotaged = false` and `current_state` to default; emit `hope_changed`, then `intent_resolved(intent, succeeded)` — FR-007, FR-008, FR-009, research.md R11 step 4 — resolution evaluation (T031-T033) is interleaved before the flag reset, not after; see the file's ordering-bug comment
- [X] T018 [US1] Implement passive Dark Energy regeneration and `energy_state` derivation in `levels/bedroom/bedroom_controller.gd` (same file, after T017): a repeating regen `Timer`-driven +5/second while `dark_energy < 100` and `resolution == NONE`; READY at max, CRITICAL below 20, else RECHARGING — FR-006
- [X] T019 [US1] Implement `Resident`'s minimal `intent_resolved` listener in `entities/resident/resident.gd` (extends T010's file): on receipt, clear `current_intent` and restart `pick_intent_timer` — this is what keeps the contest cycling; no animation/bubble reaction yet (US2) — implemented as the full `on_intent_resolved()` including US2's reaction/bubble logic (T028/T029) in the same pass
- [X] T020 [US1] Implement `BedroomController._ready()` in `levels/bedroom/bedroom_controller.gd` (same file, after T018): `Input.set_custom_mouse_cursor()` with the "Depressão" cursor texture (research.md R6); reset `hope = 50.0`, `dark_energy = 100.0`, `session_clock`, and every `InteractableObject`'s `current_state`/`is_sabotaged` to starting values — FR-019 — cursor uses a small procedurally-built placeholder `ImageTexture` (no art asset exists yet)
- [X] T021 [US1] In `levels/bedroom/bedroom.tscn`, connect all 5 `InteractableObject.sabotage_attempted` signals and the `Resident.intent_selected` signal to `BedroomController`'s handlers — depends on T013, T015, T016, T010 — implemented as code-based connections in `bedroom_controller.gd`'s `_ready()` (looping over children / connecting to `resident`) rather than `.tscn`-file `[connection]` blocks; equivalent and easier to review as a diff
- [X] T022 [P] [US1] Build the reusable `ResourceBar` component (`class_name ResourceBar extends Control`) in `ui/hud/resource_bar.tscn` + `ui/hud/resource_bar.gd`: `label_key`/`current_value`/`max_value` per data-model.md, rendered via `TextureProgressBar` (research.md R9) — `texture_under`/`texture_progress` are small procedural placeholder textures (no art); label shows "translated name: current/max" so affordability is readable without a separate indicator
- [X] T023 [US1] Build `ui/hud/hud.tscn` + `ui/hud/hud.gd`: a `CanvasLayer` instancing two `ResourceBar`s (Hope: `UI_HOPE_LABEL`; Energy: `UI_ENERGY_LABEL`) connected to `BedroomController.hope_changed`/`energy_changed`, plus a per-object affordability indicator (SC-006) — depends on T022 — affordability satisfied via each bar's numeric readout rather than a separate per-object indicator (kept simple, no new hardcoded/untranslated strings needed)
- [X] T024 [US1] Add the `HUD` instance into `levels/bedroom/bedroom.tscn`'s `HUD` placeholder slot and wire its `BedroomController` signal connections — depends on T023, T009

**Checkpoint**: quickstart.md §2 passes end-to-end; `test_bedroom_controller_hope_energy.gd` is
green. The full contest is playable and numerically correct — the resident is a static placeholder
shape with no animation or visible thought bubble yet (that's User Story 2), and there is no
win/lose ending yet (that's User Story 3).

---

## Phase 4: User Story 2 - Resident Reacts to the Sabotaged Room (Priority: P2)

**Goal**: The placeholder resident from Foundational/User Story 1 gets real animations
(idle/walking/reaching/sad/crying), a real thought bubble showing its telegraphed intent, and a
distinct reaction when thwarted — turning the already-working numeric contest into a legible,
characterful one.

**Independent Test**: quickstart.md §3, driving Hope via User Story 1's already-working contest.

### Implementation for User Story 2

- [X] T025 [US2] Replace the placeholder visual in `entities/resident/resident.tscn` with a real `AnimatedSprite2D` carrying idle/walking/reaching/sitting-sad/crying animation states (asset dependency — see Polish note on placeholder art if final sprites aren't ready); extend `entities/resident/resident_state.gd`'s `ResidentState` usage in `entities/resident/resident.gd` to actually switch animations — no art exists, so `_set_state()` swaps a `Polygon2D` placeholder's color per state instead of a real `AnimatedSprite2D`; all 5 states are distinguishable
- [X] T026 [US2] Wire `WALKING`/`REACHING` to the attempt lifecycle in `entities/resident/resident.gd` (same file, after T025): on `intent_selected`, transition to `WALKING` then (after a short fixed delay) `REACHING`, held until `intent_resolved` arrives — FR-011
- [X] T027 [US2] Wire the idle-mood bias in `entities/resident/resident.gd` (same file, after T026): while `IDLE` (between attempts), trend toward `SITTING_SAD` below Hope 50 and `CRYING` below Hope 20, using the last value from a `BedroomController.hope_changed` connection made by `BedroomController` — never `get_parent()` (Principle III) — per research.md R10's idle-mood threshold
- [X] T028 [US2] Build the visual thought-bubble display in `entities/resident/resident.tscn` + `entities/resident/resident.gd` (same file, after T027): a `Node2D` child showing the matching `BUBBLE_*` key (`contracts/localization-keys.md`) the instant `intent_selected` fires, for all five intents including `BUBBLE_THOUGHTS` — FR-001
- [X] T029 [US2] Implement the thwarted reaction in `entities/resident/resident.gd` (same file, after T028): on `intent_resolved(intent, succeeded=false)`, swap the bubble to `BUBBLE_SEARCHING` instead of clearing it normally, briefly, before the next `pick_intent_timer` cycle begins — FR-012

**Checkpoint**: quickstart.md §3 passes end-to-end, independent of whether User Story 3 exists yet.

---

## Phase 5: User Story 3 - The Day Resolves in Depression's Favor or the Resident's (Priority: P3)

**Goal**: The session resolves to "Depression prevails" (Hope=0%) or "Resident endures" (Hope=100%
with the key available, or the clock times out first), with the door key's 100%-hold failsafe
correctly honored.

**Independent Test**: quickstart.md §4 (three separate fresh-session runs: win path, baseline/
inaction path, key-failsafe path).

**Note**: T031–T035 extend `bedroom_controller.gd`'s resolution logic (built in T015–T020, User
Story 1) and T037 extends `hud.gd` (User Story 1's T023). Real same-file, cross-phase dependencies;
User Story 3 is independently *testable* per spec.md, but not independently *buildable* before
User Story 1's controller/HUD work lands.

### Tests for User Story 3

- [X] T030 [P] [US3] Write `tests/unit/test_bedroom_controller_resolution.gd` (GUT) covering the full resolution check order from data-model.md: `hope <= 0` resolves `DEPRESSION_PREVAILS` regardless of anything else and takes precedence; `hope >= 100` with the door key available resolves `RESIDENT_ENDURES` immediately; `hope >= 100` with the door key sabotaged holds with no resolution; clock timeout with `hope < 100` resolves `RESIDENT_ENDURES`; clock timeout with `hope` held at 100 by a sabotaged key also resolves `RESIDENT_ENDURES` — expected to fail until T031–T034 — also includes a regression test for the flag-reset-ordering bug caught during T017's implementation review

### Implementation for User Story 3

- [X] T031 [US3] In `levels/bedroom/bedroom_controller.gd`'s attempt-resolution method (extends T017), after applying the Hope change, add the `hope <= 0` precedence check: set `resolution = DEPRESSION_PREVAILS` and emit `session_resolved`, before any other check — FR-014
- [X] T032 [US3] In the same method (`levels/bedroom/bedroom_controller.gd`, after T031), add the `hope >= 100 AND interactables_by_intent[DOOR_KEY].is_sabotaged == false` check: set `resolution = RESIDENT_ENDURES` and emit `session_resolved` — FR-015
- [X] T033 [US3] In the same method (`levels/bedroom/bedroom_controller.gd`, after T032), add the explicit hold branch for `hope >= 100 AND` the door key **is** sabotaged: clamp `hope` at 100, do not resolve, let the next relevant check re-evaluate later — FR-016
- [X] T034 [US3] Implement the `session_clock.timeout` handler in `levels/bedroom/bedroom_controller.gd` (same file, after T033): if `resolution == NONE`, set `resolution = RESIDENT_ENDURES` and emit `session_resolved` regardless of whether `hope` is currently held at 100 by a sabotaged key or sitting below it — FR-017
- [X] T035 [US3] Implement the post-resolution lockout in `levels/bedroom/bedroom_controller.gd` (same file, after T034): once `resolution != NONE`, the `sabotage_attempted` handler, the `intent_selected` handler, and the energy-regen timer all become no-ops, per `contracts/signals.md`
- [X] T036 [P] [US3] Build `ui/hud/resolution_overlay.tscn` + `ui/hud/resolution_overlay.gd`: on `BedroomController.session_resolved`, display `RES_DEPRESSION_PREVAILS_TITLE` or `RES_RESIDENT_ENDURES_TITLE` depending on which resolution fired, and block further scene input — actual input-blocking lives in BedroomController (T035, a robust code-level guarantee); this overlay is presentation-only, see its file header comment for why
- [X] T037 [US3] Add the cosmetic HH:MM clock label to `ui/hud/hud.tscn` + `ui/hud/hud.gd` (extends T023/T024), mapping `session_clock`'s elapsed/remaining time onto the 21:00→22:00 in-fiction range from research.md R10 — FR-013 — driven by a new `BedroomController._process()` per research.md R3 (day-end logic itself stays signal-driven; only this cosmetic label polls)
- [X] T038 [US3] Add the `ResolutionOverlay` instance into `levels/bedroom/bedroom.tscn`'s `ResolutionOverlay` placeholder slot and connect `session_resolved` — depends on T036, T035

**Checkpoint**: quickstart.md §4 passes end-to-end. All three of spec.md's user stories are
complete — this is the full playable MVP loop.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Verification and content follow-ups spanning all three stories.

- [X] T039 [P] Cross-check every `tr("...")` call site added in T013–T038 against `localization/strings.csv`; confirm zero missing keys (including `BUBBLE_THOUGHTS` and the renamed `BUBBLE_CURTAINS`/`BUBBLE_PHONE`/`BUBBLE_LAUNDRY`/`BUBBLE_DOOR_KEY`) and run quickstart.md §5's locale spot-check — SC-004 — verified via a full grep cross-check (code→CSV and CSV→code, both directions clean) rather than the locale spot-check, which needs a human running the editor with a non-pt-BR locale set; that part is still open
- [ ] T040 Run the full quickstart.md manual walkthrough (§2–§6) via the Godot MCP tools (`run_project`, `get_debug_output`, screenshots), recording pass/fail per numbered step, per constitution Principle IV — pay particular attention to §4's key-failsafe path, whose flag-consumption subtlety is easy to get wrong — **partially done**: verified clean load + multi-minute error-free runtime via `run_project`/`get_debug_output`, and the underlying logic via the GUT suites (T041); the exact click/drag steps in §2-§4 need a human at the keyboard, since no exposed MCP tool injects synthetic mouse input
- [X] T041 [P] Run all three GUT suites (`test_interactable_definition.gd`, `test_bedroom_controller_hope_energy.gd`, `test_bedroom_controller_resolution.gd`) together in `tests/unit/` and confirm all green — 22/22 tests, 54 assertions, 0 failures (`godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`)
- [ ] T042 Time a complete fresh playthrough from session start to any resolution; confirm it finishes in ≤10 minutes, and separately note the baseline/inaction path's much shorter typical duration — SC-005, quickstart.md §6 — needs a human playthrough; not measurable without real input
- [X] T043 [P] Review every script touched in T005–T038 against constitution Principles V and VI: static typing on all fields/params/returns/signals, `class_name` on reusable types, correct naming conventions, zero fragile `get_node("../..")`-style traversal, and confirm `Resident`/`InteractableObject` never reference each other directly (research.md R11) — verified via grep: zero `get_node("../..")` / `get_parent()` calls in feature code, zero untyped `var` declarations, and `InteractableObject` has no reference to `Resident`/`BedroomController` at all (only `InteractableDefinition`'s shared enum, which is the designed exception)
- [ ] T044 Replace the placeholder pt-BR copy for `RES_DEPRESSION_PREVAILS_TITLE`, `RES_RESIDENT_ENDURES_TITLE`, and the four proposed `BUBBLE_*` bubble strings in `localization/strings.csv` with final narrative text — needs the game's writer/designer's judgment on tone, not an automated rewrite — **intentionally left for the user**, per this task's own instruction

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (T001–T004)**: No dependencies — start immediately. T002–T004 are `[P]`; T001 implicitly
  precedes them.
- **Foundational (T005–T011)**: Depends on Setup. **Blocks all user stories.** T006–T010
  parallelize once T005 lands; T011 is the sequential integration point needing T007+T008+T009+T010.
  Foundational now includes a functioning (if unanimated) `Resident` intent-picker — a deliberate
  amendment consequence, not scope creep: User Story 1 cannot be tested without it.
- **User Story 1 (T012–T024)**: Depends on Foundational only. This is the MVP slice — the numeric
  contest is fully correct and testable even though the resident looks like a placeholder shape.
- **User Story 2 (T025–T029)**: Depends on Foundational **and** functionally on User Story 1's
  `intent_resolved`/`hope_changed` signals actually firing correctly to have something to react to,
  though it can be *coded* against Foundational's skeleton alone and manually driven for testing
  per spec.md's Independent Test note.
- **User Story 3 (T030–T038)**: Depends on Foundational for structure, but T031–T035 literally
  extend `bedroom_controller.gd`'s resolution method built in User Story 1 (T015–T020), and T037
  extends `hud.gd` from User Story 1 (T023). **Implement User Story 1 first in practice.**
- **Polish (T039–T044)**: Depends on whichever of User Story 1/2/3 have been implemented.

### Parallel Opportunities

- Setup: T002, T003, T004 together (after T001).
- Foundational: T006, T007, T008, T009, T010 together (after T005).
- User Story 1: T012 (test) and T022 (ResourceBar) can run alongside the T013→T021
  `bedroom_controller.gd`/`interactable_object.gd`/`resident.gd` chain — different files.
- User Story 3: T030 (test) and T036 (ResolutionOverlay) can run alongside the T031→T035
  `bedroom_controller.gd` chain.
- Polish: T039, T041, T043 together; T040, T042, T044 are sequential/manual.

---

## Parallel Example: Foundational Phase

```bash
# After T005 (InteractableDefinition class + IntentType enum) lands, run together:
Task: "Write tests/unit/test_interactable_definition.gd"
Task: "Populate resources/interactables/*.tres (5 files)"
Task: "Create components/interactable/interactable_object.tscn + .gd skeleton"
Task: "Create levels/bedroom/bedroom_controller.gd skeleton"
Task: "Create entities/resident/resident.tscn + .gd minimal intent-picker skeleton"
```

## Parallel Example: User Story 1

```bash
# Once Foundational is done, these can start together:
Task: "Write tests/unit/test_bedroom_controller_hope_energy.gd"
Task: "Build ui/hud/resource_bar.tscn + resource_bar.gd"
# ...while the sequential chain (gesture detection -> sabotage handler -> intent_selected handler
# -> attempt resolution -> regen -> resident's minimal cycle-keeper -> ready/reset) proceeds
# separately in interactable_object.gd / bedroom_controller.gd / resident.gd
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (blocks everything else; now includes the minimal Resident)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: run quickstart.md §2 and `test_bedroom_controller_hope_energy.gd`
5. This is a demonstrable, numerically-correct tug-of-war — no animation, no ending, but the real
   contest (resident tries, player sabotages or doesn't, Hope moves accordingly) is playable

### Incremental Delivery

1. Setup + Foundational → scene skeleton exists, resident silently cycles through intents with
   nothing reacting yet
2. User Story 1 → the contest itself is playable and numerically correct (MVP)
3. User Story 2 → the resident feels alive (idle/walk/reach/sad/cry, real thought bubbles)
4. User Story 3 → the game has a beginning and an end (win/lose resolution, key failsafe)
5. Polish → verified, localized, tuned

### Jam-Timebox Note

spec.md's priority order is P1 (User Story 1) > P2 (User Story 2) > P3 (User Story 3), and the
phases above follow that order. Worth flagging for your own time-boxing given the GDD's 32-hour,
5-person budget: if time runs short, **User Story 3 (T030–T038) closes the loop into a complete,
winnable/losable game** even with a minimal (unanimated) resident, whereas skipping it leaves a
numerically-correct but endless contest with no ending regardless of how polished User Story 2's
animations are. This is not a reordering of the tasks above — spec.md's stated priorities stand —
just a data point for a real go/no-go call under time pressure, echoing the GDD's own PO role
("foco em não deixar a equipe adicionar mecânicas extras").

### Placeholder art note — SUPERSEDED (2026-07-03 asset integration)

~~No sprite/audio assets exist in this repository as of this task list~~ **Real art now exists
and is fully integrated** (second `/speckit-implement` pass, 2026-07-03). What changed:

- `sprites/` (raw source art: S Frisk "Midnight Lilac" 32px tileset + a padded gameplay sprite
  sheet) was added by the user; clean sprites were extracted into `assets/sprites/`,
  `assets/tileset/`, and `entities/resident/sprites/` (the padded slices were grid-misaligned, so
  extraction used alpha connected-component analysis; see `assets/CREDITS.md` for license). The
  raw `sprites/` folder carries a `.gdignore` so Godot only imports the curated copies.
- The room is now a real **TileMapLayer** map (`FloorLayer` + `WallLayer` in `bedroom.tscn`,
  backed by `levels/bedroom/bedroom_tileset.tres`, 32px tiles at 2x scale) plus static furniture
  Sprite2Ds (bed, nightstand, dresser, door, rug, poster, wall clock) and repositioned
  interactables (window/curtains + key on the wall, phone on the nightstand, laundry on the
  floor, thoughts bubble over the rug).
- T008/T014: `InteractableObject`'s `Polygon2D` color-swap placeholder became a `Sprite2D`
  texture swap driven by two new `InteractableDefinition` fields (`default_texture` /
  `sabotaged_texture`, set in all five `.tres`).
- T025/T026: the resident's `Polygon2D` became an `AnimatedSprite2D` with real
  idle/walking/reaching/sitting_sad/crying animations, and WALKING is now **actual movement**:
  `BedroomController._on_intent_selected` mediates a `resident.walk_to(stand_spot)` call
  (research.md R11 — the controller remains the only party knowing both sides), with the old
  timer kept as a fallback so headless logic tests still pass.
- T020: the placeholder cursor became the extracted purple-bolt sprite
  (`assets/sprites/ui/cursor_bolt.png`).
- T022: `ResourceBar` gained `under_texture`/`progress_texture` exports (nine-patch pill bars
  from the sprite set); the procedural fill remains as fallback.
- `project.godot`: `run/main_scene` set (game is runnable standalone), nearest-neighbor default
  texture filter, dark-purple clear color.
- Verified: full GUT suite 22/22 (54 asserts) green after integration; game runs error-free with
  the tilemap, animations, movement, pt-BR bubbles, and HUD confirmed via in-engine screenshots.

**Follow-up user-requested enhancements (2026-07-03, same session)**:

- **Sabotage state now reverts at every attempt resolution**: `_on_attempt_timer_timeout` resets
  ALL interactables (not just the resolved target) after `_evaluate_resolution()` reads the flags,
  so no object stays stuck in its sabotaged sprite when the resident shifts focus. Consequence:
  holding the key at 100% Hope requires actively re-sabotaging it each attempt (FR-016's hold
  still verified by the untouched T030 tests, which pass unchanged).
- **Door key**: now the user-supplied 24-frame spinning sheet
  (`assets/sprites/interactables/key_32x32_24f.png` + generated darkened `_hidden` variant),
  placed floating above the dresser; `InteractableDefinition` gained `texture_frame_count`/
  `texture_frames_per_second` and `InteractableObject` animates `hframes` strips.
- **Audio**: `InteractableDefinition.sabotage_sound` per object (curtains/phone/laundry/thoughts
  MP3s from `sound_effects/`), played by the component on accepted sabotage; looping background
  music (`game_song.mp3`) via a `Music` player started in `_reset_session`.
- **Play Again**: `ResolutionOverlay` gained a `UI_PLAY_AGAIN` ("Jogar novamente") button that
  `reload_current_scene()`s back to a fresh session; key added to `strings.csv` and the
  localization contract. Full flow (resolve → button → reload) verified with in-engine
  screenshots.

## Notes

- `[P]` tasks touch different files and have no incomplete-task dependency.
- Every `bedroom_controller.gd` / `interactable_object.gd` / `resident.gd` / `hud.gd` edit across
  phases is sequential with every other edit to that same file, even across user-story boundaries —
  noted explicitly wherever it occurs above.
- Per constitution Principle IV, T006/T012/T030 (the three GUT test tasks) are meant to be run and
  observed **failing** before their corresponding implementation tasks, and passing after.
- `Resident` and `InteractableObject` must never gain a direct reference to each other at any point
  across T010–T038 — if a task seems to need one, re-read research.md R11; the mediation belongs in
  `BedroomController`.
- Commit after each task or logical group, per constitution Development Workflow guidance.
- Stop at any Checkpoint to manually validate that story via the matching quickstart.md section
  before continuing.
