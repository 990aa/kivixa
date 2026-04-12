import 'package:flutter/material.dart';
import 'package:kivixa/components/overlay/floating_window.dart';
import 'package:kivixa/services/overlay/overlay_controller.dart';
import 'package:kivixa/services/productivity/productivity_timer_service.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

/// Floating clock widget that shows in the overlay
class FloatingClockWindow extends StatefulWidget {
  const FloatingClockWindow({super.key});

  @override
  State<FloatingClockWindow> createState() => _FloatingClockWindowState();
}

class _FloatingClockWindowState extends State<FloatingClockWindow> {
  final _timerService = ProductivityTimerService.instance;

  @override
  void initState() {
    super.initState();
    _timerService.addListener(_onTimerUpdate);
    _timerService.initialize();
  }

  @override
  void dispose() {
    _timerService.removeListener(_onTimerUpdate);
    super.dispose();
  }

  void _onTimerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = OverlayController.instance;
    final rect =
        controller.getToolWindowRect('clock') ??
        const Rect.fromLTWH(100, 100, 380, 520);

    return FloatingWindow(
      rect: rect,
      onRectChanged: (newRect) =>
          controller.updateToolWindowRect('clock', newRect),
      onClose: () => controller.closeToolWindow('clock'),
      title: 'Productivity Timer',
      icon: Icons.timer,
      minWidth: 340,
      minHeight: 450,
      child: _FloatingClockContent(timerService: _timerService),
    );
  }
}

class _FloatingClockContent extends StatefulWidget {
  const _FloatingClockContent({required this.timerService});

  final ProductivityTimerService timerService;

  @override
  State<_FloatingClockContent> createState() => _FloatingClockContentState();
}

class _FloatingClockContentState extends State<_FloatingClockContent>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  var _showTemplates = false;

  ProductivityTimerService get _timer => widget.timerService;

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

    return Column(
      children: [
        // Tab bar
        ColoredBox(
          color: theme.colorScheme.surfaceContainerHighest,
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.timer), text: 'Timer'),
              Tab(icon: Icon(Icons.bar_chart), text: 'Stats'),
              Tab(icon: Icon(Icons.settings), text: 'Settings'),
            ],
          ),
        ),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTimerTab(context),
              _buildStatsTab(context),
              _buildSettingsTab(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimerTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Session type selector
          if (_timer.isIdle) ...[
            _buildSessionTypeSelector(context),
            const SizedBox(height: 16),
          ],

          // Main timer display
          _buildTimerDisplay(context),
          const SizedBox(height: 16),

          // Timer controls
          _buildTimerControls(context),
          const SizedBox(height: 16),

          // Template selector (when idle)
          if (_timer.isIdle) ...[
            _buildTemplateSection(context),
            const SizedBox(height: 16),
          ],

          // Current session info
          if (!_timer.isIdle) _buildSessionInfo(context),

          // Daily progress
          const SizedBox(height: 16),
          _buildDailyProgress(context),
        ],
      ),
    );
  }

  Widget _buildSessionTypeSelector(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: SessionType.values.map((type) {
        final isSelected = _timer.sessionType == type;
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
          onSelected: (_) => _timer.setSessionType(type),
        );
      }).toList(),
    );
  }

  Widget _buildTimerDisplay(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sessionColor = _timer.sessionType.color;

    // Determine display color based on state
    Color displayColor;
    if (_timer.isBreak) {
      displayColor = Colors.green;
    } else if (_timer.isPaused) {
      displayColor = Colors.orange;
    } else {
      displayColor = sessionColor;
    }

    return CircularPercentIndicator(
      radius: 100,
      lineWidth: 12,
      percent: _timer.isIdle ? 0 : _timer.progress,
      center: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _timer.isBreak ? Icons.coffee : _timer.sessionType.icon,
            size: 32,
            color: displayColor,
          ),
          const SizedBox(height: 4),
          Text(
            _timer.formattedTime,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: displayColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            _timer.isBreak
                ? 'Break Time'
                : _timer.isIdle
                ? 'Ready'
                : _timer.isPaused
                ? 'Paused'
                : _timer.sessionType.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      progressColor: displayColor,
      backgroundColor: colorScheme.surfaceContainerHighest,
      circularStrokeCap: CircularStrokeCap.round,
      animation: true,
      animateFromLastPercent: true,
    );
  }

  Widget _buildTimerControls(BuildContext context) {
    final theme = Theme.of(context);

    if (_timer.isIdle) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Duration selector
          IconButton.outlined(
            icon: const Icon(Icons.remove),
            onPressed: () {
              if (_timer.totalDuration.inMinutes > 5) {
                _timer.setDuration(
                  _timer.totalDuration - const Duration(minutes: 5),
                );
              }
            },
          ),
          const SizedBox(width: 8),
          Text(
            '${_timer.totalDuration.inMinutes} min',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            icon: const Icon(Icons.add),
            onPressed: () {
              _timer.setDuration(
                _timer.totalDuration + const Duration(minutes: 5),
              );
            },
          ),
          const SizedBox(width: 24),
          // Start button
          FilledButton.icon(
            onPressed: () => _timer.startSession(),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start'),
            style: FilledButton.styleFrom(
              backgroundColor: _timer.sessionType.color,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      );
    }

    // Running/Paused controls
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Stop button
        IconButton.outlined(
          icon: const Icon(Icons.stop),
          onPressed: _timer.stop,
          tooltip: 'Stop',
        ),
        const SizedBox(width: 16),
        // Play/Pause button
        FilledButton.icon(
          onPressed: _timer.isRunning || _timer.isBreak
              ? _timer.pause
              : _timer.resume,
          icon: Icon(_timer.isPaused ? Icons.play_arrow : Icons.pause),
          label: Text(_timer.isPaused ? 'Resume' : 'Pause'),
          style: FilledButton.styleFrom(
            backgroundColor: _timer.sessionType.color,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(width: 16),
        // Skip button
        IconButton.outlined(
          icon: const Icon(Icons.skip_next),
          onPressed: _timer.skip,
          tooltip: 'Skip',
        ),
      ],
    );
  }

  Widget _buildTemplateSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _showTemplates = !_showTemplates),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(Icons.playlist_play, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Timer Templates',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Icon(
                  _showTemplates
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
        if (_showTemplates)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TimerTemplate.allTemplates.map((template) {
              return ActionChip(
                label: Text(template.name),
                avatar: const Icon(Icons.timer, size: 16),
                onPressed: () {
                  _timer.startSession(template: template);
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildSessionInfo(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(
            context,
            'Cycle',
            '${_timer.currentCycle}/${_timer.totalCycles}',
            Icons.loop,
          ),
          _buildInfoItem(
            context,
            'Break',
            '${_timer.breakDuration.inMinutes}m',
            Icons.coffee,
          ),
          if (_timer.activeTemplate != null)
            _buildInfoItem(
              context,
              'Template',
              _timer.activeTemplate!.name,
              Icons.playlist_play,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Icon(icon, size: 16, color: colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyProgress(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final stats = _timer.stats;
    final goal = _timer.goal;

    final dailyProgress = _timer.getDailyProgress();
    final sessionsProgress = goal.dailySessions > 0
        ? (stats.todaySessions / goal.dailySessions).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Progress",
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildProgressBar(
                  context,
                  'Focus Time',
                  '${stats.todayFocusMinutes}/${goal.dailyFocusMinutes} min',
                  dailyProgress,
                  colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildProgressBar(
                  context,
                  'Sessions',
                  '${stats.todaySessions}/${goal.dailySessions}',
                  sessionsProgress,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    String label,
    String value,
    double progress,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodySmall),
            Text(value, style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: color.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation(color),
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildStatsTab(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final stats = _timer.stats;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Total Focus',
                  '${(stats.totalFocusMinutes / 60).toStringAsFixed(1)}h',
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

          // Average session
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.analytics, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Average Session', style: theme.textTheme.bodySmall),
                      Text(
                        '${stats.averageSessionMinutes.toStringAsFixed(1)} minutes',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Completion Rate', style: theme.textTheme.bodySmall),
                    Text(
                      '${(stats.completionRate * 100).toStringAsFixed(0)}%',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Weekly progress
          Text(
            'Weekly Progress',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildWeeklyChart(context),
          const SizedBox(height: 16),

          // Session type breakdown
          Text(
            'Session Types',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildSessionTypeBreakdown(context),
        ],
      ),
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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
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
    );
  }

  Widget _buildWeeklyChart(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final stats = _timer.stats;

    final now = DateTime.now();
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    // Get max minutes for scaling
    var maxMinutes = 1;
    for (var i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final minutes = stats.dailyMinutes[key] ?? 0;
      if (minutes > maxMinutes) maxMinutes = minutes;
    }

    return Container(
      height: 120,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final date = weekStart.add(Duration(days: i));
          final key =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          final minutes = stats.dailyMinutes[key] ?? 0;
          final height = (minutes / maxMinutes) * 80;
          final isToday = i == now.weekday - 1;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${minutes}m',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 24,
                height: height.clamp(4.0, 80.0),
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
                  fontSize: 10,
                  fontWeight: isToday ? FontWeight.bold : null,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSessionTypeBreakdown(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final stats = _timer.stats;

    final totalSessions = stats.sessionsByType.values.fold(0, (a, b) => a + b);
    if (totalSessions == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No sessions yet',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: SessionType.values
          .where((type) {
            return (stats.sessionsByType[type.name] ?? 0) > 0;
          })
          .map((type) {
            final count = stats.sessionsByType[type.name] ?? 0;
            final percentage = (count / totalSessions * 100).toStringAsFixed(0);

            return Chip(
              avatar: Icon(type.icon, size: 16, color: type.color),
              label: Text('$count ($percentage%)'),
              backgroundColor: type.color.withValues(alpha: 0.1),
            );
          })
          .toList(),
    );
  }

  Widget _buildSettingsTab(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Timer settings
        Text(
          'Timer Settings',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildSettingSwitch(
          context,
          'Auto-start break',
          'Start break automatically after focus session',
          _timer.autoStartBreak,
          _timer.setAutoStartBreak,
        ),
        _buildSettingSwitch(
          context,
          'Auto-start next session',
          'Start next focus session after break',
          _timer.autoStartNextSession,
          _timer.setAutoStartNextSession,
        ),
        const Divider(height: 24),

        // Notification settings
        Text(
          'Notifications',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildSettingSwitch(
          context,
          'Sound enabled',
          'Play sound for notifications',
          _timer.soundEnabled,
          _timer.setSoundEnabled,
        ),
        _buildSettingSwitch(
          context,
          'Pre-end warning',
          'Notify ${_timer.preEndWarningMinutes} minutes before end',
          _timer.showPreEndWarning,
          (v) => _timer.setPreEndWarning(v),
        ),
        const Divider(height: 24),

        // Goals
        Text(
          'Daily Goals',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildGoalSlider(
          context,
          'Focus time goal',
          '${_timer.goal.dailyFocusMinutes} minutes',
          _timer.goal.dailyFocusMinutes.toDouble(),
          30,
          300,
          (v) => _timer.setGoal(
            _timer.goal.copyWith(dailyFocusMinutes: v.round()),
          ),
        ),
        _buildGoalSlider(
          context,
          'Sessions goal',
          '${_timer.goal.dailySessions} sessions',
          _timer.goal.dailySessions.toDouble(),
          1,
          12,
          (v) => _timer.setGoal(_timer.goal.copyWith(dailySessions: v.round())),
        ),
        const Divider(height: 24),

        // Reset stats
        Center(
          child: TextButton.icon(
            onPressed: () => _showResetConfirmation(context),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Reset Statistics'),
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingSwitch(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final theme = Theme.of(context);

    return SwitchListTile(
      title: Text(title, style: theme.textTheme.bodyMedium),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildGoalSlider(
    BuildContext context,
    String title,
    String value,
    double currentValue,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: theme.textTheme.bodyMedium),
            Text(value, style: theme.textTheme.bodySmall),
          ],
        ),
        Slider(
          value: currentValue,
          min: min,
          max: max,
          divisions: ((max - min) / 5).round(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Statistics?'),
        content: const Text(
          'This will permanently delete all your session history, streaks, and progress. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _timer.resetStats();
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Statistics reset')));
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
