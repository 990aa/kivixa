import 'package:flutter/material.dart';
import 'package:kivixa/data/calendar_storage.dart';
import 'package:kivixa/data/models/calendar_event.dart';
import 'package:kivixa/i18n/strings.g.dart';
import 'package:url_launcher/url_launcher.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  var _selectedDate = DateTime.now();
  var _focusedMonth = DateTime.now();
  var _monthEvents = <CalendarEvent>[];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final monthEvents = await CalendarStorage.getEventsForMonth(
      _focusedMonth.year,
      _focusedMonth.month,
    );
    setState(() {
      _monthEvents = monthEvents;
    });
  }

  Future<void> _refreshEvents() async {
    await _loadEvents();
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
    _loadEvents();
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
    _loadEvents();
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  Future<void> _showEventDialog({CalendarEvent? existingEvent}) async {
    await showDialog(
      context: context,
      builder: (context) => EventDialog(
        event: existingEvent,
        initialDate: existingEvent?.date ?? _selectedDate,
        onSave: (event) async {
          if (existingEvent != null) {
            await CalendarStorage.updateEvent(event);
          } else {
            await CalendarStorage.addEvent(event);
          }
          _refreshEvents();
        },
      ),
    );
  }

  Future<void> _deleteEvent(CalendarEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.calendar.deleteEvent),
        content: Text(t.calendar.deleteConfirmation(title: event.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(t.common.delete),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await CalendarStorage.deleteEvent(event.id);
      _refreshEvents();
    }
  }

  List<CalendarEvent> _getEventsForDate(DateTime date) {
    return _monthEvents.where((e) {
      return e.date.year == date.year &&
          e.date.month == date.month &&
          e.date.day == date.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedDateEvents = _getEventsForDate(_selectedDate);

    return Scaffold(
      body: Column(
        children: [
          // Calendar header with month navigation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _previousMonth,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  _getMonthYearString(_focusedMonth),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),

          // Calendar grid
          Expanded(
            child: Column(
              children: [
                // Days of week header
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      for (final day in _daysOfWeek)
                        Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Calendar dates
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                        ),
                    itemCount: _getCalendarDaysCount(),
                    itemBuilder: (context, index) {
                      final date = _getDateForIndex(index);
                      final isCurrentMonth = date.month == _focusedMonth.month;
                      final isSelected =
                          date.day == _selectedDate.day &&
                          date.month == _selectedDate.month &&
                          date.year == _selectedDate.year;
                      final isToday =
                          date.day == DateTime.now().day &&
                          date.month == DateTime.now().month &&
                          date.year == DateTime.now().year;
                      final eventsOnDay = _getEventsForDate(date);

                      return InkWell(
                        onTap: () => _selectDate(date),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primaryContainer
                                : isToday
                                ? colorScheme.surfaceContainerHighest
                                : null,
                            borderRadius: BorderRadius.circular(8),
                            border: isToday
                                ? Border.all(
                                    color: colorScheme.primary,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    color: isCurrentMonth
                                        ? (isSelected
                                              ? colorScheme.onPrimaryContainer
                                              : colorScheme.onSurface)
                                        : colorScheme.onSurfaceVariant
                                              .withValues(alpha: 0.5),
                                    fontWeight: isSelected || isToday
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (eventsOnDay.isNotEmpty)
                                Positioned(
                                  bottom: 4,
                                  left: 0,
                                  right: 0,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      eventsOnDay.length.clamp(0, 3),
                                      (i) => Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 1,
                                        ),
                                        width: 4,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color:
                                              eventsOnDay[i].type ==
                                                  EventType.event
                                              ? colorScheme.primary
                                              : colorScheme.tertiary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Events list for selected date
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: selectedDateEvents.isEmpty
                      ? Center(
                          child: Text(
                            t.calendar.noEvents,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: selectedDateEvents.length,
                          itemBuilder: (context, index) {
                            final event = selectedDateEvents[index];
                            return EventCard(
                              event: event,
                              onTap: () =>
                                  _showEventDialog(existingEvent: event),
                              onDelete: () => _deleteEvent(event),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEventDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _getMonthYearString(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  static const _daysOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  int _getCalendarDaysCount() {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month);
    final lastDayOfMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    );
    final firstWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0
    final totalDays = lastDayOfMonth.day;
    final remainingDays = (7 - ((firstWeekday + totalDays) % 7)) % 7;
    return firstWeekday + totalDays + remainingDays;
  }

  DateTime _getDateForIndex(int index) {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month);
    final firstWeekday = firstDayOfMonth.weekday % 7;
    final dayOffset = index - firstWeekday;
    return firstDayOfMonth.add(Duration(days: dayOffset));
  }
}

class EventCard extends StatelessWidget {
  const EventCard({
    required this.event,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  final CalendarEvent event;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          event.type == EventType.event ? Icons.event : Icons.task_alt,
          color: event.type == EventType.event
              ? colorScheme.primary
              : colorScheme.tertiary,
        ),
        title: Text(event.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.description != null && event.description!.isNotEmpty)
              Text(
                event.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              event.isAllDay
                  ? t.calendar.allDay
                  : '${_formatTime(event.startTime!)} - ${_formatTime(event.endTime!)}',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (event.meetingLink != null && event.meetingLink!.isNotEmpty)
              GestureDetector(
                onTap: () async {
                  final uri = Uri.parse(event.meetingLink!);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Text(
                  t.calendar.joinMeeting,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: onTap,
            ),
            IconButton(
              icon: Icon(Icons.delete, size: 20, color: colorScheme.error),
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

class EventDialog extends StatefulWidget {
  const EventDialog({
    required this.onSave,
    required this.initialDate,
    this.event,
    super.key,
  });

  final CalendarEvent? event;
  final DateTime initialDate;
  final Function(CalendarEvent) onSave;

  @override
  State<EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends State<EventDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _meetingLinkController;
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late bool _isAllDay;
  late EventType _eventType;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.event?.description ?? '',
    );
    _meetingLinkController = TextEditingController(
      text: widget.event?.meetingLink ?? '',
    );
    _selectedDate = widget.event?.date ?? widget.initialDate;
    _startTime = widget.event?.startTime ?? const TimeOfDay(hour: 9, minute: 0);
    _endTime = widget.event?.endTime ?? const TimeOfDay(hour: 10, minute: 0);
    _isAllDay = widget.event?.isAllDay ?? false;
    _eventType = widget.event?.type ?? EventType.event;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _meetingLinkController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (time != null) {
      setState(() {
        _startTime = time;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final time = await showTimePicker(context: context, initialTime: _endTime);
    if (time != null) {
      setState(() {
        _endTime = time;
      });
    }
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.calendar.titleRequired)));
      return;
    }

    final event = CalendarEvent(
      id: widget.event?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      date: _selectedDate,
      startTime: _isAllDay ? null : _startTime,
      endTime: _isAllDay ? null : _endTime,
      isAllDay: _isAllDay,
      type: _eventType,
      meetingLink: _meetingLinkController.text.trim().isEmpty
          ? null
          : _meetingLinkController.text.trim(),
    );

    widget.onSave(event);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.event == null ? t.calendar.newEvent : t.calendar.editEvent,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Event type selector
            SegmentedButton<EventType>(
              segments: [
                ButtonSegment(
                  value: EventType.event,
                  label: Text(t.calendar.event),
                  icon: const Icon(Icons.event),
                ),
                ButtonSegment(
                  value: EventType.task,
                  label: Text(t.calendar.task),
                  icon: const Icon(Icons.task_alt),
                ),
              ],
              selected: {_eventType},
              onSelectionChanged: (Set<EventType> newSelection) {
                setState(() {
                  _eventType = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 16),

            // Title
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: t.calendar.title,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: t.calendar.description,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Date
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(t.calendar.date),
              subtitle: Text(_formatDate(_selectedDate)),
              onTap: _selectDate,
            ),

            // All day toggle
            SwitchListTile(
              title: Text(t.calendar.allDay),
              value: _isAllDay,
              onChanged: (value) {
                setState(() {
                  _isAllDay = value;
                });
              },
            ),

            // Start and end time (only if not all day)
            if (!_isAllDay) ...[
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(t.calendar.startTime),
                subtitle: Text(_formatTimeOfDay(_startTime)),
                onTap: _selectStartTime,
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(t.calendar.endTime),
                subtitle: Text(_formatTimeOfDay(_endTime)),
                onTap: _selectEndTime,
              ),
            ],

            // Meeting link (only for events)
            if (_eventType == EventType.event) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _meetingLinkController,
                decoration: InputDecoration(
                  labelText: t.calendar.meetingLink,
                  border: const OutlineInputBorder(),
                  hintText: 'https://...',
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.common.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(t.common.save)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
