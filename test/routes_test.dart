import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/data/routes.dart';

void main() {
  test('Test that browseFilePath returns the browse page', () {
    final url = HomeRoutes.browseFilePath('/');
    expect(url.startsWith('/home/browse'), true);
  });
}
