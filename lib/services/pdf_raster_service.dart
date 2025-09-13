import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

import '../data/repository.dart';

class PdfRasterService {
  final Repository _repo;

  PdfRasterService(this._repo);

  Future<String?> getRasterizedPage(String pdfPath, int pageNumber) async {
    final cachedPage = await _repo.getPdfPageCache(pdfPath, pageNumber);
    if (cachedPage != null) {
      return cachedPage['image_path'];
    }

    try {
      final doc = await PdfDocument.openFile(pdfPath);
      final page = await doc.getPage(pageNumber);
      final pageImage = await page.render(width: page.width, height: page.height);

      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory(p.join(appDir.path, 'assets_cache'));
      await cacheDir.create(recursive: true);

      final pdfPathHash = sha256.convert(pdfPath.codeUnits).toString();
      final imagePath = p.join(cacheDir.path, pdfPathHash, '$pageNumber.png');

      final imageFile = File(imagePath);
      await imageFile.create(recursive: true);
      await imageFile.writeAsBytes(pageImage!.bytes);

      await _repo.createPdfPageCache({
        'pdf_path': pdfPath,
        'page_number': pageNumber,
        'image_path': imagePath,
      });

      await page.close();
      await doc.close();

      return imagePath;
    } catch (e) {
      // Handle exceptions
      print(e);
      return null;
    }
  }
}