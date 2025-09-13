import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../data/repository.dart';

class ImagesService {
  final Repository _repository;

  ImagesService(this._repository);

  Future<String> get _assetsPath async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/assets_original';
  }

  /// Persists an image to the assets_original/ directory.
  Future<void> persistImage(int imageId, File image) async {
    final path = await _assetsPath;
    final newPath = '$path/$imageId.png';
    await image.copy(newPath);

    await _repository.updateImage(imageId, {'asset_path': newPath});
  }

  /// Updates the 2D transform matrix for an image.
  Future<void> updateImageTransform(int imageId, Matrix4 transform) async {
    await _repository.updateImage(imageId, {'transform': transform.storage.toList()});
  }

  /// Gets the thumbnail for an image.
  Future<File?> getThumbnail(int imageId) async {
    final image = await _repository.getImage(imageId);
    if (image != null && image['thumbnail_path'] != null) {
      return File(image['thumbnail_path']);
    }
    return null;
  }
}

