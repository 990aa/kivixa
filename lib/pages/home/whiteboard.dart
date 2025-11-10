import 'package:flutter/material.dart';
import 'package:kivixa/components/canvas/save_indicator.dart';
import 'package:kivixa/data/prefs.dart';
import 'package:kivixa/i18n/strings.g.dart';
import 'package:kivixa/pages/editor/editor.dart';

class Whiteboard extends StatelessWidget {
  const Whiteboard({super.key});

  static const filePath = '/_whiteboard';

  static bool needsToAutoClearWhiteboard =
      stows.autoClearWhiteboardOnExit.value;

  static final _whiteboardKey = GlobalKey<EditorState>(
    debugLabel: 'whiteboard',
  );

  static SavingState? get savingState =>
      _whiteboardKey.currentState?.savingState.value;
  static void triggerSave() {
    final editorState = _whiteboardKey.currentState;
    if (editorState == null) return;
    assert(editorState.savingState.value == SavingState.waitingToSave);
    editorState.saveToFile();
    editorState.snackBarNeedsToSaveBeforeExiting();
  }

  @override
  Widget build(BuildContext context) {
    return Editor(
      key: _whiteboardKey,
      path: filePath,
      customTitle: t.home.titles.whiteboard,
    );
  }
}
