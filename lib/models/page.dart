import 'package:hive/hive.dart';
import 'stroke.dart';

part 'page.g.dart';

enum PageTemplate {
  plain,
  ruled,
  grid,
}

@HiveType(typeId: 1)
class NotePage extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  List<DrawingStroke> strokes;
  
  @HiveField(2)
  final PageTemplate template;
  
  @HiveField(3)
  List<ImageData> images;

  NotePage({
    required this.id,
    required this.strokes,
    required this.template,
    required this.images,
  });
}

@HiveType(typeId: 2)
class ImageData extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String path;
  
  @HiveField(2)
  double x;
  
  @HiveField(3)
  double y;
  
  @HiveField(4)
  double width;
  
  @HiveField(5)
  double height;
  
  @HiveField(6)
  double rotation;

  ImageData({
    required this.id,
    required this.path,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rotation = 0,
  });
}
