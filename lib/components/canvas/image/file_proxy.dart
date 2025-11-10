
import 'dart:typed_data';

abstract class XFile {
  Future<Uint8List> readAsBytes();
  String get path;
}
