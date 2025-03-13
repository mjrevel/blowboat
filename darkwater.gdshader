shader_type spatial;
render_mode blend_mul; // darken whatever texture you already have set up on the mesh

//I know some of you didn't read the description, so here's what you need to know:
	// Made in GODOT 4.3.
	// Designed to be used in the "MATERIAL_OVERLAY" property on a mesh instance. That way you can do your usual texturing underneath it.
	// The math is whatever I could get to work. I'm sure there's a better way to use it. Feel free to mess around with it.


//Variable declarations.
uniform float water_sharpness: hint_range(0.0, 1.0) = 0.45;
uniform float height_modifier = 2.0;
uniform vec3 darkening_color : source_color = vec3(0.1,0.2,0.2);
uniform vec3 source_color_modifier : source_color = vec3(1.,1.,1.);
uniform float max_metallic: hint_range(0.0, 1.0) = 1.0;
uniform float max_specular: hint_range(0.0, 1.0) = 1.0;

varying vec3 pos;


//Find the Y POSITION in the world (water is usually flat).
void vertex() {
    pos = mat3(MODEL_MATRIX) * -VERTEX;
    pos = pos - NODE_POSITION_WORLD;
}

//use the position to determine the color change, the metallic, and the specular.
void fragment() {
	ALBEDO = mix(vec3(1.,1.,1.), vec3(0.1,0.2,0.2), clamp(pow(pos.y+height_modifier, water_sharpness), 0., 1.));
	METALLIC = clamp(pow(pos.y+height_modifier, water_sharpness), 0., 1.);
	SPECULAR = clamp(pow(pos.y+height_modifier, water_sharpness), 0., 1.);
}