import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kivixa/data/flavor_config.dart';
import 'package:kivixa/data/version.dart';
import 'package:kivixa/i18n/strings.g.dart';
import 'package:url_launcher/url_launcher.dart';

class AppInfo extends StatelessWidget {
  const AppInfo({super.key});

  static final Uri sponsorUrl = Uri.parse('https://github.com/sponsors/990aa');
  static final Uri privacyPolicyUrl = Uri.parse(
    'https://kivixa.990aa.org/privacy-policy/',
  );
  static final Uri licenseUrl = Uri.parse(
    'https://github.com/kivixa/blob/main/LICENSE.md',
  );
  static final Uri releasesUrl = Uri.parse(
    'https://github.com/kivixa/releases',
  );

  static String get info => [
    'v$buildName',
    if (FlavorConfig.flavor.isNotEmpty) FlavorConfig.flavor,
    if (FlavorConfig.dirty) t.appInfo.dirty,
    if (kDebugMode && showDebugMessage) t.appInfo.debug,
    '($buildNumber)',
  ].join(' ');

  @visibleForTesting
  static var showDebugMessage = true;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => _showAboutDialog(context),
      child: Text(info),
    );
  }

  void _showAboutDialog(BuildContext context) => showAboutDialog(
    context: context,
    applicationVersion: info,
    applicationIcon: SvgPicture.asset(
      'assets/icon/icon.svg',
      width: 50,
      height: 50,
    ),
    applicationLegalese: t.appInfo.licenseNotice(buildYear: buildYear),
    children: [
      const SizedBox(height: 10),
      TextButton(
        onPressed: () => launchUrl(sponsorUrl),
        child: SizedBox(
          width: double.infinity,
          child: Text(t.appInfo.sponsorButton),
        ),
      ),
      TextButton(
        onPressed: () => launchUrl(licenseUrl),
        child: SizedBox(
          width: double.infinity,
          child: Text(t.appInfo.licenseButton),
        ),
      ),
      TextButton(
        onPressed: () => launchUrl(privacyPolicyUrl),
        child: SizedBox(
          width: double.infinity,
          child: Text(t.appInfo.privacyPolicyButton),
        ),
      ),
    ],
  );
}
