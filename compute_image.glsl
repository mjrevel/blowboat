#[compute]
#version 450

float vertices[] = {
	-0.5f, -0.5f, 0.0f,
	 0.5f, -0.5f, 0.0f,
	 0.0f,  0.5f, 0.0f
};  

// Instruct the GPU to use 8x8x1 = 64 local invocations per workgroup.
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(r8, binding = 0) restrict uniform image2D heightmap;

layout(rgba8, binding = 1) restrict readonly uniform image2D gradient;

// The code we want to execute in each invocation
void main() {
	// gl_GlobalInvocationID.x uniquely identifies this invocation across all work groups
	my_data_buffer.data[gl_GlobalInvocationID.x] *= 1.0;
}
