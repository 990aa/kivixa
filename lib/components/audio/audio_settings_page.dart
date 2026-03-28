// Audio Settings Page
//
// Settings UI for managing AI models (Whisper/Kokoro), voice selection,
// model downloads, and audio configuration with visual model cards.

import 'dart:async';

import 'package:flutter/material.dart';

/// Model information for display
class AudioModelInfo {
  /// Model ID
  final String id;

  /// Display name
  final String name;

  /// Description
  final String description;

  /// Model size in bytes
  final int sizeBytes;

  /// Whether downloaded
  final bool isDownloaded;

  /// Download progress (0.0 to 1.0)
  final double downloadProgress;

  /// Whether currently downloading
  final bool isDownloading;

  /// Model type (stt, tts, vad)
  final String type;

  /// Model quality tier
  final ModelQuality quality;

  const AudioModelInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.sizeBytes,
    this.isDownloaded = false,
    this.downloadProgress = 0.0,
    this.isDownloading = false,
    required this.type,
    this.quality = ModelQuality.medium,
  });

  AudioModelInfo copyWith({
    bool? isDownloaded,
    double? downloadProgress,
    bool? isDownloading,
  }) {
    return AudioModelInfo(
      id: id,
      name: name,
      description: description,
      sizeBytes: sizeBytes,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      isDownloading: isDownloading ?? this.isDownloading,
      type: type,
      quality: quality,
    );
  }

  String get formattedSize {
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    } else if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}

/// Model quality tier
enum ModelQuality { tiny, small, medium, large, turbo }

/// TTS Voice information
class VoiceInfo {
  /// Voice ID
  final String id;

  /// Display name
  final String name;

  /// Voice description/characteristics
  final String description;

  /// Language code
  final String language;

  /// Gender
  final String gender;

  /// Avatar asset path or network URL
  final String? avatarUrl;

  /// Preview audio URL
  final String? previewUrl;

  /// Whether this voice is selected
  final bool isSelected;

  const VoiceInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.language,
    required this.gender,
    this.avatarUrl,
    this.previewUrl,
    this.isSelected = false,
  });
}

/// Audio Settings Page
class AudioSettingsPage extends StatefulWidget {
  /// Callback when settings change
  final void Function(AudioSettings settings)? onSettingsChanged;

  const AudioSettingsPage({super.key, this.onSettingsChanged});

  @override
  State<AudioSettingsPage> createState() => _AudioSettingsPageState();
}

class _AudioSettingsPageState extends State<AudioSettingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sample models (in production, fetch from backend)
  final _sttModels = <AudioModelInfo>[
    const AudioModelInfo(
      id: 'whisper-tiny',
      name: 'Whisper Tiny',
      description: 'Fastest, lowest accuracy. Good for quick notes.',
      sizeBytes: 75 * 1024 * 1024,
      type: 'stt',
      quality: ModelQuality.tiny,
      isDownloaded: true,
    ),
    const AudioModelInfo(
      id: 'whisper-base',
      name: 'Whisper Base',
      description: 'Balanced speed and accuracy.',
      sizeBytes: 145 * 1024 * 1024,
      type: 'stt',
      quality: ModelQuality.small,
      isDownloaded: false,
    ),
    const AudioModelInfo(
      id: 'whisper-small',
      name: 'Whisper Small',
      description: 'Better accuracy, moderate speed.',
      sizeBytes: 488 * 1024 * 1024,
      type: 'stt',
      quality: ModelQuality.medium,
      isDownloaded: false,
    ),
    const AudioModelInfo(
      id: 'whisper-medium',
      name: 'Whisper Medium',
      description: 'High accuracy for detailed transcription.',
      sizeBytes: 1536 * 1024 * 1024,
      type: 'stt',
      quality: ModelQuality.large,
      isDownloaded: false,
    ),
    const AudioModelInfo(
      id: 'whisper-turbo',
      name: 'Whisper Turbo',
      description: 'Near-realtime with excellent accuracy.',
      sizeBytes: 810 * 1024 * 1024,
      type: 'stt',
      quality: ModelQuality.turbo,
      isDownloaded: false,
    ),
  ];

  final _ttsModels = <AudioModelInfo>[
    const AudioModelInfo(
      id: 'kokoro-v1',
      name: 'Kokoro TTS',
      description: 'Natural-sounding neural text-to-speech.',
      sizeBytes: 350 * 1024 * 1024,
      type: 'tts',
      quality: ModelQuality.medium,
      isDownloaded: true,
    ),
  ];

  final _voices = <VoiceInfo>[
    const VoiceInfo(
      id: 'af_heart',
      name: 'Heart',
      description: 'Warm and friendly female voice.',
      language: 'en-US',
      gender: 'female',
      isSelected: true,
    ),
    const VoiceInfo(
      id: 'af_sky',
      name: 'Sky',
      description: 'Clear and professional female voice.',
      language: 'en-US',
      gender: 'female',
    ),
    const VoiceInfo(
      id: 'am_adam',
      name: 'Adam',
      description: 'Calm and authoritative male voice.',
      language: 'en-US',
      gender: 'male',
    ),
    const VoiceInfo(
      id: 'am_michael',
      name: 'Michael',
      description: 'Energetic and engaging male voice.',
      language: 'en-US',
      gender: 'male',
    ),
    const VoiceInfo(
      id: 'bf_emma',
      name: 'Emma',
      description: 'Sophisticated British female voice.',
      language: 'en-GB',
      gender: 'female',
    ),
    const VoiceInfo(
      id: 'bm_george',
      name: 'George',
      description: 'Elegant British male voice.',
      language: 'en-GB',
      gender: 'male',
    ),
  ];

  var _selectedSttModel = 'whisper-tiny';
  var _selectedTtsModel = 'kokoro-v1';
  var _selectedVoice = 'af_heart';
  var _autoDownload = false;
  var _silenceDetectionSensitivity = 0.5;
  var _vadEnabled = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Intelligence'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Models', icon: Icon(Icons.model_training)),
            Tab(text: 'Voices', icon: Icon(Icons.record_voice_over)),
            Tab(text: 'Settings', icon: Icon(Icons.tune)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildModelsTab(theme, colorScheme),
          _buildVoicesTab(theme, colorScheme),
          _buildSettingsTab(theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildModelsTab(ThemeData theme, ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // STT Models Section
        _buildSectionHeader('Speech-to-Text Models', Icons.mic),
        const SizedBox(height: 12),
        ..._sttModels.map((model) => _buildModelCard(model, colorScheme)),

        const SizedBox(height: 24),

        // TTS Models Section
        _buildSectionHeader('Text-to-Speech Models', Icons.volume_up),
        const SizedBox(height: 12),
        ..._ttsModels.map((model) => _buildModelCard(model, colorScheme)),

        const SizedBox(height: 24),

        // Storage info
        _buildStorageInfo(colorScheme),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildModelCard(AudioModelInfo model, ColorScheme colorScheme) {
    final isSelected = model.type == 'stt'
        ? model.id == _selectedSttModel
        : model.id == _selectedTtsModel;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: model.isDownloaded ? () => _selectModel(model) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Quality badge
                  _buildQualityBadge(model.quality, colorScheme),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          model.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          model.formattedSize,
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status indicator
                  _buildModelStatus(model, colorScheme),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                model.description,
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),

              // Download progress
              if (model.isDownloading) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: model.downloadProgress,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(model.downloadProgress * 100).toInt()}% downloaded',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQualityBadge(ModelQuality quality, ColorScheme colorScheme) {
    Color color;
    String label;

    switch (quality) {
      case ModelQuality.tiny:
        color = Colors.green;
        label = 'TINY';
      case ModelQuality.small:
        color = Colors.teal;
        label = 'BASE';
      case ModelQuality.medium:
        color = Colors.blue;
        label = 'SMALL';
      case ModelQuality.large:
        color = Colors.purple;
        label = 'MED';
      case ModelQuality.turbo:
        color = Colors.orange;
        label = 'TURBO';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildModelStatus(AudioModelInfo model, ColorScheme colorScheme) {
    if (model.isDownloaded) {
      final isSelected = model.type == 'stt'
          ? model.id == _selectedSttModel
          : model.id == _selectedTtsModel;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          isSelected ? 'Active' : 'Ready',
          style: TextStyle(
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    } else if (model.isDownloading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          value: model.downloadProgress,
        ),
      );
    } else {
      return IconButton(
        onPressed: () => _downloadModel(model),
        icon: const Icon(Icons.download),
        tooltip: 'Download',
      );
    }
  }

  Widget _buildStorageInfo(ColorScheme colorScheme) {
    final downloadedSize =
        _sttModels
            .where((m) => m.isDownloaded)
            .fold<int>(0, (sum, m) => sum + m.sizeBytes) +
        _ttsModels
            .where((m) => m.isDownloaded)
            .fold<int>(0, (sum, m) => sum + m.sizeBytes);

    final totalAvailable =
        _sttModels.fold<int>(0, (sum, m) => sum + m.sizeBytes) +
        _ttsModels.fold<int>(0, (sum, m) => sum + m.sizeBytes);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.storage, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Storage Used'),
                  Text(
                    '${_formatBytes(downloadedSize)} of ${_formatBytes(totalAvailable)} available',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _clearUnusedModels,
              child: const Text('Clear Unused'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  Widget _buildVoicesTab(ThemeData theme, ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Voice grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: _voices.length,
          itemBuilder: (context, index) {
            return _buildVoiceCard(_voices[index], colorScheme);
          },
        ),
      ],
    );
  }

  Widget _buildVoiceCard(VoiceInfo voice, ColorScheme colorScheme) {
    final isSelected = voice.id == _selectedVoice;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _selectVoice(voice),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar circle
              CircleAvatar(
                radius: 36,
                backgroundColor: voice.gender == 'female'
                    ? Colors.pink.withValues(alpha: 0.2)
                    : Colors.blue.withValues(alpha: 0.2),
                child: Text(
                  voice.name[0],
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: voice.gender == 'female' ? Colors.pink : Colors.blue,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                voice.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                voice.language,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),

              const SizedBox(height: 8),

              // Preview button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => _previewVoice(voice),
                    icon: const Icon(Icons.play_circle_outline, size: 28),
                    tooltip: 'Preview',
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTab(ThemeData theme, ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Voice Activity Detection
        _buildSettingsTile(
          title: 'Voice Activity Detection',
          subtitle: 'Automatically detect when you start speaking',
          trailing: Switch(
            value: _vadEnabled,
            onChanged: (value) {
              setState(() => _vadEnabled = value);
              _notifySettingsChanged();
            },
          ),
        ),

        const SizedBox(height: 8),

        // Silence detection sensitivity
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Silence Detection Sensitivity',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Higher values detect shorter pauses as end of speech',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 12),
                Slider(
                  value: _silenceDetectionSensitivity,
                  onChanged: (value) {
                    setState(() => _silenceDetectionSensitivity = value);
                    _notifySettingsChanged();
                  },
                  divisions: 10,
                  label: '${(_silenceDetectionSensitivity * 100).toInt()}%',
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Auto-download
        _buildSettingsTile(
          title: 'Auto-download Models',
          subtitle: 'Download recommended models automatically',
          trailing: Switch(
            value: _autoDownload,
            onChanged: (value) {
              setState(() => _autoDownload = value);
              _notifySettingsChanged();
            },
          ),
        ),

        const SizedBox(height: 24),

        // Reset button
        OutlinedButton.icon(
          onPressed: _resetToDefaults,
          icon: const Icon(Icons.refresh),
          label: const Text('Reset to Defaults'),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing,
      ),
    );
  }

  void _selectModel(AudioModelInfo model) {
    setState(() {
      if (model.type == 'stt') {
        _selectedSttModel = model.id;
      } else {
        _selectedTtsModel = model.id;
      }
    });
    _notifySettingsChanged();
  }

  void _downloadModel(AudioModelInfo model) {
    // In production, implement actual download logic
    final index = model.type == 'stt'
        ? _sttModels.indexWhere((m) => m.id == model.id)
        : _ttsModels.indexWhere((m) => m.id == model.id);

    if (index == -1) return;

    // Simulate download
    setState(() {
      if (model.type == 'stt') {
        _sttModels[index] = model.copyWith(isDownloading: true);
      } else {
        _ttsModels[index] = model.copyWith(isDownloading: true);
      }
    });

    // Simulate progress
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final current = model.type == 'stt'
          ? _sttModels[index]
          : _ttsModels[index];

      if (current.downloadProgress >= 1.0) {
        timer.cancel();
        setState(() {
          if (model.type == 'stt') {
            _sttModels[index] = current.copyWith(
              isDownloading: false,
              isDownloaded: true,
            );
          } else {
            _ttsModels[index] = current.copyWith(
              isDownloading: false,
              isDownloaded: true,
            );
          }
        });
        return;
      }

      setState(() {
        if (model.type == 'stt') {
          _sttModels[index] = current.copyWith(
            downloadProgress: current.downloadProgress + 0.05,
          );
        } else {
          _ttsModels[index] = current.copyWith(
            downloadProgress: current.downloadProgress + 0.05,
          );
        }
      });
    });
  }

  void _selectVoice(VoiceInfo voice) {
    setState(() => _selectedVoice = voice.id);
    _notifySettingsChanged();
  }

  void _previewVoice(VoiceInfo voice) {
    // In production, play preview audio
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playing preview for ${voice.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _clearUnusedModels() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Unused Models?'),
        content: const Text(
          'This will remove downloaded models that are not currently active.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // In production, implement cleanup
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _resetToDefaults() {
    setState(() {
      _selectedSttModel = 'whisper-tiny';
      _selectedTtsModel = 'kokoro-v1';
      _selectedVoice = 'af_heart';
      _autoDownload = false;
      _silenceDetectionSensitivity = 0.5;
      _vadEnabled = true;
    });
    _notifySettingsChanged();
  }

  void _notifySettingsChanged() {
    widget.onSettingsChanged?.call(
      AudioSettings(
        sttModelId: _selectedSttModel,
        ttsModelId: _selectedTtsModel,
        voiceId: _selectedVoice,
        vadEnabled: _vadEnabled,
        silenceSensitivity: _silenceDetectionSensitivity,
        autoDownload: _autoDownload,
      ),
    );
  }
}

/// Audio settings model
class AudioSettings {
  final String sttModelId;
  final String ttsModelId;
  final String voiceId;
  final bool vadEnabled;
  final double silenceSensitivity;
  final bool autoDownload;

  const AudioSettings({
    required this.sttModelId,
    required this.ttsModelId,
    required this.voiceId,
    required this.vadEnabled,
    required this.silenceSensitivity,
    required this.autoDownload,
  });
}
