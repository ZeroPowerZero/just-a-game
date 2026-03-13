extends CharacterBody3D

@onready var head = $head
@onready var animation_player: AnimationPlayer = $head/Camera3D/view_model/AnimationPlayer

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var mouse_sens = 0.3

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))


func _physics_process(delta: float) -> void:

	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump (changed from ui_accept → jump)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Attack animations
	if Input.is_action_just_pressed("left_mouse"):
		animation_player.play("swing_01")

	if Input.is_action_just_pressed("right_mouse"):
		animation_player.play("swing_02")

	if !animation_player.is_playing():
		animation_player.play("idle")

	# Movement input (changed to new input map)
	var input_dir := Input.get_vector("left", "right", "up", "down")

	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
