#include "pdf_ffi.h"

extern "C" {

void* extract_pdf_text_selection(const unsigned char* pdf_data, int length, int page, float x1, float y1, float x2, float y2, int* out_size) {
    // Dummy: return a small buffer with fake selection data
    *out_size = 8;
    unsigned char* buf = new unsigned char[*out_size];
    for (int i = 0; i < *out_size; ++i) buf[i] = (unsigned char)(i + 1);
    return buf;
}

int annotate_pdf(const unsigned char* pdf_data, int length, int page, float x1, float y1, float x2, float y2, int annotation_type) {
    // Dummy: always succeed
    return 1;
}

}
