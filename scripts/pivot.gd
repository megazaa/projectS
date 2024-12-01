#extends Node3D
#
#@export var min_rotation: float = -0.5  # Minimum rotation in radians
#@export var max_rotation: float = 0.5   # Maximum rotation in radians
#var is_peeking:bool = false
## Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#pass # Replace with function body.
#
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#rotate_player(delta)
	#
#func rotate_player(delta: float) -> void:
	#if is_peeking:
		#print("PEEK")
		#var mouse_delta = Input.get_last_mouse_velocity()# Rotate around the Y-axis only (left and right)
		#rotation.z -= mouse_delta.x * 0.2 * delta *0.2
		#rotation.z = clamp(rotation.z, min_rotation, max_rotation)
		#rotation.x=0
		#rotation.y = 0
		#print("Pivot Rotation Z: ", rotation.z)
	#elif !is_peeking:
		#print("NOPE")
		#rotation.z = 0
#
#func toggle_is_peeking():
	#if is_peeking:
		#print("PEEK")
	#elif !is_peeking:
		#print("NOPE")
	#is_peeking = !is_peeking
