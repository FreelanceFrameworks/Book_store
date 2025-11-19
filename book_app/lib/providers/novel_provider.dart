
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/api_service.dart';
import '../models/novel.dart';

class NovelProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  late Box<Novel> _novelBox;
  late Box _pendingBox;
  late Box _aiCacheBox;

  List<Novel> _saved = [];
  List<Novel> get saved => _saved;

  List<dynamic> _searchResults = [];
  List<dynamic> get searchResults => _searchResults;

  bool _loading = false;
  bool get loading => _loading;

  StreamSubscription<ConnectivityResult>? _connectivitySub;

  NovelProvider();

  Future<void> init() async {
    _novelBox = Hive.box<Novel>('savedNovels');
    _pendingBox = Hive.box('pendingSaves');
    _aiCacheBox = Hive.box('aiCache');

    _saved = _novelBox.values.cast<Novel>().toList();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        syncPending();
      }
    });
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;
    _loading = true;
    notifyListeners();
    try {
      final results = await _api.googleNovels(query);
      _searchResults = results['items'] ?? [];
    } catch (e) {
      _searchResults = [];
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadSaved() async {
    _saved = _novelBox.values.cast<Novel>().toList();
    notifyListeners();
  }

  Future<void> save(Map<String, dynamic> novelInfo) async {
    final novel = Novel.fromMap(novelInfo);
    await _novelBox.put(novel.id, novel);
    _pendingBox.put(novel.id, novel.toMap());
    _saved = _novelBox.values.cast<Novel>().toList();
    notifyListeners();
    await syncPending();
  }

  Future<void> delete(String id) async {
    await _novelBox.delete(id);
    await _pendingBox.delete(id);
    await _aiCacheBox.delete(id);
    _saved = _novelBox.values.cast<Novel>().toList();
    notifyListeners();
    try {
      await _api.deleteNovel(id);
    } catch (_) {
      // ignore network failure for delete
    }
  }

  Future<void> syncPending() async {
    if (_pendingBox.isEmpty) return;
    final keys = _pendingBox.keys.toList();
    for (final key in keys) {
      try {
        final map = Map<String, dynamic>.from(_pendingBox.get(key));
        await _api.saveNovel(map);
        await _pendingBox.delete(key);
      } catch (e) {
        // keep in queue
      }
    }
  }

  Future<Map<String, dynamic>?> getAiForNovel(String id, {String? title, String? description, bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _aiCacheBox.get(id);
      if (cached != null) return Map<String, dynamic>.from(cached);
    }
    final result = await _api.generateSummaryAndRecommendations(title: title ?? '', description: description ?? '');
    if (result != null) {
      await _aiCacheBox.put(id, result);
    }
    return result;
  }

  Future<String?> fetchImage(String query) => _api.fetchPexelsImage(query);
}
