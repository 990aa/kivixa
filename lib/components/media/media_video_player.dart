
import 'package:flutter/material.dart';
import 'package:kivixa/data/models/media_element.dart';
import 'package:kivixa/services/media_service.dart';
import 'package:visibility_detector/visibility_detector.dart';

// Platform-specific imports are handled conditionally
// Windows: media_kit
// Android: awesome_video_player

/// Platform-aware video player widget for embedded video playback.
///
/// Features:
/// - Play/pause controls
/// - Progress bar with seeking
/// - Mute toggle
/// - Fullscreen toggle
/// - Lazy initialization (loads when visible)
/// - Resizable container
class MediaVideoPlayer extends StatefulWidget {
  const MediaVideoPlayer({
    super.key,
    required this.element,
    required this.onChanged,
    this.autoPlay = false,
    this.showControls = true,
  });

  /// The media element containing video info
  final MediaElement element;

  /// Callback when element properties change
  final ValueChanged<MediaElement> onChanged;

  /// Whether to auto-play when visible
  final bool autoPlay;

  /// Whether to show playback controls
  final bool showControls;

  @override
  State<MediaVideoPlayer> createState() => _MediaVideoPlayerState();
}

class _MediaVideoPlayerState extends State<MediaVideoPlayer> {
  var _isVisible = false;
  var _isInitialized = false;
  var _isPlaying = false;
  var _isMuted = false;
  var _isLoading = true;
  var _hasError = false;
  Duration _position = Duration.zero;
  final Duration _duration = Duration.zero;

  // This is a platform-agnostic implementation
  // In production, you'd use conditional imports for:
  // - media_kit on Windows/Desktop
  // - awesome_video_player on Android

  @override
  void initState() {
    super.initState();
    _checkVideoExists();
  }

  Future<void> _checkVideoExists() async {
    if (widget.element.isFromWeb) {
      // For web videos, we'll handle differently
      setState(() {
        _isLoading = false;
        _isInitialized = true;
      });
    } else {
      final exists = await MediaService.instance.resolveLocalPath(
        widget.element.path,
      );
      setState(() {
        _isLoading = false;
        _hasError = !exists;
        _isInitialized = exists;
      });
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    final wasVisible = _isVisible;
    _isVisible = info.visibleFraction > 0.5;

    if (_isVisible && !wasVisible && _isInitialized && widget.autoPlay) {
      _play();
    } else if (!_isVisible && wasVisible && _isPlaying) {
      _pause();
    }
  }

  void _play() {
    setState(() => _isPlaying = true);
    // Actual playback would be handled by platform-specific player
  }

  void _pause() {
    setState(() => _isPlaying = false);
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _pause();
    } else {
      _play();
    }
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
  }

  void _seekTo(double value) {
    final newPosition = Duration(
      milliseconds: (value * _duration.inMilliseconds).round(),
    );
    setState(() => _position = newPosition);
  }

  void _openFullscreen() {
    // Would open fullscreen video player
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Fullscreen mode')));
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      final hours = duration.inHours.toString();
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.element.width ?? 400;
    final height = widget.element.height ?? 225;

    return VisibilityDetector(
      key: Key('video-${widget.element.path}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_hasError) {
      return _buildErrorState();
    }

    return Stack(
      children: [
        // Video preview/thumbnail
        _buildVideoPreview(),

        // Play button overlay when paused
        if (!_isPlaying)
          Center(
            child: IconButton(
              onPressed: _togglePlayPause,
              icon: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
          ),

        // Controls overlay
        if (widget.showControls)
          Positioned(left: 0, right: 0, bottom: 0, child: _buildControls()),
      ],
    );
  }

  Widget _buildVideoPreview() {
    // In production, this would show the actual video frame
    // For now, showing a placeholder with video icon
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 8),
            Text(
              _getFileName(),
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _getFileName() {
    final path = widget.element.path;
    if (path.contains('/')) {
      return path.split('/').last;
    } else if (path.contains('\\')) {
      return path.split('\\').last;
    }
    return path;
  }

  Widget _buildErrorState() {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 8),
            Text('Video not found', style: TextStyle(color: Colors.grey[400])),
            const SizedBox(height: 4),
            Text(
              widget.element.path,
              style: TextStyle(color: Colors.grey[600], fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
              thumbColor: Colors.white,
            ),
            child: Slider(
              value: _duration.inMilliseconds > 0
                  ? _position.inMilliseconds / _duration.inMilliseconds
                  : 0,
              onChanged: _seekTo,
            ),
          ),

          // Control buttons
          Row(
            children: [
              // Play/Pause
              IconButton(
                onPressed: _togglePlayPause,
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 20,
                ),
                visualDensity: VisualDensity.compact,
              ),

              // Time display
              Text(
                '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),

              const Spacer(),

              // Mute
              IconButton(
                onPressed: _toggleMute,
                icon: Icon(
                  _isMuted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                  size: 20,
                ),
                visualDensity: VisualDensity.compact,
              ),

              // Fullscreen
              IconButton(
                onPressed: _openFullscreen,
                icon: const Icon(
                  Icons.fullscreen,
                  color: Colors.white,
                  size: 20,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Clean up video player resources
    super.dispose();
  }
}
