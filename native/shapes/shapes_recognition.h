#pragma once

#ifdef __cplusplus
extern "C" {
#endif

// Returns 1 if line, 2 if curve, 0 if not recognized
int recognize_shape(const float* points, int count);

// Generates 3D primitive geometry (returns pointer to buffer, sets out_size)
void* generate_primitive_geometry(const char* type, const float* params, int param_count, int* out_size);

// Creates a parameterized shape (returns pointer to buffer, sets out_size)
void* create_parameterized_shape(const char* type, const float* params, int param_count, int* out_size);

#ifdef __cplusplus
}
#endif
