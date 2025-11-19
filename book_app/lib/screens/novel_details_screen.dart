import 'package:book_app/providers/novel_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NovelDetailsScreen extends StatefulWidget {
  const NovelDetailsScreen({Key? key}) : super(key: key);

  @override
  _NovelDetailsScreenState createState() => _NovelDetailsScreenState();
}

class _NovelDetailsScreenState extends State<NovelDetailsScreen> {
  bool _loadingAi = false;
  Map<String, dynamic>? _aiData;

  /// Loads summary + recommendations from Provider
  Future<void> _loadAiData(
    Map<String, dynamic> novelArg,
    Map<String, dynamic> volumeInfo,
  ) async {
    setState(() => _loadingAi = true);

    final provider = Provider.of<NovelProvider>(context, listen: false);
    final data = await provider.getAiForNovel(
      novelArg['id'] as String,
      title: volumeInfo['title'] as String? ?? '',
      description: volumeInfo['description'] as String? ?? '',
    );

    setState(() {
      _aiData = data;
      _loadingAi = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args == null || args is! Map<String, dynamic>) {
      return const Scaffold(
        body: Center(child: Text('No novel data provided')),
      );
    }

    final novelArg = args;
    final isGoogle = novelArg.containsKey('volumeInfo');

    // -------------------------
    // SAFE PARSING OF GOOGLE DATA
    // -------------------------
    Map<String, dynamic> volumeInfo =
        (isGoogle && novelArg['volumeInfo'] is Map<String, dynamic>)
            ? novelArg['volumeInfo'] as Map<String, dynamic>
            : {};

    final authors = isGoogle
        ? ((volumeInfo['authors'] as List<dynamic>?)?.join(', ') ?? '')
        : ((novelArg['authors'] as List<dynamic>?)?.join(', ') ?? '');

    final description = isGoogle
        ? (volumeInfo['description'] as String? ?? '')
        : (novelArg['description'] as String? ?? '');

    // IMAGE PARSING SAFELY
    String? thumbnail;
    if (isGoogle) {
      final imageLinks = volumeInfo['imageLinks'];
      if (imageLinks is Map<String, dynamic>) {
        thumbnail = imageLinks['thumbnail'] as String?;
      }
    } else {
      final rawVolumeInfo =
          (novelArg['raw'] as Map<String, dynamic>?)?['volumeInfo'];
      if (rawVolumeInfo is Map<String, dynamic>) {
        final imageLinks = rawVolumeInfo['imageLinks'];
        if (imageLinks is Map<String, dynamic>) {
          thumbnail = imageLinks['thumbnail'] as String?;
        }
      }
    }

    final novelInfo = {
      'id': novelArg['id'] as String,
      'title': volumeInfo['title'] as String? ?? '',
      'authors': volumeInfo['authors'] ?? [],
      'description': volumeInfo['description'] ?? '',
      'raw': novelArg,
    };

    final provider = Provider.of<NovelProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(volumeInfo['title'] as String? ?? 'Novel Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              await provider.save(novelInfo);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Novel saved locally!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (thumbnail != null)
              Center(
                child: Image.network(
                  thumbnail,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
            const SizedBox(height: 16),

            Text(
              'Authors: $authors',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Text(description),
            const SizedBox(height: 24),

            // AI BUTTON
            ElevatedButton(
              onPressed: _loadingAi
                  ? null
                  : () => _loadAiData(novelArg, volumeInfo),
              child: Text(
                _loadingAi
                    ? 'Loading AI...'
                    : 'Generate Summary & Recommendations',
              ),
            ),
            const SizedBox(height: 16),

            // DISPLAY AI RESULTS
            if (_aiData != null) ...[
              if (_aiData!['summary'] != null) ...[
                const Text(
                  'Summary:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(_aiData!['summary']),
                const SizedBox(height: 12),
              ],
              if (_aiData!['key_points'] != null) ...[
                const Text(
                  'Key Points:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...(_aiData!['key_points'] as List<dynamic>)
                    .map((e) => Text('- $e')),
                const SizedBox(height: 12),
              ],
              if (_aiData!['recommendations'] != null) ...[
                const Text(
                  'Recommendations:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...(_aiData!['recommendations'] as List<dynamic>)
                    .map((e) => Text('- $e')),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
