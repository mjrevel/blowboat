extends MeshInstance3D

@export var wave_speed = 1.0
@export var resolution = Vector2(1024, 1024)

var prev_state: ImageTexture
var curr_state: ImageTexture
var shader_material
var time = 0.0

# Create a local rendering device.
var rd := RenderingServer.create_local_rendering_device()

# Load GLSL shader
var shader_file := load("res://compute_test.glsl")
var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
var shader := rd.shader_create_from_spirv(shader_spirv)

# Prepare our data. We use floats in the shader, so we need 32 bit.
var input := PackedFloat32Array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
var input_bytes := input.to_byte_array()

# Create a storage buffer that can hold our float values.
# Each float has 4 bytes (32 bit) so 10 x 4 = 40 bytes
var buffer := rd.storage_buffer_create(input_bytes.size(), input_bytes)

func create_texture():
	var tex = ImageTexture.new()
	tex.create(int(resolution.x), int(resolution.y), Image.FORMAT_R8)
	return tex
	
func update_textures(boundary_left: float, boundary_right: float):
	var prev_img = prev_state.get_image()
	var curr_img = curr_state.get_image()

	var new_img = Image.create(int(resolution.x), int(resolution.y), false, Image.FORMAT_RF)

	for x in range(int(resolution.x)):
		if x == 0:
			# Apply left boundary condition
			new_img.set_pixel(x, 0, Color(boundary_left, 0, 0))
		elif x == resolution.x - 1:
			# Apply right boundary condition
			new_img.set_pixel(x, 0, Color(boundary_right, 0, 0))
		else:
			# Compute new displacement using the wave equation
			var u_left = prev_img.get_pixel(x - 1, 0).r
			var u_right = prev_img.get_pixel(x + 1, 0).r
			var u_curr = curr_img.get_pixel(x, 0).r

			var u_new = 2.0 * u_curr - prev_img.get_pixel(x, 0).r + wave_speed * wave_speed * (u_right - 2.0 * u_curr + u_left)
				
			new_img.set_pixel(x, 0, Color(u_new))

	# Update the texture with new state
	prev_state = ImageTexture.create_from_image(curr_img)
	curr_state = ImageTexture.create_from_image(new_img)
	
func swap_textures():
	var temp = prev_state
	prev_state = curr_state
	curr_state = temp
	
func initialize_textures() -> Image:
	var img = Image.create(int(resolution.x), int(resolution.y), false, Image.FORMAT_R8)
	#img.fill(Color(0,1,0))
	
	return img
	
# Called when the node enters the scene tree for the first time.
func _ready():
	shader_material = mesh.surface_get_material(0)
	prev_state = ImageTexture.create_from_image(initialize_textures())
	curr_state = ImageTexture.create_from_image(initialize_textures())

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
	
func _physics_process(delta: float) -> void:
	pass
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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time += delta
	var boundary_left = sin(time * 100.0) # Example: f1(t) = sin(t)
	var boundary_right = cos(time) # Example: f2(t) = cos(t)
	
	update_textures(boundary_left, boundary_right)

	shader_material.set_shader_parameter("time", time)
	shader_material.set_shader_parameter("wave_speed", wave_speed)
	shader_material.set_shader_parameter("resolution", resolution)
	shader_material.set_shader_parameter("prev_state", prev_state)
	shader_material.set_shader_parameter("curr_state", curr_state)
	shader_material.set_shader_parameter("boundary_left", boundary_left)
	shader_material.set_shader_parameter("boundary_right", boundary_right)
	
	swap_textures()

func get_height(world_position: Vector3) -> float:
	return 1
	#var uv_x = wrapf(world_position.x / noise_scale + time * wave_speed, 0, 1)
	#var uv_y = wrapf(world_position.z / noise_scale + time * wave_speed, 0, 1)
#
	#var pixel_pos = Vector2(uv_x * noise.get_width(), uv_y * noise.get_height())
	#return global_position.y + noise.get_pixelv(pixel_pos).r * height_scale;
