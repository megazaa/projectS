extends CharacterBody3D
@onready var hp_bar: ProgressBar = $ui/hp_bar
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape_3d: CollisionShape3D = $obs_detect/CollisionShape3D
@onready var obs_detect: Area3D = $obs_detect
@onready var camer_holder: Node3D = $camer_holder
@onready var camera_3d: Camera3D = $camer_holder/Camera3D
@onready var min_climb_detector: RayCast3D = $min_climb_detector
#@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision_player: CollisionShape3D = $CollisionShape3D
@onready var center: Node3D = $camer_holder/Camera3D/center
@onready var player: CharacterBody3D = $"."
@onready var right: MeshInstance3D = $right
@onready var left: MeshInstance3D = $left
@onready var camera_3d2: Camera3D = $Control/SubViewportContainer/SubViewport/Camera3D
@onready var height_detect: RayCast3D = $height_detect
@onready var floor_detector: Area3D = $floor_detector
@onready var get_foot_sound: AudioStreamPlayer3D = $player_sound_manager/AudioStreamPlayer3D
@onready var step_cast_3d: ShapeCast3D = $foot_pointer/StepCast3D
@onready var subtopview: SubViewport = $center/subtopview
@onready var subbottom: SubViewport = $center/subbottom
@onready var camera_3d_top: Camera3D = $center/subtopview/light_detection/Camera3DTop
@onready var color_rect_top: ColorRect = $CanvasLayer/ColorRectTop
@onready var weaporn_cam: Camera3D = $camer_holder/Camera3D/SubViewportContainer/SubViewport/weaporn_cam

@onready var label: Label = $Control/Label
@onready var label_2: Label = $Control/Label2
@onready var light_detection: Node3D = $center/subtopview/light_detection
@onready var light_detection2: Node3D = $center/subbottom/light_detection
@onready var texture_rect_top: TextureRect = $Control/TextureRectTop
@onready var texture_rect_bottom: TextureRect = $Control/TextureRectBottom
@onready var sub_viewport_container: SubViewportContainer = $camer_holder/Camera3D/SubViewportContainer

@export var speed_scale = 1.5
@export var look_sensitivity := 0.1
@export var jump_height: float = 4.0  # Jump height
@export var climb_height: float = 1.5     # How high the player climbs
@export var climb_speed: float = 2.0      # Speed of climbing
@export var gravity: float = -9.8  # Gravity value
@export var min_rotation: float = -0.5  # Minimum rotation in radians
@export var max_rotation: float = 0.5   # Maximum rotation in radians
@export var peek_len: float = 0.5
@export var duration:float = 0.5

@onready var attack_hand: Sprite3D = $body/attack_hand
@onready var hands: Sprite3D = $body/hands
@export var player_max_HP = 10
var crouch_height = 1
var normal_height = 1.75
var grounded = false
var is_jumping: bool = false  # Track if the player is jumping
var move_speed = 5
var is_climbing = false
var nearby_climbable = false
var something_above:bool = false
var is_peeking:bool = false
var footstep_timer = 0
var sound_num = 1
var walk_sound_scale = 1
var yaw := 0.0  # Horizontal rotation
var pitch := 0.0  # Vertical rotation
var foot_sound_vol = 1
var attack_animation = false
var current_weapon = 1
@export var foot_sound_vol_scale = 1
var mouse_lock = false
var can_peek = false
var is_tweening:bool
var Projectile = preload("res://scenes/throwable_items.tscn")
enum {
	PEEK,
	WALK,
	RUN,
	CROUCH,
	PEEK_L,
	PEEK_R,
}
@export var peek_state = PEEK
@export var state = WALK
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var interact_label: Label = $ui/VBoxContainer/interact_label

@onready var object_2: MeshInstance3D = $center/subtopview/light_detection/Object_2

var inventory= {
}
var crouch_flag:bool = false
func _ready():
	hp_bar.visible = true
	interact_label.visible = true
	Global.player_hp = player_max_HP
	set_player_hp()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Engine.set_physics_ticks_per_second(DisplayServer.screen_get_refresh_rate())
	subtopview.debug_draw = 2
	subbottom.debug_draw = 2
	Global.player_current_pos = global_position
	mask_off()
@onready var crosshair: TextureRect = $ui/crosshair

func _input(event):
	if mouse_lock:
		if event is InputEventMouseMotion:
			return
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * look_sensitivity
		pitch -= event.relative.y * look_sensitivity
		pitch = clamp(pitch, -80, 80)  # Limit the vertical rotation
		rotation_degrees.y = yaw
		camera_3d.rotation_degrees.x = pitch
	if event.is_action_pressed("crouch"):
		toggle_crouch()
	if Input.is_action_pressed("exit"):
		get_tree().quit()
	if event.is_action_pressed("throw"):
		throw_projectile()
	if Global.mail_menu:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		canvas_layer.visible = false
		crosshair.visible = false
	if not Global.mail_menu:			
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		canvas_layer.visible = true
		crosshair.visible = true

func _process(delta: float) -> void:
	object_2.rotation = self.rotation
	weaporn_cam.global_transform = camera_3d.global_transform
	weaporn_cam.global_position.y = camer_holder.global_position.y+0.5
	set_player_hp()
	open_book()
	Global.sp_attack = attack_animation
	Global.player_current_pos = global_position
	Global.player_current_basis = transform.basis
	
func _physics_process(delta):
	weapon_select()
	interactable()
	label_2.text = "light_level: "+ str(Global.player_light_level)
	Global.player_light_level =light_detected(subtopview,subbottom,texture_rect_top,texture_rect_bottom,color_rect_top)
	animation()
	light_detection.global_position = global_position # Make light detection follow the player
	light_detection2.global_position = global_position
	#.position = Vector3(0,0.5,-2)+global_position
	obs_detect.position = Vector3(0,collision_player.shape.height-2,0)
	right.position = Vector3(1,0,0)
	left.position = Vector3(-1,0,0)
	#get_foot_sound.global_position = global_position - Vector3(0,collision_player.shape.height/2,0)
	if footstep_timer >= 120/walk_sound_scale:
		#added, checks floor only when we walk
		sound_num ++1
		get_walk_sound(sound_num)
		footstep_timer = 0
	#camer_holder.position = Vector3(0,collision_player.shape.height*2/7 ,0)
	
	var direction := Vector3.ZERO
	match state:
		WALK:
			foot_sound_vol = 1.0
			walk_sound_scale = 2.5
			move_speed = 250*speed_scale
			
		RUN:
			foot_sound_vol = 1.2
			walk_sound_scale = 5
			move_speed = 500*speed_scale
			
		CROUCH:
			foot_sound_vol = 0.8
			#get_foot_sound.global_position = global_position - Vector3(0,collision_player.shape.height+0.5 ,0)
			walk_sound_scale = 1
			move_speed = 100*speed_scale
			
	#print(state)
	if is_grounded():  # Ensure the player is on the ground before allowing jumps
		if Input.is_action_just_pressed("jump") and something_above == false and state != CROUCH:  # Use is_action_just_pressed for one-time input
			velocity.y = jump_height  # Apply jump velocity
			is_jumping = true  # Set jumping state to true
	if not is_grounded():
		velocity.y += gravity * delta  # Apply gravity when in the air
	else:
		is_jumping = false  # Reset jumping state when on the ground
	if Input.is_action_pressed("forward"):
		direction -= transform.basis.z
	if Input.is_action_pressed("backward"):
		direction += transform.basis.z
	if Input.is_action_pressed("left"):
		direction -= transform.basis.x
	if Input.is_action_pressed("right"):
		direction += transform.basis.x
	if is_peeking == true:
		velocity.x = 0
		velocity.z = 0
	if crouch_flag :
		state = CROUCH
	if Input.is_action_pressed("shift") and crouch_flag != true:
		state = RUN
	elif state != CROUCH: 
		state = WALK
	if Input.is_action_just_pressed("peek_left")  and  abs(pitch) < 20 and can_peek:
		toggle_is_peeking("peek_left")
	if Input.is_action_just_pressed("peek_right") and  abs(pitch) < 20 and can_peek:
		toggle_is_peeking("peek_right")
	# Normalize direction to prevent faster diagonal movement and apply speed
	if direction != Vector3.ZERO:
		footstep_timer += 1
		direction = direction.normalized() * move_speed * delta
		velocity.x = direction.x
		velocity.z = direction.z
	else:
		velocity.x = 0
		velocity.z = 0
	# Apply movement
	if min_climb_detector.collide_with_bodies && not is_in_group("floor"):
		height_detect.global_position =  min_climb_detector.get_collision_point()+Vector3(0,0.05,0)
	if Input.is_action_just_pressed("jump") and Input.is_action_pressed("forward") and not is_climbing and min_climb_detector.get_collider() != null and not something_above:
		print("head_checker",head_checker())
		if not head_checker() and not min_climb_detector.get_collider().is_in_group("stair"):
			climb_to_box()
	if (is_peeking == true and can_peek == false):
		toggle_is_peeking("peek_right")
	if(Input.is_action_just_pressed("sp_attack")):
		attack_animation = true
	if(Input.is_action_just_released("sp_attack")):
		attack_animation = false
	if(Input.is_action_pressed("attack") and attack_animation == true):
		hit_scanner()
		attack_animation = false
		animation_player.play("attack")
	move_stair(delta)
	move_and_slide()

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
	var cam_pos = camera_3d.global_position
	var get_collider:Object
	if !result:
		step_cast_3d.force_shapecast_update()
	step_cast_3d.force_shapecast_update()
	if step_cast_3d.is_colliding():
		if step_cast_3d.get_collider(0) != null:
			get_collider =  step_cast_3d.get_collider(0)
			#
	if step_cast_3d.is_colliding() && velocity.y <= 0.0 && !result && get_collider.is_in_group("stair"):
		global_position.y = step_cast_3d.get_collision_point(0).y+1
		camera_3d.global_position.y = lerp(cam_pos.y, camer_holder.global_position.y+0.5, delta/(move_speed/3000))
		#weaporn_cam.global_position.y = lerp(cam_pos.y, camer_holder.global_position.y+0.5, delta/(move_speed/3000))
		#camera_3d.global_position.y = lerp(camera_3d.global_position.y, camera_3d.global_position.y+0.2, 0.1)
		velocity.y = 0
		grounded = true
	else:
		#weaporn_cam.global_position.y = lerp(camera_3d.global_position.y, camer_holder.global_position.y+0.5, 0.1)
		camera_3d.global_position.y = lerp(camera_3d.global_position.y, camer_holder.global_position.y+0.5, 0.1)
		grounded = false
func is_grounded()->bool:
	return grounded || is_on_floor()
func _on_obs_detect_body_entered(body: Node3D) -> void:
	if is_in_group("climbable"):
		something_above = true
		print("above")
func _on_obs_detect_body_exited(body: Node3D) -> void:
	if is_in_group("climbable"):
		something_above = false
		print("noting")


func _on_climb_detector_body_entered(body: Node3D) -> void:
	can_peek = true

func _on_climb_detector_body_exited(body: Node3D) -> void:
	can_peek = false

func climb_to_box():
	is_climbing = true
	# First Tween animation will make player move up.
	var vertical_climb = Vector3(global_transform.origin.x, min_climb_detector.get_collision_point().y + collision_player.shape.height/2, global_transform.origin.z)
	# If your player controller's pivot is located in the middle use this: 
	# var vertical_climb = Vector3(global_transform.origin.x, (place_to_land.position.y + collision_shape.shape.height / 2), global_transform.origin.z)
	var vertical_tween = get_tree().create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	vertical_tween.tween_property(self, "global_transform:origin", vertical_climb, 0.3)
	
	# We wait for the animation to finish.
	await vertical_tween.finished
	
	# Second Tween animation will make the player move forward where the player is facing.
	var forward = global_transform.origin + (-self.basis.z * 1)
	var forward_tween = get_tree().create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	forward_tween.tween_property(self, "global_transform:origin", forward, 0.2)
	
	# We wait for the animation to finish.
	await forward_tween.finished
	
	# Player isn't climbing anymore.a
	is_climbing = false

func toggle_is_peeking(peek):
	if (peek_state == PEEK_L or peek_state == PEEK_R or (is_peeking == true and can_peek == false)):
		is_peeking = false
		var tween_back = get_tree().create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween_back.set_parallel(true)
		if peek_state == PEEK_L:
			var left_direction = -self.transform.basis.x.normalized()
			var target_pos = -left_direction*peek_len + global_transform.origin
			var target = global_transform.origin+transform.basis.x.normalized()*Vector3(1,0,1)* peek_len
			tween_back.tween_property(
					player, "rotation:z", 
					0,     # End at the target 
					duration
				)
			tween_back.tween_property(
					player, "position", 
					target,     # End at the target 
					duration
				)
			await  tween_back.finished
		if peek_state == PEEK_R:
			var right_direction = self.transform.basis.x.normalized()
			var target = global_transform.origin-transform.basis.x.normalized()*Vector3(1,0,1)*peek_len
			tween_back.tween_property(
					player, "rotation:z", 
					0,     # End at the target 
					duration
				)
			tween_back.tween_property(
					player, "position", 
					target,     # End at the target 
					duration
				)
			await  tween_back.finished
		peek_state = PEEK
		
		mouse_lock = false
		print("PEEK")
	else:
		is_peeking = true
		match peek:
			"peek_left":
				var tween_left = get_tree().create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
				tween_left.set_parallel(true)
				var target_rotation_z = deg_to_rad(10.0)
				var target = global_transform.origin-transform.basis.x.normalized()*Vector3(1,0,1)* peek_len
				peek_state = PEEK_L
				tween_left.tween_property(
					player, "rotation:z", 
					target_rotation_z,     # End at the target 
					duration
				)
				tween_left.tween_property(
					player, "position", 
					target,     # End at the target 
					duration
				)
				mouse_lock = true
				await  tween_left.finished
				print("peek_left")
			"peek_right":
				var tweenk_right = get_tree().create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
				tweenk_right.set_parallel(true)
				var target_rotation_z = deg_to_rad(-10.0)
				var right_direction = self.transform.basis.x.normalized()
				var target_position = self.transform.origin + right_direction * peek_len
				peek_state = PEEK_R
				var target = global_transform.origin +transform.basis.x.normalized()*Vector3(1,0,1) * peek_len
				tweenk_right.tween_property(
					player, "rotation:z", 
					target_rotation_z,     # End at the target 
					duration
				)
				tweenk_right.tween_property(
					player, "position", 
					target,     # End at the target 
					duration
				)
				camera_3d.rotation.x = 0
				camera_3d.rotation.y = 0
				mouse_lock = true
				print("peek_right")
				await  tweenk_right.finished
		print(global_basis)
		print("Current rotation.z: ", camera_3d.rotation.z)
			
func toggle_crouch():
	match crouch_flag:
		true:
			state = WALK
			#animation_player.play("WALK")
		false:
			state = CROUCH
			#animation_player.play("CROUCH")
	crouch_flag = !crouch_flag
	
func throw_projectile():
	var projectile_instance = Projectile.instantiate()
	projectile_instance.global_transform = center.global_transform
	get_parent().add_child(projectile_instance)
	var throw_direction = -camera_3d.global_basis.z
	projectile_instance.linear_velocity = throw_direction * 10  # Adjust speed as needed
	projectile_instance.angular_velocity = projectile_instance.rotation
	projectile_instance.add_collision_exception_with(self)
	projectile_instance.add_collision_exception_with(min_climb_detector)
	print(-camera_3d.global_basis.z)
	
func head_checker() -> bool:
	height_detect.enabled = true
	height_detect.target_position = Vector3(0,collision_player.shape.height,0)
	if (height_detect.is_colliding()):
		print("awo")	
	#height_detect.enabled = false
	return height_detect.is_colliding()
	
func get_walk_sound(current_step):
	
	if !is_grounded():
		step_cast_3d.target_position.y = -0.45
	else:
		step_cast_3d.target_position.y = -1
	
		# f string that grabs the sound file
		var sound_path =  "res://assets/sound/{type}/{num}.wav"
		var get_sound = sound_path.format({"type": "stone-steps","num": current_step})
		get_foot_sound.stream = load(get_sound)
		#get_foot_sound.pitch_scale = randf_range(.6,0.9)
		get_foot_sound.pitch_scale = randf_range(1.6,2.9)
		get_foot_sound.unit_size = randf_range(0.5,0.8)
		get_foot_sound.play()
		if current_step == 7:
			sound_num = 1
@onready var attacking: TextureRect = $ui/attacking
func animation():
	var duration = 0.05
	var crouch_height = 1
	var normal_height = 1.75
	if current_weapon == 1:
		if attack_animation == true:
			hands.visible = false
			attack_hand.visible = true
			var tween_attack_SP = get_tree().create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN).set_parallel(true)
			tween_attack_SP.tween_property(
				attack_hand, "position:y", 
				0.5,
				duration
			)
			await  tween_attack_SP.finished
			tween_attack_SP.kill()
		else :
			attack_hand.visible = false
			if animation_player.is_playing():
				return
			else :
				hands.visible = true
			var tween_attack_SP = get_tree().create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN).set_parallel(true)
			tween_attack_SP.tween_property(
				attack_hand, "position:y", 
				-0.5,
				duration
			)
			await  tween_attack_SP.finished
			tween_attack_SP.kill()
	else:
		attack_hand.visible = false
	if state == CROUCH:
		var tween_crouch = get_tree().create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN).set_parallel(true)
		tween_crouch.tween_property(
			collision_player.get_shape(), "height", 
			crouch_height,
			duration
		)
		tween_crouch.tween_property(
			camer_holder, "position:y", 
			crouch_height/2 ,
			duration
		)
		await  tween_crouch.finished
	else:
		var tween_norm = get_tree().create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN).set_parallel(true)
		tween_norm.tween_property(
			collision_player.get_shape(), "height", 
			normal_height,
			duration
		)
		tween_norm.tween_property(
			camer_holder, "position:y", 
			normal_height/2 -0.75,
			duration
		)
		await  tween_norm.finished

func light_detected(subviewtop,subviewbottom,texture_rect_top,texture_rect_bottom,color_rect)->float:
	var texture1 = subviewtop.get_texture() # Get the ViewportTexture from the SubViewport
	var texture2 = subviewbottom.get_texture() # Get the ViewportTexture from the SubViewport
	texture_rect_top.texture = texture1 # Display this texture on the TextureRect
	texture_rect_bottom.texture = texture2 # Display this texture on the TextureRect
	var color = get_average_color(texture1,texture2) # Get the average color of the ViewportTexture
	#color_rect.color = color # Display the average color on the ColorRect
	return color.get_luminance()
	#light_level.tint_progress.a = color.get_luminance() # Also tint the progress texture with the above

func get_average_color(texture1: ViewportTexture, texture2: ViewportTexture) -> Color:
	# Get the average color of the first texture
	var image1 = texture1.get_image()
	image1.resize(1, 1, Image.INTERPOLATE_LANCZOS)
	var color1 = image1.get_pixel(0, 0)
	# Get the average color of the second texture
	var image2 = texture2.get_image()
	image2.resize(1, 1, Image.INTERPOLATE_LANCZOS)
	var color2 = image2.get_pixel(0, 0)

	# Calculate the average color between the two
	var average_color = Color(
		(color1.r + color2.r) / 2.0,
		(color1.g + color2.g) / 2.0,
		(color1.b + color2.b) / 2.0,
		(color1.a + color2.a) / 2.0
	)

	return average_color
@onready var hitscan: RayCast3D = $camer_holder/Camera3D/hitscan
func hit_scanner():
	if hitscan.is_colliding():
		var obj = hitscan.get_collider()
		if obj == null:
			return
		if obj.is_in_group("backstap_target"):
			obj.get_parent().drop_item()
			obj.get_parent().queue_free()
		if obj.is_in_group("interactable"):
			pass
func door_scanner():
	if hitscan.is_colliding():
		var obj = hitscan.get_collider()
		print(obj)
		if obj.is_in_group("door"):
			print("door")
			obj.get_parent().door_toggle()
@onready var rich_text_label_2: RichTextLabel = $ui/book_bg/RichTextLabel2
func interactable():
	if hitscan.is_colliding():
		var obj = hitscan.get_collider()
		if obj == null:
			return
		if obj.is_in_group("interactable"):
			var get_parent_node = obj.get_parent()
			interact_label.visible = true
			interact_label.text = get_parent_node.item.item_name +"\n"+"[F]"
			if get_parent_node.lock == true:
				for i in Global.inventory:
					if str(i) == get_parent_node.item.key_for:
						get_parent_node.lock = false
						Global.inventory.erase(str(i))
			if(Input.is_action_just_released("interact")):
				get_parent_node.pickup()
				print(get_parent_node.item.types_name)
			#obj.get_parent().door_toggle()
	else:
		interact_label.visible = false

func quest_interact():
	if Input.is_action_pressed("interact"):
		pass
@onready var mask: Node3D = $mask
@onready var soft_body_3d_3: SoftBody3D = $mask/SoftBody3D3

func mask_off():
	var mask_tween = get_tree().create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	var new_position = mask.global_transform.origin + mask.global_transform.basis.z * 2
	mask_tween.tween_property(mask, "global_transform:origin", new_position, 1.5)
	# We wait for the animation to finish.
	await mask_tween.finished
	mask.queue_free()
@onready var book_bg: TextureRect = $ui/book_bg
@onready var hands_2: Sprite3D = $body/hands2
@onready var rich_text_label: RichTextLabel = $ui/book_bg/RichTextLabel
func open_book():
	if Global.objectiveList.size() <= 0: 
		rich_text_label.text = "nothing here"
		return
	var text = str(Global.objectiveList[0].name)+"\n" + str(Global.objectiveList[1].name)+"\n" + str(Global.objectiveList[2].name)
	rich_text_label.text = text
	if Input.is_action_just_pressed("tab"):
		var text_item =""
		for i in Global.inventory:
			text_item += str(i) + "\n"
			print(Global.inventory)
		rich_text_label_2.text = text_item  # Append the key (item name) to the text
		#print(Global.inventory)
		book_bg.visible = true
		hands_2.visible = false
	if Input.is_action_just_released("tab"):
		book_bg.visible = false
		hands_2.visible = true



func set_player_hp():
	var old_hp = hp_bar.value
	hp_bar.value = Global.player_hp
	if hp_bar.value < old_hp:
		animation_player.play("hurt")
	if hp_bar.value <= 0:
		get_tree().change_scene_to_file("res://scenes/over.tscn")
@onready var hands_3: Sprite3D = $body/hands3

func weapon_select():
	if Input.is_action_pressed("light"):
		current_weapon = 0
	elif Input.is_action_pressed("weapon"):
		current_weapon = 1
	if current_weapon == 0:
		hands_3.visible = true
		hands.visible = false
	elif current_weapon == 1:
		hands_3.visible = false
	
