import 'dart:io';

void main() async {
  print('Starting build process...');

  await _build('windows');
  await _build('apk');

  print('Build process finished.');
}

Future<void> _build(String platform) async {
  print('Building for $platform...');
  final result = await Process.run(
    'flutter',
    ['build', platform, '--release'],
    runInShell: true,
  );

  if (result.exitCode == 0) {
    print('Successfully built for $platform.');
    print(result.stdout);
  } else {
    print('Error building for $platform:');
    print(result.stderr);
  }
}
