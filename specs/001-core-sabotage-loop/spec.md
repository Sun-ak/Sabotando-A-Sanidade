# Feature Specification: Core Sabotage Loop

**Feature Branch**: `001-core-sabotage-loop`

**Created**: 2026-07-02

**Status**: Draft

**Input**: User description: "Act as an expert Software Engineer and Godot 4 Architect. Adhering to the
rules and standards defined in our constitution.md, generate a detailed spec.md for 'Sabotando a
Sanidade' — a top-down, pt-BR, Godot 4 game (via Godot MCP). The spec must cover Game Overview
(core loop/mechanics), Technical Architecture (player controller, camera, interaction systems,
point-and-click/hidden-object mechanic), Scene Composition & Data Structures, and Acceptance
Criteria — following the design and assets defined in
'/home/luis/Downloads/Sabotando a Sanidade - Design Guide.html'."

**Amendment (2026-07-02)**: The original version of this spec modeled sabotage as a one-way Hope
drain. While preparing `/speckit-implement`, the authoritative Game Design Document
(`gdd-sabotando-a-sanidade.html`, referenced by the Design Guide's own subtitle "Referência do
GDD") was located and read in full. It describes a real-time **tug-of-war**: the resident actively
pursues goals that raise Hope unless the player sabotages them in time, Hope starts at 50%, and
there are two opposite loss/win thresholds (0% and 100%). This revision corrects the spec to match
the GDD; the correction was confirmed with the user before proceeding to `/speckit-plan` rework and
implementation.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Contest the Resident's Actions to Control Hope (Priority: P1)

As the player embodying Depression, I watch the resident (Morador) announce an intention — open
the curtains, grab the phone, tidy the laundry, fetch the door key, or sit and calm down — and I
must trigger that object's sabotage gesture before the resident's attempt resolves, or the resident
succeeds and gains Hope. Successfully sabotaging Curtains or Thoughts also actively damages Hope;
sabotaging Phone or Laundry merely denies the resident's gain. Every sabotage costs my Dark Energy,
which regenerates over time.

**Why this priority**: This is the entire real-time contest the design guide and GDD describe
("cabo de guerra" — tug of war). Without it there is no game: the resident has no way to raise
Hope, and the player has no way to stop them.

**Independent Test**: Can be fully tested by loading the single bedroom scene, letting the resident
attempt each of the five objects in turn, and confirming (a) an unsabotaged attempt raises Hope by
that object's defined amount, and (b) a sabotaged attempt either lowers Hope (Curtains, Thoughts)
or simply denies the gain (Phone, Laundry) while deducting the correct Dark Energy cost — verifiable
with no day-cycle resolution system wired up yet.

**Acceptance Scenarios**:

1. **Given** the resident telegraphs an intent to open the curtains and the player takes no action,
   **When** the attempt window elapses, **Then** the curtains open, the resident's intent succeeds,
   and the Hope Bar increases by the Curtains' defined success amount.
2. **Given** the resident telegraphs an intent to open the curtains, **When** the player triggers
   the Curtains sabotage gesture before the attempt window elapses, **Then** the curtains close (or
   stay closed), the resident's intent fails, the Hope Bar decreases by 15%, and the Curtains' Low
   energy cost is deducted from Dark Energy.
3. **Given** the resident telegraphs an intent to use the phone, **When** the player drags it under
   the pillow before the attempt window elapses, **Then** the phone becomes hidden, the resident's
   intent fails with no Hope gain, no additional direct Hope penalty is applied, and the Phone's
   Low energy cost is deducted.
4. **Given** the resident telegraphs an intent to tidy the laundry, **When** the player tips the
   basket before the attempt window elapses, **Then** the basket becomes fallen/spread, the
   resident's intent fails with no Hope gain, no additional direct Hope penalty is applied, and the
   Basket's Medium energy cost is deducted.
5. **Given** the resident telegraphs an intent to fetch the door key, **When** the player hides it
   before the attempt window elapses, **Then** the key becomes hidden, the resident's intent fails
   with no Hope gain, and the Key's High energy cost is deducted.
6. **Given** the resident telegraphs an intent to calm down (Thoughts), **When** the player sends a
   bad memory before the attempt window elapses, **Then** the resident's intent fails, the Hope Bar
   decreases by 30%, and the Thoughts' Very High energy cost is deducted.
7. **Given** Dark Energy is below an object's required cost, **When** the player attempts that
   object's sabotage gesture, **Then** the gesture has no effect and Dark Energy is unchanged.
8. **Given** Dark Energy has just been spent, **When** time passes without further sabotage,
   **Then** Dark Energy regenerates back toward its ready state.
9. **Given** a new session is starting, **When** the bedroom scene loads, **Then** the Hope Bar
   reads 50%, Dark Energy reads its maximum, the clock is at its starting value, and every object
   is in its non-sabotaged state.
10. **Given** an object was sabotaged before the resident ever telegraphed an intent toward it,
    **When** the resident later does telegraph and attempt that object, **Then** the attempt
    resolves as an immediate failure using the pre-existing sabotage — confirming sabotage can be
    applied preemptively, not only during an active attempt window.

---

### User Story 2 - Resident Reacts to the Sabotaged Room (Priority: P2)

As the player, I watch the resident move around the room, react emotionally as Hope rises and
falls, and telegraph upcoming actions through thought bubbles — including a distinct reaction when
an attempt is thwarted — so that the tug-of-war feels like a contest with a living character
instead of just two numbers moving.

**Why this priority**: The resident's animations and thought bubbles are what make User Story 1's
contest legible and give it emotional weight; the design guide dedicates a full animation set
(idle, walking, reaching, sitting-sad, crying) and a thought-bubble system to this. It depends on
User Story 1's intent/resolution logic existing but does not block User Story 1 from being tested
on its own with placeholder telegraphing.

**Independent Test**: Can be fully tested by driving the Hope Bar to different levels (via User
Story 1's resolved attempts) and confirming the resident's idle animation mood and displayed
thought bubble change accordingly, independent of whether the day-cycle/resolution system (User
Story 3) is wired up.

**Acceptance Scenarios**:

1. **Given** the resident has no current intent, **When** it is between attempts, **Then** it
   cycles through idle/walking animations, biased toward sadder variants as Hope falls.
2. **Given** the resident selects a new intent, **When** the selection happens, **Then** a thought
   bubble displays that specific telegraphed intent (e.g., "wants to open the window") before the
   attempt window begins.
3. **Given** the resident is mid-attempt on an object, **When** the attempt is in progress, **Then**
   the resident shows a "reaching"/attempting animation at that object.
4. **Given** the resident's attempt fails because the target object is sabotaged, **When** the
   attempt resolves, **Then** the resident displays a distinct "searching"/thwarted thought bubble
   instead of its normal intent bubble, rather than silently trying again.
5. **Given** the Hope Bar is very low, **When** the resident is between attempts, **Then** it
   displays sitting-sad or crying animations more often than at higher Hope levels.

---

### User Story 3 - The Day Resolves in Depression's Favor or the Resident's (Priority: P3)

As the player, I see the in-game clock advance toward the end of the day and the session resolve
into a clear outcome — the resident's hope is fully extinguished, the resident successfully leaves
home, or the day simply ends with the resident enduring — so that every playthrough has a definite
ending shaped by how the tug-of-war went.

**Why this priority**: This closes the loop into a complete, winnable/losable game. It depends on
the Hope Bar and the Key's special behavior (User Story 1) and benefits from resident feedback
(User Story 2), but can be tested with stubbed-in resident behavior.

**Independent Test**: Can be fully tested with three separate forced scenarios: (a) force Hope to
0% and confirm "Depression prevails" fires immediately; (b) force Hope to 100% with the door key
available and confirm "Resident endures" fires immediately; (c) force Hope to 100% with the door
key hidden and confirm no resolution fires, then let the clock run out and confirm "Resident
endures" fires via timeout instead.

**Acceptance Scenarios**:

1. **Given** a session in progress, **When** the Hope Bar reaches 0%, **Then** the session
   immediately ends with a "Depression prevails" resolution, regardless of remaining time or any
   object's sabotage state.
2. **Given** a session in progress with the door key not currently hidden, **When** the Hope Bar
   reaches 100%, **Then** the session immediately ends with a "Resident endures" resolution (the
   resident leaves home).
3. **Given** a session in progress with the door key currently hidden, **When** the Hope Bar
   reaches 100%, **Then** the session does **not** resolve — Hope holds at 100% and remains
   adjustable by further sabotage or resident success until the key becomes available again.
4. **Given** a session in progress with Hope between 0% and 100% (exclusive), **When** the clock
   reaches the end-of-day threshold, **Then** the session ends with a "Resident endures"
   resolution.

---

### Edge Cases

- What happens when the Hope Bar reaches 0% at the same instant it would also reach a
  resolution-triggering condition on the other end? Impossible by construction — Hope is a single
  value and cannot be both 0% and 100% at once; no tie-break is needed.
- What happens when the player attempts a sabotage gesture they cannot afford? The gesture has no
  effect (no sabotage flag set, no Energy change), and the player receives feedback that Dark
  Energy is insufficient.
- What happens when the player performs no sabotage at all for an entire session? Every resident
  attempt succeeds, Hope trends toward 100%; if the door key is not hidden when Hope reaches 100%,
  the session resolves as "Resident endures" well before the clock runs out.
- What happens if the resident's intent is thwarted? The resident shows the "searching" thought
  bubble, gains no Hope, and — for Curtains/Thoughts specifically — Hope also drops; the resident
  then returns to idle and picks a new intent after a short pause.
- How does the system handle a sabotage gesture triggered on an object with no resident intent
  currently targeting it? The object is marked sabotaged immediately (visually reflected) and stays
  that way until the resident's next attempt on that specific object consumes/resolves the flag.
- What happens to Hope while it is "held" at 100% because the door key is hidden? It remains a live
  value — a subsequent sabotaged Curtains/Thoughts attempt can still lower it from 100%, and further
  unsabotaged successes have no additional effect once already at the 100% ceiling.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST have the resident periodically select one of five defined intents
  (curtains, phone, laundry, door key, calm down/thoughts) and telegraph that intent via a thought
  bubble before attempting it.
- **FR-002**: System MUST let the player trigger a sabotage gesture on any of the five objects
  (repeated click for curtains; click-and-drag for phone and key; click for basket and thoughts) at
  any time, whether or not the resident currently intends to use that object.
- **FR-003**: System MUST mark an object as sabotaged the instant its gesture completes, and MUST
  keep it marked as sabotaged until the next time the resident's intent targets that object and
  that attempt resolves.
- **FR-004**: System MUST deduct a Dark Energy cost from the player's resource pool every time a
  sabotage gesture completes, using each object's assigned tier (Curtains and Phone: Low; Basket:
  Medium; Key: High; Thoughts: Very High), such that higher tiers always cost strictly more than
  lower tiers.
- **FR-005**: System MUST prevent a sabotage gesture from taking effect, and MUST leave Dark Energy
  unchanged, whenever the player's current Dark Energy is below that gesture's cost.
- **FR-006**: System MUST regenerate the player's Dark Energy over time while it is below its
  maximum, moving it between a "ready," a "critical" (low), and a "recharging" state.
- **FR-007**: System MUST resolve the resident's current intent once its attempt window elapses:
  if the targeted object is marked sabotaged at that moment, the intent fails; otherwise it
  succeeds.
- **FR-008**: System MUST increase the Hope Bar by an object-specific amount whenever the
  resident's intent on that object succeeds.
- **FR-009**: System MUST decrease the Hope Bar by a fixed percentage whenever the Curtains (−15%)
  or Thoughts (−30%) sabotage causes the resident's intent to fail; the Phone, Laundry, and Door
  Key sabotages MUST deny the resident's success (FR-008's gain) without an additional direct Hope
  penalty.
- **FR-010**: System MUST visually reflect each object's current sabotage state (curtains
  open/closed, phone on/off and visible/hidden, basket standing/fallen, key visible/hidden) so the
  player can see the outcome of prior sabotage at a glance.
- **FR-011**: System MUST display the resident performing idle, walking, reaching, sitting-sad, and
  crying animations, biased toward sadder states as Hope falls, independent of whether the resident
  is currently mid-attempt.
- **FR-012**: System MUST display a distinct "searching"/thwarted thought bubble when the
  resident's intent fails due to sabotage, in place of its normal telegraphed intent bubble.
- **FR-013**: System MUST display an in-game clock that advances from the start of a session
  toward a defined end-of-day threshold.
- **FR-014**: System MUST end the current session with a "Depression prevails" resolution the
  instant the Hope Bar reaches 0%, regardless of the clock's remaining time or any object's
  sabotage state.
- **FR-015**: System MUST end the current session with a "Resident endures" resolution the instant
  the Hope Bar reaches 100% while the door key is not currently sabotaged (hidden).
- **FR-016**: System MUST NOT resolve the session when the Hope Bar reaches 100% while the door key
  is currently sabotaged (hidden); Hope MUST remain a live, adjustable value at/near 100% until the
  key becomes available again.
- **FR-017**: System MUST end the current session with a "Resident endures" resolution when the
  clock reaches the end-of-day threshold and the Hope Bar has not reached 0% (whether or not it has
  reached 100%).
- **FR-018**: System MUST present all player-facing text — Hope Bar and Dark Energy labels, the
  clock, thought-bubble text, and session-resolution text — in Brazilian Portuguese (pt-BR), per
  the project constitution's localization principle.
- **FR-019**: System MUST start every session with the Hope Bar at 50%, Dark Energy at its maximum,
  the clock at its starting value, and every object in its non-sabotaged state.

### Key Entities

- **Morador (Resident)**: The NPC actively pursuing Hope-raising intents. Tracked attributes:
  current animation/behavior state (idle, walking, reaching, sitting-sad, crying), current intent
  (which of the five objects it is pursuing, if any) and that intent's remaining attempt-window
  time, and whether its most recent attempt succeeded or was thwarted.
- **Depressão (Player Agent)**: The player's in-world presence, represented by a dedicated cursor
  rather than a walking character. Tracked attributes: current Dark Energy value and its
  ready/critical/recharging state.
- **Room Object (Interactable)**: One of the five contested objects. Tracked attributes: object
  identity, current sabotaged/not-sabotaged state, current visual state, its assigned sabotage
  gesture, its Dark Energy cost tier, its Hope gain-on-success amount, and its Hope
  penalty-on-sabotage amount (zero for Phone/Laundry/Key).
- **Barra de Esperança (Hope Bar)**: The single contested resource, a percentage starting at 50%
  that both agents push in opposite directions across the session.
- **Energia Sombria (Dark Energy)**: The player's core resource, spent on sabotage gestures and
  regenerating over time.
- **Ciclo do Dia (Day Cycle)**: The session timer, tracking elapsed time toward the end-of-day
  threshold that ends the session in the resident's favor if Hope has not reached 0%.
- **Resolução de Sessão (Session Resolution)**: The end state of a playthrough — "Depression
  prevails" (Hope hit 0%) or "Resident endures" (Hope hit 100% with the key available, or the clock
  ran out first) — and which of those triggers produced it.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A first-time player identifies at least one contested object and successfully
  sabotages a resident attempt within 60 seconds of a session starting, with no external
  instructions.
- **SC-002**: A player who successfully sabotages the highest-impact attempts (Thoughts, Curtains)
  whenever they're telegraphed can drive the Hope Bar from its 50% starting value to 0% within a
  single session, confirming the "Depression prevails" path is reachable through active play.
- **SC-003**: A player who performs no sabotage for an entire session observes every resident
  attempt succeed, Hope trending upward, and the session resolving as "Resident endures" — via the
  100%-Hope path if the key stays available, well before the clock's end-of-day threshold —
  confirming the baseline (do-nothing) path resolves quickly and correctly.
- **SC-004**: 100% of player-facing interface text (bars, clock, thought bubbles, resolution
  screens) displays in pt-BR, with zero placeholder or untranslated strings.
- **SC-005**: A complete playthrough, from session start to any resolution, is completable in a
  single sitting of no more than 10 minutes, consistent with the game's short-session, game-jam
  scope.
- **SC-006**: A player can tell, before attempting a sabotage gesture, whether they currently have
  enough Dark Energy to perform it, without needing to attempt the gesture first.
- **SC-007**: A player who notices a resident's thought bubble and reacts with the matching
  sabotage before the attempt window elapses observes a different outcome (a "searching" reaction,
  denied Hope gain) than if they had not reacted.
- **SC-008**: A player who lets every resident intent resolve unsabotaged observes the Hope Bar
  rising toward 100% and the session resolving as "Resident endures" without the clock ever
  reaching its end-of-day threshold, confirming the resident's success path is reachable through
  inaction alone.
- **SC-009**: A player who keeps the door key hidden at the moment Hope reaches 100% observes the
  session continue with no resolution firing, rather than immediately ending — confirming the key's
  failsafe effect against the 100%-Hope loss.

## Assumptions

- **Scope**: The playable scope for this specification is the single bedroom scene, single
  resident, and single day/night session described in the GDD, consistent with the project's
  32-hour, 5-person game-jam timeline stated in that document. Multiple rooms, multiple residents,
  or a multi-day campaign are out of scope for this feature.
- **No player avatar movement**: The GDD explicitly confirms this ("Sem avatar físico — você é o
  próprio cursor" — no physical avatar, you are the cursor itself). All player action is
  cursor-based point-and-click/drag on a single fixed room view (1280×720 reference resolution).
  "Top-down" describes the fixed camera angle looking down into the room, not character locomotion
  — the walking/idle/crying animation set belongs to the resident, not the player.
- **Interactable set**: Exactly five contested objects are in scope — curtains, phone, laundry
  basket, door key, and the resident's thoughts — matching both the Design Guide's mechanics table
  and the GDD's interaction table. Additional interactables are out of scope until a future feature
  extends the set.
- **Win/lose semantics — now GDD-sourced, not inferred**: Hope starts at 50%. "Depression prevails"
  (Hope reaches 0%) is the player's win condition. "Resident endures" (Hope reaches 100% with the
  key available, or the clock expires first) is the player's loss condition. The door key's "final
  defense" role is specifically to block the 100%-Hope loss, not a generic clock-block — this is
  stated directly in the GDD ("defesa final do Vilão").
- **Hope gain-on-success amounts are proposed, not sourced**: neither the Design Guide nor the GDD
  gives numeric values for how much Hope the resident gains from an unsabotaged success (only the
  sabotage-penalty side has sourced numbers, for Curtains/Thoughts). Concrete proposed values are
  recorded in plan.md/research.md, clearly flagged as tunable, not fixed by this specification.
- **Sabotage persistence**: an object's sabotaged flag persists once set (including if set before
  the resident ever shows intent toward it) and is consumed the next time the resident's intent on
  that specific object resolves — this reading of "antes ou durante a ação da IA" (before or during
  the AI's action) is this specification's concrete interpretation, chosen for implementation
  uniformity across all five objects rather than special-casing Curtains' "repeatedly" language.
- **Tuning values deferred**: exact Dark Energy regeneration speed, attempt-window duration, and
  session clock length are balancing details left to `/speckit-plan` and implementation, not fixed
  by this specification.
- **Single locale**: Only pt-BR is required for this feature; additional locales are out of scope.
- **Platform**: the GDD confirms "PC (Web/Desktop)" as the target platform — this is now a
  confirmed requirement, not the speculative note it was in the prior version of this spec.
- **Technical architecture deferred**: Godot node structure, scene composition, and system-level
  implementation design are intentionally not specified here — they belong to `/speckit-plan`.
