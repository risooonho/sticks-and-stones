extends KinematicBody

var speed
var default_move_speed = 7
var sprint_move_speed = 14
var crouch_move_speed = 3
var crouch_speed = 20
var acceleration = 20
var gravity = 9.8
var jump = 5
var jump_num = 0
var blink_dist = 7


var default_height = 1.5
var crouch_height = 0.5

var mouse_sensitivity = 0.05

var sprinting = false
var grappling = false
var hook_point_get = false

var direction = Vector3()
var velocity = Vector3()
var fall = Vector3()
var hook_point = Vector3()

var damage = 100

onready var head = $Head
onready var pcap = $CollisionShape
onready var bonker = $HeadBonker
onready var sprint_timer = $SprintTimer
onready var aim_cast = $Head/Camera/AimCast
onready var grapple_cast = $Head/Camera/GrappleCast
onready var muzzle = $Head/Gun/Muzzle



func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
		head.rotate_x(deg2rad(-event.relative.y * mouse_sensitivity))
		head.rotation.x = clamp(head.rotation.x, deg2rad(-90), deg2rad(90))

func grapple():
	if Input.is_action_just_pressed("grapple"):
		if grapple_cast.is_colliding():
			if not grappling:
				grappling = true
	if grappling:
		fall.y = 0
		if not hook_point_get:
			hook_point = grapple_cast.get_collision_point()
			hook_point_get = true
		if hook_point.distance_to(transform.origin) > 1:
			if hook_point_get:
				transform.origin = lerp(transform.origin, hook_point, 0.05)
		else:
			grappling = false
			hook_point_get = false
			
func _physics_process(delta: float) -> void:
	grapple()
	
	var head_bonked = false
	speed = default_move_speed
	
	
	direction = Vector3()
	
	if Input.is_action_just_pressed("fire"):
		if aim_cast.is_colliding():
			var bullet = get_world().direct_space_state
			var collision = bullet.intersect_ray(muzzle.transform.origin, aim_cast.get_collision_point())
			
			if collision:
				var target = collision.collider
				if target.is_in_group("Enemy"):
					print("Hit enemy")
					target.health -= damage
				
	if bonker.is_colliding():
		head_bonked = true
		
	if not is_on_floor():
		fall.y -= gravity * delta
	else:
		jump_num = 0
		
	if Input.is_action_just_pressed("jump"):
		if jump_num == 0 and is_on_floor():
			fall.y = jump
			jump_num = 1
		elif jump_num == 1 and not is_on_floor():
			fall.y = jump
			jump_num = 2
		
	if head_bonked:
		fall.y = -2
		
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
		
	if Input.is_action_pressed("crouch"):
		pcap.shape.height -= crouch_speed * delta
		speed = crouch_move_speed
	elif not head_bonked:
		pcap.shape.height += crouch_speed * delta
	
	pcap.shape.height = clamp(pcap.shape.height, crouch_height, default_height)
	
	
	if Input.is_action_just_pressed("ability"):
		sprinting = !sprinting
		if sprinting:
			sprint_timer.start()
	
	if sprinting: speed = sprint_move_speed
		
	if Input.is_action_pressed("move_forward"):
		direction -= transform.basis.z

	elif Input.is_action_pressed("move_backward"):
		direction += transform.basis.z

		
	if Input.is_action_pressed("move_left"):
		direction -= transform.basis.x
		
	elif Input.is_action_pressed("move_right"):
		direction += transform.basis.x 
				
	direction = direction.normalized()
	velocity = velocity.linear_interpolate(direction * speed, acceleration * delta)
	velocity = move_and_slide(velocity, Vector3.UP)
	move_and_slide(fall, Vector3.UP, true)


func _on_SprintTimer_timeout() -> void:
	sprinting = false
