extends RigidBody3D

const SPEED = 5.0
var submerged := false

@export var float_force := 4.0
@export var speed_multiplier := 2.0
@export var water_drag := 0.1
@export var water_angular_drag := 0.2

@onready var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var probes = $ProbeContainer.get_children()
@onready var water = $"../Water"

var p1_data
var p2_data

var p1_score = 0
var p2_score = 0

func _ready() -> void:
	pass
	
func _physics_process(delta: float) -> void:
	submerged = false
	var depth = 0
	var w1_speed = 0
	var w2_speed = 0	
	
	p1_data = RelicHelper.map(get_parent().get_p1_data(), 0, 1023, 0.0, 10.0)
	p2_data = RelicHelper.map(get_parent().get_p2_data(), 0, 1023, 0.0, 10.0)
	
	#print(player_data[0])
	#print("...")
	
	for p in probes:
		depth = water.get_height(p.global_position) - p.global_position.y
		
		#if depth > 0:
			#depth = 0.0
		
		if p.global_position.y < depth:
			submerged = true
			w1_speed = water.get_wave_1_speed(p.global_position)
			w2_speed = water.get_wave_2_speed(p.global_position)
			#apply_force(Vector3.DOWN * gravity, p.global_position - global_position)
			apply_force(Vector3.UP * float_force * gravity * depth, p.global_position - global_position)
			apply_force(Vector3.RIGHT * speed_multiplier * (p1_data + w1_speed), p.global_position - global_position)
			apply_force(Vector3.LEFT * speed_multiplier * (p2_data + w2_speed), p.global_position - global_position)
			#apply_force(Vector3.RIGHT * speed_multiplier * w1_speed, p.global_position - global_position)
			#apply_force(Vector3.LEFT * speed_multiplier * w2_speed, p.global_position - global_position)
		#DebugDraw2D.set_text("{0} @ {1}".format([depth, speed]), 0)
	
	#DebugDraw2D.set_text("{0} : {1}".format([probes[0].global_position.y, depth]), 0)
	#if self.global_position.x > 10 || self.global_position.x < -10:
		#self.global_position.x = 0
		
	if self.global_position.x > 10:
		self.global_position.x = -9
		p1_score += 1
		$"../CanvasLayer/CenterPanel/P1ScoreText".text = str(p1_score)
	elif self.global_position.x < -10:
		self.global_position.x = 9
		p2_score += 1
		$"../CanvasLayer/CenterPanel/P2ScoreText".text = str(p2_score)
	
	DebugDraw2D.set_text("P1:{0}|P2:{1}|Depth:{2}|Speed:{3}".format([p1_data, p2_data, depth, w1_speed]), null, 0, Color.RED, 0)
	#DebugDraw2D.set_text("P1:{0}|P2:{1}|Depth:{2}|Speed:{3}".format([probes[0].global_position.y, probes[2].global_position.y, depth, w1_speed]), null, 0, Color.RED, 0)
	
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
