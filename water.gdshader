shader_type spatial;
render_mode cull_disabled;

varying vec3 world_pos;
uniform float w = 0.5;

uniform sampler2D wave; // get wave texture
uniform float noise_scale = 10.0;
uniform float height_scale = 0.001; // .15
const int SUBDIV = 100;
uniform float height_map[SUBDIV]; // cannot set default values to uniform arrays
uniform int vertex_index;
varying vec3 clip_space;
varying vec3 local_pos;
uniform vec2 dimensions;

//uniform float amplitude = 1.0;
//uniform float wave_speed = 2.0;
//uniform float wave_num = 1.0;
//uniform float ang_freq = 0.2;

uniform float wave_1_amp[SUBDIV];
uniform float wave_1_speed[SUBDIV];
uniform float wave_1_num[SUBDIV];
uniform float wave_1_angfreq[SUBDIV];
uniform float wave_2_amp[SUBDIV];
uniform float wave_2_speed[SUBDIV];
uniform float wave_2_num[SUBDIV];
uniform float wave_2_angfreq[SUBDIV];
uniform float wave_combined[SUBDIV];
uniform bool cpu_calc;

uniform float wave_time;
varying float wave_result;

//Variable declarations.
uniform float speed: hint_range(-1, 1) = 0.0;

uniform sampler2D noise1;
uniform sampler2D noise2;
uniform sampler2D normalmap: hint_normal;

uniform vec4 color: source_color;
uniform vec4 deep_water: source_color;

//depth-fade var
uniform sampler2D DEPTH_TEXTURE: hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;
uniform float beer_law_factor = 2.0;
uniform float _distance = 0.0;

//foam var
uniform vec4 edge_color: source_color;
uniform float edge_scale = 0.25;
uniform float near = 0.1;
uniform float far = 100.0;

// wave var
uniform vec2 wave_strength = vec2(0.5, 0.25);
uniform vec2 wave_frequ = vec2(12.0, 12.0);
uniform vec2 time_factor = vec2(1.0, 2.0);

float map(float x, float in_min, float in_max, float out_min, float out_max) {
	return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}

float wave_data(float amp, float ppos, float sspeed, float num, float freq, float time) {
	return amp * sin(num * ppos + freq * time);
}

int vertex_to_index(float position, float dimension) {
	return int(floor(map(position, -dimension, dimension, 0.0, float(SUBDIV - 1))));
}

float rim(float depth) {
	depth = 2.0 * depth - 1.0;
	return near * far / (far + depth * (near - far));
}

float calc_depth_fade(float depth, mat4 projection_matrix,
						vec4 fragcoord, float beer_factor, float __distance, vec3 vertex) {

	float scene_depth = depth;

	scene_depth = scene_depth * 2.0 - 1.0;
	scene_depth = projection_matrix[3][2] / (scene_depth + projection_matrix[2][2]);
	scene_depth = scene_depth + vertex.z; // z is negative

	// application of beers law
	scene_depth = exp(-scene_depth * beer_factor);

	float screen_depth = fragcoord.z;

	float depth_fade = (scene_depth - screen_depth) / __distance;

	depth_fade = clamp(depth_fade, 0.0, 1.0);

	return depth_fade;
}

void vertex() {
	//POSITION = vec4();
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	local_pos = (MODEL_MATRIX * vec4(VERTEX, 100.0)).xyz;
	clip_space = (MODEL_MATRIX * VIEW_MATRIX * PROJECTION_MATRIX * vec4(VERTEX, 1.0)).xyz;
	//int pos = int(floor(world_pos.x * float(SUBDIV)));

	//height = texture(wave, world_pos.xz / noise_scale + wave_time * wave_speed).r;

	//wave_result = wave_data(amplitude, VERTEX.x, wave_speed, wave_num, ang_freq, TIME);
	//VERTEX.y += height * height_scale;-10
	//VERTEX.y += height_map[int(floor(map(VERTEX.x, -dimensions.x, dimensions.x, 0.0, 99.0)))] * 0.02;
	//VERTEX.y += wave_data(amplitude, VERTEX.x, wave_speed, wave_num, ang_freq, TIME);

	int index_pos = vertex_to_index(VERTEX.x, dimensions.x);

	float wave_1;
	float wave_2;

	if(cpu_calc == false) {
		wave_1 = wave_data(wave_1_amp[index_pos], VERTEX.x, wave_1_speed[index_pos], wave_1_num[index_pos], wave_1_angfreq[index_pos], wave_time);
		wave_2 = wave_data(wave_2_amp[index_pos], VERTEX.x, wave_2_speed[index_pos], wave_2_num[index_pos], wave_2_angfreq[index_pos], -wave_time);
	} else {
		wave_1 = wave_combined[index_pos];
		wave_2 = 0.0; // Waves are combined so no need for this result
	}

	VERTEX.y += wave_1 + wave_2;

	//VERTEX.y += wave_data(3.0, VERTEX.x, 1.0, 0.3, 3.0, TIME);



	//VERTEX.y += height_map[int(local_pos.x)] * 0.02;

	//if(iter >= 200) {
		//iter = 0;
	//} else {
		//iter++;
	//}
}

void fragment() {
	float time = TIME * speed;

	vec3 n1 = texture(noise1, UV + time).rgb;
	vec3 n2 = texture(noise2, UV - time * 0.2).rgb;

	vec2 uv_movement = UV * 4.0;
	uv_movement += TIME * speed * 4.0;

	float sum = (n1.r + n2.r) - 1.0;

	float z_depth = rim(texture(DEPTH_TEXTURE, SCREEN_UV).x);
	float z_pos = rim(FRAGCOORD.z);
	float diff = z_depth - z_pos;

	// depth-fade
	float z_depth_fade = calc_depth_fade(texture(DEPTH_TEXTURE, SCREEN_UV).x, PROJECTION_MATRIX, FRAGCOORD, beer_law_factor, _distance, VERTEX);
	float z_fade = rim(FRAGCOORD.z);
	float fade_diff = z_depth_fade - z_fade;

	vec4 gradientcolor = mix(color, deep_water, z_depth_fade);

	vec2 displacement = vec2(sum * 0.1);
	diff += displacement.x * 70.0;

	vec4 col = mix(edge_color, gradientcolor, step(edge_scale, diff));

	vec4 alpha = texture(SCREEN_TEXTURE, SCREEN_UV + displacement);


	float fin = 0.0;
	if (sum > 0.0 && sum < 0.4) fin = 0.1;
	if (sum > 0.4 && sum < 0.8) fin = 0.0;
	if (sum > 0.8) fin = 1.0;

	// konvertier fin in vec3 um
	ALBEDO = vec3(fin) + mix(alpha.rgb, col.rgb, gradientcolor.a);

	NORMAL = texture(normalmap, uv_movement).rgb;

	ROUGHNESS = 0.9;
}
