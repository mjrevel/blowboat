extends MeshInstance3D

@export var wave_speed = 1.0
@export var resolution = Vector2(1024, 1024)

var exp1
var exp2

var prev_state: ImageTexture
var curr_state: ImageTexture
var shader_material: ShaderMaterial
var frame_time = 0.0
var phys_time = 0.0
var left_height_map: Array[int]
var right_height_map: Array[float]
var height_map: Array[float]
var formula_map: Array[float]
var vertex_index: int = 0
var dimensions: Vector2
var wave_index: int = 1

var wave_1_index: int = 1
var wave_2_index: int = 1
@onready var wave_size: int = 100;

var decay_rate: float

var wave_1_amp_map: Array[float]
var wave_1_speed_map: Array[float]
var wave_1_num_map: Array[float]
var wave_1_angfreq_map: Array[float]

var init_wave_1_amp: float = 0.5
var init_wave_1_speed: float = 0.5
var init_wave_1_num: float = 0.5
var init_wave_1_angfreq: float = 3.0

var wave_2_amp_map: Array[float]
var wave_2_speed_map: Array[float]
var wave_2_num_map: Array[float]
var wave_2_angfreq_map: Array[float]

var init_wave_2_amp: float = 0.5
var init_wave_2_speed: float = 0.5
var init_wave_2_num: float = 0.5
var init_wave_2_angfreq: float = 3.0

var wave_combined_map: Array[float]
var cpu_calc: bool = false

var wave_launch: bool = false
var wave_delay: int = 0

# Create a local rendering device.
var rd := RenderingServer.create_local_rendering_device()

func initialize_textures() -> Image:
	var img = Image.create(int(resolution.x), int(resolution.y), false, Image.FORMAT_R8)
	#img.fill(Color(0,1,0))
	
	return img
	
func prepare_image() -> ImageTexture:
	# Create image from noise.
	var heightmap
	#var heightmap := noise.get_image(po2_dimensions, po2_dimensions, false, false)

	# Create ImageTexture to display original on screen.
	var clone := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	clone.set_pixel(15, 15, Color.RED)
	clone.set_pixel(14, 14, Color.RED)
	#clone.copy_from(heightmap)
	clone.resize(512, 512, Image.INTERPOLATE_NEAREST)
	var clone_tex := ImageTexture.create_from_image(clone)
	#heightmap_rect.texture = clone_tex

	return clone_tex

# Compute shader code
func shader_load_math() -> RID:
	# Load GLSL shader
	var shader_file := load("res://compute_image.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	var shader := rd.shader_create_from_spirv(shader_spirv)
	
	return shader

func shader_math_compute(shader: RID):
	# Prepare our data. We use floats in the shader, so we need 32 bit.
	var input := PackedFloat32Array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
	var input_bytes := input.to_byte_array()

	# Create a storage buffer that can hold our float values.
	# Each float has 4 bytes (32 bit) so 10 x 4 = 40 bytes
	var buffer := rd.storage_buffer_create(input_bytes.size(), input_bytes)
	
	# Create a uniform to assign the buffer to the rendering device
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform.binding = 0 # this needs to match the "binding" in our shader file
	uniform.add_id(buffer)
	var uniform_set := rd.uniform_set_create([uniform], shader, 0) # the last parameter (the 0) needs to match the "set" in our shader file

	# Create a compute pipeline
	var pipeline := rd.compute_pipeline_create(shader)
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, 1, 1, 1)
	rd.compute_list_end()
	
	# Submit to GPU and wait for sync
	rd.submit()
	rd.sync()
	
		# Read back the data from the buffer
	var output_bytes := rd.buffer_get_data(buffer)
	var output := output_bytes.to_float32_array()
	print("Input: ", input)
	print("Output: ", output)

# Wave dissipation over time
func wave_lerp(value: float, stop_at: float) -> float:
	var result = stop_at
	
	if value > stop_at:
		result = value
	else:
		result = stop_at
	
	return result

#func cpu_wave_calc():

func wave_data(delta: float):
	decay_rate = .1
	
	if wave_launch == true:
		wave_1_amp_map[0] = init_wave_1_amp
		wave_1_speed_map[0] = init_wave_1_speed
		wave_1_num_map[0] = init_wave_1_num
		wave_1_angfreq_map[0] = init_wave_1_angfreq
		
		wave_2_amp_map[wave_size - 1] = init_wave_2_amp
		wave_2_speed_map[wave_size - 1] = init_wave_2_speed
		wave_2_num_map[wave_size - 1] = init_wave_2_num
		wave_2_angfreq_map[wave_size - 1] = init_wave_2_angfreq
		
		wave_delay += 1
		
		#if wave_delay == 120:
			#wave_launch = false
			#print("wave disabled")
			#wave_delay = 0
	else:
		wave_1_amp_map[0] = 0
		wave_1_speed_map[0] = 0
		wave_1_num_map[0] = 0
		wave_1_angfreq_map[0] = 0
		
		wave_2_amp_map[wave_size - 1] = 0
		wave_2_speed_map[wave_size - 1] = 0
		wave_2_num_map[wave_size - 1] = 0
		wave_2_angfreq_map[wave_size - 1] = 0
		
		#wave_1_amp_map[0] = wave_lerp(wave_1_amp_map[0] - delta * decay_rate, 0)
		#wave_1_speed_map[0] = wave_lerp(wave_1_speed_map[0] - delta * decay_rate, 0)
		#wave_1_num_map[0] = wave_lerp(wave_1_num_map[0] - delta * decay_rate, 0)
		#wave_1_angfreq_map[0] = wave_lerp(wave_1_angfreq_map[0] - delta * .4, 0)
		#
		#wave_2_amp_map[wave_size - 1] = wave_lerp(wave_2_amp_map[wave_size - 1] - delta * .1, 0)
		#wave_2_speed_map[wave_size - 1] = wave_lerp(wave_2_speed_map[wave_size - 1] - delta * decay_rate, 0)
		#wave_2_num_map[wave_size - 1] = wave_lerp(wave_2_num_map[wave_size - 1] - delta * decay_rate, 0)
		#wave_2_angfreq_map[wave_size - 1] = wave_lerp(wave_2_angfreq_map[wave_size - 1] - delta * .4, 0)
	
	if wave_index > 0:
		wave_1_amp_map[wave_index] = wave_1_amp_map[wave_index - 1]
		wave_1_speed_map[wave_index] = wave_1_speed_map[wave_index - 1]
		wave_1_num_map[wave_index] = wave_1_num_map[wave_index - 1]
		wave_1_angfreq_map[wave_index] = wave_1_angfreq_map[wave_index - 1]
	
	if wave_2_index < (wave_size - 1):
		wave_2_amp_map[wave_2_index] = wave_2_amp_map[wave_2_index + 1]
		wave_2_speed_map[wave_2_index] = wave_2_speed_map[wave_2_index + 1]
		wave_2_num_map[wave_2_index] = wave_2_num_map[wave_2_index + 1]
		wave_2_angfreq_map[wave_2_index] = wave_2_angfreq_map[wave_2_index + 1]
		
	if wave_index < wave_size - 1:
		wave_index += 1
	else:
		wave_index = 1
		
	if wave_2_index > 0:
		wave_2_index -= 1
	else:
		wave_2_index = wave_size - 2;
			
	#print(height_map)

# Need to disable gshader creating sin wave if using this code
func cpu_render(time: float):
	var wave_1: float;
	var wave_2: float;
	
	for i in range(0, wave_size):
		wave_1 = wave_1_amp_map[i] * sin(wave_1_num_map[i] * i + wave_1_angfreq_map[i] * time)
		wave_2 = wave_2_amp_map[i] * sin(wave_2_num_map[i] * i + wave_2_angfreq_map[i] * time)
	
		wave_combined_map[i] = wave_1 + wave_2

# Called when the node enters the scene tree for the first time.
func _ready():
	shader_material = mesh.surface_get_material(0)
	
	# ---- Compute shader code ----
	#var shader = shader_load_math()
	#shader_math_compute(shader)
	# ---- Compute shader code END ----
	
	for i in range(0, wave_size):
		left_height_map.append(0)
		right_height_map.append(0)
		height_map.append(i)
		formula_map.append(0)
		
		wave_1_amp_map.append(0)
		wave_1_speed_map.append(0)
		wave_1_num_map.append(0)
		wave_1_angfreq_map.append(0)
		
		wave_2_amp_map.append(0)
		wave_2_speed_map.append(0)
		wave_2_num_map.append(0)
		wave_2_angfreq_map.append(0)
		
		wave_combined_map.append(0)
		
	wave_2_index = wave_size - 2;
		
	dimensions = mesh.get_size()
	
	exp1 = $"../CanvasLayer/LeftPanel/Expression"
	exp2 = $"../CanvasLayer/RightPanel/Expression2"
	update_display_params()
	
func _physics_process(delta: float) -> void:
	phys_time += delta
	
	DebugDraw2D.set_text("Wave Height: {0}".format([wave_1_amp_map[50]]))

	
	#if not is_on_floor():
		#velocity += get_gravity() * delta
		
	
	#if Input.is_action_pressed("ui_up"):
		#left_speed += 1.0
	#elif Input.is_action_pressed("ui_down"):
		#left_speed -= 1.0
	#elif Input.is_action_just_pressed("ui_left"):
		#left_toggle = !left_toggle
		#
	#material.set_shader_parameter("left_speed", left_speed)
	#material.set_shader_parameter("left_toggle", left_toggle)
	wave_data(delta)
	if cpu_calc == true:
		cpu_render(phys_time)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	frame_time += delta
	
	#for i in height_map.size():
		##height_map[i] = 3*sin(.5 * i - 5 * time) + 5*sin(.2 * i - 3 * -time)
		#height_map[i] = 3*sin(.5 * i - 5 * -time) + 5*sin(.2 * i - 3 * time)
		
	left_height_map[0] = 1
	right_height_map[0] = 5*sin(.2 * 0 - 3 * frame_time)
	
	if wave_index > 0:
		left_height_map[wave_index] = left_height_map[wave_index - 1]
	
#	use different wave equation based on initial wave parameters
	match left_height_map[wave_index]:
		0:
			height_map[wave_index] = 5*sin(.2 * 0 - 3 * frame_time)
		1:
			height_map[wave_index] = 6*sin(.3 * 0 - 4 * frame_time)
	
	#height_map[wave_index] = left_height_map[wave_index] + right_height_map[wave_index]
	#height_map[wave_index] = left_height_map[wave_index]
	

	
	prev_state = prepare_image() # update image on the cpu every render
	
	shader_material.set_shader_parameter("wave_1_amp", wave_1_amp_map)
	shader_material.set_shader_parameter("wave_1_speed", wave_1_speed_map)
	shader_material.set_shader_parameter("wave_1_num", wave_1_num_map)
	shader_material.set_shader_parameter("wave_1_angfreq", wave_1_angfreq_map)
	
	shader_material.set_shader_parameter("wave_2_amp", wave_2_amp_map)
	shader_material.set_shader_parameter("wave_2_speed", wave_2_speed_map)
	shader_material.set_shader_parameter("wave_2_num", wave_2_num_map)
	shader_material.set_shader_parameter("wave_2_angfreq", wave_2_angfreq_map)
	
	shader_material.set_shader_parameter("wave_combined", wave_combined_map)
	shader_material.set_shader_parameter("cpu_calc", cpu_calc)
	
	shader_material.set_shader_parameter("dimensions", dimensions)
	shader_material.set_shader_parameter("height_map", height_map)
	shader_material.set_shader_parameter("wave_time", phys_time)
	shader_material.set_shader_parameter("wave_speed", wave_speed)
	shader_material.set_shader_parameter("resolution", resolution)
	shader_material.set_shader_parameter("prev_state", prev_state)
	shader_material.set_shader_parameter("curr_state", curr_state)

func wave_calc(amp: float, pos: float, speed: float, num: float, freq: float, time: float) -> float:
	return amp * sin(num * pos - freq * time)

# Get wave amplitude, used in player code
# this works as long as water is in center of world
func get_height(world_position: Vector3) -> float:
	var calc_index = int(floor(RelicHelper.map(
						world_position.x
						, -dimensions.x
						, dimensions.x
						, 0.0, wave_size - 1)))
	
	var wave_1_height = wave_calc(wave_1_amp_map[calc_index]
						, world_position.x
						, wave_1_speed_map[calc_index]
						, wave_1_num_map[calc_index]
						, wave_1_angfreq_map[calc_index]
						, phys_time)
						
	var wave_2_height = wave_calc(wave_2_amp_map[calc_index]
						, world_position.x
						, wave_2_speed_map[calc_index]
						, wave_2_num_map[calc_index]
						, wave_2_angfreq_map[calc_index]
						, -phys_time)
	#var wave_height = wave_1_amp_map[calc_index] + wave_2_amp_map[calc_index]
	#DebugDraw2D.set_text("get_heght: {0}".format([wave_height]))
	#amp * sin(num * pos + freq * time);
	
	return wave_1_height + wave_2_height
							
	
	#var uv_x = wrapf(world_position.x / noise_scale + time * wave_speed, 0, 1)
	#var uv_y = wrapf(world_position.z / noise_scale + time * wave_speed, 0, 1)
#
	#var pixel_pos = Vector2(uv_x * noise.get_width(), uv_y * noise.get_height())
	#return global_position.y + noise.get_pixelv(pixel_pos).r * height_scale;

# Get wave angular freq, used in player code
func get_wave_1_speed(world_position: Vector3) -> float:
	var wave_1 = wave_1_angfreq_map[int(floor(RelicHelper.map(
							world_position.x
							, -dimensions.x
							, dimensions.x
							, 0.0, wave_size - 1)))]
							
	#DebugDraw2D.set_text("{0} @ {1}".format([wave_1, wave_2]))
	
	return wave_1
	
func get_wave_2_speed(world_position: Vector3) -> float:
	var wave_2 = wave_2_angfreq_map[int(floor(RelicHelper.map(
							world_position.x
							, -dimensions.x
							, dimensions.x
							, 0.0, wave_size - 1)))]
							
	#DebugDraw2D.set_text("{0} @ {1}".format([wave_1, wave_2]))
	
	return wave_2

func _on_button_pressed() -> void:
	init_wave_1_amp = randf_range(0.0, 1.0)
	init_wave_1_speed = randf_range(0.0, 5.0)
	init_wave_1_num = randf_range(0.0, 1.0)
	init_wave_1_angfreq = randf_range(0.0, 5.0)
	
	init_wave_2_amp = randf_range(0.0, 1.0)
	init_wave_2_speed = randf_range(0.0, 5.0)
	init_wave_2_num = randf_range(0.0, 1.0)
	init_wave_2_angfreq = randf_range(0.0, 5.0)
	
	$"../CanvasLayer/LeftPanel/Expression".update_equation(init_wave_1_amp
											, init_wave_1_num
											, init_wave_2_angfreq)


func _on_button_2_pressed() -> void:
	init_wave_1_amp = 1.0
	init_wave_1_speed = 1.0
	init_wave_1_num = 1.0
	init_wave_1_angfreq = 1.0
	
	init_wave_2_amp = 1.0
	init_wave_2_speed = 1.0
	init_wave_2_num = 1.0
	init_wave_2_angfreq = 1.0


func _on_button_3_pressed() -> void:
	init_wave_1_amp = 1.0
	init_wave_1_speed = 1.0
	init_wave_1_num = 1.0
	init_wave_1_angfreq = 1.0
	
	init_wave_2_amp = 1.0
	init_wave_2_speed = 1.0
	init_wave_2_num = 1.0
	init_wave_2_angfreq = 5.0

func _on_button_4_pressed() -> void:
	wave_launch = true
	#if wave_launch == true:
		#wave_launch = false
	#else:
		#wave_launch = true
	#DebugDraw2D.set_text("Wave: {0}".format([wave_launch]))
	
func _on_reset_btn_pressed() -> void:
	#init_wave_1_amp = 0.5
	#init_wave_1_speed = 0.5
	#init_wave_1_num = 0.5
	#init_wave_1_angfreq = 3.0
	#
	#init_wave_2_amp = 0.5
	#init_wave_2_speed = 0.5
	#init_wave_2_num = 0.5
	#init_wave_2_angfreq = 3.0
	
	$"../CanvasLayer/CenterPanel/P1ScoreText".text = str(0)
	$"../CanvasLayer/CenterPanel/P2ScoreText".text = str(0)
	wave_launch = false
	
	await get_tree().create_timer(3).timeout
	$"../Player".global_position.x = 0

func _on_amp_up_btn_pressed() -> void:
	var prev_val = init_wave_1_amp
	prev_val = float(prev_val) + .1
	prev_val = snapped(clampf(prev_val, 0, 1), .1)
	init_wave_1_amp = prev_val
	
	update_display_params()

func _on_amp_dwn_btn_pressed() -> void:
	var prev_val = init_wave_1_amp
	prev_val = float(prev_val) - .1
	prev_val = snapped(clampf(prev_val, 0, 1), .1)
	init_wave_1_amp = prev_val
	
	update_display_params()

func _on_wl_up_btn_pressed() -> void:
	var prev_val = init_wave_1_num
	prev_val = float(prev_val) + .1
	prev_val = snapped(clampf(prev_val, 0, 1), .1)
	init_wave_1_num = prev_val
	
	update_display_params()

func _on_wl_dwn_btn_pressed() -> void:
	var prev_val = init_wave_1_num
	prev_val = float(prev_val) - .1
	prev_val = snapped(clampf(prev_val, 0, 1), .1)
	init_wave_1_num = prev_val
	
	update_display_params()

func _on_ang_up_btn_pressed() -> void:
	var prev_val = init_wave_1_angfreq
	prev_val = float(prev_val) + .2
	prev_val = snapped(clampf(prev_val, 0, 5), .1)
	init_wave_1_angfreq = prev_val
	
	update_display_params()

func _on_ang_dwn_btn_pressed() -> void:
	var prev_val = init_wave_1_angfreq
	prev_val = float(prev_val) - .2
	prev_val = snapped(clampf(prev_val, 0, 5), .1)
	init_wave_1_angfreq = prev_val
	
	update_display_params()

func _on_amp2_up_btn_pressed() -> void:
	var prev_val = init_wave_2_amp
	prev_val = float(prev_val) + .1
	prev_val = snapped(clampf(prev_val, 0, 1), .1)
	init_wave_2_amp = prev_val
	
	update_display_params()

func _on_amp2_dwn_btn_pressed() -> void:
	var prev_val = init_wave_2_amp
	prev_val = float(prev_val) - .1
	prev_val = snapped(clampf(prev_val, 0, 1), .1)
	init_wave_2_amp = prev_val
	
	update_display_params()

func _on_wl2_up_btn_pressed() -> void:
	var prev_val = init_wave_2_num
	prev_val = float(prev_val) + .1
	prev_val = snapped(clampf(prev_val, 0, 1), .1)
	init_wave_2_num = prev_val
	
	update_display_params()

func _on_wl2_dwn_btn_pressed() -> void:
	var prev_val = init_wave_2_num
	prev_val = float(prev_val) - .1
	prev_val = snapped(clampf(prev_val, 0, 1), .1)
	init_wave_2_num = prev_val
	
	update_display_params()

func _on_ang2_up_btn_pressed() -> void:
	var prev_val = init_wave_2_angfreq
	prev_val = float(prev_val) + .2
	prev_val = snapped(clampf(prev_val, 0, 5), .1)
	init_wave_2_angfreq = prev_val
	
	update_display_params()

func _on_ang2_dwn_btn_pressed() -> void:
	var prev_val = init_wave_2_angfreq
	prev_val = float(prev_val) - .2
	prev_val = snapped(clampf(prev_val, 0, 5), .1)
	init_wave_2_angfreq = prev_val
	
	update_display_params()

func update_display_params():
	$"../CanvasLayer/LeftPanel/AmpContainer/RichTextLabel2".text = str(init_wave_1_amp)
	$"../CanvasLayer/LeftPanel/WaveLengthContainer/RichTextLabel2".text = str(init_wave_1_num)
	$"../CanvasLayer/LeftPanel/AngFreqContainer/RichTextLabel2".text = str(init_wave_1_angfreq)
	
	$"../CanvasLayer/RightPanel/AmpContainer2/RichTextLabel2".text = str(init_wave_2_amp)
	$"../CanvasLayer/RightPanel/WaveLengthContainer2/RichTextLabel2".text = str(init_wave_2_num)
	$"../CanvasLayer/RightPanel/AngFreqContainer2/RichTextLabel2".text = str(init_wave_2_angfreq)
	
	exp1.update_equation(init_wave_1_amp, init_wave_1_num, init_wave_1_angfreq)
	exp2.update_equation(init_wave_2_amp, init_wave_2_num, init_wave_2_angfreq) #  # Replace with function body.
