class_name HUD
extends CanvasLayer
## Listens to BedroomController's signals (connected TO by BedroomController, Principle III) and
## forwards values to its two ResourceBar children plus the cosmetic clock label. No gameplay
## logic of its own.

const CLOCK_START_MINUTES: int = 21 * 60
const CLOCK_END_MINUTES: int = 22 * 60

@onready var hope_bar: ResourceBar = $Layout/HopeBar
@onready var energy_bar: ResourceBar = $Layout/EnergyBar
@onready var clock_label: Label = $Layout/ClockLabel

func _ready() -> void:
	hope_bar.current_value = 50.0
	energy_bar.current_value = 100.0
	on_clock_fraction_elapsed(0.0)

func on_hope_changed(new_value: float) -> void:
	hope_bar.current_value = new_value

func on_energy_changed(new_value: float, _state: BedroomController.EnergyState) -> void:
	energy_bar.current_value = new_value

## FR-013: cosmetic HH:MM readout mapped onto the 21:00->22:00 in-fiction range (research.md R10).
## Called every frame by BedroomController._process (research.md R3 -- the day-end decision itself
## stays signal-driven via session_clock.timeout; only this cosmetic label polls).
func on_clock_fraction_elapsed(fraction: float) -> void:
	var span_minutes: int = CLOCK_END_MINUTES - CLOCK_START_MINUTES
	var total_minutes: int = CLOCK_START_MINUTES + roundi(clampf(fraction, 0.0, 1.0) * float(span_minutes))
	@warning_ignore("integer_division")
	var hh: int = (total_minutes / 60) % 24
	var mm: int = total_minutes % 60
	clock_label.text = "%02d:%02d" % [hh, mm]
