#pragma once

#ifdef __cplusplus
extern "C" {
#endif

void rgb_to_lab(float r, float g, float b, float* l, float* a, float* b_);
void lab_to_rgb(float l, float a, float b_, float* r, float* g, float* b_out);

#ifdef __cplusplus
}
#endif
