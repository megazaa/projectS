extends CharacterBody3D

@onready var map_nav: NavigationRegion3D = $"../MapNav"
@onready var fov_ray: RayCast3D = $fov_ray
@onready var nav_agent: NavigationAgent3D = $nav_agent
@onready var enemy: CharacterBody3D = $"."
@onready var get_foot_sound: AudioStreamPlayer3D = $player_sound_manager/AudioStreamPlayer3D

enum {
	idle,
	roam,
	alert,
	pursuit
}
var all_point:PackedVector3Array = []
var next_point =1
@export var SPEED = 100
@export var neg_pos = 1
var sound_num = 1
var foot_sound_vol = 1
var walk_sound_scale = 1
var current_step = 1
var footstep_timer = 1
var seen_player = false
var in_pursuit = false
var is_at_point = false
var in_finding = false
var random:float
@export var walk_sound  = 1
@export var duration = 0.5
@export var find_chance = 0.5
var last_seen_pos:Vector3
const JUMP_VELOCITY = 4.5
@export var is_patrolling_guard = false
func _ready() -> void:
	add_to_group("enemy")
	for x in get_parent().get_node("guard_position_points").get_children():
		all_point.append(x.global_position + Vector3(0,1,0))
	print(all_point)
func _physics_process(delta: float) -> void:
	if footstep_timer >= 120/walk_sound_scale:
		#added, checks floor only when we walk
		print("in?")
		sound_num = sound_num +1
		get_walk_sound(sound_num)
		footstep_timer = 0
	if is_patrolling_guard:
		footstep_timer = footstep_timer+1
		if in_pursuit:
			walk_sound_scale = 5
			SPEED = 500
			Global.enemy_state = "in_pursuit"
			is_pursuiting(delta)
		if in_finding:
			walk_sound_scale = 3
			SPEED = 350
			Global.enemy_state = "in_finding"
			random_lookat(delta)
			is_finding(delta)
		if not in_pursuit and not in_finding:
			walk_sound_scale = 2
			SPEED = 150
			random_lookat(delta)
			Global.enemy_state = "is_roaming"
			is_roaming(delta)
	if not is_patrolling_guard and not in_pursuit:
		Global.enemy_state = "back_to_point"
		back_to_point(delta)
	if Input.is_action_just_pressed("ui_down"):
		is_patrolling_guard = false
		in_pursuit = false
		print("idle")
	sight_check()
	move_and_slide()
	

func _on_area_3d_body_entered(body: Node3D) -> void:
	pass
func listen_for_player():
	var space_state = get_world_3d().direct_space_state

func is_roaming(delta):
	await  get_tree().process_frame
	var facing_dir 
	#nav_agent.target_position = all_point[next_point]
	nav_agent.target_position = all_point[next_point]
	facing_dir = (nav_agent.get_next_path_position()- global_position ).normalized()
	velocity = velocity.lerp(facing_dir*SPEED*delta,1.0)
	facing_dir.y = 0
	smoot_rotate(delta,global_position + facing_dir)
func is_pursuiting(delta):
	var enemy_pos = global_position
	var next_pos = nav_agent.get_next_path_position()
	var change_dir = (next_pos - enemy_pos).normalized()
	velocity = change_dir*SPEED*delta
	smoot_rotate(delta*10,Global.player_current_pos)
func is_finding(delta):
	print("last_seen_pos",last_seen_pos)
	var facing_dir 
	facing_dir = (nav_agent.get_next_path_position()- global_position ).normalized()
	velocity = facing_dir*SPEED*delta
	smoot_rotate(delta/0.5,last_seen_pos)
	var check_timer = Timer.new()
	add_child(check_timer)
	check_timer.one_shot = true
	check_timer.autostart = false
	check_timer.wait_time = 5
	set_target(last_seen_pos)
	#print (nav_agent.distance_to_target())
	print("self.velocity*Vector3(1,0,1)",self.velocity*Vector3(1,0,1))
	if nav_agent.distance_to_target() < 1 or self.velocity*Vector3(1,0,1) < Vector3.ONE :
		print("sadsadas")
		sight_check()
		print("reach_lat_pos")
		print("where")
		check_timer.start()
		print(check_timer.time_left)
		check_timer.timeout.connect(_check_timeout)
func _check_timeout():
	print("checkTimer finished!")
	sight_check()
	if in_pursuit:
		print("wait wat?")
		return
	else:
		in_finding = false
	set_target(all_point[next_point])

func back_to_point(delta):
	if not is_at_point:
		
		#keeps nav node from loading in before the scene, error occurs otherwise
		await get_tree().process_frame
		
		var dir_dir
		
		nav_agent.target_position = all_point[0]
		dir_dir = nav_agent.get_next_path_position() - global_position
		
		dir_dir = dir_dir.normalized()
		
		velocity = velocity.lerp(dir_dir * SPEED * delta,1.0)
		
		#creates a bug if not at zero
		#Players raycast allows them to climb on enemy head
		dir_dir.y = 0
		smoot_rotate(delta/0.5,dir_dir)
		
		
	if is_at_point:
		direction_transition()
func direction_transition():
	
	#The point at which the current guard should be facing
		var default_rot = get_parent().get_node("reset_guard_rotation/posted_guard1_look_at").global_position
		
		#gets default_rot and applies the objects Basis(transform data) to var
		#Basis keeps axis coherent with each other????
		
		#will somtimes have guard face opposite dir, check marker pos for
		#negative numbers, if neg, change neg_pos to neg num
		var reset_rotation = Basis.looking_at(default_rot * neg_pos)
		#Enemies basis
		#gets the current objects rotation and stores it. pervents quaternion to rotation conversion error
		var current_rotation = basis.get_rotation_quaternion()
		
		#sets the new rotation to the object using interpolation
		#slerp is similar to lerp however, slerp takes into account angles
		basis = current_rotation.slerp(reset_rotation, 0.1)
		
		velocity = Vector3.ZERO

func _on_enemy_fov_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		seen_player = true


func _on_enemy_fov_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		seen_player = false
		last_seen_pos = Global.player_current_pos*Vector3(1,0,1)


func _on_nav_agent_target_reached() -> void:
	if is_patrolling_guard:
		next_point += 1
		if next_point >= all_point.size():
			next_point = all_point[-1]
			next_point = 0
	if not is_patrolling_guard and not in_pursuit:
		is_at_point = true
@onready var head: MeshInstance3D = $head

func sight_check():
	if seen_player:
		print("woo")
		fov_ray.look_at(Global.player_current_pos,Vector3(0,1,0))
	if fov_ray.is_colliding():
		var collider = fov_ray.get_collider()
		if collider.is_in_group("player"):
			var camera_h = get_parent().get_node("player/Camera3D").global_position.y
			head.look_at(Global.player_current_pos*Vector3(1,0,1)+Vector3(0,camera_h,0),Vector3(0,1,0))
			set_target(Global.player_current_pos)
			is_patrolling_guard = true
			in_pursuit = true
			is_at_point = false
			in_finding = false
			#collider.enemy_can_see_call()
	if not seen_player and in_pursuit:
		in_pursuit = false
		in_finding = true
	elif not seen_player and not is_finding:
		print("not seen_player and not is_finding")
		set_target(all_point[next_point])


func set_target(target):
	nav_agent.set_target_position(target)
func get_random_point_in_bounds(min: Vector3, max: Vector3) -> Vector3:
	var random_point = Vector3(
		randf_range(min.x, max.x),
		randf_range(min.y, max.y),
		randf_range(min.z, max.z)
	)
	return random_point

func smoot_rotate(delta,target_pos):
	#var tween = get_tree().create_tween()
	var posto2d = Vector2(global_position.x,-global_position.z)
	var playerPosto2d = Vector2(target_pos.x,-target_pos.z) 
	var dir_2d = (playerPosto2d - posto2d)
	var angle = -atan2(dir_2d.x,dir_2d.y)
	rotation.y = lerp_angle(rotation.y,angle,delta/1)
func random_lookat(delta):
	if random > 0.5:
		print("left")
		head.rotation.y = lerp_angle(head.rotation.y,deg_to_rad(90.0-17)
,delta/1)
	else: 
		print("right")
		head.rotation.y = lerp_angle(head.rotation.y,deg_to_rad(-90.0+17)
,delta/1)
func get_angle_to_player(enemy: Node3D, player_position: Vector3) -> float:
	# Get the direction the enemy is facing (forward direction)
	var enemy_forward = enemy.transform.basis.z.normalized()  # Z-axis is typically the forward direction in Godot's default coordinate system
	
	# Get the direction to the player
	var direction_to_player = (player_position - enemy.global_position).normalized()
	
	# Calculate the angle between the two vectors
	var angle = enemy_forward.angle_to(direction_to_player)
	
	return angle
	
func get_walk_sound(current_step):
	
	#will only play footstep sound if player is on the ground
	if is_on_floor():
		
		# f string that grabs the sound file
		var sound_path =  "res://assets/sound/{type}/{num}.wav"
		var get_sound = sound_path.format({"type": "stone-steps","num": current_step})
		get_foot_sound.stream = load(get_sound)
		get_foot_sound.pitch_scale = randf_range(.6,0.9)
		get_foot_sound.unit_size = walk_sound_scale
		get_foot_sound.play()
		if current_step == 7:
			sound_num = 1
		

func _on_timer_timeout() -> void:
	random = randf()
	print (random)
