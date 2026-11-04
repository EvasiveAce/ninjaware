
extends CharacterBody2D
class_name Player

const SUBPIXELS_PER_PIXEL: int = 16
var sub_pixel: Vector2 = Vector2.ZERO

#region -- Movement Setup --
const WORLD_SCALE: float = 480.0 / 1920.0

var speed_factor: float = 4.5

var max_walk_speed: float
var max_run_speed: float

var walk_accel: float
var stop_decel: float

var gravity_without_jump_held: float = 2000.0 * 4 / 1.5 * WORLD_SCALE
var gravity_with_jump_held: float = 1000.0 * 4 / 1.5 * WORLD_SCALE

var jump_speed_running: float = 313.0
var jump_speed_standing: float = 295.0

var jump_buffered: bool = false
var is_skidding: bool = false
var skid_timer: float = 0.0
var skid_min_duration: float = 0.2
#endregion

#region -- Extras Setup --
const SMOKE_BOMB = preload("res://entities/ninja/smoke_bomb/scenes/smoke_bomb.tscn")
#endregion

#region -- Texture Setup --
@onready var ninja_texture = preload("res://entities/ninja/art/ninja_sheet.png")
@onready var ninja_snow_texture = preload("res://entities/ninja/art/ninja_snow_sheet.png")
#endregion

#region -- Animation Setup --
@onready var anim_tree = $AnimationTree
@onready var state_machine = anim_tree.get("parameters/playback")

var _last_requested_animation: StringName = &""
#endregion


func _ready() -> void:
	global_position = global_position.round()
	sub_pixel = Vector2.ZERO


func _physics_process(delta: float) -> void:
	if GlobalScene.movement_enabled:
		_set_speed()
		_set_direction(delta)
		_handle_jump()
		_set_gravity(delta)

		var was_on_floor = is_on_floor()

		_move_subpixel(delta)

		_handle_misc_jump(was_on_floor)
		_handle_animation()


func _move_subpixel(delta: float) -> void:
	var wanted := velocity

	# Accumulate this tick's displacement in subpixels.
	sub_pixel += wanted * delta * float(SUBPIXELS_PER_PIXEL)

	# Convert accumulated subpixels into whole-pixel movement.
	var step := Vector2(
		float(int(sub_pixel.x / SUBPIXELS_PER_PIXEL)),
		float(int(sub_pixel.y / SUBPIXELS_PER_PIXEL))
	)

	# Preserve leftover fractional movement.
	sub_pixel -= step * float(SUBPIXELS_PER_PIXEL)

	# Move using Godot's existing collision handling.
	velocity = step / delta
	move_and_slide()

	# Discard the remainder when collision blocks that axis.
	if is_on_wall():
		wanted.x = 0.0
		sub_pixel.x = 0.0

	if is_on_floor() and wanted.y > 0.0:
		wanted.y = 0.0
		sub_pixel.y = 0.0

	if is_on_ceiling() and wanted.y < 0.0:
		wanted.y = 0.0
		sub_pixel.y = 0.0

	# Restore the real physics velocity.
	velocity = wanted


## Handle animation states and debug wall blocking.
func _handle_animation() -> void:
	var dir := Input.get_axis("ui_left", "ui_right")

	# Check the direction of input or residual horizontal momentum.
	var check_direction := dir

	if is_zero_approx(check_direction):
		check_direction = signf(velocity.x)

	var blocked := (
		not is_zero_approx(check_direction)
		and test_move(
			global_transform,
			Vector2(signf(check_direction), 0.0)
		)
	)

	# Determine the desired animation.
	var desired_animation: StringName = &"Idle"

	if not is_on_floor():
		if velocity.y < 0.0:
			desired_animation = &"Jump"
		else:
			desired_animation = &"Fall"
	elif is_skidding:
		desired_animation = &"Skid"
	elif absf(velocity.x) > 1.0 and not blocked:
		desired_animation = &"Run"

	# Only request a transition when the desired state changes.
	if desired_animation != _last_requested_animation:
		state_machine.travel(desired_animation)
		_last_requested_animation = desired_animation



## Set and handle direction.
func _set_direction(delta: float) -> void:
	var direction := Input.get_axis("ui_left", "ui_right")

	if skid_timer > 0.0:
		skid_timer -= delta

	if is_on_floor() and direction != 0.0 and absf(velocity.x) > max_walk_speed:
		if signf(direction) != signf(velocity.x):
			is_skidding = true
			skid_timer = skid_min_duration

	if direction:
		var accel_to_use = walk_accel

		if is_skidding:
			accel_to_use = stop_decel * 1.1

		velocity.x = move_toward(
			velocity.x,
			direction * max_run_speed,
			accel_to_use * delta
		)
	elif is_on_floor():
		velocity.x = move_toward(
			velocity.x,
			0.0,
			stop_decel * delta
		)

	# Preserve your original behavior: change facing only while grounded.
	if is_on_floor():
		if not is_skidding:
			if direction < 0.0:
				$PlayerSprite.flip_h = true
				$CollisionShape2D.position.x = -1.5
				$MixedAnimations.flip_h = true
				$MixedAnimations.position.x = -4.0
			elif direction > 0.0:
				$PlayerSprite.flip_h = false
				$CollisionShape2D.position.x = 1.5
				$MixedAnimations.flip_h = false
				$MixedAnimations.position.x = 4.0

	if is_skidding and skid_timer <= 0.0:
		is_skidding = false


## Set movement speeds.
func _set_speed() -> void:
	var mult := speed_factor * WORLD_SCALE

	if $PlayerSprite.texture == ninja_snow_texture:
		mult *= 0.5

	max_walk_speed = 75.0 * mult
	max_run_speed = 135.0 * mult

	walk_accel = 450.0 * mult
	stop_decel = 600.0 * mult


## Apply gravity.
func _set_gravity(delta: float) -> void:
	var g := (
		gravity_with_jump_held
		if Input.is_action_pressed("ui_accept")
		else gravity_without_jump_held
	)

	velocity.y += g * delta


## Handle jump inputs.
func _handle_jump() -> void:
	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor():
			$JumpPlayer.play()
			velocity.y = _jump_speed()

		elif not $CoyoteTimeTimer.is_stopped():
			$CoyoteTimeTimer.stop()
			$JumpPlayer.play()
			velocity.y = _jump_speed()
			PopupText.display_text("Coyote'd!", position, 8, 0)

		elif not jump_buffered:
			$JumpBufferTimer.start()
			jump_buffered = true


## Handle jump buffering and coyote time.
func _handle_misc_jump(was_on_floor: bool) -> void:
	if was_on_floor and not is_on_floor() and velocity.y >= 0.0:
		$CoyoteTimeTimer.start()
	elif is_on_floor():
		$CoyoteTimeTimer.stop()

	if not was_on_floor and is_on_floor():
		if jump_buffered:
			$JumpPlayer.play()
			jump_buffered = false
			velocity.y = _jump_speed()
			PopupText.display_text("Buffered!", position, 8, 0)


## Calculate jump speed.
func _jump_speed() -> float:
	var ratio := clampf(
		absf(velocity.x) / max_run_speed,
		0.0,
		1.0
	)

	return -lerpf(jump_speed_standing, jump_speed_running, ratio)


## Jump buffer timeout.
func _on_jump_buffer_timer_timeout() -> void:
	jump_buffered = false


## Reset movement momentum.
func reset_momentum() -> void:
	velocity.x = 0.0
	velocity.y = 0.0
	sub_pixel = Vector2.ZERO


func snowball_hit() -> void:
	$PlayerSprite.texture = ninja_snow_texture
	$MixedAnimations.play("snowcloak")
	$SnowTimer.start(1.0)


func _on_snow_timer_timeout() -> void:
	$PlayerSprite.texture = ninja_texture
	$MixedAnimations.play("stopped")


func snowegg_hit() -> void:
	$PlayerSprite.texture = ninja_snow_texture
	$MixedAnimations.play("snowcloak")
	$SnowTimer.start(2.5)


## Bounce on a spring.
func bounce_on_spring(direction: String) -> void:
	match direction:
		"up":
			velocity.y = _jump_speed() * 1.5
		"down":
			velocity.y = _jump_speed() * -1.5
		"left":
			velocity.x = _jump_speed() * 1.5
		"right":
			velocity.x = _jump_speed() * -1.5


## Handle death.
func enter_spike() -> void:
	GlobalScene.movement_enabled = false
	reset_momentum()

	$MixedAnimations.play("smokebomb")
	$DeathSmokePlayer.play()

	while $MixedAnimations.frame < 3:
		await $MixedAnimations.frame_changed

	$PlayerSprite.visible = false
	await $MixedAnimations.animation_finished

	position.y = 10000
	$PlayerSprite.visible = true


## Spawn smoke effect.
func start_smoke() -> void:
	var smoke = SMOKE_BOMB.instantiate()
	get_tree().current_scene.add_child(smoke)

	smoke.global_position = global_position
	smoke.position.y += 7

	$SmokePlayer.play()
	await smoke.get_node("SmokeBombAnimated").animation_finished
	smoke.queue_free()
