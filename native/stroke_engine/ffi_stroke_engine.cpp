#include "pressure_interpolation.h"
#include "eraser_algorithms.h"
#include <stdint.h>

extern "C" {

float ffi_interpolate_pressure(float* points, int count, float t) {
    return interpolate_pressure(points, count, t);
}

void ffi_erase_pixels(uint8_t* image, int width, int height, int x, int y, int radius) {
    erase_pixels(image, width, height, x, y, radius);
}

void ffi_erase_stroke(int* stroke_ids, int count, int target_id) {
    erase_stroke(stroke_ids, count, target_id);
}

}
