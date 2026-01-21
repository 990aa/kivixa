# MCP Testing Guide

This guide provides detailed testing procedures for Kivixa's AI MCP (Model Context Protocol) system.

## Prerequisites

Before testing, ensure you have:

1. **Rust toolchain** (1.70+): `rustup update stable`
2. **Flutter SDK** (3.x): `flutter doctor`
3. **Native build complete**: Run `scripts/build_native.ps1`

## Test Architecture

```
test/
├── mcp_service_test.dart      # Dart unit tests
├── model_router_test.dart     # Model routing tests
└── ...

native/src/
├── mcp.rs                     # Rust tests at bottom of file
└── ...
```

## Running Tests

### Rust Tests (Native Side)

```powershell
# Run all MCP tests
cd native
cargo test mcp

# Run with output
cargo test mcp -- --nocapture

# Run specific test
cargo test test_path_validation

# Run single-threaded (required for file-based tests)
cargo test mcp -- --test-threads=1
```

### Flutter Tests (Dart Side)

```powershell
# Run all MCP-related tests
flutter test test/mcp_service_test.dart

# Run with verbose output
flutter test test/mcp_service_test.dart -v

# Run specific test group
flutter test test/mcp_service_test.dart --name="MCPToolInfo"
```

## Test Categories

### 1. Path Validation Tests

Tests the security sandbox enforcement:

```rust
#[test]
fn test_path_validation() {
    let config = MCPConfig::default();
    
    // Valid paths
    assert!(config.validate_path("notes.md"));
    assert!(config.validate_path("folder/deep/file.txt"));
    
    // Invalid paths (security violations)
    assert!(!config.validate_path("../outside.md"));
    assert!(!config.validate_path("/absolute/path.md"));
    assert!(!config.validate_path("folder/../../../etc/passwd"));
}
```

**What to verify:**
- Relative paths within sandbox are allowed
- Parent traversal (`..`) is blocked
- Absolute paths outside sandbox are blocked
- Complex traversal attempts are blocked

### 2. File Operation Tests

Tests CRUD operations on files:

```rust
#[test]
fn test_file_operations() {
    // Create temp directory for testing
    let temp_dir = tempfile::tempdir().unwrap();
    let config = MCPConfig::new(temp_dir.path());
    
    // Test write
    config.write_file("test.md", "# Test", false)?;
    
    // Test read
    let content = config.read_file("test.md")?;
    assert_eq!(content, "# Test");
    
    // Test append
    config.write_file("test.md", "\nMore", true)?;
    let content = config.read_file("test.md")?;
    assert!(content.contains("More"));
    
    // Test delete
    config.delete_file("test.md")?;
}
```

**What to verify:**
- Files can be created with content
- Files can be read back
- Append mode works correctly
- Files can be deleted
- Operations fail gracefully for invalid paths

### 3. Extension Validation Tests

Tests file extension whitelist:

```rust
#[test]
fn test_extension_validation() {
    let config = MCPConfig::default();
    
    // Allowed extensions
    assert!(config.is_extension_allowed("file.md"));
    assert!(config.is_extension_allowed("file.txt"));
    assert!(config.is_extension_allowed("file.json"));
    assert!(config.is_extension_allowed("file.yaml"));
    
    // Blocked extensions
    assert!(!config.is_extension_allowed("file.exe"));
    assert!(!config.is_extension_allowed("file.dll"));
    assert!(!config.is_extension_allowed("file.sh"));
}
```

**What to verify:**
- `.md`, `.txt`, `.json`, `.yaml`, `.yml`, `.toml`, `.csv` are allowed
- `.exe`, `.dll`, `.sh`, `.bat` are blocked
- Empty extension (no extension) behavior

### 4. Task Classification Tests

Tests AI task routing:

```rust
#[test]
fn test_task_classification() {
    // Tool use detection
    assert_eq!(classify_task("create a file called notes.md"), TaskCategory::ToolUse);
    assert_eq!(classify_task("add an event to calendar"), TaskCategory::ToolUse);
    assert_eq!(classify_task("start a timer"), TaskCategory::ToolUse);
    
    // Code generation detection
    assert_eq!(classify_task("write a python script"), TaskCategory::CodeGeneration);
    assert_eq!(classify_task("generate javascript code"), TaskCategory::CodeGeneration);
    
    // Conversation (default)
    assert_eq!(classify_task("what is the weather"), TaskCategory::Conversation);
    assert_eq!(classify_task("explain quantum physics"), TaskCategory::Conversation);
}
```

**What to verify:**
- File-related requests → ToolUse
- Calendar/timer requests → ToolUse
- Code requests → CodeGeneration
- General questions → Conversation

### 5. Model Routing Tests

Tests model selection logic:

```dart
test('analyzeAndSelectModel classifies tool use', () {
  final router = ModelRouterService.instance;
  
  final selection = router.analyzeAndSelectModel('create a new file');
  expect(selection.category, equals(MCPTaskCategory.toolUse));
  expect(selection.modelType, equals(AIModelType.functionGemma));
});
```

**What to verify:**
- ToolUse → Function Gemma model
- CodeGeneration → Qwen model
- Conversation → Phi-4 model

### 6. Tool Schema Tests

Tests tool definition formats:

```rust
#[test]
fn test_tool_schemas() {
    let config = MCPConfig::default();
    let schemas = config.get_tool_schemas();
    
    // Verify all tools have schemas
    assert!(schemas.contains("read_file"));
    assert!(schemas.contains("write_file"));
    
    // Verify JSON format
    let parsed: Value = serde_json::from_str(&schemas).unwrap();
    assert!(parsed.is_array());
}
```

### 7. Tool Call Parsing Tests

Tests AI response parsing:

```dart
test('parses valid tool call JSON', () {
  final json = '{"tool": "write_file", "parameters": {"path": "test.md", "content": "Hello"}}';
  final toolCall = mcpService.parseToolCall(json);
  
  expect(toolCall.tool, equals('write_file'));
  expect(toolCall.parameters['path'], equals('test.md'));
});
```

## Integration Testing

### Manual Test Procedure

1. **Start the app**:
   ```powershell
   flutter run -d windows
   ```

2. **Open AI Chat** and test each scenario:

   | Test | Input | Expected |
   |------|-------|----------|
   | File Creation | "Create a file called test.md with Hello World" | Confirmation dialog → File created |
   | File Read | "Read the contents of test.md" | Shows file contents |
   | Path Traversal | "Read ../../../etc/passwd" | Error: Invalid path |
   | Binary Rejection | "Create a file called virus.exe" | Error: Extension not allowed |
   | Timer | "Start a 5 minute timer" | Timer starts via Lua |
   | Calendar | "Add meeting tomorrow at 3pm" | Event added via Lua |

3. **Verify model switching**:
   - General question → Should use Phi-4
   - File operation → Should switch to Function Gemma
   - Code request → Should switch to Qwen

### Automated Integration Tests

```dart
// test/integration/mcp_integration_test.dart
testWidgets('MCP file creation flow', (tester) async {
  await tester.pumpWidget(MyApp());
  
  // Type file creation request
  await tester.enterText(find.byType(TextField), 'create a file notes.md');
  await tester.tap(find.byIcon(Icons.send));
  await tester.pumpAndSettle();
  
  // Verify confirmation dialog
  expect(find.text('Write File'), findsOneWidget);
  
  // Confirm execution
  await tester.tap(find.text('Execute'));
  await tester.pumpAndSettle();
  
  // Verify success
  expect(find.text('File created successfully'), findsOneWidget);
});
```

## Performance Testing

### Benchmark File Operations

```dart
void benchmarkFileOperations() {
  final mcpService = MCPService.instance;
  final stopwatch = Stopwatch()..start();
  
  // Write 1000 small files
  for (var i = 0; i < 1000; i++) {
    mcpService.writeFile('test_$i.md', 'Content $i');
  }
  
  print('Write 1000 files: ${stopwatch.elapsedMilliseconds}ms');
  
  stopwatch.reset();
  
  // Read all files
  for (var i = 0; i < 1000; i++) {
    mcpService.readFile('test_$i.md');
  }
  
  print('Read 1000 files: ${stopwatch.elapsedMilliseconds}ms');
  
  // Cleanup
  for (var i = 0; i < 1000; i++) {
    mcpService.deleteFile('test_$i.md');
  }
}
```

### Expected Performance

| Operation | Expected Time (1000 ops) |
|-----------|-------------------------|
| Write | < 1000ms |
| Read | < 500ms |
| Delete | < 500ms |
| List | < 100ms |

## Security Testing

### Penetration Test Cases

1. **Path Traversal**:
   ```
   Input: "Read file ../../sensitive.conf"
   Expected: Blocked with error
   ```

2. **Null Byte Injection**:
   ```
   Input: "Create file test.md\x00.exe"
   Expected: Sanitized or rejected
   ```

3. **Unicode Tricks**:
   ```
   Input: "Create file test.md\u202E\u202Dexe.md"
   Expected: Sanitized or rejected
   ```

4. **Large File DoS**:
   ```
   Input: "Read file 10gb_file.md"
   Expected: Size limit enforced (10MB max)
   ```

## Continuous Integration

### GitHub Actions Workflow

```yaml
name: MCP Tests

on: [push, pull_request]

jobs:
  rust-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions-rs/toolchain@v1
        with:
          toolchain: stable
      - run: cd native && cargo test mcp -- --test-threads=1

  flutter-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter test test/mcp_service_test.dart
```

## Troubleshooting Test Failures

### Common Issues

**Test isolation failures**:
```
# Run tests single-threaded
cargo test mcp -- --test-threads=1
```

**Temp directory permissions**:
```
# Check temp directory is writable
echo $env:TEMP
Get-Acl $env:TEMP
```

**FRB binding mismatch**:
```
# Regenerate bindings
cd native
flutter_rust_bridge_codegen generate
```

**Model loading failures**:
```
# Ensure models are downloaded
# Check paths in model_router.dart
```

## Test Coverage

### Running Coverage Reports

```powershell
# Rust coverage (requires cargo-tarpaulin)
cd native
cargo tarpaulin --out Html

# Flutter coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Coverage Targets

| Module | Target Coverage |
|--------|-----------------|
| mcp.rs | 90%+ |
| mcp_service.dart | 85%+ |
| model_router.dart | 85%+ |

## Adding New Tests

### Template for New Rust Test

```rust
#[test]
fn test_new_feature() {
    // Setup
    let temp_dir = tempfile::tempdir().unwrap();
    let config = MCPConfig::new(temp_dir.path());
    
    // Action
    let result = config.new_feature();
    
    // Assert
    assert!(result.is_ok());
    assert_eq!(result.unwrap(), expected_value);
}
```

### Template for New Dart Test

```dart
group('NewFeature', () {
  late MCPService mcpService;
  
  setUp(() {
    mcpService = MCPService.instance;
  });
  
  test('new feature works correctly', () {
    final result = mcpService.newFeature();
    expect(result, equals(expectedValue));
  });
});
```

## Checklist Before PR

- [ ] All Rust tests pass (`cargo test mcp`)
- [ ] All Flutter tests pass (`flutter test`)
- [ ] No new warnings
- [ ] Test coverage maintained
- [ ] Manual testing completed
- [ ] Documentation updated
