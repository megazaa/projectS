extends RigidBody3D
@onready var collision_shape_3d: CollisionShape3D = $sound_range/CollisionShape3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _time_out():
	queue_free()


func _on_collision_detect_body_entered(body: Node3D) -> void:
	if body.is_in_group("floor"):
		var timer:Timer = Timer.new()
		print("boom")
		collision_shape_3d.disabled = false
		add_child(timer)
		timer.one_shot = true
		timer.wait_time = 2
		timer.autostart = false
		timer.start()
		timer.timeout.connect(_time_out)
