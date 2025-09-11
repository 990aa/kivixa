import 'package:meta/meta.dart';

@immutable
class Document {
  final int id;
  final String title;
  final int createdAt;
  final int updatedAt;

  const Document({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });
}

@immutable
class Page {
  final int id;
  final int documentId;
  final int pageNumber;
  final int createdAt;
  final int updatedAt;

  const Page({
    required this.id,
    required this.documentId,
    required this.pageNumber,
    required this.createdAt,
    required this.updatedAt,
  });
}

@immutable
class Layer {
  final int id;
  final int pageId;
  final int zIndex;
  final String type;
  final int createdAt;
  final int updatedAt;

  const Layer({
    required this.id,
    required this.pageId,
    required this.zIndex,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
  });
}

@immutable
class Stroke {
  final int id;
  final int layerId;
  final int chunkIndex;
  final List<int> data;
  final int createdAt;
  final int updatedAt;

  const Stroke({
    required this.id,
    required this.layerId,
    required this.chunkIndex,
    required this.data,
    required this.createdAt,
    required this.updatedAt,
  });
}

@immutable
class Template {
  final int id;
  final String name;
  final List<int> data;
  final int createdAt;
  final int updatedAt;

  const Template({
    required this.id,
    required this.name,
    required this.data,
    required this.createdAt,
    required this.updatedAt,
  });
}

@immutable
class Link {
  final int id;
  final int fromPageId;
  final int toPageId;
  final String type;
  final int createdAt;
  final int updatedAt;

  const Link({
    required this.id,
    required this.fromPageId,
    required this.toPageId,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
  });
}
