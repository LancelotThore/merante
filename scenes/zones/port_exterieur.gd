extends Node2D

func _on_exit_surface_body_entered(body: Node) -> void:
	if body.is_in_group("ida"):
		GameState.force_surface()
