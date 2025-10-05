import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note.dart';
import '../models/page.dart';
import '../models/stroke.dart';

final currentNoteProvider = StateProvider<Note?>((ref) => null);
final currentPageIndexProvider = StateProvider<int>((ref) => 0);
final canvasScaleProvider = StateProvider<double>((ref) => 1.0);
final canvasOffsetProvider = StateProvider<Offset>((ref) => Offset.zero);

final currentStrokeProvider = StateProvider<DrawingStroke?>((ref) => null);
