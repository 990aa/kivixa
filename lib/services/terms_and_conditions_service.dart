import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing Terms and Conditions acceptance
class TermsAndConditionsService {
  static const _termsAcceptedKey = 'termsAccepted';
  static const _termsAcceptedVersionKey = 'termsAcceptedVersion';
  static const _termsAcceptedDateKey = 'termsAcceptedDate';

  /// Current version of the terms and conditions
  /// Bump this when terms are updated to require re-acceptance
  static const currentTermsVersion = '0.1.1';

  /// Check if user has accepted the current terms
  static Future<bool> hasAcceptedTerms() async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool(_termsAcceptedKey) ?? false;

    if (!accepted) return false;

    // Check if terms version matches
    final acceptedVersion = prefs.getString(_termsAcceptedVersionKey);
    return acceptedVersion == currentTermsVersion;
  }

  /// Record that user has accepted the terms
  static Future<void> acceptTerms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_termsAcceptedKey, true);
    await prefs.setString(_termsAcceptedVersionKey, currentTermsVersion);
    await prefs.setString(
      _termsAcceptedDateKey,
      DateTime.now().toIso8601String(),
    );
  }

  /// Get the date when terms were accepted
  static Future<DateTime?> getAcceptedDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_termsAcceptedDateKey);
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr);
  }

  /// Reset terms acceptance (for testing or if terms need re-acceptance)
  static Future<void> resetAcceptance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_termsAcceptedKey);
    await prefs.remove(_termsAcceptedVersionKey);
    await prefs.remove(_termsAcceptedDateKey);
  }

  /// Get the terms and conditions text
  static String getTermsText() {
    return '''
KIVIXA TERMS AND CONDITIONS

Last Updated: December 2025
Version: $currentTermsVersion

By using Kivixa, you agree to these terms and conditions.

1. ACCEPTANCE OF TERMS

By downloading, installing, or using the Kivixa application ("App"), you agree to be bound by these Terms and Conditions ("Terms"). If you do not agree to these Terms, do not use the App.

2. LICENSE

Kivixa grants you a limited, non-exclusive, non-transferable, revocable license to use the App for personal or educational purposes, subject to these Terms.

3. USER DATA

3.1 Local Storage: Your notes, projects, and other data are stored locally on your device. Kivixa does not collect or transmit your personal data to external servers unless you explicitly use sync or backup features.

3.2 Data Responsibility: You are responsible for backing up your data. Kivixa is not responsible for any data loss due to device failure, app updates, or user error.

3.3 Data Clearing: The App provides options to clear your data. Once cleared, data cannot be recovered.

4. INTELLECTUAL PROPERTY

4.1 App Content: The App, including its design, code, graphics, and documentation, is the property of the Kivixa development team and is protected by intellectual property laws.

4.2 User Content: You retain ownership of all content you create using the App. By using the App, you grant Kivixa a limited license to process your content solely for the purpose of providing App functionality.

5. PROHIBITED USES

You agree not to:
- Reverse engineer, decompile, or disassemble the App
- Use the App for any illegal or unauthorized purpose
- Distribute, sell, or sublicense the App
- Remove any proprietary notices from the App

6. DISCLAIMER OF WARRANTIES

THE APP IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND. KIVIXA DISCLAIMS ALL WARRANTIES, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.

7. LIMITATION OF LIABILITY

IN NO EVENT SHALL KIVIXA BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES ARISING OUT OF OR RELATED TO YOUR USE OF THE APP.

8. UPDATES AND MODIFICATIONS

Kivixa may update or modify the App at any time. Continued use of the App after updates constitutes acceptance of any modified Terms.

9. TERMINATION

Kivixa may terminate your access to the App at any time for any reason. Upon termination, you must cease all use of the App.

10. GOVERNING LAW

These Terms shall be governed by and construed in accordance with applicable laws, without regard to conflict of law principles.

11. CONTACT

For questions about these Terms, please visit our repository or contact the development team.

By clicking "I Agree" or continuing to use the App, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions.
''';
  }

  /// Get the privacy policy text
  static String getPrivacyPolicyText() {
    return '''
KIVIXA PRIVACY POLICY

Last Updated: December 2025

1. INFORMATION WE COLLECT

Kivixa is designed with privacy in mind. We do not collect personal information unless explicitly stated.

1.1 Local Data: All notes, projects, and settings are stored locally on your device.

1.2 No Telemetry: Kivixa does not send usage statistics or telemetry data.

2. DATA STORAGE

Your data is stored in the following locations:
- Notes and documents: Local device storage
- Settings and preferences: Local app preferences
- Calendar events: Local device storage

3. DATA SHARING

We do not share your data with third parties.

4. SECURITY

While we implement reasonable security measures, no system is completely secure. You are responsible for maintaining the security of your device.

5. CHILDREN'S PRIVACY

Kivixa is not intended for children under 13 years of age.

6. CHANGES TO THIS POLICY

We may update this Privacy Policy from time to time. Continued use of the App constitutes acceptance of any changes.

7. CONTACT

For privacy-related questions, please visit our repository or contact the development team.
''';
  }
}
