import 'package:sqflite/sqflite.dart';
import 'dart:typed_data';

import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import '../ffi_bindings.dart';

class ImagesService {
  final Database db;
  ImagesService(this.db);

  Future<void> addImage(
    int layerId,
    String filePath,
    int width,
    int height,
  ) async {
    // Read file and compute hash via FFI
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final ptr = malloc.allocate<Uint8>(bytes.length);
    final byteList = ptr.asTypedList(bytes.length);
    byteList.setAll(0, bytes);
    final hash = computeImageHash(ptr, bytes.length);
    malloc.free(ptr);
    await db.insert('images', {
      'layer_id': layerId,
      'uri': filePath,
      'hash': hash.toString(),
      'width': width,
      'height': height,
    });
  }

  Future<List<Map<String, dynamic>>> findDuplicates(int hash) async {
    return await db.query(
      'images',
      where: 'hash = ?',
      whereArgs: [hash.toString()],
    );
  }

  Future<Uint8List> generateThumbnail(
    Uint8List imageData,
    int width,
    int height,
    int thumbWidth,
    int thumbHeight,
  ) async {
    final ptr = malloc.allocate<Uint8>(imageData.length);
    ptr.asTypedList(imageData.length).setAll(0, imageData);
    final outSizePtr = malloc.allocate<Int32>(1);
    final resultPtr = generateThumbnail(
      ptr,
      width,
      height,
      thumbWidth,
      thumbHeight,
      outSizePtr,
    );
    final outSize = outSizePtr.value;
    final thumb = Uint8List.fromList(
      resultPtr.cast<Uint8>().asTypedList(outSize),
    );
    malloc.free(ptr);
    malloc.free(outSizePtr);
    // Free resultPtr if needed (depends on C++ side)
    return thumb;
  }

  Future<Uint8List> transformImage(
    Uint8List imageData,
    int width,
    int height,
    Float32List matrix,
  ) async {
    final ptr = malloc.allocate<Uint8>(imageData.length);
    ptr.asTypedList(imageData.length).setAll(0, imageData);
    final matrixPtr = malloc.allocate<Float>(matrix.length);
    matrixPtr.asTypedList(matrix.length).setAll(0, matrix);
    final outSizePtr = malloc.allocate<Int32>(1);
    final resultPtr = transformImage(ptr, width, height, matrixPtr, outSizePtr);
    final outSize = outSizePtr.value;
    final outImg = Uint8List.fromList(
      resultPtr.cast<Uint8>().asTypedList(outSize),
    );
    malloc.free(ptr);
    malloc.free(matrixPtr);
    malloc.free(outSizePtr);
    // Free resultPtr if needed (depends on C++ side)
    return outImg;
  }
}
