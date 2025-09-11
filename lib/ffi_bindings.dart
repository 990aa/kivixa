import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// Load the C++ FFI libraries
final DynamicLibrary databaseFfiLib = Platform.isWindows
    ? DynamicLibrary.open('database_ffi.dll')
    : DynamicLibrary.process(); // Adjust for other platforms
final DynamicLibrary strokeEngineLib = Platform.isWindows
    ? DynamicLibrary.open('stroke_engine.dll')
    : DynamicLibrary.process();
final DynamicLibrary infiniteCanvasLib = Platform.isWindows
    ? DynamicLibrary.open('infinite_canvas.dll')
    : DynamicLibrary.process();
final DynamicLibrary freePaperLib = Platform.isWindows
    ? DynamicLibrary.open('free_paper_movement.dll')
    : DynamicLibrary.process();

// ---- database_ffi.h ----
typedef EncodeStrokeChunkNative =
    Void Function(
      Pointer<Float>,
      Uint64,
      Pointer<Pointer<Uint8>>,
      Pointer<Uint64>,
    );
typedef EncodeStrokeChunk =
    void Function(
      Pointer<Float>,
      int,
      Pointer<Pointer<Uint8>>,
      Pointer<Uint64>,
    );
final EncodeStrokeChunk encodeStrokeChunk = databaseFfiLib
    .lookup<NativeFunction<EncodeStrokeChunkNative>>('encode_stroke_chunk')
    .asFunction();

typedef DecodeStrokeChunkNative =
    Void Function(
      Pointer<Uint8>,
      Uint64,
      Pointer<Pointer<Float>>,
      Pointer<Uint64>,
    );
typedef DecodeStrokeChunk =
    void Function(
      Pointer<Uint8>,
      int,
      Pointer<Pointer<Float>>,
      Pointer<Uint64>,
    );
final DecodeStrokeChunk decodeStrokeChunk = databaseFfiLib
    .lookup<NativeFunction<DecodeStrokeChunkNative>>('decode_stroke_chunk')
    .asFunction();

typedef BuildSpatialIndexNative =
    Void Function(Pointer<Float>, Uint64, Pointer<Pointer<Void>>);
typedef BuildSpatialIndex =
    void Function(Pointer<Float>, int, Pointer<Pointer<Void>>);
final BuildSpatialIndex buildSpatialIndex = databaseFfiLib
    .lookup<NativeFunction<BuildSpatialIndexNative>>('build_spatial_index')
    .asFunction();

typedef FreeSpatialIndexNative = Void Function(Pointer<Void>);
typedef FreeSpatialIndex = void Function(Pointer<Void>);
final FreeSpatialIndex freeSpatialIndex = databaseFfiLib
    .lookup<NativeFunction<FreeSpatialIndexNative>>('free_spatial_index')
    .asFunction();

typedef QuerySpatialIndexNative =
    Int32 Function(
      Pointer<Void>,
      Float,
      Float,
      Float,
      Float,
      Pointer<Int32>,
      Uint64,
    );
typedef QuerySpatialIndex =
    int Function(
      Pointer<Void>,
      double,
      double,
      double,
      double,
      Pointer<Int32>,
      int,
    );
final QuerySpatialIndex querySpatialIndex = databaseFfiLib
    .lookup<NativeFunction<QuerySpatialIndexNative>>('query_spatial_index')
    .asFunction();

// ---- stroke_engine ----
// Add FFI bindings for stroke serialization, compression, and erasing as needed
// Example:
typedef AppendStrokeNative = Void Function(Pointer<Uint8>, Uint64);
typedef AppendStroke = void Function(Pointer<Uint8>, int);
final AppendStroke appendStroke = strokeEngineLib
    .lookup<NativeFunction<AppendStrokeNative>>('append_stroke')
    .asFunction();

// ---- infinite_canvas ----
// Add FFI bindings for sparse tiling and viewport queries as needed
// Example:
typedef QueryVisibleTilesNative =
    Void Function(Float, Float, Float, Float, Pointer<Int32>, Uint64);
typedef QueryVisibleTiles =
    void Function(double, double, double, double, Pointer<Int32>, int);
final QueryVisibleTiles queryVisibleTiles = infiniteCanvasLib
    .lookup<NativeFunction<QueryVisibleTilesNative>>('query_visible_tiles')
    .asFunction();

// ---- free_paper_movement ----
// Add FFI bindings for touch-edge detection and offset calculation as needed
// Example:
typedef ComputeOptimalOffsetNative =
    Void Function(Float, Float, Float, Float, Pointer<Float>);
typedef ComputeOptimalOffset =
    void Function(double, double, double, double, Pointer<Float>);
final ComputeOptimalOffset computeOptimalOffset = freePaperLib
    .lookup<NativeFunction<ComputeOptimalOffsetNative>>(
      'compute_optimal_offset',
    )
    .asFunction();

// ---- stroke_engine: pressure interpolation ----
typedef FfiInterpolatePressureNative =
    Float Function(Pointer<Float>, Int32, Float);
typedef FfiInterpolatePressure = double Function(Pointer<Float>, int, double);
final FfiInterpolatePressure ffiInterpolatePressure = strokeEngineLib
    .lookup<NativeFunction<FfiInterpolatePressureNative>>(
      'ffi_interpolate_pressure',
    )
    .asFunction();

// ---- stroke_engine: eraser algorithms ----
typedef FfiErasePixelsNative =
    Void Function(Pointer<Uint8>, Int32, Int32, Int32, Int32, Int32);
typedef FfiErasePixels = void Function(Pointer<Uint8>, int, int, int, int, int);
final FfiErasePixels ffiErasePixels = strokeEngineLib
    .lookup<NativeFunction<FfiErasePixelsNative>>('ffi_erase_pixels')
    .asFunction();

typedef FfiEraseStrokeNative = Void Function(Pointer<Int32>, Int32, Int32);
typedef FfiEraseStroke = void Function(Pointer<Int32>, int, int);
final FfiEraseStroke ffiEraseStroke = strokeEngineLib
    .lookup<NativeFunction<FfiEraseStrokeNative>>('ffi_erase_stroke')
    .asFunction();

// ---- thumbnail_service: color conversion ----
typedef FfiRgbToLabNative =
    Void Function(
      Float,
      Float,
      Float,
      Pointer<Float>,
      Pointer<Float>,
      Pointer<Float>,
    );
typedef FfiRgbToLab =
    void Function(
      double,
      double,
      double,
      Pointer<Float>,
      Pointer<Float>,
      Pointer<Float>,
    );
final FfiRgbToLab ffiRgbToLab = strokeEngineLib
    .lookup<NativeFunction<FfiRgbToLabNative>>('ffi_rgb_to_lab')
    .asFunction();

typedef FfiLabToRgbNative =
    Void Function(
      Float,
      Float,
      Float,
      Pointer<Float>,
      Pointer<Float>,
      Pointer<Float>,
    );
typedef FfiLabToRgb =
    void Function(
      double,
      double,
      double,
      Pointer<Float>,
      Pointer<Float>,
      Pointer<Float>,
    );
final FfiLabToRgb ffiLabToRgb = strokeEngineLib
    .lookup<NativeFunction<FfiLabToRgbNative>>('ffi_lab_to_rgb')
    .asFunction();

// ---- shapes_recognition (shapes.dll/so) ----
final DynamicLibrary shapesLib = Platform.isWindows
    ? DynamicLibrary.open('shapes.dll')
    : DynamicLibrary.process();

typedef RecognizeShapeNative = Int32 Function(Pointer<Float>, Int32);
typedef RecognizeShape = int Function(Pointer<Float>, int);
final RecognizeShape recognizeShape = shapesLib
    .lookup<NativeFunction<RecognizeShapeNative>>('recognize_shape')
    .asFunction();

typedef GeneratePrimitiveGeometryNative =
    Pointer<Void> Function(
      Pointer<Utf8>,
      Pointer<Float>,
      Int32,
      Pointer<Int32>,
    );
typedef GeneratePrimitiveGeometry =
    Pointer<Void> Function(Pointer<Utf8>, Pointer<Float>, int, Pointer<Int32>);
final GeneratePrimitiveGeometry generatePrimitiveGeometry = shapesLib
    .lookup<NativeFunction<GeneratePrimitiveGeometryNative>>(
      'generate_primitive_geometry',
    )
    .asFunction();

typedef CreateParameterizedShapeNative =
    Pointer<Void> Function(
      Pointer<Utf8>,
      Pointer<Float>,
      Int32,
      Pointer<Int32>,
    );
typedef CreateParameterizedShape =
    Pointer<Void> Function(Pointer<Utf8>, Pointer<Float>, int, Pointer<Int32>);
final CreateParameterizedShape createParameterizedShape = shapesLib
    .lookup<NativeFunction<CreateParameterizedShapeNative>>(
      'create_parameterized_shape',
    )
    .asFunction();

// ---- gestures_recognition (gestures.dll/so) ----
final DynamicLibrary gesturesLib = Platform.isWindows
    ? DynamicLibrary.open('gestures.dll')
    : DynamicLibrary.process();

typedef RecognizeGestureNative = Int32 Function(Pointer<Float>, Int32, Int32);
typedef RecognizeGesture = int Function(Pointer<Float>, int, int);
final RecognizeGesture recognizeGesture = gesturesLib
    .lookup<NativeFunction<RecognizeGestureNative>>('recognize_gesture')
    .asFunction();

typedef DetectDeviceCapabilitiesNative = Int32 Function();
typedef DetectDeviceCapabilities = int Function();
final DetectDeviceCapabilities detectDeviceCapabilities = gesturesLib
    .lookup<NativeFunction<DetectDeviceCapabilitiesNative>>(
      'detect_device_capabilities',
    )
    .asFunction();
