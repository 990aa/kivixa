import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/services/terms_and_conditions_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('TermsAndConditionsService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('hasAcceptedTerms returns false when terms not accepted', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await TermsAndConditionsService.hasAcceptedTerms();

      expect(result, false);
    });

    test('hasAcceptedTerms returns true after acceptTerms is called', () async {
      SharedPreferences.setMockInitialValues({});

      await TermsAndConditionsService.acceptTerms();
      final result = await TermsAndConditionsService.hasAcceptedTerms();

      expect(result, true);
    });

    test('acceptTerms stores current terms version', () async {
      SharedPreferences.setMockInitialValues({});

      await TermsAndConditionsService.acceptTerms();

      final prefs = await SharedPreferences.getInstance();
      final storedVersion = prefs.getString('termsAcceptedVersion');

      expect(storedVersion, TermsAndConditionsService.currentTermsVersion);
    });

    test('acceptTerms stores acceptance date', () async {
      SharedPreferences.setMockInitialValues({});

      final beforeAccept = DateTime.now();
      await TermsAndConditionsService.acceptTerms();
      final afterAccept = DateTime.now();

      final acceptedDate = await TermsAndConditionsService.getAcceptedDate();

      expect(acceptedDate, isNotNull);
      expect(
        acceptedDate!.isAfter(
          beforeAccept.subtract(const Duration(seconds: 1)),
        ),
        true,
      );
      expect(
        acceptedDate.isBefore(afterAccept.add(const Duration(seconds: 1))),
        true,
      );
    });

    test('getAcceptedDate returns null when terms not accepted', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await TermsAndConditionsService.getAcceptedDate();

      expect(result, null);
    });

    test('resetAcceptance clears all terms data', () async {
      SharedPreferences.setMockInitialValues({});

      // First accept terms
      await TermsAndConditionsService.acceptTerms();
      expect(await TermsAndConditionsService.hasAcceptedTerms(), true);

      // Then reset
      await TermsAndConditionsService.resetAcceptance();

      expect(await TermsAndConditionsService.hasAcceptedTerms(), false);
      expect(await TermsAndConditionsService.getAcceptedDate(), null);
    });

    test('hasAcceptedTerms returns false if terms version changed', () async {
      // Simulate accepting an old version
      SharedPreferences.setMockInitialValues({
        'termsAccepted': true,
        'termsAcceptedVersion': '0.9.0', // Old version
        'termsAcceptedDate': DateTime.now().toIso8601String(),
      });

      final result = await TermsAndConditionsService.hasAcceptedTerms();

      // Should return false because version doesn't match current
      expect(result, false);
    });

    test('hasAcceptedTerms returns true if terms version matches', () async {
      SharedPreferences.setMockInitialValues({
        'termsAccepted': true,
        'termsAcceptedVersion': TermsAndConditionsService.currentTermsVersion,
        'termsAcceptedDate': DateTime.now().toIso8601String(),
      });

      final result = await TermsAndConditionsService.hasAcceptedTerms();

      expect(result, true);
    });

    test('getTermsText returns non-empty string', () {
      final terms = TermsAndConditionsService.getTermsText();

      expect(terms, isNotEmpty);
      expect(terms.contains('KIVIXA'), true);
      expect(terms.contains('TERMS AND CONDITIONS'), true);
    });

    test('getPrivacyPolicyText returns non-empty string', () {
      final privacy = TermsAndConditionsService.getPrivacyPolicyText();

      expect(privacy, isNotEmpty);
      expect(privacy.contains('PRIVACY POLICY'), true);
    });

    test('terms text contains required sections', () {
      final terms = TermsAndConditionsService.getTermsText();

      // Check for key sections
      expect(terms.contains('ACCEPTANCE OF TERMS'), true);
      expect(terms.contains('LICENSE'), true);
      expect(terms.contains('USER DATA'), true);
      expect(terms.contains('INTELLECTUAL PROPERTY'), true);
      expect(terms.contains('PROHIBITED USES'), true);
      expect(terms.contains('DISCLAIMER OF WARRANTIES'), true);
      expect(terms.contains('LIMITATION OF LIABILITY'), true);
    });

    test('privacy policy contains required sections', () {
      final privacy = TermsAndConditionsService.getPrivacyPolicyText();

      expect(privacy.contains('INFORMATION WE COLLECT'), true);
      expect(privacy.contains('DATA STORAGE'), true);
      expect(privacy.contains('DATA SHARING'), true);
      expect(privacy.contains('SECURITY'), true);
    });

    test('privacy policy contains Local AI section', () {
      final privacy = TermsAndConditionsService.getPrivacyPolicyText();

      // Verify the new LOCAL AI FEATURES section exists
      expect(privacy.contains('LOCAL AI FEATURES'), true);
      expect(privacy.contains('On-Device Processing'), true);
      expect(privacy.contains('No Cloud AI'), true);
      expect(privacy.contains('AI Model Storage'), true);
      expect(privacy.contains('Privacy by Design'), true);

      // Verify it mentions SLMs and LLMs running locally
      expect(privacy.contains('Small Language Models'), true);
      expect(privacy.contains('Large Language Models'), true);
      expect(privacy.contains('entirely on your device'), true);
    });

    test('currentTermsVersion is valid semantic version', () {
      const version = TermsAndConditionsService.currentTermsVersion;

      // Should be in format X.Y.Z
      final parts = version.split('.');
      expect(parts.length, 3);

      for (final part in parts) {
        expect(int.tryParse(part), isNotNull);
      }
    });
  });
}
