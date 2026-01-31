#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
// EXTRA BEGIN
typedef struct DartCObject *WireSyncRust2DartDco;
typedef struct WireSyncRust2DartSse {
  uint8_t *ptr;
  int32_t len;
} WireSyncRust2DartSse;

typedef int64_t DartPort;
typedef bool (*DartPostCObjectFnType)(DartPort port_id, void *message);
void store_dart_post_cobject(DartPostCObjectFnType ptr);
// EXTRA END
typedef struct _Dart_Handle* Dart_Handle;

/**
 * Default buffer duration in seconds (Whisper requires 30s chunks)
 */
#define DEFAULT_BUFFER_DURATION_SECS 30.0

/**
 * Standard sample rate for Whisper models
 */
#define WHISPER_SAMPLE_RATE 16000

typedef struct wire_cst_list_prim_u_8_loose {
  uint8_t *ptr;
  int32_t len;
} wire_cst_list_prim_u_8_loose;

typedef struct wire_cst_list_prim_i_16_loose {
  int16_t *ptr;
  int32_t len;
} wire_cst_list_prim_i_16_loose;

typedef struct wire_cst_list_prim_f_32_loose {
  float *ptr;
  int32_t len;
} wire_cst_list_prim_f_32_loose;

typedef struct wire_cst_list_prim_u_8_strict {
  uint8_t *ptr;
  int32_t len;
} wire_cst_list_prim_u_8_strict;

typedef struct wire_cst_dart_transcription_segment {
  uint32_t id;
  struct wire_cst_list_prim_u_8_strict *text;
  float start_time;
  float end_time;
  struct wire_cst_list_prim_u_8_strict *language;
  float confidence;
  bool is_final;
} wire_cst_dart_transcription_segment;

typedef struct wire_cst_list_dart_transcription_segment {
  struct wire_cst_dart_transcription_segment *ptr;
  int32_t len;
} wire_cst_list_dart_transcription_segment;

typedef struct wire_cst_dart_transcription {
  struct wire_cst_list_dart_transcription_segment *segments;
  struct wire_cst_list_prim_u_8_strict *language;
  float duration;
  uint64_t processing_time_ms;
  struct wire_cst_list_prim_u_8_strict *full_text;
} wire_cst_dart_transcription;

typedef struct wire_cst_list_String {
  struct wire_cst_list_prim_u_8_strict **ptr;
  int32_t len;
} wire_cst_list_String;

typedef struct wire_cst_dart_voice_style {
  struct wire_cst_list_prim_u_8_strict *id;
  struct wire_cst_list_prim_u_8_strict *name;
  struct wire_cst_list_prim_u_8_strict *description;
  float rate;
  float pitch;
} wire_cst_dart_voice_style;

typedef struct wire_cst_list_dart_voice_style {
  struct wire_cst_dart_voice_style *ptr;
  int32_t len;
} wire_cst_list_dart_voice_style;

typedef struct wire_cst_list_prim_f_32_strict {
  float *ptr;
  int32_t len;
} wire_cst_list_prim_f_32_strict;

typedef struct wire_cst_list_prim_i_16_strict {
  int16_t *ptr;
  int32_t len;
} wire_cst_list_prim_i_16_strict;

typedef struct wire_cst_dart_synthesized_audio {
  struct wire_cst_list_prim_f_32_strict *samples;
  uint32_t sample_rate;
  float duration;
} wire_cst_dart_synthesized_audio;

typedef struct wire_cst_dart_vad_result {
  int32_t state;
  float speech_probability;
  bool is_speech;
  float state_duration;
} wire_cst_dart_vad_result;

typedef struct wire_cst_streaming_result {
  struct wire_cst_dart_vad_result vad;
  bool transcription_attempted;
  struct wire_cst_dart_transcription *transcription;
} wire_cst_streaming_result;

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__audio_buffer_available(void);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__audio_buffer_available_duration(void);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__audio_buffer_clear(void);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__audio_buffer_has_full_chunk(void);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__audio_buffer_read(uintptr_t count);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__audio_buffer_read_all(void);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__audio_buffer_write_bytes(struct wire_cst_list_prim_u_8_loose *bytes);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__audio_buffer_write_i16(struct wire_cst_list_prim_i_16_loose *samples);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__audio_buffer_write_samples(struct wire_cst_list_prim_f_32_loose *samples);

void frbgen_kivixa_wire__crate__api__audio_initialize_all(int64_t port_);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__audio_module_health_check(void);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__audio_module_version(void);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__audio_reset_all(void);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__get_whisper_sample_rate(void);

void frbgen_kivixa_wire__crate__api__process_streaming_audio(int64_t port_,
                                                             struct wire_cst_list_prim_u_8_loose *bytes,
                                                             float start_time,
                                                             bool force_transcribe);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__stt_available_models(void);

void frbgen_kivixa_wire__crate__api__stt_initialize(int64_t port_);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__stt_is_ready(void);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__stt_model_size(struct wire_cst_list_prim_u_8_strict *model_name);

void frbgen_kivixa_wire__crate__api__stt_process(int64_t port_,
                                                 struct wire_cst_list_prim_f_32_loose *samples,
                                                 float start_time);

void frbgen_kivixa_wire__crate__api__stt_process_buffer(int64_t port_, float start_time);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__stt_reset(void);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__stt_state(void);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__tts_available_voices(void);

void frbgen_kivixa_wire__crate__api__tts_initialize(int64_t port_);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__tts_is_ready(void);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__tts_state(void);

void frbgen_kivixa_wire__crate__api__tts_synthesize(int64_t port_,
                                                    struct wire_cst_list_prim_u_8_strict *text);

void frbgen_kivixa_wire__crate__api__tts_synthesize_to_bytes(int64_t port_,
                                                             struct wire_cst_list_prim_u_8_strict *text);

void frbgen_kivixa_wire__crate__api__tts_synthesize_to_i16(int64_t port_,
                                                           struct wire_cst_list_prim_u_8_strict *text);

void frbgen_kivixa_wire__crate__api__tts_synthesize_with_voice(int64_t port_,
                                                               struct wire_cst_list_prim_u_8_strict *text,
                                                               struct wire_cst_list_prim_u_8_strict *voice_id);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__vad_current_state(void);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__vad_is_speech(void);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__vad_process(struct wire_cst_list_prim_f_32_loose *samples);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__vad_reset(void);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__vad_set_threshold(float threshold);

struct wire_cst_dart_transcription *frbgen_kivixa_cst_new_box_autoadd_dart_transcription(void);

struct wire_cst_list_String *frbgen_kivixa_cst_new_list_String(int32_t len);

struct wire_cst_list_dart_transcription_segment *frbgen_kivixa_cst_new_list_dart_transcription_segment(int32_t len);

struct wire_cst_list_dart_voice_style *frbgen_kivixa_cst_new_list_dart_voice_style(int32_t len);

struct wire_cst_list_prim_f_32_loose *frbgen_kivixa_cst_new_list_prim_f_32_loose(int32_t len);

struct wire_cst_list_prim_f_32_strict *frbgen_kivixa_cst_new_list_prim_f_32_strict(int32_t len);

struct wire_cst_list_prim_i_16_loose *frbgen_kivixa_cst_new_list_prim_i_16_loose(int32_t len);

struct wire_cst_list_prim_i_16_strict *frbgen_kivixa_cst_new_list_prim_i_16_strict(int32_t len);

struct wire_cst_list_prim_u_8_loose *frbgen_kivixa_cst_new_list_prim_u_8_loose(int32_t len);

struct wire_cst_list_prim_u_8_strict *frbgen_kivixa_cst_new_list_prim_u_8_strict(int32_t len);
static int64_t dummy_method_to_enforce_bundling(void) {
    int64_t dummy_var = 0;
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_cst_new_box_autoadd_dart_transcription);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_cst_new_list_String);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_cst_new_list_dart_transcription_segment);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_cst_new_list_dart_voice_style);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_cst_new_list_prim_f_32_loose);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_cst_new_list_prim_f_32_strict);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_cst_new_list_prim_i_16_loose);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_cst_new_list_prim_i_16_strict);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_cst_new_list_prim_u_8_loose);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_cst_new_list_prim_u_8_strict);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__audio_buffer_available);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__audio_buffer_available_duration);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__audio_buffer_clear);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__audio_buffer_has_full_chunk);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__audio_buffer_read);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__audio_buffer_read_all);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__audio_buffer_write_bytes);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__audio_buffer_write_i16);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__audio_buffer_write_samples);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__audio_initialize_all);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__audio_module_health_check);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__audio_module_version);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__audio_reset_all);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__get_whisper_sample_rate);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__process_streaming_audio);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__stt_available_models);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__stt_initialize);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__stt_is_ready);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__stt_model_size);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__stt_process);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__stt_process_buffer);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__stt_reset);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__stt_state);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__tts_available_voices);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__tts_initialize);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__tts_is_ready);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__tts_state);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__tts_synthesize);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__tts_synthesize_to_bytes);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__tts_synthesize_to_i16);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__tts_synthesize_with_voice);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__vad_current_state);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__vad_is_speech);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__vad_process);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__vad_reset);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__vad_set_threshold);
    dummy_var ^= ((int64_t) (void*) store_dart_post_cobject);
    return dummy_var;
}
