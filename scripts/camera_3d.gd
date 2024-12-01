extends Camera3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# Define rotation speeds and limits
var rotation_speed := 0.1
var pitch_limit := 80

# Store yaw and pitch angles
var yaw := 0.0
var pitch := 0.0

func _input(event):
	if event is InputEventMouseMotion:
		# Rotate camera based on mouse movement
		yaw -= event.relative.x * rotation_speed
		pitch -= event.relative.y * rotation_speed
		# Clamp pitch to avoid flipping
		pitch = clamp(pitch, -pitch_limit, pitch_limit)
		# Apply rotation to the camera
		rotation_degrees = Vector3(pitch, yaw, 0)
		# Lock the cursor to the center
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
