import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp
        .createTemp('kivixa_test')
        .then((dir) => dir.path);
  }

  @override
  Future<String?> getTemporaryPath() async {
    return Directory.systemTemp
        .createTemp('kivixa_test_tmp')
        .then((dir) => dir.path);
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    return Directory.systemTemp
        .createTemp('kivixa_test_support')
        .then((dir) => dir.path);
  }
}

Directory? tmpDir;

void setupMockPathProvider() {
  PathProviderPlatform.instance = MockPathProviderPlatform();

  tmpDir = Directory.systemTemp.createTempSync('kivixa_test');
}

void setupMockPrinting() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('printing'), (
        MethodCall methodCall,
      ) async {
        if (methodCall.method == 'printingInfo') {
          return {
            'canRaster': true,
            'canPrint': false,
            'canShare': false,
            'canConvertHtml': false,
            'canListPrinters': false,
          };
        }
        return null;
      });
}

void setupMockAudioplayers() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers'), (
    MethodCall methodCall,
  ) async {
    return null;
  });
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('xyz.luan/audioplayers.global'),
          (MethodCall methodCall) async {
    return null;
  });
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('xyz.luan/audioplayers.global/events'),
          (MethodCall methodCall) async {
    return null;
  });
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('xyz.luan/audioplayers/events/pencilSoundEffect'),
          (MethodCall methodCall) async {
    return null;
  });
}
