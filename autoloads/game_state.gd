extends Node

var oxygen_max := 180.0       # 3 minutes en secondes
var oxygen := oxygen_max
var is_diving := false
var player_ref: CharacterBody2D = null

func _process(delta: float) -> void:
	if not is_diving or player_ref == null:
		return

	var consumption := 1.0
	if player_ref.velocity.length() > 120:
		consumption = 1.4   # consommation accrue en fuite

	oxygen = max(0.0, oxygen - delta * consumption)

	if oxygen <= 0.0:
		force_surface()

func reset_oxygen() -> void:
	oxygen = oxygen_max

func force_surface() -> void:
	is_diving = false
	if ResourceLoader.exists("res://scenes/zones/surface.tscn"):
		get_tree().change_scene_to_file("res://scenes/zones/surface.tscn")
