#include "color_conversion.h"

extern "C" {

void ffi_rgb_to_lab(float r, float g, float b, float* l, float* a, float* b_) {
    rgb_to_lab(r, g, b, l, a, b_);
}

void ffi_lab_to_rgb(float l, float a, float b_, float* r, float* g, float* b_out) {
    lab_to_rgb(l, a, b_, r, g, b_out);
}

}
