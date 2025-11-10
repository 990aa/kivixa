class KivixaVersion {
  final int major;
  final int minor;
  final int patch;
  final int revision;

  KivixaVersion(this.major, this.minor, this.patch, [this.revision = 0])
    : assert(major >= 0 && major < 100),
      assert(minor >= 0 && minor < 100),
      assert(patch >= 0 && patch < 100),
      assert(revision >= 0 && revision < 10);

  factory KivixaVersion.fromName(String name) {
    final parts = name.split('.');
    assert(parts.length == 3);
    return KivixaVersion(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  factory KivixaVersion.fromNumber(int number) {
    // rightmost digit is the revision number
    final revision = number % 10;
    // next 2 digits are patch version
    final patch = (number ~/ 10) % 100;
    // next 2 digits are minor version
    final minor = (number ~/ 1000) % 100;
    // next 2 digits are major version
    final major = (number ~/ 100000) % 100;

    return KivixaVersion(major, minor, patch, revision);
  }

  String get buildName => '$major.$minor.$patch';
  String get buildNameWithCommas => '$major,$minor,$patch';
  int get buildNumber => revision + patch * 10 + minor * 1000 + major * 100000;
  int get buildNumberWithoutRevision => buildNumber - revision;

  KivixaVersion bumpMajor() => KivixaVersion(major + 1, 0, 0);
  KivixaVersion bumpMinor() => KivixaVersion(major, minor + 1, 0);
  KivixaVersion bumpPatch() => KivixaVersion(major, minor, patch + 1);

  KivixaVersion copyWith({int? major, int? minor, int? patch, int? revision}) =>
      KivixaVersion(
        major ?? this.major,
        minor ?? this.minor,
        patch ?? this.patch,
        revision ?? this.revision,
      );

  @override
  String toString() => buildName;

  @override
  bool operator ==(Object other) =>
      other is KivixaVersion &&
      major == other.major &&
      minor == other.minor &&
      patch == other.patch;

  @override
  int get hashCode => buildNumber;
}
