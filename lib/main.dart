import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'screens/home_screen.dart';
import 'models/annotation_layer.dart';
import 'models/drawing_tool.dart';
import 'widgets/annotation_canvas.dart';

/// Main entry point with error handling and initialization
void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set up global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  // Handle async errors
  runZonedGuarded(
    () {
      runApp(const MyApp());
    },
    (error, stackTrace) {
      debugPrint('Async Error: $error');
      debugPrint('Stack trace: $stackTrace');
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kivixa PDF Annotator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,

        // Optimize for stylus input
        visualDensity: VisualDensity.adaptivePlatformDensity,

        // Custom app bar theme
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 2),

        // Custom button themes
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),

      // Dark theme support
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),

      // Use system theme mode
      themeMode: ThemeMode.system,

      home: const HomeScreen(),

      routes: {'/demo': (context) => const PDFAnnotatorDemo()},

      // Error handling UI
      builder: (context, widget) {
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          return ErrorScreen(errorDetails: errorDetails);
        };

        return widget!;
      },
    );
  }
}

/// Demo page showing the PDF annotation system in action
class PDFAnnotatorDemo extends StatefulWidget {
  const PDFAnnotatorDemo({super.key});

  @override
  State<PDFAnnotatorDemo> createState() => _PDFAnnotatorDemoState();
}

class _PDFAnnotatorDemoState extends State<PDFAnnotatorDemo> {
  // Annotation layer to store all strokes
  late AnnotationLayer _annotationLayer;

  // Current drawing settings
  DrawingTool _currentTool = DrawingTool.pen;
  Color _currentColor = Colors.black;
  final int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _annotationLayer = AnnotationLayer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kivixa PDF Annotator'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Undo button
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
            onPressed: () {
              setState(() {
                _annotationLayer.undoLastStroke();
              });
            },
          ),
          // Redo button
          IconButton(
            icon: const Icon(Icons.redo),
            tooltip: 'Redo',
            onPressed: () {
              setState(() {
                _annotationLayer.redoLastUndo();
              });
            },
          ),
          // Clear page button
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear Page',
            onPressed: () {
              setState(() {
                _annotationLayer.clearPage(_currentPage);
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.grey[200],
            child: Row(
              children: [
                // Tool selector
                const Text(
                  'Tool: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                _buildToolButton(DrawingTool.pen, Icons.edit, 'Pen'),
                _buildToolButton(
                  DrawingTool.highlighter,
                  Icons.highlight,
                  'Highlighter',
                ),
                _buildToolButton(
                  DrawingTool.eraser,
                  Icons.auto_fix_high,
                  'Eraser',
                ),
                const SizedBox(width: 16),

                // Color selector (disabled for eraser)
                if (_currentTool != DrawingTool.eraser) ...[
                  const Text(
                    'Color: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  _buildColorButton(Colors.black),
                  _buildColorButton(Colors.red),
                  _buildColorButton(Colors.blue),
                  _buildColorButton(Colors.green),
                  _buildColorButton(Colors.yellow),
                  _buildColorButton(Colors.orange),
                ],

                const Spacer(),

                // Annotation stats
                Text(
                  'Total annotations: ${_annotationLayer.totalAnnotationCount}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),

          // Canvas area
          Expanded(
            child: Container(
              color: Colors.grey[300],
              child: Center(
                child: Container(
                  width: 595, // A4 width at 72 DPI
                  height: 842, // A4 height at 72 DPI
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: AnnotationCanvas(
                    annotationLayer: _annotationLayer,
                    currentPage: _currentPage,
                    currentTool: _currentTool,
                    currentColor: _currentColor,
                    canvasSize: const Size(595, 842),
                    onAnnotationsChanged: () {
                      setState(() {});
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Export annotations
          FloatingActionButton(
            heroTag: 'export',
            onPressed: _exportAnnotations,
            tooltip: 'Export Annotations',
            child: const Icon(Icons.save_alt),
          ),
          const SizedBox(height: 8),
          // Import annotations
          FloatingActionButton(
            heroTag: 'import',
            onPressed: _importAnnotations,
            tooltip: 'Import Annotations',
            child: const Icon(Icons.file_upload),
          ),
        ],
      ),
    );
  }

  /// Builds a tool selection button
  Widget _buildToolButton(DrawingTool tool, IconData icon, String label) {
    final isSelected = _currentTool == tool;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ElevatedButton.icon(
        onPressed: () {
          setState(() {
            _currentTool = tool;
          });
        },
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
          foregroundColor: isSelected ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  /// Builds a color selection button
  Widget _buildColorButton(Color color) {
    final isSelected = _currentColor == color;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentColor = color;
        });
      },
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
    );
  }

  /// Exports annotations to JSON (in production, would save to file)
  void _exportAnnotations() {
    final jsonString = _annotationLayer.exportToJson();

    // In a real app, you would use file_picker and path_provider to save this
    // For demo purposes, we'll just print it
    debugPrint('Exported annotations:');
    debugPrint(jsonString);

    // Show snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Exported ${_annotationLayer.totalAnnotationCount} annotations',
        ),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            _showJsonDialog(jsonString);
          },
        ),
      ),
    );
  }

  /// Imports annotations from JSON (in production, would load from file)
  void _importAnnotations() {
    // In a real app, you would use file_picker to select a file
    // For demo purposes, we'll show a dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Import feature: Use file_picker to select annotation file',
        ),
      ),
    );
  }

  /// Shows JSON in a dialog for demo purposes
  void _showJsonDialog(String jsonString) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exported JSON'),
        content: SingleChildScrollView(child: SelectableText(jsonString)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Error screen for graceful error handling
class ErrorScreen extends StatelessWidget {
  final FlutterErrorDetails errorDetails;

  const ErrorScreen({super.key, required this.errorDetails});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[700]),
              const SizedBox(height: 24),
              Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'The app encountered an unexpected error.',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Show error details in debug mode
              if (kDebugMode) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      errorDetails.exceptionAsString(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton.icon(
                onPressed: () {
                  // Attempt to navigate back to home
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.home),
                label: const Text('Return to Home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
