extends Control

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
func _on_try_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/demo.tscn")


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/quests_room.tscn")
