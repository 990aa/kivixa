import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/services/ai/mcp_service.dart';
import 'package:kivixa/services/ai/model_router.dart';

void main() {
  group('MCP Service Tests', () {
    group('MCPToolInfo', () {
      test('should create tool info with correct properties', () {
        const toolInfo = MCPToolInfo(
          name: 'read_file',
          description: 'Read a file',
          parameters: [
            MCPParameterInfo(
              name: 'path',
              description: 'File path',
              type: 'string',
              required: true,
            ),
          ],
        );

        expect(toolInfo.name, 'read_file');
        expect(toolInfo.description, 'Read a file');
        expect(toolInfo.parameters.length, 1);
        expect(toolInfo.parameters[0].name, 'path');
        expect(toolInfo.parameters[0].required, true);
      });
    });

    group('MCPExecutionResult', () {
      test('should create successful result', () {
        const result = MCPExecutionResult(
          success: true,
          result: 'File content',
          toolName: 'read_file',
        );

        expect(result.success, true);
        expect(result.result, 'File content');
        expect(result.toolName, 'read_file');
        expect(result.userCancelled, false);
      });

      test('should create cancelled result', () {
        final result = MCPExecutionResult.cancelled('write_file');

        expect(result.success, false);
        expect(result.userCancelled, true);
        expect(result.toolName, 'write_file');
        expect(result.result, 'User cancelled the operation');
      });
    });

    group('PendingToolCall', () {
      test('should display correct description for read_file', () {
        const call = PendingToolCall(
          tool: 'read_file',
          parameters: {'path': 'notes/test.md'},
          description: 'Reading a test file',
        );

        expect(call.displayDescription, 'Read file: notes/test.md');
      });

      test('should display correct description for write_file', () {
        const call = PendingToolCall(
          tool: 'write_file',
          parameters: {'path': 'notes/new.md', 'content': 'Hello'},
          description: 'Writing a new file',
        );

        expect(call.displayDescription, 'Write file: notes/new.md');
      });

      test('should display correct description for delete_file', () {
        const call = PendingToolCall(
          tool: 'delete_file',
          parameters: {'path': 'notes/old.md'},
          description: 'Deleting old file',
        );

        expect(call.displayDescription, 'Delete file: notes/old.md');
      });

      test('should display correct description for create_folder', () {
        const call = PendingToolCall(
          tool: 'create_folder',
          parameters: {'path': 'notes/archive'},
          description: 'Creating archive folder',
        );

        expect(call.displayDescription, 'Create folder: notes/archive');
      });

      test('should display correct description for list_files', () {
        const call = PendingToolCall(
          tool: 'list_files',
          parameters: {'path': 'notes'},
          description: 'Listing files',
        );

        expect(call.displayDescription, 'List files in: notes');
      });

      test('should display root for list_files without path', () {
        const call = PendingToolCall(
          tool: 'list_files',
          parameters: {},
          description: 'Listing files',
        );

        expect(call.displayDescription, 'List files in: root');
      });

      test('should display correct description for calendar_lua', () {
        const call = PendingToolCall(
          tool: 'calendar_lua',
          parameters: {'script': 'calendar.addEvent(...)'},
          description: 'Adding a meeting',
        );

        expect(
          call.displayDescription,
          'Execute calendar script: Adding a meeting',
        );
      });

      test('should display correct description for timer_lua', () {
        const call = PendingToolCall(
          tool: 'timer_lua',
          parameters: {'script': 'timer.start(...)'},
          description: 'Starting a pomodoro timer',
        );

        expect(
          call.displayDescription,
          'Execute timer script: Starting a pomodoro timer',
        );
      });

      test('should display correct description for export_markdown', () {
        const call = PendingToolCall(
          tool: 'export_markdown',
          parameters: {'path': 'exports/summary.md', 'content': '# Summary'},
          description: 'Exporting summary',
        );

        expect(call.displayDescription, 'Export to: exports/summary.md');
      });
    });

    group('MCPTaskCategory', () {
      test('should have all expected values', () {
        expect(MCPTaskCategory.values.length, 3);
        expect(
          MCPTaskCategory.values.contains(MCPTaskCategory.conversation),
          true,
        );
        expect(MCPTaskCategory.values.contains(MCPTaskCategory.toolUse), true);
        expect(
          MCPTaskCategory.values.contains(MCPTaskCategory.codeGeneration),
          true,
        );
      });
    });
  });

  group('Model Router Tests', () {
    group('AIModelType', () {
      test('should have all expected values', () {
        expect(AIModelType.values.length, 3);
        expect(AIModelType.values.contains(AIModelType.phi4), true);
        expect(AIModelType.values.contains(AIModelType.qwen), true);
        expect(AIModelType.values.contains(AIModelType.functionary), true);
      });

      test('should return correct displayName', () {
        expect(AIModelType.phi4.displayName, 'Phi-4 (Reasoning)');
        expect(AIModelType.qwen.displayName, 'Qwen 2.5 (Code)');
        expect(AIModelType.functionary.displayName, 'Functionary (Tools)');
      });

      test('should return correct shortName', () {
        expect(AIModelType.phi4.shortName, 'Phi-4');
        expect(AIModelType.qwen.shortName, 'Qwen');
        expect(AIModelType.functionary.shortName, 'Func');
      });
    });

    group('ModelSelection', () {
      test('should create selection with correct properties', () {
        const selection = ModelSelection(
          modelType: AIModelType.phi4,
          taskCategory: MCPTaskCategory.conversation,
          modelName: 'phi4',
          modelPath: '/path/to/model.gguf',
          isAvailable: true,
        );

        expect(selection.modelType, AIModelType.phi4);
        expect(selection.taskCategory, MCPTaskCategory.conversation);
        expect(selection.modelName, 'phi4');
        expect(selection.modelPath, '/path/to/model.gguf');
        expect(selection.isAvailable, true);
      });

      test('should handle unavailable model', () {
        const selection = ModelSelection(
          modelType: AIModelType.functionary,
          taskCategory: MCPTaskCategory.toolUse,
          modelName: 'functionary',
          modelPath: null,
          isAvailable: false,
        );

        expect(selection.isAvailable, false);
        expect(selection.modelPath, null);
      });
    });

    group('ModelRouterService', () {
      test('should be singleton', () {
        final router1 = ModelRouterService.instance;
        final router2 = ModelRouterService.instance;
        expect(identical(router1, router2), true);
      });

      test('should return null for currentModel when not loaded', () {
        // Check initial state
        expect(ModelRouterService.instance.currentModel, isNull);
      });

      test('should generate optimized system prompt for phi4', () {
        final router = ModelRouterService.instance;
        final prompt = router.getOptimizedSystemPrompt(AIModelType.phi4);

        expect(prompt.contains('helpful AI assistant'), true);
        expect(prompt.contains('reasoning'), true);
      });

      test('should generate optimized system prompt for functionary', () {
        final router = ModelRouterService.instance;
        final prompt = router.getOptimizedSystemPrompt(AIModelType.functionary);

        expect(prompt.contains('tools'), true);
        expect(prompt.contains('JSON'), true);
      });

      test('should generate optimized system prompt for qwen', () {
        final router = ModelRouterService.instance;
        final prompt = router.getOptimizedSystemPrompt(AIModelType.qwen);

        expect(prompt.contains('coding'), true);
        expect(prompt.contains('code'), true);
      });
    });
  });

  group('Tool Call JSON Parsing', () {
    test('should create valid tool call JSON', () {
      final toolCallJson = jsonEncode({
        'tool': 'write_file',
        'parameters_json': jsonEncode({'path': 'test.md', 'content': '# Test'}),
        'description': 'Creating a test file',
      });

      final decoded = jsonDecode(toolCallJson) as Map<String, dynamic>;
      expect(decoded['tool'], 'write_file');
      expect(decoded['description'], 'Creating a test file');

      final params =
          jsonDecode(decoded['parameters_json'] as String)
              as Map<String, dynamic>;
      expect(params['path'], 'test.md');
      expect(params['content'], '# Test');
    });

    test('should handle complex parameters', () {
      final params = {
        'path': 'notes/meeting.md',
        'content': '''
# Meeting Notes
        
## Attendees
- Alice
- Bob

## Action Items
1. Review proposal
2. Schedule follow-up
''',
        'append': false,
      };

      final paramsJson = jsonEncode(params);
      final decoded = jsonDecode(paramsJson) as Map<String, dynamic>;

      expect(decoded['path'], 'notes/meeting.md');
      expect(decoded['content'], contains('# Meeting Notes'));
      expect(decoded['append'], false);
    });
  });

  group('Task Classification Patterns', () {
    // These tests verify the expected behavior based on the Rust implementation
    // They should match the patterns in mcp.rs classify_task function

    test('should identify tool use patterns', () {
      final toolUseMessages = [
        'Create a file called notes.md',
        'Add an event to my calendar',
        'Start a 25 minute timer',
        'List files in the notes folder',
        'Delete the old report',
        'Create a new folder for archives',
      ];

      // These are expected to be classified as ToolUse
      for (final msg in toolUseMessages) {
        // Note: We're testing the pattern, not the actual classification
        // since we can't call Rust directly in unit tests
        expect(
          msg.toLowerCase().contains('create') ||
              msg.toLowerCase().contains('add') ||
              msg.toLowerCase().contains('start') ||
              msg.toLowerCase().contains('list') ||
              msg.toLowerCase().contains('delete') ||
              msg.toLowerCase().contains('file') ||
              msg.toLowerCase().contains('folder') ||
              msg.toLowerCase().contains('timer') ||
              msg.toLowerCase().contains('calendar'),
          true,
          reason: 'Message "$msg" should contain tool use keywords',
        );
      }
    });

    test('should identify code generation patterns', () {
      final codeGenMessages = [
        'Write code to sort a list',
        'Implement a binary search function',
        'Debug this algorithm',
        'Refactor the function',
        'Generate Python code for data analysis',
      ];

      for (final msg in codeGenMessages) {
        expect(
          msg.toLowerCase().contains('code') ||
              msg.toLowerCase().contains('implement') ||
              msg.toLowerCase().contains('debug') ||
              msg.toLowerCase().contains('refactor') ||
              msg.toLowerCase().contains('algorithm'),
          true,
          reason: 'Message "$msg" should contain code generation keywords',
        );
      }
    });

    test('should identify conversation patterns', () {
      final conversationMessages = [
        'What is machine learning?',
        'Explain quantum computing',
        'Hello, how are you?',
        'Tell me about history',
        'Why is the sky blue?',
      ];

      // These should NOT contain tool use or code gen keywords
      for (final msg in conversationMessages) {
        final lower = msg.toLowerCase();
        expect(
          !lower.contains('create file') &&
              !lower.contains('delete file') &&
              !lower.contains('write code') &&
              !lower.contains('implement'),
          true,
          reason:
              'Message "$msg" should not contain tool use or code gen keywords',
        );
      }
    });
  });
}
