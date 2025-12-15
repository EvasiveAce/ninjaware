extends CharacterBody2D
class_name Player


#region -- Movement Setup --
var speed_factor : float = 4.5

var max_walk_speed : float
var max_run_speed : float
var max_sprint_speed : float

var walk_accel : float
var stop_decel : float

var gravity_without_jump_held : float = 2000.0 * 4 / 1.5
var gravity_with_jump_held : float = 1000.0 * 4 / 1.5

var base_jump_speed : float = 280.0 * 4 / 1.5
var jump_speed_increased : float = 9.375 * 4 / 1.5

var jump_buffered : bool = false
var air_speed : float = 0.0
#endregion

#region -- Animation Setup --
## The animation tree.
## [br] Used for the [state_machine]. 
@onready var anim_tree = $AnimationTree
## State machine for the animation tree playback.
## [br] Used for most animations. 
@onready var state_machine = anim_tree.get("parameters/playback")
#endregion


func _physics_process(delta: float) -> void:
	if GlobalScene.enabledMovement:
		_set_speed()
		_set_gravity(delta)
		_set_direction(delta)
		_handle_jump()
		_handle_misc_jump()
		move_and_slide()
		
		
		_handle_animation()


## Handle player animation states.
func _handle_animation():
	if not is_on_floor():
		if velocity.y < 0:  # Moving up = jumping
			if state_machine.get_current_node() != "Jump":
				$JumpPlayer.play()
				state_machine.travel("Jump")
		else:  # Moving down = falling
			if state_machine.get_current_node() != "Fall":
				state_machine.travel("Fall")
	elif abs(velocity.x) > 1:
		var current_speed = abs(velocity.x)

		if current_speed > max_walk_speed:
			if state_machine.get_current_node() != "Run":
				state_machine.travel("Run")
		else:
			if state_machine.get_current_node() != "Walk":
				state_machine.travel("Walk")
	else:
		if state_machine.get_current_node() != "Idle":
			state_machine.travel("Idle")


## Set and handle direction.
func _set_direction(delta : float):
	var direction := Input.get_axis("ui_left", "ui_right")
	
	if is_on_floor():
		if Input.is_action_pressed("ui_left"):
			$PlayerSprite.flip_h = true
			$CollisionShape2D.position.x = -1.5
		elif Input.is_action_pressed("ui_right"):
			$PlayerSprite.flip_h = false
			$CollisionShape2D.position.x = 1.5
		# Ground movement - normal behavior
	if direction:
		var max_speed := max_walk_speed
		if 1 == 1:
			max_speed = max_run_speed
		velocity.x = move_toward(velocity.x, (direction * max_speed), walk_accel * delta)
	else:
		velocity.x = move_toward(velocity.x, (direction * max_walk_speed), stop_decel * delta)


## Sets the movement speeds to the [speed_factor].
func _set_speed():
	max_walk_speed = 75.0 * speed_factor
	max_run_speed = 135.0 * speed_factor
	max_sprint_speed = 180.0 * speed_factor
	walk_accel = 337.5 * speed_factor
	stop_decel = 600.0 * speed_factor


## Applies gravity if needed.
func _set_gravity(delta : float):
	if not is_on_floor():
		if Input.is_action_pressed("ui_accept"):
			velocity += Vector2(0.0, gravity_with_jump_held) * delta
		else:
			velocity += Vector2(0.0, gravity_without_jump_held) * delta


## Handle jump inputs.
func _handle_jump():
	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor(): 
			# Store the current horizontal speed when jumping
			air_speed = abs(velocity.x)
			velocity.y = _jump_speed()
		elif !$CoyoteTimeTimer.is_stopped():
			# Coyote jump - only if timer is active and we're falling
			air_speed = abs(velocity.x)
			velocity.y = _jump_speed()
			PopupText.display_text("Coyote'd!", position, 32, 2)
		else:
			if !jump_buffered:
				$JumpBufferTimer.start()
				jump_buffered = true
		

## Handle jump buffering/coyote.
func _handle_misc_jump():
	var was_on_floor : bool = is_on_floor()
	if was_on_floor && !is_on_floor():
		$CoyoteTimeTimer.start()
	else:
		$CoyoteTimeTimer.stop()

	if !was_on_floor && is_on_floor():
		if jump_buffered:
			jump_buffered = false
			velocity.y = _jump_speed()
			PopupText.display_text("Buffered!", position, 32, 2)


## Returns the jump speed to use.
func _jump_speed():
	var base_speed : float = base_jump_speed
	var speed_increase : float = jump_speed_increased
	var velocity_to_use : float = max_run_speed
	return -(base_speed + speed_increase * (velocity_to_use / 30))


## Jump buffer timeout function.
## [br] Signal connected from [JumpBufferTimer].
func _on_jump_buffer_timer_timeout() -> void:
	jump_buffered = false


## Resets velocity to 0.
## [br] Used in [base_stage.gd].
func reset_momentum():
	velocity.x = 0
	velocity.y = 0


## Bounces on Potato Bomb using [_jump_speed()].
## [br] Used in [potato_bomb.gd].
func bounce_on_potato_bomb():
	velocity.y = _jump_speed() * 1.5


## Bounces on Potato Bomb using [_jump_speed()].
## [br] Used in [potato_bomb_left_facing.gd].
func bounce_on_potato_bomb_left_facing():
	velocity.x = _jump_speed() * 1.5


## Bounces on Potato Bomb using [_jump_speed()].
## [br] Used in [potato_bomb_right_facing.gd].
func bounce_on_potato_bomb_right_facing():
	velocity.x = _jump_speed() * -1.5


## Places player out of bounds to end level.
## [br] Used in [spike.gd].
func enter_spike():
	velocity.y = 0
	position.y = 10000
