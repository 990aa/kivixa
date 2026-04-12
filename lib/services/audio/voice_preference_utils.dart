import 'package:kivixa/services/audio/audio_neural_engine.dart';

enum AudioVoiceProfile { female, male, custom }

AudioVoiceProfile audioVoiceProfileFromPref(int value) {
  if (value <= 0) return AudioVoiceProfile.female;
  if (value == 1) return AudioVoiceProfile.male;
  return AudioVoiceProfile.custom;
}

bool isMaleVoice(VoiceStyle voice) =>
    isMaleVoiceIdOrName(voice.id, voice.name, voice.description);

bool isFemaleVoice(VoiceStyle voice) =>
    isFemaleVoiceIdOrName(voice.id, voice.name, voice.description);

bool isMaleVoiceIdOrName(String id, String name, String description) {
  final idLower = id.toLowerCase();
  final nameLower = name.toLowerCase();
  final descriptionLower = description.toLowerCase();
  final malePattern = RegExp(r'(^|[^a-z])male([^a-z]|$)');

  if (idLower.startsWith('am_') || idLower.startsWith('bm_')) {
    return true;
  }

  if (malePattern.hasMatch(idLower) ||
      malePattern.hasMatch(nameLower) ||
      malePattern.hasMatch(descriptionLower)) {
    return true;
  }

  const maleNames = <String>{'adam', 'michael', 'george', 'david', 'james'};
  return maleNames.any(
    (value) =>
        idLower.contains(value) ||
        nameLower.contains(value) ||
        descriptionLower.contains(value),
  );
}

bool isFemaleVoiceIdOrName(String id, String name, String description) {
  final idLower = id.toLowerCase();
  final nameLower = name.toLowerCase();
  final descriptionLower = description.toLowerCase();
  final femalePattern = RegExp(r'(^|[^a-z])female([^a-z]|$)');

  if (idLower.startsWith('af_') || idLower.startsWith('bf_')) {
    return true;
  }

  if (femalePattern.hasMatch(idLower) ||
      femalePattern.hasMatch(nameLower) ||
      femalePattern.hasMatch(descriptionLower)) {
    return true;
  }

  const femaleNames = <String>{'heart', 'sky', 'emma', 'sarah', 'olivia'};
  return femaleNames.any(
    (value) =>
        idLower.contains(value) ||
        nameLower.contains(value) ||
        descriptionLower.contains(value),
  );
}

String inferVoiceGenderLabel(VoiceStyle voice) {
  if (isFemaleVoice(voice)) {
    return 'female';
  }
  if (isMaleVoice(voice)) {
    return 'male';
  }
  return 'neutral';
}

String? inferVoiceLocaleFromId(String voiceId) {
  final lower = voiceId.toLowerCase();
  if (lower.startsWith('af_') || lower.startsWith('am_')) {
    return 'en-US';
  }
  if (lower.startsWith('bf_') || lower.startsWith('bm_')) {
    return 'en-GB';
  }
  return null;
}

String? selectPreferredVoiceId(
  List<VoiceStyle> voices,
  AudioVoiceProfile profile, {
  String? customVoiceId,
}) {
  if (voices.isEmpty) return null;

  if (profile == AudioVoiceProfile.custom &&
      customVoiceId != null &&
      customVoiceId.isNotEmpty) {
    final exactMatch = voices.where((voice) => voice.id == customVoiceId);
    if (exactMatch.isNotEmpty) {
      return exactMatch.first.id;
    }
  }

  final preferred = switch (profile) {
    AudioVoiceProfile.male => voices.where(isMaleVoice),
    AudioVoiceProfile.female => voices.where(isFemaleVoice),
    AudioVoiceProfile.custom => const Iterable<VoiceStyle>.empty(),
  };

  if (preferred.isNotEmpty) {
    return preferred.first.id;
  }

  return voices.first.id;
}
