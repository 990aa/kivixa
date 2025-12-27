import 'dart:convert';

/// Represents the source type of media
enum MediaSourceType {
  /// Local file path
  local,

  /// Web URL
  web,
}

/// Represents the type of media
enum MediaType { image, video }

/// Represents a media element (image or video) with metadata for positioning,
/// sizing, rotation, and comments.
///
/// Supports serialization to/from:
/// - Extended markdown syntax: `![alt|width=300,height=200,rotation=45,x=10,y=20](path)`
/// - JSON for Quill embed metadata
class MediaElement {
  MediaElement({
    required this.path,
    required this.mediaType,
    this.sourceType = MediaSourceType.local,
    this.altText = '',
    this.width,
    this.height,
    this.rotation = 0.0,
    this.posX = 0.0,
    this.posY = 0.0,
    this.comment,
    this.isPreviewMode = false,
    this.previewWidth,
    this.previewHeight,
    this.scrollOffsetX = 0.0,
    this.scrollOffsetY = 0.0,
  });

  /// Path to the media file (local path or URL)
  final String path;

  /// Type of media (image or video)
  final MediaType mediaType;

  /// Source type (local file or web URL)
  final MediaSourceType sourceType;

  /// Alt text for accessibility
  String altText;

  /// Display width in logical pixels (null = natural size)
  double? width;

  /// Display height in logical pixels (null = natural size)
  double? height;

  /// Rotation in degrees (0-360)
  double rotation;

  /// X position offset for dragging/repositioning
  double posX;

  /// Y position offset for dragging/repositioning
  double posY;

  /// Optional comment shown on hover (Windows) or tap (Android)
  String? comment;

  /// Whether the media is in preview mode (scrollable view for large images)
  bool isPreviewMode;

  /// Preview container width when in preview mode
  double? previewWidth;

  /// Preview container height when in preview mode
  double? previewHeight;

  /// Scroll offset X within preview container
  double scrollOffsetX;

  /// Scroll offset Y within preview container
  double scrollOffsetY;

  /// Regular expression for parsing extended markdown image/video syntax
  /// Matches: ![alt|key=value,key=value](path)
  static final _markdownRegex = RegExp(
    r'!\[([^\|\]]*?)(?:\|([^\]]*))?\]\(([^)]+)\)',
  );

  /// Parse a MediaElement from extended markdown syntax
  /// Format: ![alt|width=300,height=200,rotation=45,x=10,y=20,comment=text](path)
  static MediaElement? fromMarkdownSyntax(String markdown) {
    final match = _markdownRegex.firstMatch(markdown);
    if (match == null) return null;

    final altText = match.group(1) ?? '';
    final paramsString = match.group(2);
    final path = match.group(3) ?? '';

    if (path.isEmpty) return null;

    // Determine media type from extension
    final mediaType = _getMediaTypeFromPath(path);

    // Determine source type
    final sourceType = path.startsWith('http://') || path.startsWith('https://')
        ? MediaSourceType.web
        : MediaSourceType.local;

    // Parse parameters
    final params = <String, String>{};
    if (paramsString != null && paramsString.isNotEmpty) {
      for (final param in paramsString.split(',')) {
        final parts = param.split('=');
        if (parts.length == 2) {
          params[parts[0].trim()] = parts[1].trim();
        }
      }
    }

    return MediaElement(
      path: path,
      mediaType: mediaType,
      sourceType: sourceType,
      altText: altText,
      width: double.tryParse(params['width'] ?? ''),
      height: double.tryParse(params['height'] ?? ''),
      rotation: double.tryParse(params['rotation'] ?? '') ?? 0.0,
      posX: double.tryParse(params['x'] ?? '') ?? 0.0,
      posY: double.tryParse(params['y'] ?? '') ?? 0.0,
      comment: params['comment'] != null
          ? Uri.decodeComponent(params['comment']!)
          : null,
      isPreviewMode: params['preview'] == 'true',
      previewWidth: double.tryParse(params['pw'] ?? ''),
      previewHeight: double.tryParse(params['ph'] ?? ''),
      scrollOffsetX: double.tryParse(params['sx'] ?? '') ?? 0.0,
      scrollOffsetY: double.tryParse(params['sy'] ?? '') ?? 0.0,
    );
  }

  /// Convert to extended markdown syntax
  String toMarkdownSyntax() {
    final params = <String>[];

    if (width != null) params.add('width=${width!.toStringAsFixed(0)}');
    if (height != null) params.add('height=${height!.toStringAsFixed(0)}');
    if (rotation != 0.0) params.add('rotation=${rotation.toStringAsFixed(1)}');
    if (posX != 0.0) params.add('x=${posX.toStringAsFixed(1)}');
    if (posY != 0.0) params.add('y=${posY.toStringAsFixed(1)}');
    if (comment != null && comment!.isNotEmpty) {
      params.add('comment=${Uri.encodeComponent(comment!)}');
    }
    if (isPreviewMode) {
      params.add('preview=true');
      if (previewWidth != null) {
        params.add('pw=${previewWidth!.toStringAsFixed(0)}');
      }
      if (previewHeight != null) {
        params.add('ph=${previewHeight!.toStringAsFixed(0)}');
      }
      if (scrollOffsetX != 0.0) {
        params.add('sx=${scrollOffsetX.toStringAsFixed(1)}');
      }
      if (scrollOffsetY != 0.0) {
        params.add('sy=${scrollOffsetY.toStringAsFixed(1)}');
      }
    }

    final paramsStr = params.isEmpty ? '' : '|${params.join(',')}';
    return '![$altText$paramsStr]($path)';
  }

  /// Create from JSON map (for Quill embed metadata)
  factory MediaElement.fromJson(Map<String, dynamic> json) {
    return MediaElement(
      path: json['path'] as String? ?? '',
      mediaType: MediaType.values.byName(
        json['mediaType'] as String? ?? 'image',
      ),
      sourceType: MediaSourceType.values.byName(
        json['sourceType'] as String? ?? 'local',
      ),
      altText: json['altText'] as String? ?? '',
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      posX: (json['posX'] as num?)?.toDouble() ?? 0.0,
      posY: (json['posY'] as num?)?.toDouble() ?? 0.0,
      comment: json['comment'] as String?,
      isPreviewMode: json['isPreviewMode'] as bool? ?? false,
      previewWidth: (json['previewWidth'] as num?)?.toDouble(),
      previewHeight: (json['previewHeight'] as num?)?.toDouble(),
      scrollOffsetX: (json['scrollOffsetX'] as num?)?.toDouble() ?? 0.0,
      scrollOffsetY: (json['scrollOffsetY'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Convert to JSON map (for Quill embed metadata)
  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'mediaType': mediaType.name,
      'sourceType': sourceType.name,
      'altText': altText,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (rotation != 0.0) 'rotation': rotation,
      if (posX != 0.0) 'posX': posX,
      if (posY != 0.0) 'posY': posY,
      if (comment != null) 'comment': comment,
      if (isPreviewMode) 'isPreviewMode': isPreviewMode,
      if (previewWidth != null) 'previewWidth': previewWidth,
      if (previewHeight != null) 'previewHeight': previewHeight,
      if (scrollOffsetX != 0.0) 'scrollOffsetX': scrollOffsetX,
      if (scrollOffsetY != 0.0) 'scrollOffsetY': scrollOffsetY,
    };
  }

  /// Create from JSON string
  factory MediaElement.fromJsonString(String jsonString) {
    return MediaElement.fromJson(
      json.decode(jsonString) as Map<String, dynamic>,
    );
  }

  /// Convert to JSON string
  String toJsonString() => json.encode(toJson());

  /// Create a copy with modified fields
  MediaElement copyWith({
    String? path,
    MediaType? mediaType,
    MediaSourceType? sourceType,
    String? altText,
    double? width,
    double? height,
    double? rotation,
    double? posX,
    double? posY,
    String? comment,
    bool? isPreviewMode,
    double? previewWidth,
    double? previewHeight,
    double? scrollOffsetX,
    double? scrollOffsetY,
  }) {
    return MediaElement(
      path: path ?? this.path,
      mediaType: mediaType ?? this.mediaType,
      sourceType: sourceType ?? this.sourceType,
      altText: altText ?? this.altText,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
      comment: comment ?? this.comment,
      isPreviewMode: isPreviewMode ?? this.isPreviewMode,
      previewWidth: previewWidth ?? this.previewWidth,
      previewHeight: previewHeight ?? this.previewHeight,
      scrollOffsetX: scrollOffsetX ?? this.scrollOffsetX,
      scrollOffsetY: scrollOffsetY ?? this.scrollOffsetY,
    );
  }

  /// Determine media type from file path/URL extension
  static MediaType _getMediaTypeFromPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.m4v') ||
        lower.endsWith('.wmv') ||
        lower.endsWith('.flv')) {
      return MediaType.video;
    }
    return MediaType.image;
  }

  /// Check if the media is from the web
  bool get isFromWeb => sourceType == MediaSourceType.web;

  /// Check if the media is a local file
  bool get isLocal => sourceType == MediaSourceType.local;

  /// Check if the media is an image
  bool get isImage => mediaType == MediaType.image;

  /// Check if the media is a video
  bool get isVideo => mediaType == MediaType.video;

  /// Check if the media has custom dimensions
  bool get hasCustomDimensions => width != null || height != null;

  /// Check if the media has been rotated
  bool get hasRotation => rotation != 0.0;

  /// Check if the media has been repositioned
  bool get hasCustomPosition => posX != 0.0 || posY != 0.0;

  /// Check if the media has a comment
  bool get hasComment => comment != null && comment!.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MediaElement &&
        other.path == path &&
        other.mediaType == mediaType &&
        other.sourceType == sourceType &&
        other.altText == altText &&
        other.width == width &&
        other.height == height &&
        other.rotation == rotation &&
        other.posX == posX &&
        other.posY == posY &&
        other.comment == comment &&
        other.isPreviewMode == isPreviewMode &&
        other.previewWidth == previewWidth &&
        other.previewHeight == previewHeight &&
        other.scrollOffsetX == scrollOffsetX &&
        other.scrollOffsetY == scrollOffsetY;
  }

  @override
  int get hashCode {
    return Object.hash(
      path,
      mediaType,
      sourceType,
      altText,
      width,
      height,
      rotation,
      posX,
      posY,
      comment,
      isPreviewMode,
      previewWidth,
      previewHeight,
      scrollOffsetX,
      scrollOffsetY,
    );
  }

  @override
  String toString() {
    return 'MediaElement(path: $path, type: $mediaType, size: ${width}x$height, '
        'rotation: $rotation°, pos: ($posX, $posY), comment: $comment)';
  }
}
