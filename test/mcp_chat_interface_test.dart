import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/ai/mcp_chat_controller.dart';
import 'package:kivixa/components/ai/mcp_chat_interface.dart';
import 'package:kivixa/services/ai/chat_attachment_service.dart';

class _FakeMcpChatController extends Fake implements MCPChatController {
  _FakeMcpChatController(List<MCPChatMessage> initialMessages)
    : _messages = List<MCPChatMessage>.from(initialMessages);

  final List<MCPChatMessage> _messages;
  var clearCalled = false;
  var retryCalled = false;
  String? lastSentContent;
  var lastSentAttachments = const <ChatAttachment>[];

  @override
  List<MCPChatMessage> get messages => List.unmodifiable(_messages);

  @override
  bool get isGenerating => false;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  Future<void> sendMessage(
    String content, {
    BuildContext? context,
    List<ChatAttachment> attachments = const <ChatAttachment>[],
  }) async {
    lastSentContent = content;
    lastSentAttachments = List<ChatAttachment>.from(attachments);
  }

  @override
  void clearMessages() {
    clearCalled = true;
    _messages.clear();
  }

  @override
  Future<void> retryLastMessage({BuildContext? context}) async {
    retryCalled = true;
  }

  @override
  String exportConversationAsJson({String sessionType = 'mcp-chat'}) {
    return '{"sessionType":"$sessionType"}';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'MCP chat shows copy for user and assistant, plus retry for assistant',
    (tester) async {
      final controller = _FakeMcpChatController([
        MCPChatMessage(
          role: 'user',
          content: 'Use `create_folder` to create **sandbox/tmp_folder**.',
        ),
        MCPChatMessage(role: 'assistant', content: '- Done\n- Confirmed'),
      ]);

      String? exportedPayload;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: MCPChatInterface(
                controller: controller,
                context: context,
                onExportChat: (payload) async {
                  exportedPayload = payload;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Copy'), findsNWidgets(2));
      expect(find.byTooltip('Retry'), findsOneWidget);
      expect(find.byType(MarkdownBody), findsWidgets);

      await tester.tap(find.byTooltip('Retry'));
      await tester.pumpAndSettle();
      expect(controller.retryCalled, isTrue);

      await tester.tap(find.byTooltip('Export chat as JSON'));
      await tester.pumpAndSettle();
      expect(exportedPayload, contains('mcp-chat'));

      await tester.tap(find.byTooltip('Clear chat'));
      await tester.pumpAndSettle();
      expect(controller.clearCalled, isTrue);
    },
  );

  testWidgets('MCP composer supports attachment add/remove and send payload', (
    tester,
  ) async {
    final controller = _FakeMcpChatController(const []);

    const attachment = ChatAttachment(
      id: 'mcp-1',
      filePath: '/tmp/notes.txt',
      fileName: 'notes.txt',
      sizeBytes: 96,
      mediaType: 'text/plain',
      extractedText: 'Attachment payload for MCP',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: MCPChatInterface(
              controller: controller,
              context: context,
              onPickAttachments: () async => const [attachment],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add attachments'));
    await tester.pumpAndSettle();

    expect(find.text('notes.txt'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove attachment'));
    await tester.pumpAndSettle();
    expect(find.text('notes.txt'), findsNothing);

    await tester.tap(find.byTooltip('Add attachments'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Check attachment');
    await tester.tap(find.byIcon(Icons.send).first);
    await tester.pumpAndSettle();

    expect(controller.lastSentContent, 'Check attachment');
    expect(controller.lastSentAttachments.length, 1);
    expect(controller.lastSentAttachments.first.fileName, 'notes.txt');
  });

  testWidgets('MCP composer navigates prompt history with arrow keys', (
    tester,
  ) async {
    final controller = _FakeMcpChatController([
      MCPChatMessage(role: 'user', content: 'prompt one'),
      MCPChatMessage(role: 'assistant', content: 'answer one'),
      MCPChatMessage(role: 'user', content: 'prompt two'),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: MCPChatInterface(controller: controller, context: context),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField).first);
    await tester.enterText(find.byType(TextField).first, 'draft prompt');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();

    var field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.controller?.text, 'prompt two');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.controller?.text, 'prompt one');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.controller?.text, 'prompt two');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.controller?.text, 'draft prompt');
  });

  testWidgets('MCP header can be hidden for merged top bar layouts', (
    tester,
  ) async {
    final controller = _FakeMcpChatController(const []);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: MCPChatInterface(
              controller: controller,
              context: context,
              showHeader: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kivixa MCP Assistant'), findsNothing);
  });
}
