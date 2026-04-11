import 'package:flutter/foundation.dart';

class CanvasImageActiveNotifier extends ChangeNotifier {
  void deactivateAll() {
    notifyListeners();
  }
}
