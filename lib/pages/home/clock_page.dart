import 'package:flutter/material.dart';
import 'package:kivixa/services/productivity/chained_routine_service.dart';
import 'package:kivixa/services/productivity/multi_timer_service.dart';
import 'package:kivixa/services/productivity/productivity_timer_service.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class _BlockStyle {
  const _BlockStyle({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

const _blockStyles = <_BlockStyle>[
  _BlockStyle(label: 'Focus', icon: Icons.psychology, color: Color(0xFF4CAF50)),
  _BlockStyle(label: 'Break', icon: Icons.coffee, color: Color(0xFF795548)),
  _BlockStyle(label: 'Study', icon: Icons.school, color: Color(0xFF2196F3)),
  _BlockStyle(
    label: 'Exercise',
    icon: Icons.fitness_center,
    color: Color(0xFFF44336),
  ),
  _BlockStyle(
    label: 'Planning',
    icon: Icons.event_note,
    color: Color(0xFF9C27B0),
  ),
  _BlockStyle(label: 'Custom', icon: Icons.tune, color: Color(0xFF607D8B)),
];

/// Full-page Clock/Productivity Timer interface
class ClockPage extends StatefulWidget {
  const ClockPage({super.key});

  @override
  State<ClockPage> createState() => _ClockPageState();
}

class _ClockPageState extends State<ClockPage>
    with SingleTickerProviderStateMixin {
  final _timerService = ProductivityTimerService.instance;
  final _multiTimerService = MultiTimerService.instance;
  final _routineService = ChainedRoutineService.instance;

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initializeServices();
    _timerService.addListener(_onUpdate);
    _multiTimerService.addListener(_onUpdate);
    _routineService.addListener(_onUpdate);
  }

  Future<void> _initializeServices() async {
    await _timerService.initialize();
    await _multiTimerService.initialize();
    await _routineService.initialize();
    if (mounted) setState(() {});
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _timerService.removeListener(_onUpdate);
    _multiTimerService.removeListener(_onUpdate);
    _routineService.removeListener(_onUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productivity Timer'),
        actions: [
          // Active timers indicator
          if (_multiTimerService.hasActiveTimers)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                avatar: const Icon(Icons.timer, size: 16),
                label: Text('${_multiTimerService.activeCount}'),
                backgroundColor: colorScheme.primaryContainer,
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.timer), text: 'Focus'),
            Tab(icon: Icon(Icons.flash_on), text: 'Presets'),
            Tab(icon: Icon(Icons.playlist_play), text: 'Routines'),
            Tab(icon: Icon(Icons.account_tree_outlined), text: 'Chains'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Stats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFocusTab(context),
          _buildPresetsTab(context),
          _buildRoutinesTab(context),
          _buildCustomChainsTab(context),
          _buildStatsTab(context),
        ],
      ),
    );
  }

  // ============================================================
  // Focus Tab - Main timer with context tags
  // ============================================================

  Widget _buildFocusTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Main Timer Display
          _buildMainTimerCard(context),
          const SizedBox(height: 16),

          // Context Tags Section
          _buildContextTagsSection(context),
          const SizedBox(height: 16),

          // Secondary Timers Section
          _buildSecondaryTimersSection(context),
          const SizedBox(height: 16),

          // Today's Progress
          _buildDailyProgressCard(context),
        ],
      ),
    );
  }

  Widget _buildMainTimerCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final timer = _timerService;

    Color displayColor;
    if (timer.isBreak) {
      displayColor = Colors.green;
    } else if (timer.isPaused) {
      displayColor = Colors.orange;
    } else {
      displayColor = timer.sessionType.color;
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Session type selector
            if (timer.isIdle) ...[
              _buildSessionTypeSelector(context),
              const SizedBox(height: 24),
            ],

            // Timer display
            CircularPercentIndicator(
              radius: 120,
              lineWidth: 16,
              percent: timer.isIdle ? 0 : timer.progress,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    timer.isBreak ? Icons.coffee : timer.sessionType.icon,
                    size: 40,
                    color: displayColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timer.formattedTime,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: displayColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    timer.isBreak
                        ? 'Break Time'
                        : timer.isIdle
                        ? 'Ready'
                        : timer.isPaused
                        ? 'Paused'
                        : timer.sessionType.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (timer.currentContextTag != null)
                    Chip(
                      avatar: Icon(
                        timer.currentContextTag!.icon,
                        size: 16,
                        color: timer.currentContextTag!.color,
                      ),
                      label: Text(
                        timer.currentContextTag!.name,
                        style: theme.textTheme.bodySmall,
                      ),
                      backgroundColor: timer.currentContextTag!.color
                          .withValues(alpha: 0.1),
                    ),
                ],
              ),
              progressColor: displayColor,
              backgroundColor: colorScheme.surfaceContainerHighest,
              circularStrokeCap: CircularStrokeCap.round,
              animation: true,
              animateFromLastPercent: true,
            ),
            const SizedBox(height: 24),

            // Timer controls
            _buildTimerControls(context),

            // Cycle info
            if (!timer.isIdle) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.loop, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Cycle ${timer.currentCycle}/${timer.totalCycles}',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (timer.activePreset != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.flash_on, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      timer.activePreset!.name,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSessionTypeSelector(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: SessionType.values.map((type) {
        final isSelected = _timerService.sessionType == type;
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(type.icon, size: 16),
              const SizedBox(width: 4),
              Text(type.label),
            ],
          ),
          selected: isSelected,
          selectedColor: type.color.withValues(alpha: 0.3),
          onSelected: (_) => _timerService.setSessionType(type),
        );
      }).toList(),
    );
  }

  Widget _buildTimerControls(BuildContext context) {
    final timer = _timerService;
    final theme = Theme.of(context);

    if (timer.isIdle) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Duration selector
          IconButton.outlined(
            icon: const Icon(Icons.remove),
            onPressed: () {
              if (timer.totalDuration.inMinutes > 5) {
                timer.setDuration(
                  timer.totalDuration - const Duration(minutes: 5),
                );
              }
            },
          ),
          const SizedBox(width: 8),
          Text(
            '${timer.totalDuration.inMinutes} min',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            icon: const Icon(Icons.add),
            onPressed: () {
              timer.setDuration(
                timer.totalDuration + const Duration(minutes: 5),
              );
            },
          ),
          const SizedBox(width: 24),
          // Start button
          FilledButton.icon(
            onPressed: () => timer.startSession(),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start'),
            style: FilledButton.styleFrom(
              backgroundColor: timer.sessionType.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      );
    }

    // Running/Paused controls
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.outlined(
          icon: const Icon(Icons.stop),
          onPressed: timer.stop,
          tooltip: 'Stop',
          iconSize: 28,
        ),
        const SizedBox(width: 16),
        FilledButton.icon(
          onPressed: timer.isRunning || timer.isBreak
              ? timer.pause
              : timer.resume,
          icon: Icon(timer.isPaused ? Icons.play_arrow : Icons.pause),
          label: Text(timer.isPaused ? 'Resume' : 'Pause'),
          style: FilledButton.styleFrom(
            backgroundColor: timer.sessionType.color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
        const SizedBox(width: 16),
        IconButton.outlined(
          icon: const Icon(Icons.skip_next),
          onPressed: timer.skip,
          tooltip: 'Skip',
          iconSize: 28,
        ),
      ],
    );
  }

  Widget _buildContextTagsSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.label, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Context Tag',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_timerService.currentContextTag != null)
                  TextButton.icon(
                    onPressed: () => _timerService.setContextTag(null),
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Clear'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _timerService.allContextTags.map((tag) {
                final isSelected = _timerService.currentContextTag == tag;
                final minutes = _timerService.getMinutesForTag(tag.id);
                return ActionChip(
                  avatar: Icon(tag.icon, size: 16, color: tag.color),
                  label: Text(
                    minutes > 0
                        ? '${tag.name} (${_formatMinutes(minutes)})'
                        : tag.name,
                  ),
                  backgroundColor: isSelected
                      ? tag.color.withValues(alpha: 0.3)
                      : null,
                  side: isSelected
                      ? BorderSide(color: tag.color, width: 2)
                      : null,
                  onPressed: () =>
                      _timerService.setContextTag(isSelected ? null : tag),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryTimersSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.av_timer, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Parallel Timers',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddSecondaryTimerDialog(context),
                  tooltip: 'Add Timer',
                ),
              ],
            ),
            if (_multiTimerService.timers.isEmpty) ...[
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'No parallel timers running',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: SecondaryTimerPreset.presets.take(4).map((preset) {
                  return ActionChip(
                    avatar: Icon(preset.icon, size: 16, color: preset.color),
                    label: Text(preset.name),
                    onPressed: () {
                      final timer = preset.toTimer();
                      _multiTimerService.addTimer(timer);
                      timer.start();
                    },
                  );
                }).toList(),
              ),
            ] else ...[
              const SizedBox(height: 12),
              ..._multiTimerService.timers.map((timer) {
                return ListTile(
                  leading: CircularPercentIndicator(
                    radius: 20,
                    lineWidth: 4,
                    percent: timer.progress,
                    center: Icon(timer.icon, size: 16, color: timer.color),
                    progressColor: timer.color,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                  ),
                  title: Text(timer.name),
                  subtitle: Text(timer.formattedTime),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (timer.isIdle)
                        IconButton(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: () =>
                              _multiTimerService.startTimer(timer.id),
                        )
                      else if (timer.isPaused)
                        IconButton(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: () =>
                              _multiTimerService.resumeTimer(timer.id),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.pause),
                          onPressed: () =>
                              _multiTimerService.pauseTimer(timer.id),
                        ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () =>
                            _multiTimerService.removeTimer(timer.id),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDailyProgressCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final timer = _timerService;
    final stats = timer.stats;
    final goal = timer.goal;

    final dailyProgress = timer.getDailyProgress();
    final sessionsProgress = goal.dailySessions > 0
        ? (stats.todaySessions / goal.dailySessions).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  "Today's Progress",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildProgressIndicator(
                    context,
                    'Focus Time',
                    '${stats.todayFocusMinutes}/${goal.dailyFocusMinutes} min',
                    dailyProgress,
                    colorScheme.primary,
                    Icons.timer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildProgressIndicator(
                    context,
                    'Sessions',
                    '${stats.todaySessions}/${goal.dailySessions}',
                    sessionsProgress,
                    Colors.orange,
                    Icons.check_circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatChip(
                    context,
                    Icons.local_fire_department,
                    '${stats.currentStreak} day streak',
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatChip(
                    context,
                    Icons.access_time,
                    '${_formatMinutes(timer.getWeeklyFocusMinutes())} this week',
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(
    BuildContext context,
    String label,
    String value,
    double progress,
    Color color,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        CircularPercentIndicator(
          radius: 40,
          lineWidth: 8,
          percent: progress,
          center: Icon(icon, color: color),
          progressColor: color,
          backgroundColor: color.withValues(alpha: 0.2),
          circularStrokeCap: CircularStrokeCap.round,
        ),
        const SizedBox(height: 8),
        Text(label, style: theme.textTheme.bodySmall),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Presets Tab
  // ============================================================

  Widget _buildPresetsTab(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final presets = _timerService.allQuickPresets;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Quick-Switch Presets',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton.filledTonal(
              onPressed: () => _showPresetEditorDialog(context),
              icon: const Icon(Icons.add),
              tooltip: 'Create preset',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Tap any preset to launch instantly. Edit or delete built-in and custom presets anytime.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        if (presets.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No presets available yet. Create one using the + button.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        ...presets.map((preset) {
          final presetType = preset.isDefault ? 'Default' : 'Custom';
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                _timerService.startWithPreset(preset);
                _tabController.animateTo(0); // Go to focus tab
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(preset.icon, color: colorScheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                preset.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Chip(
                                label: Text(presetType),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                          if (preset.description != null)
                            Text(
                              preset.description!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            children: [
                              _buildPresetChip(
                                Icons.work,
                                '${preset.workMinutes}m',
                              ),
                              _buildPresetChip(
                                Icons.coffee,
                                '${preset.breakMinutes}m break',
                              ),
                              _buildPresetChip(
                                Icons.loop,
                                '${preset.totalCycles}x',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 132),
                      child: Wrap(
                        spacing: 2,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.play_circle),
                            iconSize: 32,
                            color: colorScheme.primary,
                            tooltip: 'Start preset',
                            onPressed: () {
                              _timerService.startWithPreset(preset);
                              _tabController.animateTo(0);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Edit preset',
                            onPressed: () => _showPresetEditorDialog(
                              context,
                              preset: preset,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Delete preset',
                            onPressed: () =>
                                _confirmDeletePreset(context, preset),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPresetChip(IconData icon, String label) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12),
          const SizedBox(width: 4),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  // ============================================================
  // Routines Tab
  // ============================================================

  Widget _buildRoutinesTab(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Show active routine if running
    if (!_routineService.isIdle) {
      return _buildActiveRoutineView(context);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Chained Routines',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton.filledTonal(
              onPressed: () => _showRoutineEditorDialog(context),
              icon: const Icon(Icons.add),
              tooltip: 'Create routine',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Run a sequence of timer blocks automatically. Edit and delete any routine from here.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        if (_routineService.allRoutines.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No routines found. Create a new routine with the + button.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        ..._routineService.allRoutines.map((routine) {
          return _buildRoutineCard(context, routine);
        }),
      ],
    );
  }

  Widget _buildCustomChainsTab(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final customRoutines = _routineService.customRoutines;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Custom Chains',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton.filled(
              onPressed: () => _showRoutineEditorDialog(context),
              icon: const Icon(Icons.add),
              tooltip: 'Create custom chain',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Create fully custom timer chains and manage every block in your sequence.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        if (customRoutines.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No custom chains yet. Tap + to build your first routine.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        ...customRoutines.map((routine) => _buildRoutineCard(context, routine)),
      ],
    );
  }

  Widget _buildRoutineCard(BuildContext context, ChainedRoutine routine) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final routineType = routine.isDefault ? 'Default' : 'Custom';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showRoutineDetails(context, routine),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: routine.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(routine.icon, color: routine.color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          routine.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Chip(
                          label: Text(routineType),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    if (routine.description != null)
                      Text(
                        routine.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '${routine.blocks.length} blocks - ${routine.totalMinutes} min total',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 132),
                child: Wrap(
                  spacing: 2,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.play_circle),
                      iconSize: 32,
                      color: colorScheme.primary,
                      tooltip: 'Start routine',
                      onPressed: () => _routineService.startRoutine(routine),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit routine',
                      onPressed: () =>
                          _showRoutineEditorDialog(context, routine: routine),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete routine',
                      onPressed: () => _confirmDeleteRoutine(context, routine),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveRoutineView(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final routine = _routineService.currentRoutine!;
    final block = _routineService.currentBlock;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Routine header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(routine.icon, color: routine.color, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routine.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        LinearProgressIndicator(
                          value: _routineService.overallProgress,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Block ${_routineService.completedBlocks + 1}/${_routineService.totalBlocks}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.stop),
                    onPressed: _routineService.stop,
                    tooltip: 'Stop Routine',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Current block
          if (block != null && !_routineService.isCompleted)
            Card(
              color: block.color.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(block.icon, size: 48, color: block.color),
                    const SizedBox(height: 16),
                    Text(
                      block.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (block.description != null)
                      Text(
                        block.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: 16),
                    CircularPercentIndicator(
                      radius: 80,
                      lineWidth: 12,
                      percent: _routineService.blockProgress,
                      center: Text(
                        _routineService.formattedTime,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: block.color,
                        ),
                      ),
                      progressColor: block.color,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      circularStrokeCap: CircularStrokeCap.round,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton.outlined(
                          icon: Icon(
                            _routineService.isPaused
                                ? Icons.play_arrow
                                : Icons.pause,
                          ),
                          onPressed: _routineService.isPaused
                              ? _routineService.resume
                              : _routineService.pause,
                        ),
                        const SizedBox(width: 16),
                        IconButton.outlined(
                          icon: const Icon(Icons.skip_next),
                          onPressed: _routineService.skipBlock,
                          tooltip: 'Skip to next block',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Completed state
          if (_routineService.isCompleted)
            Card(
              color: Colors.green.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 64,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Routine Complete!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _routineService.stop,
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Upcoming blocks
          Text(
            'Blocks',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...routine.blocks.asMap().entries.map((entry) {
            final index = entry.key;
            final b = entry.value;
            final isCompleted = index < _routineService.completedBlocks;
            final isCurrent = index == _routineService.completedBlocks;

            return ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.withValues(alpha: 0.2)
                      : isCurrent
                      ? b.color.withValues(alpha: 0.2)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isCompleted ? Icons.check : b.icon,
                  color: isCompleted ? Colors.green : b.color,
                ),
              ),
              title: Text(
                b.name,
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.bold : null,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Text('${b.durationMinutes} min'),
              trailing: isCurrent
                  ? Icon(Icons.arrow_forward, color: colorScheme.primary)
                  : null,
            );
          }),
        ],
      ),
    );
  }

  void _showRoutineDetails(BuildContext pageContext, ChainedRoutine routine) {
    showModalBottomSheet<void>(
      context: pageContext,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Icon(routine.icon, color: routine.color, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        routine.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                if (routine.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    routine.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Chip(
                      avatar: const Icon(Icons.timer, size: 16),
                      label: Text('${routine.totalMinutes} min total'),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      avatar: const Icon(Icons.list, size: 16),
                      label: Text('${routine.blocks.length} blocks'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Blocks',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...routine.blocks.map((block) {
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: block.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(block.icon, color: block.color),
                    ),
                    title: Text(block.name),
                    subtitle: block.description != null
                        ? Text(block.description!)
                        : null,
                    trailing: Text('${block.durationMinutes} min'),
                  );
                }),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showRoutineEditorDialog(
                            pageContext,
                            routine: routine,
                          );
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmDeleteRoutine(pageContext, routine);
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _routineService.startRoutine(routine);
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Routine'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPresetEditorDialog(BuildContext context, {QuickPreset? preset}) {
    final nameController = TextEditingController(text: preset?.name ?? '');
    final workMinutesController = TextEditingController(
      text: '${preset?.workMinutes ?? 25}',
    );
    final breakMinutesController = TextEditingController(
      text: '${preset?.breakMinutes ?? 5}',
    );
    final cyclesController = TextEditingController(
      text: '${preset?.totalCycles ?? 4}',
    );
    final descriptionController = TextEditingController(
      text: preset?.description ?? '',
    );
    var autoStartBreak = preset?.autoStartBreak ?? true;
    var autoStartNextSession = preset?.autoStartNextSession ?? false;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(preset == null ? 'Create Preset' : 'Edit Preset'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'Deep Work',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: workMinutesController,
                      decoration: const InputDecoration(
                        labelText: 'Work Minutes',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: breakMinutesController,
                      decoration: const InputDecoration(
                        labelText: 'Break Minutes',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cyclesController,
                      decoration: const InputDecoration(labelText: 'Cycles'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Auto-start break'),
                      value: autoStartBreak,
                      onChanged: (value) {
                        setDialogState(() {
                          autoStartBreak = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Auto-start next session'),
                      value: autoStartNextSession,
                      onChanged: (value) {
                        setDialogState(() {
                          autoStartNextSession = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final workMinutes = int.tryParse(
                      workMinutesController.text.trim(),
                    );
                    final breakMinutes = int.tryParse(
                      breakMinutesController.text.trim(),
                    );
                    final cycles = int.tryParse(cyclesController.text.trim());

                    if (name.isEmpty ||
                        workMinutes == null ||
                        breakMinutes == null ||
                        cycles == null ||
                        workMinutes <= 0 ||
                        breakMinutes <= 0 ||
                        cycles <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter valid preset values.'),
                        ),
                      );
                      return;
                    }

                    final normalizedName = name
                        .toLowerCase()
                        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
                        .replaceAll(RegExp(r'^_+|_+$'), '');
                    final presetId =
                        preset?.id ??
                        'custom_preset_${normalizedName.isEmpty ? 'preset' : normalizedName}_${DateTime.now().millisecondsSinceEpoch}';

                    final updatedPreset = QuickPreset(
                      id: presetId,
                      name: name,
                      icon: preset?.icon ?? Icons.tune,
                      workMinutes: workMinutes,
                      breakMinutes: breakMinutes,
                      longBreakMinutes: preset?.longBreakMinutes,
                      cyclesBeforeLongBreak: preset?.cyclesBeforeLongBreak,
                      totalCycles: cycles,
                      autoStartBreak: autoStartBreak,
                      autoStartNextSession: autoStartNextSession,
                      description: descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                      isDefault: preset?.isDefault ?? false,
                    );

                    _timerService.saveQuickPreset(updatedPreset);
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeletePreset(BuildContext context, QuickPreset preset) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete preset?'),
          content: Text('Delete "${preset.name}" permanently?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                _timerService.deleteQuickPreset(preset.id);
                Navigator.pop(dialogContext);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showRoutineEditorDialog(
    BuildContext context, {
    ChainedRoutine? routine,
  }) {
    final nameController = TextEditingController(text: routine?.name ?? '');
    final descriptionController = TextEditingController(
      text: routine?.description ?? '',
    );
    final draftBlocks = List<RoutineBlock>.from(routine?.blocks ?? const []);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> addBlock({int? insertIndex}) async {
              final newBlock = await _showBlockEditorDialog(context);
              if (newBlock == null) {
                return;
              }

              setSheetState(() {
                final targetIndex = insertIndex ?? draftBlocks.length;
                draftBlocks.insert(
                  targetIndex.clamp(0, draftBlocks.length),
                  newBlock,
                );
              });
            }

            Future<void> editBlock(int index) async {
              final existing = draftBlocks[index];
              final updated = await _showBlockEditorDialog(
                context,
                existing: existing,
              );
              if (updated == null) {
                return;
              }

              setSheetState(() {
                draftBlocks[index] = updated;
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            routine == null ? 'Create Chain' : 'Edit Chain',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Blocks',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (draftBlocks.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No blocks yet. Add your first block to continue.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ...draftBlocks.asMap().entries.map((entry) {
                      final index = entry.key;
                      final block = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: block.color.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      block.icon,
                                      color: block.color,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          block.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        Text(
                                          '${block.durationMinutes} min',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => editBlock(index),
                                    tooltip: 'Edit block',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () {
                                      setSheetState(() {
                                        draftBlocks.removeAt(index);
                                      });
                                    },
                                    tooltip: 'Delete block',
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () =>
                                        addBlock(insertIndex: index),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Insert Before'),
                                  ),
                                  TextButton.icon(
                                    onPressed: () =>
                                        addBlock(insertIndex: index + 1),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Insert After'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    OutlinedButton.icon(
                      onPressed: () => addBlock(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Block'),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () {
                        final name = nameController.text.trim();
                        if (name.isEmpty || draftBlocks.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Enter a routine name and at least one block.',
                              ),
                            ),
                          );
                          return;
                        }

                        final normalizedName = name
                            .toLowerCase()
                            .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
                            .replaceAll(RegExp(r'^_+|_+$'), '');
                        final routineId =
                            routine?.id ??
                            'custom_routine_${normalizedName.isEmpty ? 'routine' : normalizedName}_${DateTime.now().millisecondsSinceEpoch}';

                        final updatedRoutine = ChainedRoutine(
                          id: routineId,
                          name: name,
                          blocks: List<RoutineBlock>.from(draftBlocks),
                          icon: routine?.icon ?? Icons.account_tree_outlined,
                          color:
                              routine?.color ??
                              Theme.of(context).colorScheme.primary,
                          description: descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                          isDefault: routine?.isDefault ?? false,
                        );

                        _routineService.saveRoutine(updatedRoutine);
                        Navigator.pop(sheetContext);
                      },
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save Chain'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<RoutineBlock?> _showBlockEditorDialog(
    BuildContext context, {
    RoutineBlock? existing,
  }) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final durationController = TextEditingController(
      text: '${existing?.durationMinutes ?? 25}',
    );
    final descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );

    final initialStyle = _blockStyles.indexWhere(
      (style) =>
          style.icon.codePoint ==
          (existing?.icon.codePoint ?? Icons.timer.codePoint),
    );
    var selectedStyleIndex = initialStyle == -1 ? 0 : initialStyle;

    return showDialog<RoutineBlock>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existing == null ? 'Add Block' : 'Edit Block'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Block name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: durationController,
                      decoration: const InputDecoration(
                        labelText: 'Duration (minutes)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: selectedStyleIndex,
                      decoration: const InputDecoration(labelText: 'Style'),
                      items: _blockStyles.asMap().entries.map((entry) {
                        final index = entry.key;
                        final style = entry.value;
                        return DropdownMenuItem<int>(
                          value: index,
                          child: Row(
                            children: [
                              Icon(style.icon, color: style.color, size: 18),
                              const SizedBox(width: 8),
                              Text(style.label),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setDialogState(() {
                          selectedStyleIndex = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final durationMinutes = int.tryParse(
                      durationController.text.trim(),
                    );
                    if (name.isEmpty ||
                        durationMinutes == null ||
                        durationMinutes <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter a valid block name and duration.',
                          ),
                        ),
                      );
                      return;
                    }

                    final style = _blockStyles[selectedStyleIndex];
                    Navigator.pop(
                      dialogContext,
                      RoutineBlock(
                        name: name,
                        durationMinutes: durationMinutes,
                        icon: style.icon,
                        color: style.color,
                        description: descriptionController.text.trim().isEmpty
                            ? null
                            : descriptionController.text.trim(),
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteRoutine(BuildContext context, ChainedRoutine routine) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete routine?'),
          content: Text('Delete "${routine.name}" permanently?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                _routineService.deleteRoutine(routine.id);
                Navigator.pop(dialogContext);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // Stats Tab
  // ============================================================

  Widget _buildStatsTab(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final stats = _timerService.stats;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Total Focus',
                _formatMinutes(stats.totalFocusMinutes),
                Icons.timer,
                colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'Sessions',
                '${stats.completedSessions}',
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Current Streak',
                '${stats.currentStreak} days',
                Icons.local_fire_department,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'Best Streak',
                '${stats.longestStreak} days',
                Icons.emoji_events,
                Colors.amber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Weekly chart
        Text(
          'Weekly Progress',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildWeeklyChart(context),
        const SizedBox(height: 16),

        // Tag breakdown
        Text(
          'Time by Context',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildTagBreakdown(context),
        const SizedBox(height: 16),

        // Session type breakdown
        Text(
          'Session Types',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildSessionTypeBreakdown(context),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final stats = _timerService.stats;

    final now = DateTime.now();
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    var maxMinutes = 1;
    for (var i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final minutes = stats.dailyMinutes[key] ?? 0;
      if (minutes > maxMinutes) maxMinutes = minutes;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 150,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final date = weekStart.add(Duration(days: i));
              final key =
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
              final minutes = stats.dailyMinutes[key] ?? 0;
              final height = (minutes / maxMinutes) * 100;
              final isToday = i == now.weekday - 1;

              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _formatMinutes(minutes),
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 32,
                    height: height.clamp(4.0, 100.0),
                    decoration: BoxDecoration(
                      color: isToday
                          ? colorScheme.primary
                          : colorScheme.primary.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    weekDays[i],
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: isToday ? FontWeight.bold : null,
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildTagBreakdown(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final topTags = _timerService.getTopTags();
    if (topTags.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No context data yet. Tag your sessions to see stats here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: topTags.map((entry) {
            final tag = _timerService.allContextTags.firstWhere(
              (t) => t.id == entry.key,
              orElse: () => TimerContextTag(
                id: entry.key,
                name: entry.key,
                icon: Icons.label,
                color: Colors.grey,
              ),
            );
            final totalMinutes = _timerService.tagMinutes.values.fold(
              0,
              (a, b) => a + b,
            );
            final percentage = totalMinutes > 0
                ? (entry.value / totalMinutes * 100).toStringAsFixed(0)
                : '0';

            return ListTile(
              leading: Icon(tag.icon, color: tag.color),
              title: Text(tag.name),
              subtitle: LinearProgressIndicator(
                value: totalMinutes > 0 ? entry.value / totalMinutes : 0,
                backgroundColor: tag.color.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(tag.color),
              ),
              trailing: Text(
                '${_formatMinutes(entry.value)} ($percentage%)',
                style: theme.textTheme.bodySmall,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSessionTypeBreakdown(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final stats = _timerService.stats;

    final totalSessions = stats.sessionsByType.values.fold(0, (a, b) => a + b);
    if (totalSessions == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No sessions yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SessionType.values
              .where((type) => (stats.sessionsByType[type.name] ?? 0) > 0)
              .map((type) {
                final count = stats.sessionsByType[type.name] ?? 0;
                final percentage = (count / totalSessions * 100)
                    .toStringAsFixed(0);

                return Chip(
                  avatar: Icon(type.icon, size: 16, color: type.color),
                  label: Text('$count ($percentage%)'),
                  backgroundColor: type.color.withValues(alpha: 0.1),
                );
              })
              .toList(),
        ),
      ),
    );
  }

  // ============================================================
  // Dialogs
  // ============================================================

  void _showAddSecondaryTimerDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);

        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Add Timer',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...SecondaryTimerPreset.presets.map((preset) {
              return ListTile(
                leading: Icon(preset.icon, color: preset.color),
                title: Text(preset.name),
                subtitle: Text(_formatDuration(preset.duration)),
                trailing: preset.repeat
                    ? const Icon(Icons.repeat, size: 16)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  final timer = preset.toTimer();
                  _multiTimerService.addTimer(timer);
                  timer.start();
                },
              );
            }),
          ],
        );
      },
    );
  }

  // ============================================================
  // Helpers
  // ============================================================

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) return '$hours hr $minutes min';
    return '$minutes min';
  }
}
