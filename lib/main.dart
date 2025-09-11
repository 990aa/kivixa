
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'services/python_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}


  int _counter = 0;
  String? _ocrResult;
  bool _loading = false;

  Future<void> _runOcr() async {
    setState(() { _loading = true; _ocrResult = null; });
    final picked = await FilePicker.platform.pickFiles(type: FileType.image);
    if (picked != null && picked.files.single.path != null) {
      final file = File(picked.files.single.path!);
      final client = await PythonServiceClient.detect();
      if (client != null) {
        final req = http.MultipartRequest('POST', Uri.parse('${client.baseUrl}/ocr'));
        req.files.add(await http.MultipartFile.fromPath('file', file.path));
        final streamed = await req.send();
        final resp = await streamed.stream.bytesToString();
        setState(() { _ocrResult = resp; });
      } else {
        setState(() { _ocrResult = 'Python service not available'; });
      }
    }
    setState(() { _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _loading ? null : _runOcr,
              child: const Text('Run OCR via Python Service'),
            ),
            if (_loading) const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
            if (_ocrResult != null) Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_ocrResult!),
            ),
          ],
        ),
      ),
    );
  }
}
