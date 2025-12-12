import 'package:flutter/material.dart';

class MaterialIconCodec {
  static const _knownIcons = <IconData>[
    Icons.accessibility,
    Icons.air,
    Icons.assignment,
    Icons.book,
    Icons.brush,
    Icons.camera_alt,
    Icons.checklist,
    Icons.circle,
    Icons.coffee,
    Icons.code,
    Icons.directions_walk,
    Icons.edit,
    Icons.edit_note,
    Icons.event_note,
    Icons.favorite,
    Icons.fitness_center,
    Icons.flash_on,
    Icons.groups,
    Icons.local_cafe,
    Icons.local_laundry_service,
    Icons.menu_book,
    Icons.nights_stay,
    Icons.note_alt,
    Icons.palette,
    Icons.playlist_play,
    Icons.psychology,
    Icons.quiz,
    Icons.restaurant,
    Icons.save,
    Icons.school,
    Icons.search,
    Icons.self_improvement,
    Icons.star,
    Icons.timer,
    Icons.visibility,
    Icons.water_drop,
    Icons.wb_sunny,
  ];

  static IconData fromCodePoint(
    int? codePoint, {
    IconData fallback = Icons.timer,
  }) {
    if (codePoint == null) {
      return fallback;
    }

    for (final icon in _knownIcons) {
      if (icon.codePoint == codePoint) {
        return icon;
      }
    }

    return fallback;
  }
}
