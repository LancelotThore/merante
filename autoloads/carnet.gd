extends CanvasLayer

@onready var fragment_list: VBoxContainer = $ScrollContainer/FragmentList

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

func toggle() -> void:
	visible = not visible
	get_tree().paused = visible
	if visible:
		_refresh()

func _refresh() -> void:
	for child in fragment_list.get_children():
		child.queue_free()

	for id in Narrative.fragments:
		var frag: Dictionary = Narrative.fragments[id]
		if not frag["found"]:
			continue
		var label := Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.text = "%s\n« %s »" % [frag["text"], frag["ida_comment"]]
		fragment_list.add_child(label)

	if fragment_list.get_child_count() == 0:
		var empty_label := Label.new()
		empty_label.text = "Rien pour l'instant."
		empty_label.modulate = Color(1, 1, 1, 0.5)
		fragment_list.add_child(empty_label)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_notebook"):
		toggle()
		get_viewport().set_input_as_handled()
