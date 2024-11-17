extends CharacterBody3D

@onready var map_nav: NavigationRegion3D = $"../MapNav"
@onready var nav_agent: NavigationAgent3D = $nav_agent
@onready var enemy: CharacterBody3D = $"."
@onready var get_foot_sound: AudioStreamPlayer3D = $player_sound_manager/AudioStreamPlayer3D
@onready var fov_ray: RayCast3D = $head/MeshInstance3D2/fov_ray
@onready var around_detect: ShapeCast3D = $around_detect
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
var hp = 10
var can_back_stab = false
var sound_num = 1
var foot_sound_vol = 1
var walk_sound_scale = 1
var current_step = 1
var footstep_timer = 1
var elapsed_time = 0.001
var sight_check_time = -1
var move_radius: float = 5
var distance_threshold: float = 0.5 # Distance threshold to consider as "reached"
var target_position: Vector3
var stuck_threshold = 0.0001
var seen_player = false
var in_pursuit = false
var is_at_point = false
var in_finding = false
var in_roaming = true
var last_position : Vector3
var stuck_time : float = 0.0
var set_random_target_bool = false
var past_distance 
var random:float
var target_time = 1000.0  # The duration you want, e.g., 2 seconds
var grounded:bool
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

@onready var debug: Label = $Control/Container/BoxContainer/debug
func _process(delta: float) -> void:
	debug.text = "seen_player:" + str(seen_player)+"\nin_pursuit"+ str(in_pursuit)+ "\nis_at_point"+str(is_at_point)+"\nin_roaming"+str(in_roaming)+"\nin_finding"+str(in_finding)
func _physics_process(delta: float) -> void:
	move_stair(delta)
	#print(global_position.distance_to(last_position))
	if global_position.distance_to(last_position) < stuck_threshold and is_patrolling_guard == true:
		stuck_time += delta
	else:
		stuck_time = 0.0  # Reset if bot is moving

	if stuck_time > 10.0:  # If stuck for more than 3 seconds
		#var save_position = get_parent().get_node("save_position_points").get_children()
		#var skipper = get_tree().create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		#skipper.tween_property(self, "global_position",nav_agent.get_next_path_position()*Vector3(1,0,1) +Vector3(0,global_position.y+0.5,0) ,delta * 0.5)
		#nav_agent.set_target_position(save_position[0].global_position)
		struck_agent()
		in_pursuit = false
		in_finding = false
		in_roaming = true
		print("hwww")
		print("struck")
	if Input.is_action_just_pressed("ui_left"):
		in_finding = true
	past_distance =  nav_agent.get_next_path_position().distance_to(global_position)
	#print("next_path",nav_agent.get_next_path_position(),"current_position",global_position)
	if footstep_timer >= 120/walk_sound_scale:
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
		if in_roaming:
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
	last_position = global_position
	if (can_back_stab == true):
		if Global.sp_attack == true:
			target_sprite_3d.visible = true
		else:
			target_sprite_3d.visible = false
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
	#smoot_rotate(delta,global_position + facing_dir)
	smoot_rotate(delta/0.5,nav_agent.get_next_path_position())
func is_pursuiting(delta):
	var enemy_pos = global_position
	var next_pos = nav_agent.get_next_path_position()
	var change_dir = (next_pos - enemy_pos).normalized()
	var velocity_new = change_dir*SPEED*delta
	velocity = velocity_new
	if fov_ray.is_colliding():
		var collider = fov_ray.get_collider()
		print("sight_check_time",sight_check_time)
		if collider.is_in_group("player"):
			print("seen_player",seen_player)
			smoot_rotate(delta*10,Global.player_current_pos)
			sight_check_time = 0
			return
		else:
			sight_check_time = sight_check_time + 1
	
func is_finding(delta):
	print("last_seen_pos",last_seen_pos)
	var facing_dir 
	facing_dir = (nav_agent.get_next_path_position()- global_position ).normalized()
	velocity = facing_dir*SPEED*delta
	if not has_node("check_timer"):
		var check_timer = Timer.new()
		check_timer.name = "check_timer"
		add_child(check_timer)
		check_timer.one_shot = true
		check_timer.autostart = false
		check_timer.wait_time = 20
		check_timer.start()
	var check_timer = get_node("check_timer")
	set_random_target(delta,last_seen_pos)
	smoot_rotate(delta/0.5,last_seen_pos)
	#print (nav_agent.distance_to_target())
	print("self.velocity*Vector3(1,0,1)",self.velocity*Vector3(1,0,1))
	if nav_agent.distance_to_target() < 1 or self.velocity*Vector3(1,0,1) < Vector3.ONE :
		sight_check()
		print("timeleft",check_timer.time_left,"in_finding",in_finding)
		if in_pursuit:
			in_finding = false
			print("wait wat?")
			self.remove_child(check_timer)
			check_timer.queue_free()
			return
		if check_timer.time_left == 0:
			sight_check_time = 0
			print("checkTimer finished!")
			in_finding = false
			set_target(all_point[next_point])
			self.remove_child(check_timer)
			check_timer.queue_free()
			in_roaming = true
		#if not check_timer.is_connected("timeout", Callable(self, "_check_timeout")):
			#check_timer.connect("timeout", Callable(self, "_check_timeout"))
func _check_timeout():
	print("checkTimer finished!")
	sight_check()
	if in_pursuit:
		print("wait wat?")
		return
	else:
		in_finding = false
	set_target(all_point[next_point])
	var timer = get_node("check_timer")
	if timer:
		timer.remove_child(timer)
		timer.queue_free()

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
		if fov_ray.is_colliding():
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
		fov_ray.look_at(Global.player_current_pos,Vector3(0,1,0))
	if fov_ray.is_colliding():
		var collider = fov_ray.get_collider()
		if collider.is_in_group("player") and Global.player_light_level >= 0.1:
			var camera_h = get_parent().get_node("player/camer_holder/Camera3D").global_position.y
			head.look_at(Global.player_current_pos*Vector3(1,0,1)+Vector3(0,camera_h,0),Vector3(0,1,0))
			set_target(Global.player_current_pos)
			is_patrolling_guard = true
			in_pursuit = true
			is_at_point = false
			in_finding = false
			in_roaming = false
			#collider.enemy_can_see_call()
	#if not seen_player and in_pursuit:
		#in_pursuit = false
		#in_finding = true
	if sight_check_time >= target_time:
		in_finding = true
		in_pursuit = false
		sight_check_time = 0
	if in_roaming:
		set_target(all_point[next_point])
	elif not seen_player and sight_check_time == 0:
		in_finding = true
		in_pursuit = false 
func forgot():
	var timer_forgot = Timer.new()
	add_child(timer_forgot)
	timer_forgot.autostart = false
	timer_forgot.one_shot = false
	if fov_ray.is_colliding():
		var collider = fov_ray.get_collider()
		if collider.is_in_group("player"):
			timer_forgot.wait_time = 5
	else:
		timer_forgot.start()
		timer_forgot.timeout.connect(timer_forgot_timeout)
		
func timer_forgot_timeout():
	print("timeout")

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
		head.rotation.y = lerp_angle(head.rotation.y,deg_to_rad(90.0-17)
,delta/1)
	else: 
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
		if current_step >= 7:
			sound_num = 1

@onready var step_cast_3d: ShapeCast3D = $stepcast3d

func move_stair(delta):
	if !is_grounded():
		step_cast_3d.target_position.y = -0.3
	else:
		step_cast_3d.target_position.y = -1
	step_cast_3d.global_position.x = global_position.x + velocity.x*delta
	step_cast_3d.global_position.z = global_position.z + velocity.z*delta
	var quary = PhysicsShapeQueryParameters3D.new()
	quary.exclude = [self]
	quary.shape = step_cast_3d.shape
	quary.transform = step_cast_3d.global_transform
	var result = get_world_3d().direct_space_state.intersect_shape(quary,1)
	var get_collider:Object
	if !result:
		step_cast_3d.force_shapecast_update()
	step_cast_3d.force_shapecast_update()
	if step_cast_3d.is_colliding():
		if step_cast_3d.get_collider(0) != null:
			get_collider =  step_cast_3d.get_collider(0)
	if step_cast_3d.is_colliding() && velocity.y <= 0.0 && !result && get_collider.is_in_group("stair"):
		global_position.y = step_cast_3d.get_collision_point(0).y+1
		#camera_3d.global_position.y = lerp(camera_3d.global_position.y, camera_3d.global_position.y+0.2, 0.1)
		velocity.y = 0
		grounded = true
	else:
		grounded = false
func is_grounded()->bool:
	return grounded || is_on_floor()

func _on_timer_timeout() -> void:
	set_random_target_bool = true
	last_position = global_position
	random = randf()
	print (random)
func set_random_target(delta, center_point: Vector3):
	if set_random_target_bool:
		var angle = randf() * TAU
		var distance = randf() * move_radius
			# Calculate the offset position
		var offset = Vector3(cos(angle) * distance, 0, sin(angle) * distance)
		target_position = center_point + offset
		nav_agent.set_target_position(target_position)
		smoot_rotate(delta/0.5,target_position)
		global_position = global_position.move_toward(target_position,delta*0.5)
		print("New target position set:", target_position)
	set_random_target_bool = false

func struck_agent():
	around_detect.force_shapecast_update()
	if around_detect.is_colliding():
		var collision_point = around_detect.get_collision_point(0)
		print(global_position.y*Vector3(0,1,0) -collision_point*Vector3(0.2,0,0.2))
		global_position =((global_position- collision_point) + global_position )

@onready var target_area: MeshInstance3D = $back_attack_detector/target_area
@onready var target_area_3d: Area3D = $target_area3d
@onready var target_sprite_3d: Sprite3D = $target_area3d/target_collision/Sprite3D

func _on_hit_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		can_back_stab = true
		var size = target_area.get_aabb().size
		var randomvector2d = _random_target_vector2D(Vector2(size.x,size.y))
		target_area_3d.position = target_area.position+Vector3(randomvector2d.x,randomvector2d.y,0.1)
func _on_back_attack_detector_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		can_back_stab = false
		target_sprite_3d.visible = false
	
func _random_target_vector2D(size:Vector2)->Vector2:
	var target_x = randf_range(-size.x/2,size.x/2)
	var target_y = randf_range(-size.y/2,size.y/2)
	print (Vector2(target_x,target_y))
	return Vector2(target_x,target_y)
	
