# Debugging Guide for Kivixa

## How to See Detailed Error Messages in VS Code

When you encounter "Paused on exception" with no details in VS Code, here's how to get more information:

### 1. Enable Exception Breakpoints

In VS Code:
1. Open the **Debug** panel (Ctrl+Shift+D)
2. Look for the **Breakpoints** section in the sidebar
3. Check the box for **"All Exceptions"** or **"Uncaught Exceptions"**
4. When an exception occurs, VS Code will pause and show:
   - The exact line where the error occurred
   - The error message
   - The full stack trace
   - Variable values at that point

### 2. Use the Debug Console

When the app is running in debug mode:
1. Open the **Debug Console** (Ctrl+Shift+Y or View → Debug Console)
2. All log messages, print statements, and errors will appear here
3. You can also type Dart expressions to inspect variables

### 3. View Application Logs

The app now has comprehensive logging. To view logs:

**Option A: In-App Logs Page**
- Navigate to Settings → Logs
- All logged errors and warnings are displayed with timestamps
- Click on any log entry to see full details including stack traces

**Option B: Debug Console**
- All logs are automatically printed to the debug console in this format:
  ```
  [LEVEL] LoggerName: Message
  Error: ErrorDetails
  Stack trace: ...
  ```

**Option C: Terminal/Command Line**
- Run the app with verbose logging:
  ```powershell
  flutter run -d windows -v
  ```
- This shows extremely detailed output including all framework operations

### 4. Check the Debug Output Panel

In VS Code:
1. Go to View → Output (or Ctrl+Shift+U)
2. In the dropdown at the top-right, select **"Flutter (flutter run)"**
3. This shows all Flutter framework messages, warnings, and errors

### 5. Common Debugging Commands

```powershell
# Run with verbose output
flutter run -d windows -v

# Run with specific exception handling
flutter run -d windows --enable-asserts

# Check for any analysis issues before running
flutter analyze

# Run tests to verify functionality
flutter test

# Clean build artifacts if things are broken
flutter clean
flutter pub get
flutter run -d windows
```

## Understanding Error Types

### Flutter Errors (Red Screen)
- **What**: Errors in the Flutter framework or UI rendering
- **Where to see**: Red error screen in the app + Debug Console
- **Now logged to**: FlutterError handler → App logs

### Uncaught Async Errors
- **What**: Errors in async operations that aren't caught
- **Where to see**: Debug Console with "=== UNCAUGHT ERROR ===" header
- **Now logged to**: PlatformDispatcher handler → App logs

### Application Logic Errors
- **What**: Errors in business logic with proper try-catch
- **Where to see**: App logs (Settings → Logs) + Debug Console
- **Logged via**: Logger instances in each class

## Tips for Effective Debugging

### 1. Use Breakpoints
- Click in the gutter (left of line numbers) to add a breakpoint
- App will pause when that line is reached
- Hover over variables to see their values
- Use Step Over (F10), Step Into (F11), Continue (F5)

### 2. Add Strategic Log Statements
```dart
final log = Logger('MyClassName');

// Info level (general flow)
log.info('User opened file: $filePath');

// Warning level (potential issues)
log.warning('File not found: $filePath');

// Severe level (errors)
log.severe('Failed to load file', error, stackTrace);
```

### 3. Hot Reload vs Hot Restart
- **Hot Reload (r)**: Fast, updates UI only - use for UI changes
- **Hot Restart (R)**: Slower, restarts app - use when state is corrupted
- **Full Restart**: Stop debugging and start again - use when really stuck

### 4. Check File System Issues
If files aren't appearing or functionality is broken:
1. Check that files actually exist in the app's directory:
   - Windows: `C:\Users\YourName\Documents\kivixa\`
2. Deleted files are now automatically removed from recent files list
3. File existence is checked before loading previews

### 5. Common Issues and Solutions

**Issue: "Paused on exception" with no message**
- Solution: Enable "All Exceptions" in Breakpoints panel
- Or: Check Debug Console for printed errors
- Or: Check Settings → Logs in the app

**Issue: App functionality not working**
- Solution 1: Try Hot Restart (R) instead of Hot Reload (r)
- Solution 2: Stop debugging and restart from VS Code
- Solution 3: Run `flutter clean` and rebuild
- Solution 4: Check Debug Console and Logs for errors

**Issue: Files deleted externally still showing**
- Solution: Pull down to refresh on Recent/Browse pages
- The app now automatically removes non-existent files from recent list

**Issue: Preview cards showing errors**
- Solution: Check that the file still exists
- Check Debug Console for "Error loading thumbnail" or "Error loading markdown"
- The app will show fallback message if file is missing or corrupted

## Recent Improvements

### Error Handling Enhancements
1. **Global Error Handlers**: All uncaught errors are now logged with full stack traces
2. **File Existence Checks**: Preview cards check if files exist before trying to load them
3. **Detailed Logging**: All errors include context, error details, and stack traces
4. **Console Output**: Errors are printed to debug console in readable format

### Deleted File Handling
1. **Automatic Cleanup**: Recently accessed files list is cleaned when files don't exist
2. **Preview Safety**: Preview cards gracefully handle missing files
3. **Existence Validation**: Files are checked before loading thumbnails or content

## Getting Help
When reporting issues:
1. Include the exact error message from Debug Console or Logs
2. Include the stack trace if available
3. Describe what you were doing when the error occurred
4. Mention if it happens consistently or randomly
5. Note if it started after specific changes

## Logging Levels

The app uses these logging levels:
- **INFO**: Normal operations, useful for debugging (debug mode only)
- **WARNING**: Potential issues that don't break functionality
- **SEVERE**: Actual errors that need attention

To see INFO level logs, run with the verbose flag:
```powershell
flutter run -d windows -v
```
