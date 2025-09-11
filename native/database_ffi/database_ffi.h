// FFI bindings for vectorized stroke operations and spatial indexing
// This is a C++ header for use with Dart FFI

#ifndef KIVIXA_DATABASE_FFI_H
#define KIVIXA_DATABASE_FFI_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// Vectorized stroke chunk encoding/decoding
void encode_stroke_chunk(const float* points, size_t point_count, uint8_t** out_data, size_t* out_size);
void decode_stroke_chunk(const uint8_t* data, size_t data_size, float** out_points, size_t* out_point_count);

// Spatial index operations
void build_spatial_index(const float* bboxes, size_t count, void** out_index);
void free_spatial_index(void* index);
int query_spatial_index(void* index, float min_x, float min_y, float max_x, float max_y, int* out_ids, size_t max_results);

#ifdef __cplusplus
}
#endif

#endif // KIVIXA_DATABASE_FFI_H
