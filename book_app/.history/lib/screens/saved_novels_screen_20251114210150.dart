
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/novel_provider.dart';

class SavedNovelsScreen extends StatefulWidget {
  const SavedNovelsScreen({Key? key}) : super(key: key);

  @override
  State<SavedNovelsScreen> createState() => _SavedNovelsScreenState();
}

class _SavedNovelsScreenState extends State<SavedNovelsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NovelProvider>(context, listen: false).loadSaved();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NovelProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Novels'),
        actions: [IconButton(onPressed: () => provider.loadSaved(), icon: const Icon(Icons.refresh))],
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.saved.isEmpty
              ? const Center(child: Text('You have no saved novels.'))
              : ListView.separated(
                  itemCount: provider.saved.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final novel = provider.saved[index];
                    final title = novel['title'] ?? 'Untitled';
                    final authors = (novel['authors'] as List?)?.join(', ') ?? '';
                    final id = novel['id'] ?? '';

                    return ListTile(
                      title: Text(title),
                      subtitle: Text(authors),
                      onTap: () => Navigator.pushNamed(context, '/details', arguments: novel),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          try {
                            await provider.delete(id);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted (local)')));
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delete failed: \$e')));
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
