shader_type spatial;

varying vec3 world_pos;
varying float height;
uniform float w = 0.5;

uniform vec2 resolution; // Resolution of the string (number of points)

uniform sampler2D prev_state; // Texture storing the previous state
uniform sampler2D curr_state; // Texture storing the current state

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

uniform float wave_time = 0;
varying float wave_result;

//Variable declarations.
uniform float water_sharpness: hint_range(0.0, 1.0) = 0.45;
uniform float height_modifier = 1.0;
uniform vec3 darkening_color : source_color = vec3(0.1,0.2,0.2);
uniform vec3 source_color_modifier : source_color = vec3(1.,1.,1.);
uniform float max_metallic: hint_range(0.0, 1.0) = 1.0;
uniform float max_specular: hint_range(0.0, 1.0) = 1.0;

varying vec3 pos;

float map(float x, float in_min, float in_max, float out_min, float out_max) {
	return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}

float wave_data(float amp, float ppos, float speed, float num, float freq, float time) {
	return amp * sin(num * ppos + freq * time);
}

int vertex_to_index(float position, float dimension) {
	return int(floor(map(position, -dimension, dimension, 0.0, float(SUBDIV - 1))));
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
		wave_1 = wave_data(wave_1_amp[index_pos], VERTEX.x, wave_1_speed[index_pos], wave_1_num[index_pos], wave_1_angfreq[index_pos], TIME);
		wave_2 = wave_data(wave_2_amp[index_pos], VERTEX.x, wave_2_speed[index_pos], wave_2_num[index_pos], wave_2_angfreq[index_pos], -TIME);
	} else {
		wave_1 = wave_combined[index_pos];
		wave_2 = 0.0; // Waves are combined so no need for this result
	}

	VERTEX.y += wave_1 + wave_2;
	
    pos = mat3(MODEL_MATRIX) * -VERTEX;
    pos = pos - NODE_POSITION_WORLD;
	
	//VERTEX.y += wave_data(3.0, VERTEX.x, 1.0, 0.3, 3.0, TIME);



	//VERTEX.y += height_map[int(local_pos.x)] * 0.02;

	//if(iter >= 200) {
		//iter = 0;
	//} else {
		//iter++;
	//}
}

void fragment() {
	ALBEDO = mix(vec3(1.,1.,1.), vec3(0.1,0.2,0.6), clamp(pow(pos.y+height_modifier, water_sharpness), 0.9, 1.));
	//METALLIC = clamp(pow(pos.y+height_modifier, water_sharpness), 0., 1.);
	//SPECULAR = clamp(pow(pos.y+height_modifier, water_sharpness), 0., 1.);
	
	//ALBEDO = vec3(0.2, 0.2, 0.8);
	//ALPHA = 0.9;
	// Called for every pixel the material is visible on.
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
