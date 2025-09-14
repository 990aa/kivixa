import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kivixa/data/database.dart';
import 'package:kivixa/data/repository.dart';

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class DocumentsNotifier extends StateNotifier<AsyncValue<List<DocumentData>>> {
  DocumentsNotifier(this._repository) : super(const AsyncValue.loading()) {
    _init();
  }

  final DocumentRepository _repository;
  // Removed unused _ref and _cache fields
  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub; // Explicitly typed StreamSubscription

  Future<void> _init() async {
    // Listen to connectivity changes
    _connectivitySub = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) { // Explicitly typed result
      // Updated line to correctly check for offline status from List<ConnectivityResult>
      _isOffline = !(result.contains(ConnectivityResult.mobile) ||
          result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.ethernet) ||
          result.contains(ConnectivityResult.vpn));
      if (!_isOffline) {
        // On reconnect, refresh from backend
        refreshDocuments();
      }
    });
    // Try to load from cache first
    await _loadFromCache();
    // Then subscribe to backend
    _repository
        .watchDocuments()
        .listen((documents) {
          // _cache removed
          state = AsyncValue.data(documents);
          _saveToCache(documents);
        })
        .onError((error) {
          state = AsyncValue.error(error, StackTrace.current);
        });
  }

  Future<void> _loadFromCache() async {
    // Cache loading logic not implemented
  }

  Future<void> _saveToCache(List<DocumentData> docs) async {
    // Cache saving logic not implemented
  }

  Future<void> refreshDocuments() async {
    state = const AsyncValue.loading();
    try {
      final docs = await _repository.watchDocuments().first;
      // _cache removed
      state = AsyncValue.data(docs);
      _saveToCache(docs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createDocument(String title) async {
    // Optimistic update
    final previousState = state;
    final optimisticDocument = DocumentData(
      id: -1, // Placeholder ID
      title: title,
      // Add other required fields with dummy values if needed
    );

    state = AsyncValue.data([optimisticDocument, ...?state.value]);

    try {
      await _repository.createDocument(title);
    } catch (e) {
      // Revert on error
      state = previousState;
      // Optionally, expose the error to the UI
      _showError('Failed to create document. Please try again.');
    }
  }

  void _showError(String message) {
    // Optionally, use a global error handler or UI callback
    debugPrint(message);
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }
}

// Provider is defined in providers.dart

