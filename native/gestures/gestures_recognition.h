#pragma once

#ifdef __cplusplus
extern "C" {
#endif

// Returns gesture type as int (1=swipe, 2=pinch, etc.)
int recognize_gesture(const float* points, int count, int device_type);

// Returns device capability flags
int detect_device_capabilities();

#ifdef __cplusplus
}
#endif
