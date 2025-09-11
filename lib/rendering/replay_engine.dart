import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import '../data/database/database_provider.dart';

class ReplayEngine {
  final DatabaseProvider _provider = DatabaseProvider();
  final StreamController<List<dynamic>> _commandStream =
      StreamController.broadcast();
  Isolate? _isolate;
  ReceivePort? _receivePort;

  Stream<List<dynamic>> get commandStream => _commandStream.stream;

  Future<void> startReplay(int pageId) async {
    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_replayIsolate, [
      _receivePort!.sendPort,
      pageId,
    ]);
    _receivePort!.listen((data) {
      _commandStream.add(data as List<dynamic>);
    });
  }

  void stopReplay() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _receivePort?.close();
    _receivePort = null;
  }

  static Future<void> _replayIsolate(List args) async {
    final SendPort sendPort = args[0];
    final int pageId = args[1];
    // TODO: Open SQLite, fetch stroke_chunks for pageId, decode with FFI, yield drawing commands
    // sendPort.send(commands);
  }
}
