extends Node3D
@export var item:interact_manager
@onready var collision_shape_3d_2: CollisionShape3D = $Area3D/CollisionShape3D2

var toggle:bool = false
@export var lock = false

func pickup():
	if item.types_name == 1:
		Global.inventory[item.item_name] = 1
		queue_free()
	if item.types_name == 3:
		Global.inventory[item.item_name] = 3
		queue_free()
	if  item.types_name == 0:	
		door_toggle()
func door_toggle():
	#if door_ani.is_playing(): return 
	if lock == true:
		return
	toggle=!toggle
	if toggle:
		open()
		collision_shape_3d_2.disabled = true
	if !toggle:
		close()
		collision_shape_3d_2.disabled = false
func open():
	print("opening")
func close():
	pass
