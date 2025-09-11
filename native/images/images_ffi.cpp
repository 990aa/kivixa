#include "images_ffi.h"
#include <stdint.h>

extern "C" {

uint64_t compute_image_hash(const unsigned char* data, int length) {
    // FNV-1a 64-bit hash
    uint64_t hash = 14695981039346656037ULL;
    for (int i = 0; i < length; ++i) {
        hash ^= data[i];
        hash *= 1099511628211ULL;
    }
    return hash;
}

void* generate_thumbnail(const unsigned char* data, int width, int height, int thumb_width, int thumb_height, int* out_size) {
    // Simple nearest-neighbor downscale, 4 bytes per pixel (RGBA)
    int channels = 4;
    unsigned char* thumb = new unsigned char[thumb_width * thumb_height * channels];
    for (int y = 0; y < thumb_height; ++y) {
        for (int x = 0; x < thumb_width; ++x) {
            int src_x = x * width / thumb_width;
            int src_y = y * height / thumb_height;
            for (int c = 0; c < channels; ++c) {
                thumb[(y * thumb_width + x) * channels + c] = data[(src_y * width + src_x) * channels + c];
            }
        }
    }
    *out_size = thumb_width * thumb_height * channels;
    return thumb;
}

void* transform_image(const unsigned char* data, int width, int height, const float* matrix, int* out_size) {
    // Affine transform (3x3 matrix), output same size, 4 bytes per pixel (RGBA)
    int channels = 4;
    unsigned char* out = new unsigned char[width * height * channels];
    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            // Inverse transform to find source pixel
            float fx = matrix[0] * x + matrix[1] * y + matrix[2];
            float fy = matrix[3] * x + matrix[4] * y + matrix[5];
            int src_x = (int)(fx + 0.5f);
            int src_y = (int)(fy + 0.5f);
            for (int c = 0; c < channels; ++c) {
                if (src_x >= 0 && src_x < width && src_y >= 0 && src_y < height)
                    out[(y * width + x) * channels + c] = data[(src_y * width + src_x) * channels + c];
                else
                    out[(y * width + x) * channels + c] = 0;
            }
        }
    }
    *out_size = width * height * channels;
    return out;
}

}
