import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/services/math/math_service.dart';
import 'package:kivixa/src/rust/frb_generated.dart';

void main() {
  setUpAll(() async {
    try {
      await RustLib.init();
    } catch (e) {
      // Ignore if already initialized
    }
    await MathService.instance.initialize();
  });

  group('Advanced Math Tests', () {
    test('Combinatorics: Permutations', () {
      final res = MathService.instance.permutations(5, 3);
      expect(res.success, isTrue);
    });

    test('Combinatorics: Combinations', () {
      final res = MathService.instance.combinations(5, 3);
      expect(res.success, isTrue);
    });

    test('Combinatorics: Stirling Second Kind', () async {
      final res = await MathService.instance.stirlingSecond(5, 3);
      expect(res.success, isTrue);
    });

    test('Combinatorics: Derangements', () async {
      final res = await MathService.instance.derangements(4);
      expect(res.success, isTrue);
    });

    test('Statistics: Regression Linear', () async {
      final res = await MathService.instance.advancedRegression(
        [1.0, 2.0, 3.0, 4.0, 5.0],
        [2.0, 4.0, 5.0, 4.0, 5.0],
        'linear',
      );
      expect(res.success, isTrue);
      expect(res.coefficients.isNotEmpty, isTrue);
    });
  });
}
