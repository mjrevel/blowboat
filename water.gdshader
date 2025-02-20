shader_type spatial;

varying vec3 world_pos;
varying float height;
uniform float w = 0.5;

uniform float time;
uniform float boundary_left; // Boundary condition f1(t)
uniform float boundary_right; // Boundary condition f2(t)
uniform vec2 resolution; // Resolution of the string (number of points)

uniform sampler2D prev_state; // Texture storing the previous state
uniform sampler2D curr_state; // Texture storing the current state

uniform sampler2D wave; // get wave texture
uniform float wave_time = 0;
uniform float wave_speed = 2.0;
uniform float noise_scale = 10.0;
uniform float height_scale = 0.001; // .15
const int SUBDIV = 100;
uniform float height_map[SUBDIV]; // cannot set default values to uniform arrays
uniform int vertex_index;
varying vec3 clip_space;
varying vec3 local_pos;
uniform vec2 dimensions;

float map(float x, float in_min, float in_max, float out_min, float out_max) {
	return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}

void vertex() {
	//POSITION = vec4();
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	local_pos = (MODEL_MATRIX * vec4(VERTEX, 100.0)).xyz;
	clip_space = (MODEL_MATRIX * VIEW_MATRIX * PROJECTION_MATRIX * vec4(VERTEX, 1.0)).xyz;
	int pos = int(floor(world_pos.x * float(SUBDIV)));
	
	height = texture(wave, world_pos.xz / noise_scale + wave_time * wave_speed).r;
	//VERTEX.y += height * height_scale;-10
	VERTEX.y += height_map[int(floor(map(VERTEX.x, -dimensions.x, dimensions.x, 0.0, 99.0)))] * 0.02;
	//VERTEX.y += height_map[int(local_pos.x)] * 0.02;

	//if(iter >= 200) {
		//iter = 0;
	//} else {
		//iter++;
	//}
}

void fragment() {
	ALBEDO = vec3(0.2, 0.2, 0.8);
	ALPHA = 0.9;
	// Called for every pixel the material is visible on.
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
