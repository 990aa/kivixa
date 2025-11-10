import 'package:flutter/material.dart';
import 'package:kivixa/screens/home_screen.dart';
import 'package:kivixa/services/resource_cleanup_manager.dart';

void main() {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize resource cleanup for long-running performance
  ResourceCleanupManager.startPeriodicCleanup();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final AppLifecycleManager _lifecycleManager;

  @override
  void initState() {
    super.initState();
    // Initialize app lifecycle management
    _lifecycleManager = AppLifecycleManager();
    WidgetsBinding.instance.addObserver(_lifecycleManager);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleManager);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kivixa',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
