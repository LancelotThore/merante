extends CharacterBody2D

const SPEED := 160.0
const SPEED_STEALTH := 80.0   # mode lampe faible
const DRAG := 0.82            # friction de l'eau

@onready var lamp := $PointLight2D
@onready var sprite := $Sprite

var lamp_mode := "normal"     # "normal" | "stealth" | "blue"

func _ready() -> void:
	GameState.player_ref = self
	GameState.reset_oxygen()
	GameState.is_diving = true

func _physics_process(_delta: float) -> void:
	var input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var speed := SPEED_STEALTH if lamp_mode == "stealth" else SPEED

	if input != Vector2.ZERO:
		velocity = velocity.lerp(input * speed, 0.12)
		if sprite is Sprite2D:
			sprite.flip_h = input.x < 0
	else:
		velocity *= DRAG

	move_and_slide()

func toggle_lamp_mode() -> void:
	match lamp_mode:
		"normal":
			lamp_mode = "stealth"
			lamp.energy = 0.3
			lamp.texture_scale = 0.8
		"stealth":
			lamp_mode = "normal"
			lamp.energy = 1.2
			lamp.texture_scale = 3.0

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("lamp_toggle"):
		toggle_lamp_mode()
	if event.is_action_pressed("open_notebook"):
		if ResourceLoader.exists("res://scenes/ui/carnet.tscn"):
			get_tree().change_scene_to_file("res://scenes/ui/carnet.tscn")
	# tool_use sera branché sur ToolSystem une fois l'autoload créé (outils)
