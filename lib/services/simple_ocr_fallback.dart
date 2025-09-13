abstract class OcrService {
  Future<String> ocr(String imagePath);
  bool get isAvailable;
}

class SimpleOcrFallback implements OcrService {
  @override
  Future<String> ocr(String imagePath) async {
    return 'OCR not available on this platform.';
  }

  @override
  bool get isAvailable => false;
}
