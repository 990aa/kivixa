// Browser Service
//
// Manages browser bookmarks, history, and tab state persistence.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A bookmark entry
class BrowserBookmark {
  final String id;
  final String title;
  final String url;
  final DateTime createdAt;
  final String? favicon;

  BrowserBookmark({
    required this.id,
    required this.title,
    required this.url,
    required this.createdAt,
    this.favicon,
  });

  factory BrowserBookmark.create({
    required String title,
    required String url,
    String? favicon,
  }) {
    return BrowserBookmark(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      url: url,
      createdAt: DateTime.now(),
      favicon: favicon,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'url': url,
    'createdAt': createdAt.toIso8601String(),
    'favicon': favicon,
  };

  factory BrowserBookmark.fromJson(Map<String, dynamic> json) {
    return BrowserBookmark(
      id: json['id'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      favicon: json['favicon'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BrowserBookmark &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// A browser tab
class BrowserTab {
  final String id;
  String title;
  String url;
  bool isLoading;
  double progress;

  BrowserTab({
    required this.id,
    required this.title,
    required this.url,
    this.isLoading = false,
    this.progress = 0.0,
  });

  factory BrowserTab.create({String? url}) {
    return BrowserTab(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Tab',
      url: url ?? 'https://www.google.com',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'url': url};

  factory BrowserTab.fromJson(Map<String, dynamic> json) {
    return BrowserTab(
      id: json['id'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
    );
  }
}

/// Browser service for managing bookmarks and tabs
class BrowserService extends ChangeNotifier {
  static final _instance = BrowserService._internal();
  static BrowserService get instance => _instance;

  BrowserService._internal();

  static const _bookmarksKey = 'browser_bookmarks';
  static const _historyKey = 'browser_history';
  static const _tabsKey = 'browser_tabs';

  final _bookmarks = <BrowserBookmark>[];
  final _history = <String>[];
  final _tabs = <BrowserTab>[];
  var _currentTabIndex = 0;

  List<BrowserBookmark> get bookmarks => List.unmodifiable(_bookmarks);
  List<String> get history => List.unmodifiable(_history);
  List<BrowserTab> get tabs => List.unmodifiable(_tabs);
  int get currentTabIndex => _currentTabIndex;
  BrowserTab? get currentTab =>
      _tabs.isNotEmpty && _currentTabIndex < _tabs.length
      ? _tabs[_currentTabIndex]
      : null;

  var _initialized = false;

  /// Initialize the service
  Future<void> init() async {
    if (_initialized) return;
    await _loadBookmarks();
    await _loadHistory();
    await _loadTabs();
    _initialized = true;
  }

  // ==================== Bookmarks ====================

  Future<void> _loadBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_bookmarksKey);
      if (json != null) {
        final list = jsonDecode(json) as List;
        _bookmarks.clear();
        _bookmarks.addAll(
          list.map((e) => BrowserBookmark.fromJson(e as Map<String, dynamic>)),
        );
      }
    } catch (e) {
      debugPrint('Error loading bookmarks: $e');
    }
  }

  Future<void> _saveBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_bookmarks.map((e) => e.toJson()).toList());
      await prefs.setString(_bookmarksKey, json);
    } catch (e) {
      debugPrint('Error saving bookmarks: $e');
    }
  }

  Future<void> addBookmark({
    required String title,
    required String url,
    String? favicon,
  }) async {
    // Check if already bookmarked
    if (isBookmarked(url)) return;

    final bookmark = BrowserBookmark.create(
      title: title,
      url: url,
      favicon: favicon,
    );
    _bookmarks.insert(0, bookmark);
    await _saveBookmarks();
    notifyListeners();
  }

  Future<void> removeBookmark(String url) async {
    _bookmarks.removeWhere((b) => b.url == url);
    await _saveBookmarks();
    notifyListeners();
  }

  Future<void> removeBookmarkById(String id) async {
    _bookmarks.removeWhere((b) => b.id == id);
    await _saveBookmarks();
    notifyListeners();
  }

  bool isBookmarked(String url) {
    return _bookmarks.any((b) => b.url == url);
  }

  Future<void> clearBookmarks() async {
    _bookmarks.clear();
    await _saveBookmarks();
    notifyListeners();
  }

  // ==================== History ====================

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_historyKey);
      if (list != null) {
        _history.clear();
        _history.addAll(list);
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_historyKey, _history);
    } catch (e) {
      debugPrint('Error saving history: $e');
    }
  }

  Future<void> addToHistory(String url) async {
    // Remove duplicate if exists
    _history.remove(url);
    // Add to front
    _history.insert(0, url);
    // Keep only last 100 entries
    if (_history.length > 100) {
      _history.removeRange(100, _history.length);
    }
    await _saveHistory();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _history.clear();
    await _saveHistory();
    notifyListeners();
  }

  // ==================== Tabs ====================

  Future<void> _loadTabs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_tabsKey);
      if (json != null) {
        final data = jsonDecode(json) as Map<String, dynamic>;
        final list = data['tabs'] as List;
        _tabs.clear();
        _tabs.addAll(
          list.map((e) => BrowserTab.fromJson(e as Map<String, dynamic>)),
        );
        _currentTabIndex = (data['currentIndex'] as int?) ?? 0;
        if (_currentTabIndex >= _tabs.length) {
          _currentTabIndex = _tabs.isEmpty ? 0 : _tabs.length - 1;
        }
      }
    } catch (e) {
      debugPrint('Error loading tabs: $e');
    }

    // Ensure at least one tab
    if (_tabs.isEmpty) {
      _tabs.add(BrowserTab.create());
    }
  }

  Future<void> _saveTabs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode({
        'tabs': _tabs.map((e) => e.toJson()).toList(),
        'currentIndex': _currentTabIndex,
      });
      await prefs.setString(_tabsKey, json);
    } catch (e) {
      debugPrint('Error saving tabs: $e');
    }
  }

  Future<BrowserTab> createTab({String? url}) async {
    final tab = BrowserTab.create(url: url);
    _tabs.add(tab);
    _currentTabIndex = _tabs.length - 1;
    await _saveTabs();
    notifyListeners();
    return tab;
  }

  Future<void> closeTab(int index) async {
    if (_tabs.length <= 1) {
      // Don't close the last tab, just reset it
      _tabs[0] = BrowserTab.create();
      _currentTabIndex = 0;
    } else {
      _tabs.removeAt(index);
      if (_currentTabIndex >= _tabs.length) {
        _currentTabIndex = _tabs.length - 1;
      } else if (_currentTabIndex > index) {
        _currentTabIndex--;
      }
    }
    await _saveTabs();
    notifyListeners();
  }

  Future<void> switchTab(int index) async {
    if (index >= 0 && index < _tabs.length) {
      _currentTabIndex = index;
      await _saveTabs();
      notifyListeners();
    }
  }

  void updateTabInfo(String tabId, {String? title, String? url}) {
    final tab = _tabs.firstWhere(
      (t) => t.id == tabId,
      orElse: () => _tabs.first,
    );
    if (title != null) tab.title = title;
    if (url != null) tab.url = url;
    _saveTabs();
    notifyListeners();
  }

  void updateTabLoading(String tabId, {bool? isLoading, double? progress}) {
    final tab = _tabs.firstWhere(
      (t) => t.id == tabId,
      orElse: () => _tabs.first,
    );
    if (isLoading != null) tab.isLoading = isLoading;
    if (progress != null) tab.progress = progress;
    notifyListeners();
  }
}
