# Contract: Localization Keys (pt-BR)

Per constitution Principle VII, no player-facing string may be hardcoded — every row below is a
key in `localization/strings.csv` (columns: `keys, pt_BR`), read via `tr("KEY")`. This satisfies
FR-018 and is what SC-004 ("100% of interface text in pt-BR, zero placeholder strings") is
verified against.

**Amendment note**: bubble keys renamed to match the corrected `IntentType` enum (research.md R11:
`CURTAINS`/`PHONE`/`LAUNDRY`/`DOOR_KEY`/`THOUGHTS`, a clean 1:1 with the five objects). A
`BUBBLE_THOUGHTS` key is added — the pre-amendment model never treated Thoughts as something the
resident actively "intends," so it had no bubble; the corrected model does.

**Sourcing legend**: **Sourced** = copied verbatim from the Design Guide or GDD's own pt-BR text
(highest confidence). **Proposed** = written now to unblock implementation because neither source
document specified exact copy for this string; needs a pass from the game's writer/designer before
ship — flagged with ⚠, not to be treated as final narrative content.

## Required — UI labels

| Key | pt-BR value | Sourcing |
|---|---|---|
| `UI_HOPE_LABEL` | Esperança | Sourced |
| `UI_ENERGY_LABEL` | Energia Sombria | Sourced |
| `UI_PLAY_AGAIN` | Jogar novamente | Proposed (added 2026-07-03 with the end-screen Play Again button) |

## Required — Object display names

| Key | pt-BR value | Sourcing |
|---|---|---|
| `OBJ_CURTAINS_NAME` | Cortinas | Sourced |
| `OBJ_PHONE_NAME` | Celular | Sourced |
| `OBJ_LAUNDRY_NAME` | Roupas Sujas | Sourced |
| `OBJ_KEY_NAME` | Chave da Porta | Sourced |
| `OBJ_THOUGHTS_NAME` | Pensamentos | Sourced |

## Required — Thought bubbles (FR-001/FR-012)

| Key | pt-BR value | Sourcing |
|---|---|---|
| `BUBBLE_CURTAINS` | Quer abrir a janela | Sourced (Design Guide asset name; GDD confirms curtains/window are the same intent — "Abrir para deixar o sol entrar") |
| `BUBBLE_PHONE` | ⚠ Quer usar o celular | Proposed — GDD's intent text is "Pegar para ligar para um amigo" (pick it up to call a friend); shortened for bubble-width, needs a writer pass |
| `BUBBLE_LAUNDRY` | ⚠ Quer arrumar as roupas | Proposed — GDD: "Recolher e colocar no cesto" |
| `BUBBLE_DOOR_KEY` | ⚠ Quer pegar a chave | Proposed — GDD: "Pegar na mesa para sair" |
| `BUBBLE_THOUGHTS` | ⚠ Tentando se acalmar | Proposed, but closely paraphrased from the GDD's own words ("Ficar parado tentando se acalmar") — lower-risk placeholder than the others |
| `BUBBLE_SEARCHING` | Procurando | Sourced (Design Guide asset name "Procurando (mini)") |

## Optional — Available polish assets (not required by any current FR)

| Key | pt-BR value | Sourcing | Note |
|---|---|---|---|
| `BUBBLE_REPEAT_ACTION` | Repetir ação | Sourced (Design Guide asset exists) | No FR requires a distinct "retry" beat beyond the single searching reaction in FR-012; reserved for a future polish task if time allows within the 32h budget |
| `BUBBLE_HOPE_MINI` | (icon-only, no text confirmed) | Sourced (asset name only) | Not wired to any FR |

## Required — Session resolution (FR-014/FR-015/FR-017)

| Key | pt-BR value | Sourcing |
|---|---|---|
| `RES_DEPRESSION_PREVAILS_TITLE` | ⚠ A sanidade foi sabotada. | **Proposed placeholder** — GDD's own line for this beat is "O morador chora e volta para a cama" (the resident cries and goes back to bed), which is more specific and arguably better sourced than the original placeholder; consider using a close paraphrase of that instead. Still needs a writer pass given the subject matter. |
| `RES_RESIDENT_ENDURES_TITLE` | ⚠ Mais um dia foi vivido. | **Proposed placeholder** — GDD's line is "O morador ganha forças e sai de casa" (the resident gains strength and leaves home), covering the 100%-Hope trigger specifically; the clock-timeout trigger has no GDD text at all. Per data-model.md, both triggers currently share this one title — a writer may want to split them into two distinct lines instead. |

## Not required for this feature

Explicit on-screen text for the Phone/Laundry "denied gain" outcome is **not** added — FR-009
requires the *effect* (no Hope gain) to happen, not that it be narrated in text; the resident's
`BUBBLE_SEARCHING` reaction (already Required, above) is the player-visible signal for every denied
attempt, uniformly across all five objects, so no per-object "delay" text is needed.

## Verification hook

`test_interactable_definition.gd` (or a dedicated `test_localization_keys.gd`) SHOULD assert that
every `display_name_key`/bubble key/resolution key referenced by code or `.tres` data has a
matching row in `strings.csv` — catching a missing translation at test time rather than as a
blank/placeholder label discovered during manual play (SC-004's "zero placeholder strings" is
otherwise only checkable by eyeballing every screen).
