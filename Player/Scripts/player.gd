extends CharacterBody2D

var speedFactor := 4.5

var max_walk_speed : float
var max_run_speed : float
var max_sprint_speed : float

var walk_accel : float
var stop_decel : float

var gravity_without_jump_held := 2000.0 * 4 / 1.5
var gravity_with_jump_held := 1000.0 * 4 / 1.5

var base_jump_speed := 280.0 * 4 / 1.5
var jump_speed_incr:= 9.375 * 4 / 1.5

var jump_buffered := false
var air_speed := 0.0

var highestY := 0  

# Animation
var anim_tree
var state_machine

func _ready() -> void:
	anim_tree = $AnimationTree
	state_machine = anim_tree.get("parameters/playback")
	

func _process(_delta: float) -> void:
	max_walk_speed = 75.0 * speedFactor
	max_run_speed = 135.0 * speedFactor
	max_sprint_speed = 180.0 * speedFactor
	walk_accel = 337.5 * speedFactor
	stop_decel = 600.0 * speedFactor

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if GlobalScene.enabledMovement:
		if not is_on_floor():
			if Input.is_action_pressed("ui_accept"):
				velocity += Vector2(0.0, gravity_with_jump_held) * delta
			else:
				velocity += Vector2(0.0, gravity_without_jump_held) * delta

		# Handle jump.
		if Input.is_action_just_pressed("ui_accept"):
			if is_on_floor(): 
				# Store the current horizontal speed when jumping
				air_speed = abs(velocity.x)
				velocity.y = _jump_speed()
			elif !$CoyoteTimeTimer.is_stopped():
				# Coyote jump - only if timer is active and we're falling
				air_speed = abs(velocity.x)
				velocity.y = _jump_speed()
				PopupText.display_text("Coyote'd!", position, 16, 2)
			else:
				if !jump_buffered:
					$JumpBufferTimer.start()
					jump_buffered = true
		
		# Get the input direction and handle the movement/deceleration.
		var direction := Input.get_axis("ui_left", "ui_right")
		
		
		if is_on_floor():
			if Input.is_action_pressed("ui_left"):
				$PlayerSprite.flip_h = true
			elif Input.is_action_pressed("ui_right"):
				$PlayerSprite.flip_h = false
			# Ground movement - normal behavior
		if direction:
			var max_speed := max_walk_speed
			if Input.is_action_pressed('x'):
				max_speed = max_run_speed
			velocity.x = move_toward(velocity.x, (direction * max_speed), walk_accel * delta)
		else:
			velocity.x = move_toward(velocity.x, (direction * max_walk_speed), stop_decel * delta)
		#else:
			## Air movement - maintain the speed we had when we jumped
			#if direction:
				## Only allow changing direction, not speed
				## Use the air_speed we stored when jumping
				#var target_speed := air_speed * direction
				#print(air_speed, 'target speed!')
				#velocity.x = move_toward(velocity.x, target_speed, stop_decel * delta)

		
		var was_on_floor := is_on_floor()
		move_and_slide()
		
		if was_on_floor && !is_on_floor():
			$CoyoteTimeTimer.start()
		else:
			$CoyoteTimeTimer.stop()

		if !was_on_floor && is_on_floor():
			if jump_buffered:
				jump_buffered = false
				velocity.y = _jump_speed()
				PopupText.display_text("Buffered!", position, 16, 2)
		
	# ------------------------
	# Animation control logic:
	if not is_on_floor() and GlobalScene.enabledMovement:
		# Check if we're jumping (moving up) or falling (moving down)
		if velocity.y < 0:  # Moving up = jumping
			if state_machine.get_current_node() != "Jump":
				$JumpPlayer.play()
				state_machine.travel("Jump")
		else:  # Moving down = falling
			if state_machine.get_current_node() != "Fall":
				state_machine.travel("Fall")
	elif abs(velocity.x) > 1:
		var current_speed = abs(velocity.x)
		# Use your existing speed thresholds
		if current_speed > max_walk_speed:
			if state_machine.get_current_node() != "Run":
				state_machine.travel("Run")
		else:
			if state_machine.get_current_node() != "Walk":
				state_machine.travel("Walk")
	else:
		if state_machine.get_current_node() != "Idle":
			state_machine.travel("Idle")



func _jump_speed():
	var base_speed := base_jump_speed
	var speed_incr := jump_speed_incr
	var velocityToUse := max_run_speed if Input.is_action_pressed('x') else max_walk_speed
	return -(base_speed + speed_incr * (velocityToUse / 30))


func _on_jump_buffer_timer_timeout() -> void:
	jump_buffered = false
