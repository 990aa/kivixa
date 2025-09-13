import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../data/repository.dart';
import 'tiled_thumbnails_service.dart';

class ThumbnailsRegenerator {
  final Repository _repo;
  final TiledThumbnailsService _tiledThumbnailsService;

  final _regenerationQueue = Queue<int>();
  Timer? _throttleTimer;

  ThumbnailsRegenerator(this._repo, this._tiledThumbnailsService);

  Future<Uint8List?> getThumbnail(int pageId) async {
    final thumbnail = await _repo.getPageThumbnail(pageId);
    if (thumbnail != null) {
      final asset = await _repo.getAsset(thumbnail['asset_id']);
      if (asset != null) {
        // In a real implementation, we would load the asset data from storage.
        // For now, we'll just return an empty list.
        return Uint8List(0);
      }
    }

    // If no thumbnail, queue for regeneration.
    invalidate(pageId);
    return null;
  }

  void invalidate(int pageId) {
    if (!_regenerationQueue.contains(pageId)) {
      _regenerationQueue.add(pageId);
      _scheduleRegeneration();
    }
  }

  void _scheduleRegeneration() {
    if (_throttleTimer?.isActive ?? false) return;

    _throttleTimer = Timer(const Duration(milliseconds: 500), () {
      if (_regenerationQueue.isNotEmpty) {
        final pageId = _regenerationQueue.removeFirst();
        _regenerate(pageId);
        _scheduleRegeneration(); // Schedule the next one
      }
    });
  }

  Future<void> _regenerate(int pageId) async {
    await _tiledThumbnailsService.markStale(pageId);
    await _tiledThumbnailsService.generateThumbnail(pageId);
    // After regeneration, we might want to notify the UI to update.
  }

  void dispose() {
    _throttleTimer?.cancel();
  }
}