import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/ai/chat_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AIChatMessage', () {
    test('should create with required fields', () {
      final message = AIChatMessage(role: 'user', content: 'Hello!');
      expect(message.role, 'user');
      expect(message.content, 'Hello!');
      expect(message.isLoading, false);
      expect(message.timestamp, isA<DateTime>());
    });

    test('should identify user messages', () {
      final message = AIChatMessage(role: 'user', content: 'Hi');
      expect(message.isUser, true);
      expect(message.isAssistant, false);
      expect(message.isSystem, false);
    });

    test('should identify assistant messages', () {
      final message = AIChatMessage(role: 'assistant', content: 'Hello!');
      expect(message.isUser, false);
      expect(message.isAssistant, true);
      expect(message.isSystem, false);
    });

    test('should identify system messages', () {
      final message = AIChatMessage(role: 'system', content: 'Be helpful.');
      expect(message.isUser, false);
      expect(message.isAssistant, false);
      expect(message.isSystem, true);
    });

    test('should track loading state', () {
      final loading = AIChatMessage(
        role: 'assistant',
        content: '',
        isLoading: true,
      );
      expect(loading.isLoading, true);

      final notLoading = AIChatMessage(
        role: 'assistant',
        content: 'Response',
        isLoading: false,
      );
      expect(notLoading.isLoading, false);
    });

    test('copyWith should update specified fields', () {
      final original = AIChatMessage(
        role: 'assistant',
        content: '',
        isLoading: true,
      );

      final updated = original.copyWith(
        content: 'Response text',
        isLoading: false,
      );

      expect(updated.role, 'assistant');
      expect(updated.content, 'Response text');
      expect(updated.isLoading, false);
    });

    test('toChatMessage should convert correctly', () {
      final aiMessage = AIChatMessage(role: 'user', content: 'Test');
      final chatMessage = aiMessage.toChatMessage();

      expect(chatMessage.role, 'user');
      expect(chatMessage.content, 'Test');
    });
  });

  // Skip AIChatController tests as they require platform plugins
  // (path_provider, background_downloader) that aren't available in test environment
  group('AIChatController', () {
    test(
      'should initialize empty',
      () {
        final controller = AIChatController();
        expect(controller.messages, isEmpty);
        expect(controller.isGenerating, false);
      },
      skip: 'Requires platform plugins (path_provider, background_downloader)',
    );

    test('should accept system prompt', () {
      final controller = AIChatController(
        systemPrompt: 'You are a helpful assistant.',
      );
      expect(controller.systemPrompt, 'You are a helpful assistant.');
    }, skip: 'Requires platform plugins');

    test('should allow updating system prompt', () {
      final controller = AIChatController();
      controller.systemPrompt = 'New prompt';
      expect(controller.systemPrompt, 'New prompt');
    }, skip: 'Requires platform plugins');

    test('clearMessages should empty the list', () async {
      final controller = AIChatController();
      await controller.sendMessage('Test');
      expect(controller.messages, isNotEmpty);

      controller.clearMessages();
      expect(controller.messages, isEmpty);
    }, skip: 'Requires platform plugins');

    test(
      'removeLastMessage should remove one message',
      () async {
        final controller = AIChatController();
        await controller.sendMessage('First');
        // Wait for response
        await Future.delayed(const Duration(milliseconds: 100));

        final countBefore = controller.messages.length;
        controller.removeLastMessage();
        expect(controller.messages.length, countBefore - 1);
      },
      skip: 'Requires platform plugins',
    );

    test('should not send empty messages', () async {
      final controller = AIChatController();
      await controller.sendMessage('');
      await controller.sendMessage('   ');
      expect(controller.messages, isEmpty);
    }, skip: 'Requires platform plugins');

    test('should notify listeners on changes', () async {
      final controller = AIChatController();
      var notified = false;
      controller.addListener(() {
        notified = true;
      });

      await controller.sendMessage('Test');
      expect(notified, true);
    }, skip: 'Requires platform plugins');

    test('dispose should not throw', () {
      final controller = AIChatController();
      expect(() => controller.dispose(), returnsNormally);
    }, skip: 'Requires platform plugins');
  });
}
