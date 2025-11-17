import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "https://www.googleapis.com/books/v1/volumes";

  /// Looks for a novel
  Future<dynamic> googleNovels(String query) async {
    final url = Uri.parse("$baseUrl?q=$query");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to fetch novels");
    }
  }

  /// Saves the book to MongoDB
  Future<dynamic> saveNovel(Map<String, dynamic> novelInfo) async {
    final url = Uri.parse("https://your-server-url.com/${novelInfo['id']}");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: json.encode(novelInfo),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to save novel");
    }
  }

  /// Gets all saved novels
  Future<List<dynamic>> getNovels() async {
    final url = Uri.parse("https://your-server-url.com/api/novels");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to load saved novels");
    }
  }

  /// Gets a single novel by ID
  Future<dynamic> getNovel(String id) async {
    final url = Uri.parse("https://your-server-url.com/api/novels/$id");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to get novel");
    }
  }

  /// Deletes a novel by ID
  Future<dynamic> deleteNovel(String id) async {
    final url = Uri.parse("https://your-server-url.com/api/novels/$id");

    final response = await http.delete(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to delete novel");
    }
  }
}
