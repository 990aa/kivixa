#include "pdf_ffi.h"

extern "C" {

void* extract_pdf_text_selection(const unsigned char* pdf_data, int length, int page, float x1, float y1, float x2, float y2, int* out_size) {
    // TODO: Implement PDF text selection extraction
    *out_size = 0;
    return nullptr;
}

int annotate_pdf(const unsigned char* pdf_data, int length, int page, float x1, float y1, float x2, float y2, int annotation_type) {
    // TODO: Implement PDF annotation
    return 0;
}

}
