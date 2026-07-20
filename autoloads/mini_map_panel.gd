extends Control

const CELL_PX := 4.0
const TILE_SIZE := 16.0
const MAP_SIZE := 150.0
const MARGIN := 16.0

@onready var state: Node = get_parent()

func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	offset_left = -MAP_SIZE - MARGIN
	offset_top = MARGIN
	offset_right = -MARGIN
	offset_bottom = MAP_SIZE + MARGIN
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	# Fond papier
	draw_rect(Rect2(Vector2.ZERO, size), Color("#f5f0e0"))

	# Le centre du panneau représente l'origine (0,0) du monde
	var center := size / 2.0

	# Cellules explorées
	for cell in state.explored_cells:
		var draw_pos: Vector2 = center + Vector2(cell) * CELL_PX
		draw_rect(Rect2(draw_pos, Vector2(3, 3)), Color("#1a1208"))

	# Position d'Ida
	var ida_map_pos: Vector2 = center + (state.ida_position / TILE_SIZE) * CELL_PX
	draw_circle(ida_map_pos, 3.0, Color("#f4a020"))
