import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('labeler workflow uses actions/labeler@v6 and config has no suspicious metadata', () {
    final workflow = File('.github/workflows/labeler.yml').readAsStringSync();
    final config = File('.github/labeler.yml').readAsStringSync();

    expect(workflow.contains('actions/labeler@v6'), isTrue,
        reason: 'labeler workflow should use actions/labeler@v6');

    final lowerConfig = config.toLowerCase();
    // Ensure known suspicious keywords from the previous error are not present
    expect(lowerConfig.contains('edge'), isFalse);
    expect(lowerConfig.contains('tabs'), isFalse);
    expect(lowerConfig.contains('metadata'), isFalse);
  });
}
