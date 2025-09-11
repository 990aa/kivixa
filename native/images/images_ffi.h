#pragma once

#ifdef __cplusplus
extern "C" {
#endif

// Returns hash as 64-bit int
uint64_t compute_image_hash(const unsigned char* data, int length);

// Generates thumbnail, returns pointer to buffer, sets out_size
void* generate_thumbnail(const unsigned char* data, int width, int height, int thumb_width, int thumb_height, int* out_size);

// Applies transformation matrix to image data
void* transform_image(const unsigned char* data, int width, int height, const float* matrix, int* out_size);

#ifdef __cplusplus
}
#endif
