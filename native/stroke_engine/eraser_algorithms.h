#pragma once

#ifdef __cplusplus
extern "C" {
#endif

void erase_pixels(unsigned char* image, int width, int height, int x, int y, int radius);
void erase_stroke(int* stroke_ids, int count, int target_id);

#ifdef __cplusplus
}
#endif
