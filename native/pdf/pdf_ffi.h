#pragma once

#ifdef __cplusplus
extern "C" {
#endif

// Returns pointer to selection data, sets out_size
void* extract_pdf_text_selection(const unsigned char* pdf_data, int length, int page, float x1, float y1, float x2, float y2, int* out_size);

// Annotates PDF (highlight, underline, etc.)
int annotate_pdf(const unsigned char* pdf_data, int length, int page, float x1, float y1, float x2, float y2, int annotation_type);

#ifdef __cplusplus
}
#endif
