import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class PythonServiceClient {
  final String baseUrl;
  PythonServiceClient(this.baseUrl);

  static Future<PythonServiceClient?> detect({
    String host = '127.0.0.1',
    int port = 8000,
  }) async {
    try {
      final resp = await http.get(Uri.parse('http://$host:$port/ocr'));
      if (resp.statusCode == 405) {
        return PythonServiceClient('http://$host:$port');
      }
    } catch (_) {}
    return null;
  }

  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> data, {
    int retries = 2,
  }) async {
    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        final resp = await http.post(
          Uri.parse('$baseUrl$endpoint'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(data),
        );
        if (resp.statusCode == 200) {
          return jsonDecode(resp.body);
        }
      } catch (e) {
        if (attempt == retries) rethrow;
        await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
      }
    }
    throw Exception('Python service unavailable');
  }

  // Fallback: Dart/C++ implementations can be called here if needed
}
