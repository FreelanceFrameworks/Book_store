
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  final String googleBooksBase = 'https://www.googleapis.com/books/v1/volumes';
  final String backendBase = dotenv.env['BACKEND_BASE_URL'] ?? 'https://your-server-url.com';
  final String openaiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  final String pexelsKey = dotenv.env['PEXELS_API_KEY'] ?? '';

  /// Search Google Books
  Future<Map<String, dynamic>> googleNovels(String query) async {
    final url = Uri.parse('\$googleBooksBase?q=\${Uri.encodeComponent(query)}');
    final response = await http.get(url);
    if (response.statusCode == 200) return json.decode(response.body) as Map<String, dynamic>;
    throw Exception('Failed to fetch from Google Books');
  }

  /// Save novel to backend (RESTful POST /api/novels)
  Future<Map<String, dynamic>> saveNovel(Map<String, dynamic> novelInfo) async {
    final url = Uri.parse('\$backendBase/api/novels');
    final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: json.encode(novelInfo));
    if (response.statusCode == 200 || response.statusCode == 201) return json.decode(response.body) as Map<String, dynamic>;
    throw Exception('Failed to save novel');
  }

  /// Get saved novels
  Future<List<dynamic>> getNovels() async {
    final url = Uri.parse('\$backendBase/api/novels');
    final response = await http.get(url);
    if (response.statusCode == 200) return json.decode(response.body) as List<dynamic>;
    throw Exception('Failed to load saved novels');
  }

  /// Get novel by id
  Future<Map<String, dynamic>> getNovel(String id) async {
    final url = Uri.parse('\$backendBase/api/novels/\$id');
    final response = await http.get(url);
    if (response.statusCode == 200) return json.decode(response.body) as Map<String, dynamic>;
    throw Exception('Failed to get novel');
  }

  /// Delete novel by id
  Future<void> deleteNovel(String id) async {
    final url = Uri.parse('\$backendBase/api/novels/\$id');
    final response = await http.delete(url);
    if (response.statusCode == 200) return;
    throw Exception('Failed to delete novel');
  }

  /// Pexels image search (optional)
  Future<String?> fetchPexelsImage(String query) async {
    if (pexelsKey.isEmpty) return null;
    final url = Uri.parse('https://api.pexels.com/v1/search?query=\${Uri.encodeComponent(query)}&per_page=1');
    final response = await http.get(url, headers: {'Authorization': pexelsKey});
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      final photos = body['photos'] as List?;
      if (photos != null && photos.isNotEmpty) return photos[0]['src']?['medium'] as String?;
    }
    return null;
  }

  /// OpenAI review generation (optional)
  Future<String?> generateOpenAIReview({required String title, String? description}) async {
    if (openaiKey.isEmpty) return null;
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    const prompt = 'Write a concise friendly 3-sentence review for the book "\$title". Use the description if provided: "\$description"';

    final body = json.encode({
      'model': 'gpt-4o-mini',
      'messages': [
        {'role': 'system', 'content': 'You are a helpful assistant that writes concise friendly book reviews.'},
        {'role': 'user', 'content': prompt}
      ],
      'max_tokens': 150
    });

    final response = await http.post(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer \$openaiKey'
    }, body: body);

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final choices = decoded['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        final text = choices[0]['message']?['content'] as String?;
        return text?.trim();
      }
    }
    return null;
  }
}
