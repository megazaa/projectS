extends Area3D
@onready var player: CharacterBody3D = $"../../player"
@onready var camera_3d_3: Camera3D = $"../../Camera3D3"
@onready var h_box_container_2: HBoxContainer = $"../../bed/Control/HBoxContainer2"
@onready var label: Label = $"../../bed/Control/Label"

func _on_body_entered(body: Node3D) -> void:
	player.set_visible(false)
	Global.mail_menu = true
	camera_3d_3.set_current(true)
	h_box_container_2.visible = true
	label.visible = true
func _on_body_exited(body: Node3D) -> void:
	Global.mail_menu = false
	player.set_visible(true)
	camera_3d_3.set_current(false)
	h_box_container_2.visible = false
	label.visible = false
