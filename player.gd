extends RigidBody3D

const SPEED = 5.0
var submerged := false

@export var float_force := 1.3
@export var speed_multiplier := 1.0
@export var water_drag := 0.05
@export var water_angular_drag := 0.5

@onready var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var probes = $ProbeContainer.get_children()
@onready var water = $"../Water"

func _ready() -> void:
	pass
	
func _physics_process(delta: float) -> void:
	submerged = false
	var depth = 0
	var speed = 0
	for p in probes:
		depth = water.get_height(p.global_position) - p.global_position.y
		
		if p.global_position.y < depth:
			submerged = true
			speed = water.get_speed(p.global_position)
			apply_force(Vector3.UP * float_force * gravity * abs(depth), p.global_position - global_position)
			apply_force(Vector3.LEFT * speed_multiplier * speed, p.global_position - global_position)
		#DebugDraw2D.set_text("{0} @ {1}".format([depth, speed]), 0)
	
	#DebugDraw2D.set_text("{0} : {1}".format([probes[0].global_position.y, depth]), 0)
	if self.global_position.x > 10 || self.global_position.x < -10:
		self.global_position.x = 0
		
	DebugDraw2D.set_text("P1:{0}|P2:{1}|Depth:{2}|Speed:{3}".format([probes[0].global_position.y, probes[2].global_position.y, depth, speed]), null, 0, Color.RED, 0)
	
	#if not is_on_floor():
		#velocity += get_gravity() * delta
		
	#var input_dir := Input.get_vector("ui_left", "ui_right", "forward", "backward")
			
	#var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	#if direction:
		#velocity.x = direction.x * SPEED
		#velocity.z = direction.z * SPEED
	#else:
		#velocity.x = move_toward(velocity.x, 0, SPEED)
		#velocity.z = move_toward(velocity.z, 0, SPEED)
#
	#move_and_slide()

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if submerged:
		state.linear_velocity *=  1 - water_drag
		state.angular_velocity *= 1 - water_angular_drag 
