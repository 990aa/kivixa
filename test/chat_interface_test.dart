import 'dart:convert';

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

  group('Chat export JSON', () {
    test('exports only user and assistant messages in order', () {
      final messages = [
        AIChatMessage(role: 'system', content: 'system prompt'),
        AIChatMessage(role: 'user', content: 'What changed?'),
        AIChatMessage(role: 'assistant', content: 'Here is the summary.'),
        AIChatMessage(role: 'assistant', content: '', isLoading: true),
      ];

      final jsonPayload = buildChatConversationExportJson(
        messages,
        sessionType: 'ai-chat',
      );

      final decoded = jsonDecode(jsonPayload) as Map<String, dynamic>;
      expect(decoded['sessionType'], 'ai-chat');
      expect(decoded['schemaVersion'], 1);
      expect(decoded['messageCount'], 2);

      final exportedMessages = decoded['messages'] as List<dynamic>;
      expect(exportedMessages.length, 2);
      expect((exportedMessages[0] as Map<String, dynamic>)['role'], 'user');
      expect(
        (exportedMessages[0] as Map<String, dynamic>)['content'],
        'What changed?',
      );
      expect(
        (exportedMessages[1] as Map<String, dynamic>)['role'],
        'assistant',
      );
      expect(
        (exportedMessages[1] as Map<String, dynamic>)['content'],
        'Here is the summary.',
      );
    });
  });

  group('Reasoning parser', () {
    test('extracts think block and keeps final answer content', () {
      const raw = '<think>step 1\nstep 2</think>\n\nThe final answer is 42.';
      final parsed = parseReasoningContent(raw);

      expect(parsed.hasReasoning, true);
      expect(parsed.reasoningContent, 'step 1\nstep 2');
      expect(parsed.visibleContent, 'The final answer is 42.');
    });

    test('extracts thinking block regardless of case', () {
      const raw =
          '<THINKING>internal notes</THINKING>\nVisible output for user.';
      final parsed = parseReasoningContent(raw);

      expect(parsed.hasReasoning, true);
      expect(parsed.reasoningContent, 'internal notes');
      expect(parsed.visibleContent, 'Visible output for user.');
    });

    test('returns original content when no reasoning tags exist', () {
      const raw = 'Regular assistant message without hidden reasoning.';
      final parsed = parseReasoningContent(raw);

      expect(parsed.hasReasoning, false);
      expect(parsed.reasoningContent, isNull);
      expect(parsed.visibleContent, raw);
    });

    test('parses Qwen 3.5 Claude-distilled reasoning tags', () {
      const raw =
          '<think>Analyze constraints and choose plan.</think>\nFinal implementation summary.';
      final parsed = parseReasoningContent(raw);

      expect(parsed.hasReasoning, true);
      expect(parsed.reasoningContent, 'Analyze constraints and choose plan.');
      expect(parsed.visibleContent, 'Final implementation summary.');
    });

    test('parses Phi-4 mini reasoning tags', () {
      const raw = '<thinking>step A -> step B</thinking>\nAnswer for user.';
      final parsed = parseReasoningContent(raw);

      expect(parsed.hasReasoning, true);
      expect(parsed.reasoningContent, 'step A -> step B');
      expect(parsed.visibleContent, 'Answer for user.');
    });

    test(
      'parses reasoning blocks for all requested strongest reasoning models',
      () {
        const samples = {
          'qwen35-4b-claude46-distilled-v2-q4km':
              '<think>plan for 4b model</think>\nfinal 4b answer',
          'qwen35-2b-claude46-distilled-q5km':
              '<think>plan for 2b model</think>\nfinal 2b answer',
          'qwen35-08b-claude46-distilled-q5km':
              '<think>plan for 0.8b model</think>\nfinal 0.8b answer',
          'phi4-mini-reasoning-q4km':
              '<thinking>plan for phi reasoning</thinking>\nfinal phi answer',
        };

        for (final entry in samples.entries) {
          final parsed = parseReasoningContent(entry.value);
          expect(parsed.hasReasoning, true, reason: entry.key);
          expect(parsed.reasoningContent, isNotNull, reason: entry.key);
          expect(parsed.visibleContent, contains('final'), reason: entry.key);
        }
      },
    );
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
