import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/ai/mcp_chat_controller.dart';
import 'package:kivixa/components/ai/mcp_chat_interface.dart';

class _FakeMcpChatController extends Fake implements MCPChatController {
  _FakeMcpChatController(List<MCPChatMessage> initialMessages)
    : _messages = List<MCPChatMessage>.from(initialMessages);

  final List<MCPChatMessage> _messages;
  var clearCalled = false;
  var retryCalled = false;

  @override
  List<MCPChatMessage> get messages => List.unmodifiable(_messages);

  @override
  bool get isGenerating => false;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  Future<void> sendMessage(String content, {BuildContext? context}) async {}

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
          content: 'Use create_folder to create sandbox/tmp_folder.',
        ),
        MCPChatMessage(role: 'assistant', content: 'Done.'),
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
}
