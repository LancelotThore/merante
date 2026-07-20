extends CharacterBody2D

const SPEED := 160.0
const SPEED_STEALTH := 80.0   # mode lampe faible
const DRAG := 0.82            # friction de l'eau
const CELL_REVEAL_FACTOR := 1.5   # rayon de révélation (en tuiles) par unité de texture_scale de la lampe

@onready var lamp := $PointLight2D
@onready var sprite := $Sprite

var lamp_mode := "normal"     # "normal" | "stealth" | "blue"
var last_cell := Vector2i(999999, 999999)

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

	var current_cell := Vector2i(global_position / 16.0)
	if current_cell != last_cell:
		last_cell = current_cell
		_reveal_cells_around(current_cell)
	MiniMap.update_ida_position(global_position)

func _reveal_cells_around(center_cell: Vector2i) -> void:
	var radius := int(ceil(lamp.texture_scale * CELL_REVEAL_FACTOR))
	var space_state := get_world_2d().direct_space_state
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			if Vector2(dx, dy).length() > radius:
				continue
			var cell := center_cell + Vector2i(dx, dy)
			var cell_world_pos := (Vector2(cell) + Vector2(0.5, 0.5)) * 16.0
			var query := PhysicsRayQueryParameters2D.create(global_position, cell_world_pos)
			query.exclude = [get_rid()]
			if space_state.intersect_ray(query).is_empty():
				MiniMap.reveal_cell(cell)

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

	# DEBUG : réarme la plongée manuellement, en attendant la vraie remontée à la surface
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		GameState.reset_oxygen()
		GameState.is_diving = true
