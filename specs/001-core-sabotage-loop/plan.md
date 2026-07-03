# Implementation Plan: Core Sabotage Loop

**Branch**: `001-core-sabotage-loop` | **Date**: 2026-07-02 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-core-sabotage-loop/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

**Amended 2026-07-02**: rewritten after the authoritative GDD (`gdd-sabotando-a-sanidade.html`) was
located and revealed the mechanic is a real-time tug-of-war, not a one-way drain. See spec.md's
Amendment note and research.md R11/R12 for the full correction.

A single fixed-camera bedroom scene where the resident (Morador) actively pursues one of five
Hope-raising intents at a time (curtains, phone, laundry, door key, calming thoughts), telegraphed
via a thought bubble, and the player (Depressão, represented only by a custom cursor — no player
avatar) must trigger that object's sabotage gesture before the attempt resolves, or the resident
succeeds and Hope rises toward 100% (a loss). Successfully sabotaging Curtains or Thoughts also
actively lowers Hope toward 0% (a win); sabotaging Phone or Laundry merely denies the resident's
gain. The door key's sabotage additionally blocks the 100%-Hope loss outright — the player's "final
defense." Every sabotage costs a regenerating Dark Energy resource. The technical approach is a
data-driven `InteractableDefinition` Resource per object consumed by one reusable
`InteractableObject` component (Principle I); a single scene-local controller
(`BedroomController`) owns all session state (Hope, Dark Energy, clock, resolution) and mediates
the entire Resident ↔ InteractableObject contest via signals, so the two never reference each other
directly (Principle III) — rather than a premature cross-scene Autoload. All text is delivered
through Godot's `TranslationServer`/CSV pipeline (Principle VII). Scope matches the GDD's stated
32-hour, 5-person game-jam budget: one scene, one resident, one session.

## Technical Context

**Language/Version**: GDScript, Godot 4.7 (per `project.godot` `config/features` and the
constitution's Technology Stack section)

**Primary Dependencies**: Godot 4 built-in nodes only — `Area2D`/`Control` for input detection,
`TextureProgressBar`/`ProgressBar` for Hope/Dark Energy bars, `Timer` for the day-cycle clock and
Dark Energy regeneration, `AnimatedSprite2D`/`AnimationPlayer` for resident and object states,
`Tween` for bubble/bar feedback. Dev-only addition: **GUT** (the constitution's designated GDScript
test framework), vendored under `res://addons/gut/`. No runtime third-party plugins.

**Storage**: N/A — this feature has no save/load requirement; every session resets to defined
starting values (FR-017), consistent with spec.md's single-session scope.

**Testing**: GUT unit tests for pure-logic systems with no render/physics dependency (Hope/Dark
Energy math, cost-tier ordering, win/lose resolution logic) per constitution Principle IV.
Everything render/animation/feel-dependent (thought-bubble timing, animation transitions, drag
gestures) is verified manually in the Godot editor via the Godot MCP tools (`run_project`,
`get_debug_output`, screenshots), also per Principle IV — GUT cannot and should not simulate mouse
drag-and-drop feel.

**Target Platform**: Desktop (Linux/Windows/macOS) is the primary development target, running on
the constitution-mandated GL Compatibility renderer. That renderer choice is also what Godot 4
requires for an HTML5/Web export — the GDD explicitly confirms "PC (Web/Desktop)" as the target, so
this is now a **confirmed** requirement, not the speculative note it was before research.md R8 was
amended.

**Project Type**: Single Godot game project (`res://`-rooted), per the constitution's Project
Layout — not a client/server or library split.

**Performance Goals**: Stable 60 FPS at the design guide's reference 1280×720 resolution on
integrated/low-end GPU hardware, consistent with the constitution's GL Compatibility / low-end
export rationale.

**Constraints**: Must fit the GDD's stated 32-hour, 5-person game-jam budget — this biases every
decision below toward built-in Godot nodes over custom frameworks and toward GUT coverage scoped
to high-value pure-logic only, not exhaustive test coverage. MUST satisfy constitution Principle V
(static typing, no exceptions) and Principle VII (pt-BR only, via translation keys, zero hardcoded
UI strings) non-negotiably regardless of time pressure. The GDD's own PO role is explicitly tasked
with preventing feature creep — a value this plan treats as binding, not just flavor (e.g.,
research.md R11 deliberately unifies all five objects under one resolution algorithm rather than
special-casing Curtains' "repeated click" framing).

**Scale/Scope**: 1 scene, 1 resident NPC with a 5-intent behavior cycle, 5 interactable objects, 2
resource bars, 1 session clock, 1 attempt-window timer, 2 terminal resolutions ("Depression
prevails" / "Resident endures", the latter with two distinct triggers) — matches spec.md's
Assumptions scope boundary exactly; no multi-room or multi-day scope.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| # | Principle | Status | Notes |
|---|-----------|--------|-------|
| I | Modular, Component-First Architecture | **PASS** | The 5 sabotage objects share one `InteractableObject` component parameterized by a per-object `InteractableDefinition` Resource (data-driven), instead of 5 hand-written scripts. Each component is instantiable/testable alone (a scene with just one `InteractableObject` + its `.tres`). |
| II | Scene & Node Hierarchy Discipline | **PASS** | Single scene, root `BedroomController` (`Node2D`) owns 5 `InteractableObject` (`Area2D`) children, 1 `Resident` (`CharacterBody2D`) child, 1 `HUD` (`CanvasLayer`/`Control`) child. Tree depth stays well under the ~4-level cap. No player `CharacterBody2D` exists — see note below. |
| III | Decoupled Communication via Signals | **PASS** | Every child (`InteractableObject`, `Resident`, both `Timer`s) emits signals upward; `BedroomController` is the sole listener/coordinator, and per research.md R11 it is also the sole mediator between `Resident` and `InteractableObject` — the two never reference each other directly, even though their behavior is now tightly coupled gameplay-wise. No cross-scene Autoload event bus is introduced yet — see research.md R7 for why that is a deliberate, compliant choice, not an oversight. |
| IV | Verify Before You Ship | **PASS** | GUT tests planned for Hope/Energy/resolution math (data-model.md), now covering the amended resolution check order (0%, 100%+key, clock-timeout); manual MCP-driven verification planned for feel-dependent systems (quickstart.md). |
| V | Strict GDScript Conventions & Static Typing (NON-NEGOTIABLE) | **PASS** | All new scripts/resources use typed fields and `class_name` declarations (data-model.md). Carried into tasks.md as a binding constraint on every implementation task. |
| VI | Predictable File Structure & Asset Naming | **PASS** | New folders below extend, and do not deviate from, the constitution's Project Layout (Project Structure section). The mechanic amendment changed field names and enum values, not file/folder structure. |
| VII | Localization-First: pt-BR Native (NON-NEGOTIABLE) | **PASS** | FR-018 requires pt-BR-only text; contracts/localization-keys.md enumerates every required key, updated for the amended intent set (adds `BUBBLE_THOUGHTS`), sourced from the Design Guide and GDD's own pt-BR copy where available. |

**Note on Principle II's node vocabulary**: the constitution's Technology Stack section lists
`CharacterBody2D` for "Actors (player, enemies, NPCs)". This feature's confirmed design (spec.md
Assumptions: "No player avatar movement") has no player-controlled body at all — the player acts
only through the OS/Godot cursor. `CharacterBody2D` is therefore used solely for the Morador
(resident), which *is* an NPC with movement. This is a scoping clarification, not a violation.

**No violations identified. Complexity Tracking table below is intentionally empty.**

**Post-Phase-1 re-check (after data-model.md / contracts/ / quickstart.md were drafted)**: still
**PASS** on all 7 principles — the concrete data model (research.md + data-model.md) confirmed the
data-driven-component and controller-owns-state design sketched above without introducing any new
Autoload, any inheritance chain, or any hardcoded pt-BR string. No Constitution Check status
changed between the pre-research and post-design passes.

**Post-amendment re-check (after the GDD-driven mechanic correction)**: still **PASS** on all 7
principles. The corrected tug-of-war mechanic added two new signals and a mediator role for
`BedroomController`, but did not introduce an Autoload, a lateral node reference, untyped fields,
or a hardcoded string — the architecture absorbed the mechanic change without a structural
violation, which is itself a mild validation that the original component/signal design (Principles
I-III) was sound independent of which exact mechanic it ended up implementing.

## Project Structure

### Documentation (this feature)

```text
specs/001-core-sabotage-loop/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md         # Phase 1 output (/speckit-plan command)
├── quickstart.md         # Phase 1 output (/speckit-plan command)
├── contracts/             # Phase 1 output (/speckit-plan command)
│   ├── signals.md
│   ├── interactable-definition-schema.md
│   └── localization-keys.md
└── tasks.md               # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
res://
├── levels/
│   └── bedroom/
│       ├── bedroom.tscn            # Root scene. Root node: BedroomController (Node2D).
│       │                           # Children include session_clock + attempt_timer (Timer)
│       └── bedroom_controller.gd   # Owns hope, dark_energy, clock, resolution state; mediates
│                                   # Resident <-> InteractableObject via intent_selected/
│                                   # intent_resolved (research.md R11)
├── entities/
│   └── resident/
│       ├── resident.tscn           # CharacterBody2D + AnimatedSprite2D + thought-bubble node +
│       │                           # pick_intent_timer (Timer)
│       ├── resident.gd             # Behavior state machine, intent telegraphing; no reference to
│       │                           # InteractableObject/InteractableDefinition (R11) beyond the
│       │                           # shared IntentType enum (defined in interactable_definition.gd)
│       └── resident_state.gd       # enum ResidentState { IDLE, WALKING, REACHING, SITTING_SAD, CRYING }
├── components/
│   └── interactable/
│       ├── interactable_object.tscn    # Area2D-based reusable sabotage-target component
│       ├── interactable_object.gd
│       └── interactable_definition.gd  # class_name InteractableDefinition extends Resource
│                                       # Also defines the shared IntentType enum (single source of
│                                       # truth — resident.gd references InteractableDefinition.
│                                       # IntentType rather than duplicating the enum)
├── resources/
│   └── interactables/
│       ├── curtains.tres
│       ├── phone.tres
│       ├── laundry_basket.tres
│       ├── door_key.tres
│       └── thoughts.tres
├── ui/
│   └── hud/
│       ├── hud.tscn                # CanvasLayer + Control: Hope bar, Energy bar, clock label
│       ├── hud.gd
│       ├── resource_bar.tscn       # Reusable bar component — both Hope and Energy instance this
│       ├── resource_bar.gd
│       ├── resolution_overlay.tscn # "Depression prevails" / "Resident endures" end screen
│       └── resolution_overlay.gd
├── localization/
│   └── strings.csv                 # pt-BR translation keys (see contracts/localization-keys.md)
└── addons/
    ├── godot_mcp/                   # existing
    └── gut/                         # new dev dependency for this feature (Principle IV)

tests/
└── unit/
    ├── test_interactable_definition.gd
    ├── test_bedroom_controller_hope_energy.gd
    └── test_bedroom_controller_resolution.gd
```

**Structure Decision**: Single-scene Godot project structure extending the constitution's Project
Layout with concrete paths for this feature. Two intentional deltas from the constitution's
illustrative list, both explained in research.md:

1. **No `autoloads/` folder is created by this feature.** research.md R7 documents why: the MVP is
   genuinely single-scene, and Principle III reserves Autoloads for "genuine cross-scene" needs.
   Introducing an `EventBus`/`GameState` Autoload now would be speculative complexity ahead of
   need. The moment a second scene (e.g., a main menu) is added, that is the trigger to introduce
   one — not before.
2. **`tests/unit/` is added at the repository root**, matching GUT's own convention (configurable
   via `.gutconfig.json`), since the constitution mandates automated tests (Principle IV) but its
   illustrative Project Layout predates any concrete test-framework placement decision.

## Complexity Tracking

> No Constitution Check violations were identified (see table above). This table is intentionally
> left empty — there is nothing to justify.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|---------------------------------------|
| — | — | — |
