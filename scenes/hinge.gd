extends Node3D
@onready var door_ani: AnimationPlayer = $door_ani
var toggle:bool = false
var lock = false
func door_toggle():
	if lock == true:
		return
	toggle=!toggle
	if toggle:
		open()
	if !toggle:
		close()
	await get_tree().create_timer(1.0,false).timeout
func open():
	print("opening")
	door_ani.play("open_door")
func close():
	door_ani.play("close_door")
