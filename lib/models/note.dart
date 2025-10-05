import 'package:hive/hive.dart';
import 'page.dart';

part 'note.g.dart';

@HiveType(typeId: 3)
class Note extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  String title;
  
  @HiveField(2)
  List<NotePage> pages;
  
  @HiveField(3)
  final PageTemplate defaultTemplate;
  
  @HiveField(4)
  final DateTime createdAt;
  
  @HiveField(5)
  DateTime modifiedAt;

  Note({
    required this.id,
    required this.title,
    required this.pages,
    required this.defaultTemplate,
    required this.createdAt,
    required this.modifiedAt,
  });
}