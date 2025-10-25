import 'package:kivixa/models/annotation_data.dart';

class CachingService {
  final Map<int, List<AnnotationData>> _cache = {};

  List<AnnotationData>? getAnnotations(int pageNumber) {
    return _cache[pageNumber];
  }

  void cacheAnnotations(int pageNumber, List<AnnotationData> annotations) {
    _cache[pageNumber] = annotations;
  }

  void clearCache() {
    _cache.clear();
  }
}
