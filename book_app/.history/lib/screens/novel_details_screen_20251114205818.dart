
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
// ignore: unused_import
import '../providers/novel_provider.dart';

class NovelDetailsScreen extends StatefulWidget {
  const NovelDetailsScreen({Key? key}) : super(key: key);

  @override
  State<NovelDetailsScreen> createState() => _NovelDetailsScreenState();
}

class _NovelDetailsScreenState extends State<NovelDetailsScreen> {
  String? _pexelsImage;
  String? _aiReview;
  bool _loadingExtras = false;

  Future<void> _loadExtras(String title, String? description) async {
    setState(() => _loadingExtras = true);
    final provider = Provider.of<NovelProvider>(context, listen: false);
    try {
      final image = await provider.fetchImage(title);
      final review = await provider.generateReview(title, description);
      setState(() {
        _pexelsImage = image;
        _aiReview = review;
      });
    } catch (_) {
      // ignore
    } finally {
      setState(() => _loadingExtras = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dynamic novel = ModalRoute.of(context)!.settings.arguments;
    final provider = Provider.of<NovelProvider>(context, listen: false);

    final isGoogle = novel != null && novel['volumeInfo'] != null;
    final volumeInfo = isGoogle ? novel['volumeInfo'] : novel;
    final title = isGoogle ? volumeInfo['title'] : novel['title'];
    final authors = isGoogle
        ? (volumeInfo['authors'] as List?)?.join(', ') ?? ''
        : (novel['authors'] as List?)?.join(', ') ?? '';
    final description = isGoogle ? (volumeInfo['description'] ?? '') : (novel['description'] ?? '');
    final thumbnail = isGoogle ? volumeInfo['imageLinks']?['thumbnail'] : (novel['raw']?['volumeInfo']?['imageLinks']?['thumbnail']);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pexelsImage == null && _aiReview == null) _loadExtras(title ?? '', description);
    });

    return Scaffold(
      appBar: AppBar(title: Text(title ?? 'Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (_pexelsImage != null)
            Center(child: CachedNetworkImage(imageUrl: _pexelsImage!))
          else if (thumbnail != null)
            Center(child: CachedNetworkImage(imageUrl: thumbnail))
          else
            const Center(child: Icon(Icons.book, size: 96)),
          const SizedBox(height: 12),
          Text(title ?? 'Untitled', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(authors),
          const SizedBox(height: 12),
          if (description != null && description.isNotEmpty) Text(description),
          const SizedBox(height: 12),
          if (_loadingExtras) const LinearProgressIndicator(),
          if (_aiReview != null) ...[
            const SizedBox(height: 12),
            Text('AI Review', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(_aiReview!),
          ],
          const SizedBox(height: 20),
          Row(children: [
            ElevatedButton.icon(
              onPressed: () async {
                if (isGoogle) {
                  final novelInfo = {
                    'id': novel['id'],
                    'title': volumeInfo['title'],
                    'authors': volumeInfo['authors'] ?? [],
                    'description': volumeInfo['description'] ?? '',
                    'raw': novel,
                  };
                  try {
                    await provider.save(novelInfo);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved (local)')));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Save failed: \$e')));
                  }
                }
              },
              icon: const Icon(Icons.save),
              label: Text(isGoogle ? 'Save' : 'Saved'),
            ),
            const SizedBox(width: 12),
            if (!isGoogle)
              ElevatedButton.icon(
                onPressed: () async {
                  final id = novel['id'];
                  try {
                    await provider.delete(id);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted (local)')));
                    Navigator.popUntil(context, ModalRoute.withName('/saved'));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delete failed: \$e')));
                  }
                },
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
          ])
        ]),
      ),
    );
  }
}
