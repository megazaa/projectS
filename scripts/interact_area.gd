extends Area3D
@onready var camera_3d: Camera3D = $"../../Camera3D"
@onready var label_3d: Label3D = $Label3D
@onready var player: CharacterBody3D = $"../../player"

func _on_body_entered(body: Node3D) -> void:
	player.set_visible(false)
	Global.mail_menu = true
	label_3d.set_visible(true)
	camera_3d.set_current(true)
	

func _on_body_exited(body: Node3D) -> void:
	Global.mail_menu = false
	player.set_visible(true)
	camera_3d.set_current(false)
