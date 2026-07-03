<!--
Sync Impact Report — Constitution Update
Version change: (none, template) → 1.0.0 (initial ratification)
Modified principles: N/A (initial adoption — no prior filled constitution existed)
Added principles:
  - I. Modular, Component-First Architecture
  - II. Scene & Node Hierarchy Discipline
  - III. Decoupled Communication via Signals
  - IV. Verify Before You Ship
  - V. Strict GDScript Conventions & Static Typing (NON-NEGOTIABLE)
  - VI. Predictable File Structure & Asset Naming
  - VII. Localization-First: pt-BR Native (NON-NEGOTIABLE)
Added sections:
  - Technology Stack & Environment Constraints
  - Development Workflow & Quality Gates
  - Governance
Removed sections: none
Templates reviewed for consistency:
  - .specify/templates/plan-template.md      ✅ compatible — generic Constitution Check gate, no edits required
  - .specify/templates/spec-template.md      ✅ compatible — no constitution-specific references
  - .specify/templates/tasks-template.md     ✅ compatible — generic task categories, no constitution-specific references
  - .specify/templates/checklist-template.md ✅ compatible — generic, not principle-coupled
  - .specify/templates/commands/*.md         — N/A, directory does not exist in this installation
  - README.md / docs/quickstart.md           — N/A, do not exist yet in this repository
Deferred placeholders / TODOs: none — all template tokens resolved from user-supplied project
  context (title, engine, tooling, localization) and repository inspection (project.godot).
-->

# Sabotando a Sanidade Constitution

## Core Principles

### I. Modular, Component-First Architecture
Every gameplay capability (movement, health, interaction, sanity/madness effects, inventory,
AI perception, etc.) MUST be built as a self-contained component: a script and/or scene with a
single responsibility that does not assume the identity, name, or tree position of its parent or
siblings beyond its own documented `@export` fields. Composition MUST be preferred over deep
class-inheritance chains — build entities by attaching small reusable components (e.g.,
`HealthComponent`, `HitboxComponent`, `SanityComponent`, `InteractableComponent`) rather than
subclassing a monolithic `Player`/`Entity` base class per feature. A component MUST be
runnable/instantiable in isolation (a minimal test scene containing only that component) to prove
it has no hidden coupling.
**Rationale**: Top-down action/horror mechanics evolve fast during prototyping (new enemies, new
sanity effects, new interactions); "God scripts" that mix movement, combat, UI, and state make
that iteration slow and risky. Components keep each concern swappable and independently
verifiable.

### II. Scene & Node Hierarchy Discipline
Every scene MUST have one clear responsibility and a root node type matching its purpose
(`CharacterBody2D` for actors, `Node2D` for logical/organizational groupings, `Control` for UI).
Shared behavior MUST be built once as a reusable sub-scene and instanced elsewhere — never
copy-pasted across multiple `.tscn` files. Logic-bearing node trees MUST stay shallow (a scene
needing more than ~4 nested levels of custom logic MUST extract a sub-scene). Cross-node
references MUST use typed `@export` node references or the `%UniqueName` scene-unique-node
syntax; long relative traversals such as `get_node("../../Foo/Bar")` MUST NOT be used.
**Rationale**: Shallow, ownership-clear trees survive refactors. Fragile relative paths and
copy-pasted scenes are the most common source of silent runtime null-reference errors as a Godot
project grows past its prototype stage.

### III. Decoupled Communication via Signals
Nodes MUST communicate outward via Godot signals, not by reaching into parents or siblings
through `get_parent()`/`get_node()` calls. A parent MAY call methods directly on children it owns
and instanced; a child MUST NOT assume anything about its parent's type or API — it emits a
signal and lets listeners react. Global, cross-scene events (player death, sanity-threshold
crossed, chapter/objective completed, save requested) MUST be routed through a single Autoload
event-bus singleton rather than scattered direct calls between unrelated Autoloads and nodes.
Autoloads MUST be reserved for genuine cross-scene services and state (event bus, game/save
state, audio bus manager, localization/settings service) — gameplay rules MUST NOT be implemented
inside an Autoload.
**Rationale**: Signal-based decoupling is what lets new enemies, rooms, and sanity mechanics be
added without editing unrelated scripts, and keeps Autoloads from becoming a second,
undisciplined global-state codebase.

### IV. Verify Before You Ship
A task is not complete when the code parses or the type checker is silent — it is complete when
it has been run and observed. Every feature or fix MUST be executed in the Godot editor or an
exported build (via the Godot MCP tooling: `run_project`, `get_debug_output`, screenshots) and
confirmed to behave as intended before being marked done. Pure-logic code with no dependency on
the render/physics loop (inventory math, save/load, dialogue and state machines, sanity-meter
calculations, RNG-driven systems) MUST have automated GDScript unit tests (using GUT, this
project's designated test framework) that fail before the change and pass after. Where an
automated test is impractical (animation timing, physics feel, AI behavior tuning), the change
MUST instead carry a documented manual repro-and-verify step.
**Rationale**: Game-feel bugs hide behind a clean static-analysis pass. Treating "run it and look
at it" as a mandatory gate — not an optional nicety — catches the class of bugs that only appear
once the scene tree, physics, and input are actually live.

### V. Strict GDScript Conventions & Static Typing (NON-NEGOTIABLE)
All GDScript MUST use static typing for variables, parameters, return types, and signal arguments
(`var hp: int = 100`, `func take_damage(amount: int) -> void:`, `signal health_changed(new_value:
int)`); an untyped `Variant` requires an inline comment explaining why typing was not possible.
Every script that represents a reusable type (component, entity, custom `Resource`) MUST declare
`class_name` and an explicit `extends`. Naming MUST follow: `snake_case` for files, variables,
functions, and signals; `PascalCase` for classes, nodes, and `class_name` declarations;
`SCREAMING_SNAKE_CASE` for constants and enum values. Signals MUST be named as past-tense events
(`health_depleted`, `item_collected`) — the `_on_` prefix is reserved exclusively for
signal-handler callback methods (`_on_hitbox_area_entered`). Every `@export` variable MUST carry
a type hint, and a one-line `##` doc-comment where its purpose is not obvious from the name.
**Rationale**: Static typing turns a large class of Godot runtime errors into edit-time errors
and keeps autocompletion — including the MCP-driven agent workflow this project relies on —
accurate. Consistent naming keeps AI-assisted and human contributions indistinguishable in style.

### VI. Predictable File Structure & Asset Naming
The project MUST use a feature/domain-oriented layout (see Project Layout in Technology Stack &
Environment Constraints) where a scene's non-generic script lives alongside its `.tscn` with a
matching base name (`player.tscn` + `player.gd`), and reusable components live in their own
shared folder rather than being duplicated per entity. File and folder names MUST be `snake_case`
and ASCII-only (no accents, no spaces) regardless of the game's pt-BR content, so tooling,
exports, and version control remain platform-safe. Asset files MUST be named
`type-prefix_descriptive_name_variant.ext` (the trailing `_variant` segment is optional) using
the project's fixed prefixes: `spr_` (sprites/textures), `sfx_` (sound effects), `mus_` (music),
`vfx_` (particles/shaders), `ui_` (interface graphics), `fnt_` (fonts).
**Rationale**: A predictable, prefix-based structure lets both humans and the Claude Code + Godot
MCP workflow locate or generate the right file on the first try instead of guessing or
duplicating assets.

### VII. Localization-First: pt-BR Native (NON-NEGOTIABLE)
The game's baseline and currently only language is `pt_BR`. Every piece of user-facing text — UI
labels, dialogue, item and objective names, subtitles, system/log messages shown to the player —
MUST be authored as a translation key resolved through Godot's Translation/`TranslationServer`
pipeline (CSV or `.po` files under `localization/`), and MUST NOT appear as a hardcoded string
literal inside a scene or script. This is a structural rule from the first scene built, not a
"translate later" pass: retrofitting localization onto hardcoded text is far more expensive than
starting with keys. Translation keys MUST use a namespaced `SCREAMING_SNAKE_CASE` convention that
encodes their domain (`UI_MENU_START`, `DLG_MOTHER_001`, `ITEM_RUSTY_KEY_NAME`). UI layout MUST
use containers and anchors (`VBoxContainer`, `HBoxContainer`, `GridContainer`) rather than fixed
pixel widths, since pt-BR strings run longer than their English equivalents; no UI element may
assume a fixed character count. Any font used for in-game text MUST have verified glyph coverage
for Portuguese accented characters and punctuation (á à â ã é ê í ó ô õ ú ç and their uppercase
forms) before adoption.
**Rationale**: The game's stated audience and content are pt-BR from day one. Treating
localization as a first-class architectural concern — not a post-launch retrofit — keeps the
codebase honest about its actual target language and leaves the door open to future locales at
low cost.

## Technology Stack & Environment Constraints

**Engine & Language**: Godot 4 (project currently pinned to the "4.7" feature set per
`project.godot`), GDScript only — no C#/.NET and no GDExtension/native modules unless a future
amendment justifies the added build complexity.

**Rendering & Platform Target**: The GL Compatibility renderer (`renderer/rendering_method =
"gl_compatibility"`) MUST be preserved unless a documented amendment changes the target hardware;
it is what keeps a mobile/low-end-desktop export path open. The `canvas_items` stretch mode MUST
be preserved for consistent 2D scaling across resolutions.

**Dimensionality**: This is a 2D top-down game built on `Node2D`/`CanvasItem`. Concrete node
vocabulary by domain:
- Actors (player, enemies, NPCs): `CharacterBody2D`
- Interaction/trigger/detection volumes (pickups, sanity triggers, stealth cones): `Area2D`
- Level geometry: `TileMapLayer` — the current Godot 4.3+ tile API. The legacy single `TileMap`
  node MUST NOT be used in new content.
- UI (HUD, menus, dialogue boxes): `Control`-derived roots
- AI navigation (if/when enemies need pathfinding): `NavigationRegion2D` / `NavigationAgent2D`

The project setting `3d/physics_engine = "Jolt Physics"` is a Godot default present in every
project regardless of dimensionality; it MUST NOT be read as license to introduce 3D nodes into
gameplay scenes without a constitution amendment to this section.

**Testing**: GUT — the widely-used community GDScript testing addon — is this project's
designated test framework for Principle IV's automated-test requirement, to be vendored under
`res://addons/gut/` when the first testable pure-logic system is implemented.

**Agent Tooling**: Scene, node, and resource edits performed by an AI coding agent SHOULD go
through the Godot MCP server (`addons/godot_mcp`) rather than hand-writing `.tscn`/`.tres` text,
so the live editor state and the saved files never diverge. `.godot/` and `*.import`-generated
output are build artifacts and MUST NOT be hand-edited or treated as source of truth.

**Project Layout** (domain/feature-oriented, per Principle VI):
```text
res://
├── autoloads/     # EventBus, GameState, SaveSystem, Localization/Settings service
├── components/    # Reusable component scenes/scripts (health, hitbox, sanity, interactable)
├── entities/      # Self-contained actor folders: entities/player/, entities/enemies/<name>/
├── levels/        # Room/chapter scenes
├── ui/            # HUD, menus, dialogue boxes
├── resources/     # Custom Resource (.tres) definitions: items, dialogue, stats
├── localization/  # .csv / .po translation source files
├── assets/        # Shared raw art/audio not owned by a single entity
└── addons/        # Third-party/editor plugins (e.g., godot_mcp)
```

## Development Workflow & Quality Gates

Every feature MUST go through this repository's adopted spec-kit flow (`/speckit-specify` →
`/speckit-plan` → `/speckit-tasks` → `/speckit-implement`) so scope, design, and tasks stay
traceable back to this constitution.

`/speckit-plan` MUST evaluate the Constitution Check gate against the current version of this
file before Phase 0 research begins, and again after Phase 1 design. Any unresolved violation
blocks `/speckit-tasks` until it is either fixed or justified in the plan's Complexity Tracking
table with the specific reason and the simpler alternative that was rejected — silent violations
are not permitted.

Before a task is marked complete, the implementer MUST satisfy Principle IV (run and observe the
change in the editor/build) and self-check the diff against Principles I, II, III, V, VI, and VII
(module boundaries, hierarchy depth, signal usage, typing/naming, file placement, and
hardcoded-string-free UI text respectively).

Commits SHOULD be scoped to a single task or behavior. New third-party addons under `addons/`
MUST be evaluated against Principles I–III (does the addon impose a conflicting architecture?)
before adoption, and, once accepted, recorded in Technology Stack & Environment Constraints.

## Governance

This constitution supersedes ad hoc conventions and prior undocumented practice. Any change that
conflicts with it MUST either be brought into compliance or justified through the amendment
procedure below — there is no silent-exception path.

**Amendment procedure**: Propose the change with its rationale (in the commit message, PR
description, or a planning doc), edit this file in the same change, recompute the version per
the policy below, and refresh the Sync Impact Report comment at the top of this file.

**Versioning policy** (semantic, applied to this document): MAJOR — a principle is removed or
redefined in a backward-incompatible way (e.g., dropping the static-typing or pt-BR-first
requirement); MINOR — a new principle or section is added, or existing guidance materially
expands; PATCH — wording, typo, or clarification fixes with no rule change.

**Compliance review**: Enforced primarily through the `/speckit-plan` Constitution Check gate
described in Development Workflow & Quality Gates above. Runtime, session-level guidance for AI
coding agents (e.g., a `CLAUDE.md` at the repository root, if/when created) MUST stay consistent
with this constitution; where the two conflict, this constitution wins.

**Version**: 1.0.0 | **Ratified**: 2026-07-02 | **Last Amended**: 2026-07-02
