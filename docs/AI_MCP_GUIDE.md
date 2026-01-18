# AI MCP (Model Context Protocol) System Guide

This document provides comprehensive documentation for Kivixa's AI MCP system, which enables AI-assisted task execution with proper safety controls and model management.

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Available Tools](#available-tools)
4. [Model Routing](#model-routing)
5. [Safety & Security](#safety--security)
6. [Integration Guide](#integration-guide)
7. [Testing Guide](#testing-guide)
8. [Troubleshooting](#troubleshooting)

## Overview

The MCP system provides a secure framework for AI models to execute actions on behalf of users. It implements:

- **Multi-Model Routing**: Automatically selects the best model (Phi-4, Functionary, Qwen) based on task type
- **Sandboxed Operations**: All file operations are restricted to the `browse/` directory
- **User Confirmation**: All destructive or modifying actions require explicit user approval
- **Lua Integration**: Calendar and timer operations via sandboxed Lua scripts

### Key Components

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter/Dart Side                        │
├─────────────────────────────────────────────────────────────┤
│  MCPService          ModelRouterService      Chat Interface │
│  - Tool execution    - Task classification   - User input   │
│  - Confirmation UI   - Model selection       - AI responses │
│  - Lua integration   - System prompts                       │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ Flutter Rust Bridge
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Rust Native Side                        │
├─────────────────────────────────────────────────────────────┤
│  mcp.rs              inference.rs            api.rs         │
│  - Path validation   - Multi-model support   - FRB bindings │
│  - File operations   - Chat templates        - API exports  │
│  - Task classification                                       │
└─────────────────────────────────────────────────────────────┘
```

## Architecture

### Rust MCP Core (`native/src/mcp.rs`)

The Rust implementation provides:

1. **MCPTool Enum**: Defines all available tools
2. **Path Validation**: Ensures all paths are within the sandbox
3. **File Operations**: Read, write, delete, create folder, list files
4. **Task Classification**: Analyzes user messages to determine task type
5. **Model Routing**: Maps task categories to appropriate models

### Dart MCP Service (`lib/services/ai/mcp_service.dart`)

The Dart service handles:

1. **Tool Execution**: Calls Rust functions via FFI
2. **Confirmation Dialogs**: Shows users what actions will be performed
3. **Lua Integration**: Routes Lua scripts to the plugin system
4. **Result Handling**: Processes and returns execution results

### Model Router (`lib/services/ai/model_router.dart`)

Manages model selection:

1. **Task Analysis**: Classifies user messages
2. **Model Loading**: Loads appropriate GGUF models
3. **System Prompts**: Generates optimized prompts per model

## Available Tools

### File Operations

| Tool | Description | Parameters |
|------|-------------|------------|
| `read_file` | Read file contents | `path` (required) |
| `write_file` | Write/create a file | `path`, `content` (required), `append` (optional) |
| `delete_file` | Delete a file | `path` (required) |
| `create_folder` | Create a directory | `path` (required) |
| `list_files` | List directory contents | `path` (optional), `recursive` (optional) |

### Lua Execution

| Tool | Description | Parameters |
|------|-------------|------------|
| `calendar_lua` | Execute calendar scripts | `script`, `description` (required) |
| `timer_lua` | Execute timer scripts | `script`, `description` (required) |

### Export

| Tool | Description | Parameters |
|------|-------------|------------|
| `export_markdown` | Export content as .md file | `path`, `content` (required), `append` (optional) |

### Tool Schema Example

```json
{
  "name": "write_file",
  "description": "Write or create a file in the notes folder",
  "parameters": [
    {
      "name": "path",
      "description": "Relative path to the file within browse/ folder",
      "type": "string",
      "required": true
    },
    {
      "name": "content",
      "description": "Content to write to the file",
      "type": "string",
      "required": true
    },
    {
      "name": "append",
      "description": "Whether to append to existing file (default: false)",
      "type": "boolean",
      "required": false
    }
  ]
}
```

## Model Routing

### Task Categories

| Category | Model | Use Cases |
|----------|-------|-----------|
| Conversation | Phi-4 Mini | General Q&A, explanations, reasoning |
| Tool Use | Functionary | File operations, calendar, timers |
| Code Generation | Qwen 2.5 | Lua scripts, code snippets |

### Classification Keywords

**Tool Use Detection**:
- File operations: "create file", "delete file", "read file", "write file"
- Organization: "create folder", "list files", "new folder"
- Productivity: "calendar", "add event", "schedule", "reminder"
- Timers: "timer", "start timer", "stop timer"
- Export: "export", "save as"

**Code Generation Detection**:
- Programming: "write code", "generate code", "implement"
- Debugging: "debug", "fix the code", "refactor"
- Languages: "python code", "javascript code"

**Conversation (Default)**:
- Questions: "what is", "explain", "why"
- General chat: greetings, opinions, discussions

## Safety & Security

### Path Sandboxing

All file operations are restricted to the `browse/` directory:

```rust
// Path validation rejects:
// - Parent traversal: "../outside.md" ❌
// - Absolute paths outside sandbox: "/etc/passwd" ❌
// - Complex traversal: "folder/../../../etc/passwd" ❌

// Allowed:
// - Relative paths: "notes/meeting.md" ✓
// - Nested folders: "deep/nested/path/file.md" ✓
```

### Allowed File Extensions

By default, only safe text-based extensions are allowed:

- `md` - Markdown
- `txt` - Plain text
- `json` - JSON
- `yaml`, `yml` - YAML
- `toml` - TOML
- `csv` - CSV

Binary files (`.exe`, `.dll`, `.sh`, etc.) are blocked.

### File Size Limits

- Maximum file size: **10MB** (configurable)
- Prevents memory exhaustion from large file reads

### User Confirmation

All tool executions require explicit user approval:

```dart
// The confirmation dialog shows:
// 1. Tool name and icon
// 2. Human-readable description
// 3. Parameters being used
// 4. Warning for destructive operations (delete)
```

## Integration Guide

### Initializing MCP

```dart
import 'package:kivixa/services/ai/mcp_service.dart';

// Initialize with browse directory
final mcpService = MCPService.instance;
await mcpService.initialize('/path/to/browse');

// Optionally set plugin API for Lua execution
mcpService.setPluginApi(myPluginApi);
```

### Executing Tool Calls

```dart
// With user confirmation (recommended)
final result = await mcpService.executeWithConfirmation(
  context,
  PendingToolCall(
    tool: 'write_file',
    parameters: {'path': 'notes.md', 'content': '# My Notes'},
    description: 'Creating a notes file',
  ),
);

if (result.success) {
  print('Success: ${result.result}');
} else if (result.userCancelled) {
  print('User cancelled');
} else {
  print('Error: ${result.result}');
}

// Direct execution (for automated workflows)
final result = await mcpService.executeDirectly(toolCall);
```

### Using Model Router

```dart
import 'package:kivixa/services/ai/model_router.dart';

final router = ModelRouterService.instance;

// Analyze message and get model recommendation
final selection = router.analyzeAndSelectModel(userMessage);
print('Recommended: ${selection.modelName}');

// Auto-switch to recommended model
await router.switchToRecommendedModel(userMessage);

// Get optimized system prompt
final systemPrompt = router.getOptimizedSystemPrompt(selection.modelType);
```

## Testing Guide

### Running Rust Tests

```powershell
cd native
cargo test mcp -- --test-threads=1
```

Expected output: All 10 MCP tests pass

### Running Flutter Tests

```powershell
flutter test test/mcp_service_test.dart
```

### Test Categories

1. **Unit Tests** (`test/mcp_service_test.dart`)
   - MCPToolInfo creation
   - MCPExecutionResult handling
   - PendingToolCall display descriptions
   - Task classification patterns

2. **Rust Integration Tests** (`native/src/mcp.rs`)
   - Path validation security
   - File operations (read/write/delete)
   - Folder operations
   - Extension validation
   - Task classification
   - Model routing

### Manual Testing Checklist

- [ ] File operations work within browse/ directory
- [ ] Path traversal attempts are blocked
- [ ] Binary file extensions are rejected
- [ ] Confirmation dialog appears before execution
- [ ] User can cancel operations
- [ ] Lua scripts execute via plugin API
- [ ] Model switching works based on task type

## Troubleshooting

### Common Issues

**MCP not initialized error**:
```dart
// Ensure MCP is initialized before use
if (!mcpService.isInitialized) {
  await mcpService.initialize(browseDir);
}
```

**Path validation failures**:
```dart
// Check if path is valid before operations
if (!mcpService.validatePath(path)) {
  print('Invalid path - must be within browse/ directory');
}
```

**Lua execution not available**:
```dart
// Ensure plugin API is set
mcpService.setPluginApi(pluginApi);
```

**Model not loading**:
```dart
// Check model availability
final selection = router.analyzeAndSelectModel(message);
if (!selection.isAvailable) {
  print('Model ${selection.modelName} not downloaded');
}
```

### Debug Logging

Enable detailed logging:

```dart
// Rust-side logging is enabled via env_logger
// Dart-side uses debugPrint for development builds
```

### Build Issues

If the native build fails:

```powershell
# Clean and rebuild
cd native
cargo clean
cd ..
powershell -ExecutionPolicy Bypass -File scripts/build_native.ps1 -SkipAndroid
```

## API Reference

### MCPService

| Method | Description |
|--------|-------------|
| `initialize(String browseDir)` | Initialize MCP with base directory |
| `isInitialized` | Check if MCP is ready |
| `getAvailableTools()` | Get list of all tools |
| `getToolSchemas()` | Get JSON schemas for AI |
| `classifyTask(String message)` | Classify message task type |
| `getModelForTask(MCPTaskCategory)` | Get recommended model name |
| `parseToolCall(String json)` | Parse AI tool call response |
| `executeWithConfirmation(...)` | Execute with user approval |
| `executeDirectly(...)` | Execute without confirmation |
| `readFile(String path)` | Direct file read |
| `writeFile(String path, String content)` | Direct file write |
| `deleteFile(String path)` | Direct file delete |
| `createFolder(String path)` | Direct folder create |
| `listFiles(String path)` | Direct directory listing |
| `validatePath(String path)` | Check if path is valid |

### ModelRouterService

| Method | Description |
|--------|-------------|
| `currentModel` | Get currently loaded model type |
| `isModelLoaded(AIModelType)` | Check if specific model is loaded |
| `analyzeAndSelectModel(String)` | Get model recommendation |
| `switchToRecommendedModel(String)` | Auto-switch to best model |
| `loadModel(AIModelType, String?)` | Load specific model |
| `getBestModelPath(MCPTaskCategory)` | Get path to best available model |
| `getOptimizedSystemPrompt(AIModelType)` | Get model-specific prompt |
| `needsModelSwitch(String)` | Check if switch is needed |
