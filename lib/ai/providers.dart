
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

// Common Interface
abstract class AIProvider {
  Future<List<String>> listModels();
  Stream<String> streamCompletion(String prompt);
  Future<String> summarize(String text);
  Future<String> translate(String text, String targetLanguage);
  Future<String> ocrHandwriting(List<int> imageData);
}

// OpenAI-Compatible Provider
class OpenAIProvider implements AIProvider {
  final String apiKey;
  final String baseUrl;

  OpenAIProvider({required this.apiKey, this.baseUrl = 'https://api.openai.com/v1'});

  @override
  Future<List<String>> listModels() async {
    final response = await http.get(
      Uri.parse('$baseUrl/models'),
      headers: {'Authorization': 'Bearer $apiKey'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['data'] as List).map((model) => model['id'] as String).toList();
    } else {
      throw Exception('Failed to list models: ${response.body}');
    }
  }

  @override
  Stream<String> streamCompletion(String prompt) async* {
    final client = http.Client();
    final request = http.Request(
      'POST',
      Uri.parse('$baseUrl/completions'),
    )
      ..headers.addAll({
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
      })
      ..body = jsonEncode({
        'model': 'text-davinci-003', // Or a model of your choice
        'prompt': prompt,
        'stream': true,
      });

    try {
      final response = await client.send(request);
      await for (var chunk in response.stream.transform(utf8.decoder)) {
        for (var line in chunk.split('\n')) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data.trim() == '[DONE]') {
              return;
            }
            final decoded = jsonDecode(data);
            if (decoded['choices'] != null && decoded['choices'].isNotEmpty) {
              yield decoded['choices'][0]['text'];
            }
          }
        }
      }
    } finally {
      client.close();
    }
  }

  @override
  Future<String> summarize(String text) async {
    // Implementation for summarization
    throw UnimplementedError();
  }

  @override
  Future<String> translate(String text, String targetLanguage) async {
    // Implementation for translation
    throw UnimplementedError();
  }

  @override
  Future<String> ocrHandwriting(List<int> imageData) async {
    throw UnsupportedError('OCR handwriting is not supported by this provider.');
  }
}

// Gemini Provider
class GeminiProvider implements AIProvider {
    final String apiKey;
    final String baseUrl;

    GeminiProvider({required this.apiKey, this.baseUrl = 'https://generativelanguage.googleapis.com/v1beta'});

    @override
    Future<List<String>> listModels() async {
        final response = await http.get(
        Uri.parse('$baseUrl/models'),
        headers: {'x-goog-api-key': apiKey},
        );
        if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['models'] as List).map((model) => model['name'] as String).toList();
        } else {
        throw Exception('Failed to list models: ${response.body}');
        }
    }

    @override
    Stream<String> streamCompletion(String prompt) {
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
        throw UnsupportedError('OCR handwriting is not supported by this provider.');
    }
}

// Anthropic Provider
class AnthropicProvider implements AIProvider {
    final String apiKey;
    final String baseUrl;

    AnthropicProvider({required this.apiKey, this.baseUrl = 'https://api.anthropic.com/v1'});

    @override
    Future<List<String>> listModels() async {
        // Anthropic does not have a public models API, returning a fixed list.
        return ['claude-2', 'claude-instant-1'];
    }

    @override
    Stream<String> streamCompletion(String prompt) {
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
        throw UnsupportedError('OCR handwriting is not supported by this provider.');
    }
}

// Local Ollama Provider
class LocalOllamaProvider implements AIProvider {
    final String baseUrl;

    LocalOllamaProvider({this.baseUrl = 'http://localhost:11434'});

    @override
    Future<List<String>> listModels() async {
        final response = await http.get(Uri.parse('$baseUrl/api/tags'));
        if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['models'] as List).map((model) => model['name'] as String).toList();
        } else {
        throw Exception('Failed to list models: ${response.body}');
        }
    }

    @override
    Stream<String> streamCompletion(String prompt) {
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
        throw UnsupportedError('OCR handwriting is not supported by this provider.');
    }
}
