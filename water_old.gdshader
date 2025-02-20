shader_type spatial;

uniform float height_scale = 0.1;
uniform float wave_time = 0;
uniform float w = 0.5;

uniform float left_speed = 10.0;
uniform bool left_toggle = false;

// Spring params
uniform float k = 5.0; // spring constant
uniform float mass = 1.0;
uniform float dr = 0.5; // dampening ratio
uniform float x0 = 1.0; // init offset
uniform float v0 = 1.0; // init velocity

// varying simulation variables
varying float pos; // current pos of spring arm
varying float vel; // current velocity of spring arm
varying float omega_0; // natural angular freq
varying float omega_d; // damped angular freq

varying vec3 world_pos;
varying float height;
varying float sin_force;

varying float L;

uniform float time;
uniform float wave_speed; // Speed of the wave (c)
uniform float boundary_left; // Boundary condition f1(t)
uniform float boundary_right; // Boundary condition f2(t)
uniform vec2 resolution; // Resolution of the string (number of points)

uniform sampler2D prev_state; // Texture storing the previous state
uniform sampler2D curr_state; // Texture storing the current state

float f1(float t) {
	return sin(t);
}

float f2(float t) {
	return cos(t);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	// init params
	omega_0 = sqrt(k/mass);
	omega_d = omega_0 * sqrt(1.0 - dr * dr);
	pos = x0;
	vel = v0;

	pos = x0 * exp(-dr * omega_0 * TIME) * cos(omega_d * TIME);

	if(left_toggle == false) {
		sin_force = 0.0;

		 sin_force = sin(world_pos.x * w + TIME * 2.0 / w);
	} else {
		sin_force = 1.0;
	}
	height = (-9.8 + sin_force)/k;

	while(height > 3.0) {

	}

	VERTEX.y = pos;
	//VERTEX.y += height * height_scale;
}
//void vertex() {
	//// Called for every vertex the material is visible on.
	////COLOR = vec4(vec3(1, 1, 0), 1);
	//world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	////height = sin(1.0 * w + world_pos.x * sin(TIME));
	////height = sin(world_pos.x * w + TIME * 2.0 / w);
	//
	//L = left_speed;
	//
	//height = sin(world_pos.x * sqrt(9.8 * (2.0 * PI)/L) + TIME * 2.0 / w);
//
	//VERTEX.y += height * height_scale;
//}

void fragment() {
	ALBEDO = vec3(0.2, 0.2, 0.8);
	ALPHA = 0.9;
	// Called for every pixel the material is visible on.
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
