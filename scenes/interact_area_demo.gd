extends Area3D

@onready var player: CharacterBody3D = $"../../player"
@onready var camera_3d: Camera3D = $"../Camera3D"
@onready var control: Control = $"../Control"
@onready var cant: VBoxContainer = $"../Control/cant"
@onready var h_box_container: HBoxContainer = $"../Control/HBoxContainer"
var search_value = 3
var count = 0
func _on_body_entered(body: Node3D) -> void:
	control.visible = true
	player.set_visible(false)
	Global.mail_menu = true
	camera_3d.set_current(true)
	for key in Global.inventory.keys():
		if Global.inventory[key] == search_value:
			count += 1
	if count < 3:
		cant.visible = true
		h_box_container.visible = false
	else :
		cant.visible = false
		h_box_container.visible = true

	

func _on_body_exited(body: Node3D) -> void:
	control.visible = false
	Global.mail_menu = false
	player.set_visible(true)
	camera_3d.set_current(false)


func _on_yes_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/demo.tscn")


func _on_no_pressed() -> void:
	control.visible = false
