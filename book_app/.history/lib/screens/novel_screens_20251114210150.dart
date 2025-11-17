// flutter_novel_screens.dart
// Place this file in lib/screens/ and import into your main.dart routes.
// Assumes you have an ApiService in lib/services/api_service.dart like previously provided.

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService api = ApiService();
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _books = [];
  bool _loading = false;

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    setState(() => _loading = true);
    try {
      final results = await api.googleNovels(query);
      setState(() {
        _books = results["items"] ?? [];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Search failed: \$e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  void _openDetails(dynamic book) {
    Navigator.pushNamed(context, '/details', arguments: book);
  }

  Future<void> _saveBook(dynamic book) async {
    // Convert Google Book volume object to the shape your backend expects.
    final novelInfo = {
      'id': book['id'],
      'title': book['volumeInfo']?['title'] ?? 'Untitled',
      'authors': book['volumeInfo']?['authors'] ?? [],
      'description': book['volumeInfo']?['description'] ?? '',
      'raw': book,
    };

    try {
      await api.saveNovel(novelInfo);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to your library')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Save failed: \$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novel Finder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () => Navigator.pushNamed(context, '/saved'),
            tooltip: 'Saved novels',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: const InputDecoration(
                      hintText: 'Search Google Books (e.g. "Pride and Prejudice")',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _search,
                  child: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Search'),
                )
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _books.isEmpty
                  ? const Center(child: Text('No results yet. Try a search.'))
                  : ListView.separated(
                      itemCount: _books.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final book = _books[index];
                        final info = book['volumeInfo'] ?? {};
                        final title = info['title'] ?? 'Untitled';
                        final authors = (info['authors'] as List?)?.join(', ') ?? '';
                        final thumbnail = info['imageLinks']?['thumbnail'];

                        return ListTile(
                          leading: thumbnail != null
                              ? Image.network(thumbnail, width: 48, fit: BoxFit.cover)
                              : const SizedBox(width: 48, child: Icon(Icons.book)),
                          title: Text(title),
                          subtitle: Text(authors),
                          onTap: () => _openDetails(book),
                          trailing: IconButton(
                            icon: const Icon(Icons.save),
                            onPressed: () => _saveBook(book),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}


class SavedNovelsScreen extends StatefulWidget {
  const SavedNovelsScreen({Key? key}) : super(key: key);

  @override
  State<SavedNovelsScreen> createState() => _SavedNovelsScreenState();
}

class _SavedNovelsScreenState extends State<SavedNovelsScreen> {
  final ApiService api = ApiService();
  List<dynamic> _saved = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    setState(() => _loading = true);
    try {
      final result = await api.getNovels();
      setState(() => _saved = result);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load saved novels: \$e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  void _openDetails(dynamic novel) {
    Navigator.pushNamed(context, '/details', arguments: novel);
  }

  Future<void> _delete(String id) async {
    try {
      await api.deleteNovel(id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
      await _loadSaved();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delete failed: \$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Novels'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSaved,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _saved.isEmpty
              ? const Center(child: Text('You have no saved novels.'))
              : ListView.separated(
                  itemCount: _saved.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final novel = _saved[index];
                    final title = novel['title'] ?? 'Untitled';
                    final authors = (novel['authors'] as List?)?.join(', ') ?? '';
                    final id = novel['id'] ?? ''; // depends on your DB shape

                    return ListTile(
                      title: Text(title),
                      subtitle: Text(authors),
                      onTap: () => _openDetails(novel),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _delete(id),
                      ),
                    );
                  },
                ),
    );
  }
}


class NovelDetailsScreen extends StatelessWidget {
  const NovelDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dynamic novel = ModalRoute.of(context)!.settings.arguments;

    // The argument could be a Google Books volume OR a saved novel from DB.
    final isGoogle = novel != null && novel['volumeInfo'] != null;
    final volumeInfo = isGoogle ? novel['volumeInfo'] : novel;

    final title = isGoogle ? volumeInfo['title'] : novel['title'];
    final authors = isGoogle
        ? (volumeInfo['authors'] as List?)?.join(', ') ?? ''
        : (novel['authors'] as List?)?.join(', ') ?? '';
    final description = isGoogle ? (volumeInfo['description'] ?? '') : (novel['description'] ?? '');
    final thumbnail = isGoogle ? volumeInfo['imageLinks']?['thumbnail'] : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? 'Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (thumbnail != null) ...[
              Center(child: Image.network(thumbnail)),
              const SizedBox(height: 12),
            ],
            Text(
              title ?? 'Untitled',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(authors ?? ''),
            const SizedBox(height: 12),
            Text(description ?? ''),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // If it's a Google result, we allow saving; else we might offer delete in saved screen.
                    if (isGoogle) {
                      final api = ApiService();
                      final novelInfo = {
                        'id': novel['id'],
                        'title': volumeInfo['title'],
                        'authors': volumeInfo['authors'] ?? [],
                        'description': volumeInfo['description'] ?? '',
                        'raw': novel,
                      };

                      api.saveNovel(novelInfo).then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
                      }).catchError((e) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Save failed: \$e')));
                      });
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: Text(isGoogle ? 'Save' : 'Saved'),
                ),
                const SizedBox(width: 12),
                if (!isGoogle)
                  ElevatedButton.icon(
                    onPressed: () {
                      // If this is a saved novel, navigate to delete via REST or back to saved screen.
                      final id = novel['id'];
                      final api = ApiService();
                      api.deleteNovel(id).then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
                        Navigator.popUntil(context, ModalRoute.withName('/saved'));
                      }).catchError((e) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delete failed: \$e')));
                      });
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

/*
Integration notes (put these in your main.dart):

  routes: {
    '/': (context) => const HomeScreen(),
    '/saved': (context) => const SavedNovelsScreen(),
    '/details': (context) => const NovelDetailsScreen(),
  },

Make sure your ApiService base URLs are correct for your backend and that CORS is handled on the server if running locally.
*/
