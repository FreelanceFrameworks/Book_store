import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  String get backendBase => dotenv.env['BACKEND_BASE_URL'] ?? 'http://localhost:3000';
  String get googleBooksBase => 'https://www.googleapis.com/books/v1/volumes';
  String get openaiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  String get pexelsKey => dotenv.env['PEXELS_API_KEY'] ?? '';

  ApiService();

  // Google Books search - returns decoded Map with 'items' key
  Future<Map<String, dynamic>> googleNovels(String query) async {
    final url = Uri.parse('\$googleBooksBase?q=\${Uri.encodeComponent(query)}');
    final res = await http.get(url);
    if (res.statusCode == 200) return json.decode(res.body) as Map<String, dynamic>;
    throw HttpException('Google Books request failed: \${res.statusCode}');
  }

  // Save novel to backend (POST /api/novels)
  Future<Map<String, dynamic>> saveNovel(Map<String, dynamic> novelInfo) async {
    final url = Uri.parse('\$backendBase/api/novels');
    final res = await http.post(url, headers: {'Content-Type': 'application/json'}, body: json.encode(novelInfo));
    if (res.statusCode == 200 || res.statusCode == 201) return json.decode(res.body) as Map<String, dynamic>;
    throw HttpException('Save failed: \${res.statusCode}');
  }

  // Get saved novels
  Future<List<dynamic>> getNovels() async {
    final url = Uri.parse('\$backendBase/api/novels');
    final res = await http.get(url);
    if (res.statusCode == 200) return json.decode(res.body) as List<dynamic>;
    throw HttpException('Get novels failed: \${res.statusCode}');
  }

  // Get a single novel
  Future<Map<String, dynamic>> getNovel(String id) async {
    final url = Uri.parse('\$backendBase/api/novels/\$id');
    final res = await http.get(url);
    if (res.statusCode == 200) return json.decode(res.body) as Map<String, dynamic>;
    throw HttpException('Get novel failed: \${res.statusCode}');
  }

  // Delete novel
  Future<void> deleteNovel(String id) async {
    final url = Uri.parse('\$backendBase/api/novels/\$id');
    final res = await http.delete(url);
    if (res.statusCode == 200) return;
    throw HttpException('Delete failed: \${res.statusCode}');
  }

  // Pexels image search (optional)
  Future<String?> fetchPexelsImage(String query) async {
    final key = pexelsKey;
    if (key.isEmpty) return null;
    final url = Uri.parse('https://api.pexels.com/v1/search?query=\${Uri.encodeComponent(query)}&per_page=1');
    final res = await http.get(url, headers: {'Authorization': key});
    if (res.statusCode == 200) {
      final decoded = json.decode(res.body) as Map<String, dynamic>;
      final photos = decoded['photos'] as List<dynamic>?;
      if (photos != null && photos.isNotEmpty) return photos[0]['src']?['medium'] as String?;
    }
    return null;
  }

  // OpenAI summary & recommendations (optional)
  Future<Map<String, dynamic>?> generateSummaryAndRecommendations({required String title, String? description, int maxRetries = 2}) async {
    final key = openaiKey;
    if (key.isEmpty) return null;

    final systemPrompt = 'You are a concise assistant that returns JSON only. Given a book title and optional description, return a JSON object with keys: "summary", "recommendations", "key_points".';
    final userPrompt = 'Title: "\$title"\nDescription: "\${description ?? ''}"';

    final payload = {
      'model': 'gpt-4o-mini',
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt}
      ],
      'max_tokens': 300,
      'temperature': 0.7
    };

    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    int attempt = 0;
    while (attempt <= maxRetries) {
      attempt++;
      try {
        final res = await http.post(url, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer \$key'}, body: json.encode(payload));
        if (res.statusCode == 200) {
          final decoded = json.decode(res.body) as Map<String, dynamic>;
          final choices = decoded['choices'] as List<dynamic>?;
          if (choices != null && choices.isNotEmpty) {
            final content = (choices[0]['message']?['content'] ?? choices[0]['text'] ?? '') as String;
            try {
              final parsed = json.decode(content);
              if (parsed is Map<String, dynamic>) {
                final summary = parsed['summary']?.toString() ?? '';
                final recommendations = (parsed['recommendations'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
                final keyPoints = (parsed['key_points'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
                return {'summary': summary, 'recommendations': recommendations, 'key_points': keyPoints, 'raw': content};
              }
            } catch (_) {
              final jsonStart = content.indexOf('{');
              final jsonEnd = content.lastIndexOf('}');
              if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
                final sub = content.substring(jsonStart, jsonEnd + 1);
                try {
                  final parsed = json.decode(sub) as Map<String, dynamic>;
                  final summary = parsed['summary']?.toString() ?? '';
                  final recommendations = (parsed['recommendations'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
                  final keyPoints = (parsed['key_points'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
                  return {'summary': summary, 'recommendations': recommendations, 'key_points': keyPoints, 'raw': content};
                } catch (_) {
                  return {'summary': content.trim(), 'recommendations': [], 'key_points': [], 'raw': content};
                }
              } else {
                return {'summary': content.trim(), 'recommendations': [], 'key_points': [], 'raw': content};
              }
            }
          }
        } else if (res.statusCode == 429) {
          await Future.delayed(Duration(seconds: 2 * attempt));
          continue;
        } else {
          break;
        }
      } catch (e) {
        if (attempt > maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * attempt));
        continue;
      }
    }
    return null;
  }
}
