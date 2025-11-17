
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/novel_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NovelProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Novel Finder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () => Navigator.pushNamed(context, '/saved'),
          )
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
                    onSubmitted: (_) => provider.search(_controller.text),
                    decoration: const InputDecoration(
                      hintText: 'Search books (title, author, keywords)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => provider.search(_controller.text),
                  child: provider.loading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Search'),
                )
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: provider.searchResults.isEmpty
                  ? const Center(child: Text('No results — try a search.'))
                  : ListView.separated(
                      itemCount: provider.searchResults.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final book = provider.searchResults[index];
                        final info = book['volumeInfo'] ?? {};
                        final title = info['title'] ?? 'Untitled';
                        final authors = (info['authors'] as List?)?.join(', ') ?? '';
                        final thumbnail = info['imageLinks']?['thumbnail'];

                        return ListTile(
                          leading: thumbnail != null
                              ? CachedNetworkImage(imageUrl: thumbnail, width: 48, fit: BoxFit.cover)
                              : const SizedBox(width: 48, child: Icon(Icons.book)),
                          title: Text(title),
                          subtitle: Text(authors),
                          onTap: () => Navigator.pushNamed(context, '/details', arguments: book),
                          trailing: IconButton(
                            icon: const Icon(Icons.save),
                            onPressed: () async {
                              final novelInfo = {
                                'id': book['id'],
                                'title': info['title'] ?? 'Untitled',
                                'authors': info['authors'] ?? [],
                                'description': info['description'] ?? '',
                                'raw': book,
                              };
                              try {
                                await provider.save(novelInfo);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved (local)')));
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: \$e')));
                              }
                            },
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
