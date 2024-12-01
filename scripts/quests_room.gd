extends Node3D
var mouse = Vector2()
const DIST = 1000 #Ray Max distance
@onready var quests_room: Node3D = $"."
@onready var camera_3d: Camera3D = $Camera3D
@onready var canvas_layer: CanvasLayer = $CanvasLayer
func _process(delta: float) -> void:
	if Global.mail_menu == false:
		canvas_layer.visible = false
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse = event.position
	if event is InputEventMouseButton:
		if event.pressed == false and event.button_index == MOUSE_BUTTON_LEFT:
			get_mouse_world_pos(mouse)
			
@onready var text: Label = $CanvasLayer/PanelContainer/VBoxContainer/text
var current_obj:Array[Dictionary]
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
	var obj = result.collider
	if obj.is_in_group("quests"):
		var quest_name = obj.get_parent().quest.mission_name
		print(quest_name)
		canvas_layer.visible = true
		text.text = quest_name
		current_obj = obj.get_parent().quest.objectives
	else:
		canvas_layer.visible = false
	

func _on_cancel_pressed() -> void:
	print("off")
	canvas_layer.visible = false


func _on_accept_pressed() -> void:
	Global.objectiveList = current_obj
