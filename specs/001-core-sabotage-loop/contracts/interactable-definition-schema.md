# Contract: InteractableDefinition Resource Schema

This is the authoritative data contract for the five `.tres` files under
`resources/interactables/`. Field types and validation rules are defined in data-model.md; this
document pins the five concrete rows so implementation and design cannot drift apart.

**Amendment note**: rewritten for the corrected tug-of-war mechanic. `hope_effect_type` /
`hope_effect_value` / `qualitative_effect_key` / `repeatable` (pre-amendment fields) are replaced by
`intent`, `hope_gain_on_success`, and `hope_penalty_on_sabotage`. `repeatable` is dropped entirely —
in the corrected model every object's sabotage flag is consumed and reset at each resolution
(research.md R11), so all five objects are inherently repeatable across the session; the old
one-shot/repeatable distinction no longer applies to anything.

| `id` | `intent` | `display_name_key` | `gesture` | `hope_gain_on_success` | `hope_penalty_on_sabotage` | `energy_cost_tier` | `default_state_key` | `sabotaged_state_key` | `blocks_door_resolution` |
|---|---|---|---|---|---|---|---|---|---|
| `&"curtains"` | `CURTAINS` | `OBJ_CURTAINS_NAME` | `CLICK_REPEAT` | `10.0` | `15.0` **(sourced)** | `LOW` | `&"open"` | `&"closed"` | `false` |
| `&"phone"` | `PHONE` | `OBJ_PHONE_NAME` | `DRAG` | `8.0` | `0.0` | `LOW` | `&"visible"` | `&"hidden"` | `false` |
| `&"laundry_basket"` | `LAUNDRY` | `OBJ_LAUNDRY_NAME` | `CLICK_ONCE` | `8.0` | `0.0` | `MEDIUM` | `&"standing"` | `&"fallen"` | `false` |
| `&"door_key"` | `DOOR_KEY` | `OBJ_KEY_NAME` | `DRAG` | `5.0` | `0.0` | `HIGH` | `&"visible"` | `&"hidden"` | `true` |
| `&"thoughts"` | `THOUGHTS` | `OBJ_THOUGHTS_NAME` | `CLICK_ONCE` | `15.0` | `30.0` **(sourced)** | `VERY_HIGH` | `&"calm"` | `&"sent"` | `false` |

`default_state_key` was added during implementation (T005) — the original schema implied every
object has a resting/default visual state without naming a field for it.

Values marked **(sourced)** come directly from the Design Guide's mechanics table
("−15% Esperança" / "−30% Esperança"). All `hope_gain_on_success` values, and the `0.0` penalties
for Phone/Laundry/Door Key, are research.md R12's proposed defaults — provisional, not sourced,
clearly flagged as tunable in spec.md's Assumptions.

**Cross-checks any implementation MUST satisfy** (mirrors data-model.md's validation rules, GUT
tests these directly against the loaded `.tres` set — see `test_interactable_definition.gd`):

1. Tier→cost map (owned by `BedroomController`, research.md R10) must be strictly increasing:
   `cost(LOW) < cost(MEDIUM) < cost(HIGH) < cost(VERY_HIGH)`.
2. Exactly one row has `blocks_door_resolution == true` (`door_key`).
3. `hope_penalty_on_sabotage` is `0.0` for every row except `curtains` and `thoughts`.
4. `hope_gain_on_success` is `> 0.0` for all five rows.
5. The five `intent` values are exactly `{CURTAINS, PHONE, LAUNDRY, DOOR_KEY, THOUGHTS}` — no
   duplicates, no omissions (`BedroomController`'s intent→object dictionary requires this).

**Traceability to spec.md**: this table *is* the concrete realization of FR-001 through FR-009 and
the Assumptions section's "Interactable set" and "Hope gain-on-success amounts are proposed"
bullets — if the design changes which objects are contested or how they're valued, spec.md changes
first, then this table, in that order (per constitution Governance, spec drives plan, not the
reverse).
