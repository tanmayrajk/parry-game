extends CharacterBody2D

@export var land_effect_scene: PackedScene

@export var speed : float = 300.0
@export var acceleration: float = 25.0
@export var deacceleration: float = 30.0

@export var jump_force : float = -300.0
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.1

@export var dash_force: float = 500
@export var dash_time: float = 0.1
@export var dash_effect_time: float = 0.23
@export var dash_cooldown_time: float = 0.5

@export var parry_time: float = 0.2
@export var parry_cooldown_time: float = 0.5

var was_in_air := false
var coyote_timer := 0.0
var jump_buffer_timer := 0.0

var can_dash = true
var dash_timer := 0.0
var dash_effect_timer := 0.0
var dash_cooldown_timer := 0.0
var dash_velocity_x = 0
var is_dashing := false
var prev_dir = 0

var can_parry = true
var parry_timer := 0.0
var parry_cooldown_timer := 0.0
var parry_dir := Vector2(0, 0)
var is_parrying = false

func jump():
	var tween = create_tween()
	tween.tween_property($sprite, "scale", Vector2(0.7, 1.3), 0.1)
	tween.tween_property($sprite, "scale", Vector2(1, 1), 0.2)
	velocity.y = jump_force

func _physics_process(delta: float) -> void:
	var on_floor = is_on_floor()
	
	if on_floor and was_in_air:
		can_dash = true
		var effect = land_effect_scene.instantiate()
		effect.position = $land_effect_pos.global_position
		get_tree().current_scene.add_child(effect)
		effect.emitting = true
		if not effect.emitting:
			effect.queue_free()
		var tween = create_tween()
		tween.tween_property($sprite, "scale", Vector2(1.3, 0.7), 0.1)
		tween.tween_property($sprite, "scale", Vector2(1, 1), 0.2)
		
	was_in_air = not on_floor
	
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta
		velocity += get_gravity() * delta
		
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
		if is_on_floor():
			jump()
		elif coyote_timer > 0:
			jump()
			
	jump_buffer_timer -= delta
	
	if is_on_floor() and jump_buffer_timer > 0:
		jump()
		jump_buffer_timer = 0
		
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5
		
	if dash_effect_timer <= 0:
		$dash_effect.emitting = false

	var direction := Input.get_axis("left", "right")
	
	if direction and direction != prev_dir:
		var img = $dash_effect.texture.get_image()
		img.flip_x()
		$dash_effect.texture = ImageTexture.create_from_image(img)
		
	if is_parrying:
		parry_timer -= delta
		$shield_holders/right/collider.disabled = false if parry_dir.x > 0 else true
		$shield_holders/left/collider.disabled = false if parry_dir.x < 0 else true
		$shield_holders/up/collider.disabled = false if parry_dir.y < 0 else true
		$shield_holders/down/collider.disabled = false if parry_dir.y > 0 else true
		if parry_timer <= 0:
			$shield_holders/right/collider.disabled = true
			$shield_holders/left/collider.disabled = true
			$shield_holders/up/collider.disabled = true
			$shield_holders/down/collider.disabled = true
			is_parrying = false
	
	if is_dashing:
		dash_timer -= delta
		velocity.x = dash_velocity_x
		if not is_on_floor():
			velocity.y = 0
		if dash_timer <= 0:
			is_dashing = false
	else:
		if direction:
			$sprite.flip_h = direction < 0
			if is_on_floor():
				$animation.play("walk")
			velocity.x = move_toward(velocity.x, speed * direction, acceleration)
		else:
			velocity.x = move_toward(velocity.x, 0, deacceleration)
			
		if Input.is_action_just_pressed("dash") and can_dash and dash_cooldown_timer <= 0:
			start_dash()
			
		if Input.is_action_just_pressed("parry") and parry_cooldown_timer <= 0 and can_parry:
			start_parry()
	
	prev_dir = 1 if not $sprite.flip_h else -1
	dash_cooldown_timer -= delta
	dash_effect_timer -= delta
	parry_cooldown_timer -= delta

	move_and_slide()

func start_dash():
	$dash_effect.emitting = true
	var direction := Input.get_axis("left", "right")
	if not is_on_floor():
		can_dash = false
	var dash_dir = direction
	if direction == 0:
		dash_dir = 1 if not $sprite.flip_h else -1
	dash_velocity_x = dash_dir * dash_force
	is_dashing = true
	dash_timer = dash_time
	dash_effect_timer = dash_effect_time
	dash_cooldown_timer = dash_cooldown_time
	
func start_parry():
	var x = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	var y = int(Input.is_action_pressed("down")) - int(Input.is_action_pressed("up"))
	parry_dir.y = y if not is_on_floor() else (-1 if y < 0 else 0)
	parry_dir.x = x if x else (0 if parry_dir.y else (-1 if $sprite.flip_h else 1))
	
	is_parrying = true
	parry_timer = parry_time
	parry_cooldown_timer = parry_cooldown_time
	
	print(parry_dir)
	
	#might need to use this instead depending on the situation
	#$shield_holders/right.monitoring = true if parry_dir.x > 0 else false
	#$shield_holders/left.monitoring = true if parry_dir.x < 0 else false
	#$shield_holders/up.monitoring = true if parry_dir.y < 0 else false
	#$shield_holders/down.monitoring = true if parry_dir.y > 0 else false
	
