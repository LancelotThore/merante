extends CanvasLayer

@onready var oxygen_bar: ProgressBar = $OxygenBar
@onready var red_overlay: ColorRect = $RedOverlay
@onready var fragment_box: ColorRect = $FragmentBox
@onready var fragment_popup: Label = $FragmentBox/FragmentPopup
@onready var fragment_timer: Timer = $FragmentTimer

func _ready() -> void:
	Narrative.found_fragment.connect(_on_fragment_found)
	fragment_timer.timeout.connect(_on_fragment_timer_timeout)

func _on_fragment_found(data: Dictionary) -> void:
	fragment_popup.text = "%s\n\n« %s »" % [data["text"], data["ida_comment"]]
	fragment_box.visible = true
	fragment_timer.start()

func _on_fragment_timer_timeout() -> void:
	fragment_box.visible = false

func _process(_delta: float) -> void:
	var ratio := GameState.oxygen / GameState.oxygen_max
	oxygen_bar.value = ratio * 100.0

	if ratio <= 0.2:
		var pulse := (sin(Time.get_ticks_msec() / 150.0) + 1.0) * 0.5
		oxygen_bar.modulate.a = lerp(0.5, 1.0, pulse)
	else:
		oxygen_bar.modulate.a = 1.0

	red_overlay.color.a = clamp(1.0 - ratio / 0.1, 0.0, 0.5) if ratio <= 0.1 else 0.0
