extends Node3D

var grabbed_object = null
var grab_distance = 10
var mouse = Vector2()
const DIST = 1000 #Ray Max distance

func _input(event: InputEvent) -> void:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if event is InputEventMouseMotion:
			mouse = event.position
		if event is InputEventMouseButton:
			if event.pressed == false and event.button_index == MOUSE_BUTTON_LEFT:
				get_mouse_world_pos(mouse)
		#Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
func get_mouse_world_pos(mouse:Vector2):
	#The physics state of the world
	var space = get_world_3d().direct_space_state
	#start and end world positions for the ray
	var start = get_viewport().get_camera_3d().project_ray_origin(mouse)
	var end = get_viewport().get_camera_3d().project_position(mouse,DIST)
	#Params for 3D raycast
	#Alt var params = PhysicsRayQueryParameters3D.create(start,end)
	var params = PhysicsRayQueryParameters3D.new()
	params.from = start
	params.to = end
	#cast the ray using the space and return the results as a Dictionary
	var result = space.intersect_ray(params)
