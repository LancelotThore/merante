extends CanvasLayer

var explored_cells := {}   # Dictionary { Vector2i : bool }
var ida_position := Vector2.ZERO

@onready var panel: Control = $Panel

func reveal_cell(cell: Vector2i) -> void:
	if not explored_cells.has(cell):
		explored_cells[cell] = true
		panel.queue_redraw()

func update_ida_position(world_pos: Vector2) -> void:
	ida_position = world_pos
	panel.queue_redraw()
