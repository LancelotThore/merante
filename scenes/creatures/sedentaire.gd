extends StaticBody2D

@export var sound_loop: AudioStream
@onready var audio := $AudioStreamPlayer2D

func _ready() -> void:
	if sound_loop:
		audio.stream = sound_loop
		audio.play()

func _on_danger_zone_body_entered(body: Node) -> void:
	if body.is_in_group("ida"):
		GameState.force_surface()
