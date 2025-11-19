import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  final String backendBaseUrl = dotenv.env['BACKEND_URL'] ?? 'http://localhost:3000';
  final String googleBooksBaseUrl = "https://www.googleapis.com/books/v1/volumes";

  final String? openAIApiKey = dotenv.env['OPENAI_API_KEY'];
  final String? pexelsApiKey = dotenv.env['PEXELS_API_KEY'];

  ApiService();

  /* ----------------------------------------------------------
   * GOOGLE BOOKS SEARCH
   * ---------------------------------------------------------- */
  Future<List<dynamic>> searchGoogleBooks(String query) async {
    final url = Uri.parse("$googleBooksBaseUrl?q=$query");

    final res = await http.get(url);

    if (res.statusCode != 200) return [];

    final json = jsonDecode(res.body);
    return json['items'] ?? [];
  }

  /* ----------------------------------------------------------
   * BACKEND - SAVE NOVEL
   * RESTFUL: POST /api/novels
   * ---------------------------------------------------------- */
  Future<bool> saveNovel(Map<String, dynamic> novel) async {
    final url = Uri.parse("$backendBaseUrl/api/novels");

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(novel),
    );

    return res.statusCode == 200 || res.statusCode == 201;
  }

  /* ----------------------------------------------------------
   * BACKEND - GET ALL NOVELS
   * ---------------------------------------------------------- */
  Future<List<dynamic>> getSavedNovels() async {
    final url = Uri.parse("$backendBaseUrl/api/novels");

    final res = await http.get(url);
    if (res.statusCode != 200) return [];

    return jsonDecode(res.body);
  }

  /* ----------------------------------------------------------
   * BACKEND - GET SINGLE NOVEL
   * ---------------------------------------------------------- */
  Future<Map<String, dynamic>?> getNovel(String id) async {
    final url = Uri.parse("$backendBaseUrl/api/novels/$id");

    final res = await http.get(url);
    if (res.statusCode != 200) return null;

    return jsonDecode(res.body);
  }

  /* ----------------------------------------------------------
   * BACKEND - DELETE NOVEL
   * ---------------------------------------------------------- */
  Future<bool> deleteNovel(String id) async {
    final url = Uri.parse("$backendBaseUrl/api/novels/$id");

    final res = await http.delete(url);
    return res.statusCode == 200;
  }

  /* ----------------------------------------------------------
   * OPENAI SUMMARY + RECOMMENDATIONS
   * ---------------------------------------------------------- */
  Future<Map<String, dynamic>> generateSummaryAndRecommendations({
    required String title,
    required String description,
  }) async {
    final url = Uri.parse("https://api.openai.com/v1/chat/completions");

    final body = jsonEncode({
      "model": "gpt-4o-mini",
      "messages": [
        {
          "role": "system",
          "content": "You are a professional book summarizer and recommendation engine."
        },
        {
          "role": "user",
          "content": """
Summarize this book and recommend 5 similar books.

Title: $title
Description: $description
"""
        }
      ]
    });

    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $openAIApiKey"
    };

    final res = await http.post(url, headers: headers, body: body);

    if (res.statusCode != 200) {
      throw Exception("OpenAI API error: ${res.body}");
    }

    final data = jsonDecode(res.body);

    final text = data["choices"][0]["message"]["content"];

    final summary = text.split("Recommendations:").first.trim();
    final recs = text.contains("Recommendations:")
        ? text
            .split("Recommendations:")[1]
            .trim()
            .split("\n")
            .where((line) => line.trim().isNotEmpty)
            .toList()
        : [];

    return {
      "summary": summary,
      "recommendations": recs,
    };
  }

  /* ----------------------------------------------------------
   * PEXELS IMAGE SEARCH
   * ---------------------------------------------------------- */
  Future<String?> fetchPexelsImage(String query) async {
    final url = Uri.parse("https://api.pexels.com/v1/search?query=$query&per_page=1");

    final res = await http.get(url, headers: {
      "Authorization": pexelsApiKey ?? "",
    });

    if (res.statusCode != 200) return null;

    final json = jsonDecode(res.body);
    if (json["photos"] == null || json["photos"].isEmpty) return null;

    return json["photos"][0]["src"]["medium"];
  }
}
