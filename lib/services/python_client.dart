import 'dart:convert';
import 'package:http/http.dart' as http;

class PythonServiceClient {
  final String baseUrl;
  PythonServiceClient(this.baseUrl);

  static Future<PythonServiceClient?> detect() async {
    // Try to connect to local FastAPI service
    // Return null if unavailable
    return null;
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    // POST to Python service, with retry logic
    return null;
  }
}
