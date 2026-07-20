extends CanvasLayer

@onready var oxygen_bar: ProgressBar = $OxygenBar
@onready var red_overlay: ColorRect = $RedOverlay

func _process(_delta: float) -> void:
	var ratio := GameState.oxygen / GameState.oxygen_max
	oxygen_bar.value = ratio * 100.0

	if ratio <= 0.2:
		var pulse := (sin(Time.get_ticks_msec() / 150.0) + 1.0) * 0.5
		oxygen_bar.modulate.a = lerp(0.5, 1.0, pulse)
	else:
		oxygen_bar.modulate.a = 1.0

	red_overlay.color.a = clamp(1.0 - ratio / 0.1, 0.0, 0.5) if ratio <= 0.1 else 0.0
