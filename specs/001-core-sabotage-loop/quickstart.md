# Quickstart: Core Sabotage Loop

Validation guide proving the feature works end-to-end, mapped directly to spec.md's Acceptance
Scenarios and Success Criteria. Not an implementation guide — see data-model.md and contracts/ for
the design this validates against, and tasks.md for build steps.

**Amendment note**: rewritten for the corrected tug-of-war mechanic (research.md R11/R12). One
structural difference from a typical scripted QA pass: the resident's intent order is
**weighted-random**, not player-driven, so the steps below are written as "when the resident next
telegraphs X, do Y" rather than a fixed linear script. A future polish task MAY add a debug hook to
force a specific intent for faster, deterministic QA — not required by any FR, noted here only as
an optional convenience.

## Prerequisites

- Godot 4.7 editor (matching `project.godot`'s `config/features`), opened on this project.
- GUT addon present at `res://addons/gut/` and enabled in Project Settings → Plugins.
- `res://levels/bedroom/bedroom.tscn` exists and is set as (or manually opened as) the running
  scene.
- Preferably run through the Godot MCP tools (`run_project`, `get_debug_output`, screenshot
  capture) per constitution Principle IV, rather than only the editor's Play button.

## 1. Automated checks (GUT) — pure-logic layer

Run GUT's test suite (editor GUT panel, or `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`):

- `test_interactable_definition.gd` → validates the five `.tres` rows against
  contracts/interactable-definition-schema.md's 5 cross-checks (strictly-increasing cost tiers,
  exactly one door-blocking row, zero penalty except Curtains/Thoughts, positive gain on all five,
  the five `intent` values form a complete 1:1 set).
- `test_bedroom_controller_hope_energy.gd` → validates FR-002 through FR-009 in isolation (accept/
  refuse logic, gain-on-success, penalty-on-sabotage, deny-only behavior, regen), independent of
  the `Resident`'s actual random intent picking (drive it via direct calls into
  `BedroomController`'s resolution method with a stubbed target).
- `test_bedroom_controller_resolution.gd` → validates the full resolution check order from
  data-model.md (0% precedence, 100%+key-available, 100%+key-hidden hold, clock-timeout).

**Expected outcome**: all three suites green before any manual pass begins.

## 2. Manual validation — User Story 1 (the contest itself)

Load `bedroom.tscn` and run it fresh each time (session must start at defaults — FR-019: Hope 50%,
Energy 100/100).

**Step 1 — session start**: confirm Hope reads 50%, Dark Energy reads 100/100, the clock is at its
starting display, and all five objects are in their default (non-sabotaged) visual state.

**Step 2 — let one intent succeed (do nothing)**: wait for the resident to telegraph any intent and
take no action. When the attempt window elapses (~6s), confirm: the object's success state is
reflected (e.g., curtains open) and Hope increases by exactly that object's `hope_gain_on_success`
(contracts/interactable-definition-schema.md — e.g., +10 for Curtains, +5 for Door Key).

**Step 3 — sabotage a Curtains or Thoughts intent (penalty path)**: the next time the resident
telegraphs Curtains or Thoughts specifically, trigger that object's gesture before the window
elapses. Confirm: the object's sabotaged state is reflected, Hope *decreases* by 15 (Curtains) or
30 (Thoughts), and the matching Dark Energy cost (10 or 50) is deducted.

**Step 4 — sabotage a Phone, Laundry, or Door Key intent (deny-only path)**: the next time the
resident telegraphs one of these three, trigger its gesture in time. Confirm: the resident's intent
fails (no Hope *increase* happens) but Hope does **not** additionally decrease either — it holds at
whatever value it was before this attempt — while the object's Dark Energy cost is still deducted.

**Step 5 — affordability refusal**: deliberately spend Dark Energy down (repeated Thoughts/Curtains
sabotages) until it's below the cost of the next gesture you attempt. Confirm the gesture has no
effect at all — no sabotage flag set, no Energy deducted — and the UI indicates insufficient Dark
Energy (SC-006).

**Step 6 — critical state + regen**: with Dark Energy below 20, confirm the UI reflects the
"critical" state distinctly from normal. Stop interacting and confirm Dark Energy climbs back
toward 100 at +5/second, moving out of "critical" once above 20 and reaching "ready" at 100.

**Step 7 — preemptive sabotage persists**: with no resident intent currently active on the Door
Key, drag it into hiding. Confirm it shows hidden immediately. Continue playing until the resident
*does* telegraph a Door Key intent; confirm that attempt resolves as an immediate failure using the
earlier sabotage, without needing to repeat the gesture during that specific window — this is
FR-002/FR-003's "before or during" and the flag-persists-until-consumed rule.

This walkthrough exercises all 10 of spec.md's User Story 1 acceptance scenarios plus SC-001,
SC-002 (partially — see §4 for the full 0% confirmation), and SC-006.

## 3. Manual validation — User Story 2 (resident reactions)

Continuing from a fresh session (or the state above):

1. Observe the resident between attempts (no current intent): confirm it cycles idle/walking
   animations, with a visibly sadder bias once Hope has dropped below 50 and sadder still below 20
   (research.md R10's idle-mood thresholds) — independent of whatever it's about to attempt next.
2. When the resident selects a new intent, confirm a thought bubble appears showing that specific
   telegraphed intent (contracts/localization-keys.md's `BUBBLE_*` keys) *before* the attempt
   window begins, and confirm the resident visibly moves toward (`WALKING`) then engages
   (`REACHING`) the corresponding object.
3. Let an intent resolve as a failure (sabotage it in time, per §2 Step 3 or 4). Confirm the
   resident shows the distinct `BUBBLE_SEARCHING` reaction rather than its normal telegraph bubble,
   then returns to idle and — after a short pause — telegraphs a new intent (SC-007).

## 4. Manual validation — User Story 3 (session resolution)

Three separate fresh sessions needed:

**Win path** (SC-002): sabotage every Curtains/Thoughts intent the resident telegraphs (the only
two with a direct Hope penalty), and sabotage the other three whenever affordable too (denying
their gain also helps, even without a penalty). Given −15/−30 penalties comfortably outpace the
+5..+10 gains from anything you miss, Hope should reach 0% well within the 300s session. Confirm:
the session ends **immediately** with the `RES_DEPRESSION_PREVAILS_TITLE` overlay the instant Hope
hits 0%, even mid-attempt-window on some other object.

**Baseline/inaction path** (SC-003, SC-008): perform zero sabotage for the whole session. Every
intent will succeed, and Hope should cross 100% quite quickly (roughly half a dozen resolved
intents at ~8s each — expect well under a minute, not the full 300s). Confirm: the session ends
with `RES_RESIDENT_ENDURES_TITLE` the instant Hope reaches 100%, since the door key was never
sabotaged in this run — well before the clock's end-of-day threshold.

**Key-failsafe path** (FR-015/FR-016, SC-009): drag the door key into hiding as early as possible.
**Important**: the sabotage flag is consumed the next time a Door Key intent resolves — if the
resident telegraphs Door Key and you don't re-hide it *during that specific window*, it becomes
available again the moment that attempt resolves. So: re-sabotage the key every single time the
resident telegraphs it, for the whole session, while otherwise taking no action on anything else.
Confirm: even after Hope reaches and would normally exceed 100%, the session does **not** resolve —
Hope holds at 100 — until either (a) you eventually let a Door Key attempt succeed (resolving
`RESIDENT_ENDURES` immediately once the key is available and Hope is already ≥100), or (b) the
300s clock runs out first, which also resolves `RESIDENT_ENDURES` (FR-017) even with the key still
hidden — confirming the key blocks the *100%-triggered* ending specifically, not the clock-timeout
ending.

## 5. Localization spot-check (SC-004)

With the OS/editor locale set to anything other than pt-BR, confirm every string on screen (bar
labels, object names, all five `BUBBLE_*` thought bubbles including `BUBBLE_THOUGHTS`, both
resolution titles) still renders in pt-BR. Cross-check against contracts/localization-keys.md's
Required tables; every key marked Required must be visible somewhere across §2–§4 of this
walkthrough.

## 6. Timing spot-check (SC-005)

Time a full playthrough (session start → any resolution). It MUST complete within 10 minutes. Given
§4's observations above, most playthroughs — especially the baseline/inaction one — will resolve
far faster than that ceiling; the ceiling mainly guards against an unusually cautious win-path
attempt that rarely engages.
