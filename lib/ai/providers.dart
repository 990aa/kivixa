import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Common interface for all AI providers
abstract class AIProvider {
  Future<List<AIModel>> listModels();
  Stream<String> streamCompletion(String prompt, AIModel model);
  Future<String> summarize(String text);
  Future<String> translate(String text, String targetLanguage);
  Future<String> ocrHandwriting(List<int> imageData);
}

// Represents an AI model
class AIModel {
  final String id;
  final String name;
  final String provider;

  AIModel({required this.id, required this.name, required this.provider});

  factory AIModel.fromJson(Map<String, dynamic> json) {
    return AIModel(
      id: json['id'],
      name: json['name'],
      provider: json['provider'],
    );
  }
}

// Adapter for OpenAI-compatible HTTP endpoints
class OpenAIProvider implements AIProvider {
  final String apiKey;
  final String baseUrl;

  OpenAIProvider({required this.apiKey, this.baseUrl = 'https://api.openai.com/v1'});

  @override
  Future<List<AIModel>> listModels() async {
    final response = await http.get(
      Uri.parse('$baseUrl/models'),
      headers: {'Authorization': 'Bearer $apiKey'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['data'] as List)
          .map((model) => AIModel(id: model['id'], name: model['id'], provider: 'openai'))
          .toList();
    } else {
      throw Exception('Failed to load models');
    }
  }

  @override
  Stream<String> streamCompletion(String prompt, AIModel model) {
    // Implementation for streaming completion
    throw UnimplementedError();
  }

  @override
  Future<String> summarize(String text) {
    // Implementation for summarization
    throw UnimplementedError();
  }

  @override
  Future<String> translate(String text, String targetLanguage) {
    // Implementation for translation
    throw UnimplementedError();
  }

  @override
  Future<String> ocrHandwriting(List<int> imageData) {
    // Implementation for handwriting OCR
    throw UnimplementedError();
  }
}

// TODO: Implement GeminiProvider, AnthropicProvider, and LocalProvider