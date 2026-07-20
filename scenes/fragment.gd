extends Area2D

@export var fragment_id: String = ""

var found := false

func _on_area_entered(area: Area2D) -> void:
	if found:
		return
	var body := area.get_parent()
	if body and body.is_in_group("ida"):
		found = true
		Narrative.find_fragment(fragment_id)
