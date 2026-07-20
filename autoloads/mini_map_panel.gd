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
	clip_contents = true

func _draw() -> void:
	# Fond papier
	draw_rect(Rect2(Vector2.ZERO, size), Color("#f5f0e0"))

	# Le centre du panneau suit Ida : on n'affiche qu'un rayon autour d'elle
	var center := size / 2.0
	var ida_map_offset: Vector2 = (state.ida_position / TILE_SIZE) * CELL_PX

	# Cellules explorées
	for cell in state.explored_cells:
		var draw_pos: Vector2 = center + Vector2(cell) * CELL_PX - ida_map_offset
		draw_rect(Rect2(draw_pos, Vector2(3, 3)), Color("#1a1208"))

	# Position d'Ida (toujours au centre du panneau)
	draw_circle(center, 3.0, Color("#f4a020"))
