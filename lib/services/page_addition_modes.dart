import 'dart:async';

enum PageAdditionMode { auto, swipeUp }

enum PageAdditionOverlayState { hidden, prompt }

class PageAdditionModes {
  PageAdditionMode _mode = PageAdditionMode.auto;
  PageAdditionMode get mode => _mode;

  final _overlayStateController = StreamController<PageAdditionOverlayState>.broadcast();
  Stream<PageAdditionOverlayState> get overlayStateStream => _overlayStateController.stream;

  void setMode(PageAdditionMode mode) {
    _mode = mode;
  }

  void handleSwipe(double distance) {
    if (_mode == PageAdditionMode.swipeUp) {
      if (distance > 100.0) { // Threshold for showing the prompt
        _overlayStateController.add(PageAdditionOverlayState.prompt);
      } else {
        _overlayStateController.add(PageAdditionOverlayState.hidden);
      }
    }
  }

  void completeAdd() {
    if (_mode == PageAdditionMode.swipeUp) {
      _overlayStateController.add(PageAdditionOverlayState.hidden);
      // Here you would trigger the actual page addition logic.
    }
  }

  void dispose() {
    _overlayStateController.close();
  }
}