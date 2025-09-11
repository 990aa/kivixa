#include "pressure_interpolation.h"

float interpolate_pressure(float* points, int count, float t) {
    // TODO: Implement efficient interpolation (e.g., Catmull-Rom, cubic)
    // Placeholder: linear interpolation
    if (count < 2) return points[0];
    int idx = (int)(t * (count - 1));
    float frac = t * (count - 1) - idx;
    if (idx >= count - 1) return points[count - 1];
    return points[idx] * (1 - frac) + points[idx + 1] * frac;
}
