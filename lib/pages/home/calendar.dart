import 'package:flutter/material.dart';
import 'package:kivixa/data/calendar_storage.dart';
import 'package:kivixa/data/models/calendar_event.dart';
import 'package:kivixa/i18n/strings.g.dart';
import 'package:url_launcher/url_launcher.dart';

enum CalendarView { month, week, day, year }

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  var _selectedDate = DateTime.now();
  var _focusedMonth = DateTime.now();
  var _monthEvents = <CalendarEvent>[];
  var _calendarView = CalendarView.month;
  var _previousView = CalendarView.month;
  DateTime? _lastTapTime;
  DateTime? _lastTappedDate;

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
    final now = DateTime.now();

    // Check for double tap
    if (_lastTappedDate != null &&
        _lastTappedDate!.year == date.year &&
        _lastTappedDate!.month == date.month &&
        _lastTappedDate!.day == date.day &&
        _lastTapTime != null &&
        now.difference(_lastTapTime!).inMilliseconds < 500) {
      // Double tap detected - show day timeline
      setState(() {
        _previousView = _calendarView;
        _selectedDate = date;
        _calendarView = CalendarView.day;
      });
      _lastTapTime = null;
      _lastTappedDate = null;
    } else {
      // Single tap - show event list popup
      setState(() {
        _selectedDate = date;
      });
      _lastTapTime = now;
      _lastTappedDate = date;

      // Show popup with events
      _showEventsPopup(date);
    }
  }

  Future<void> _showEventsPopup(DateTime date) async {
    final events = _getEventsForDate(date);
    if (events.isEmpty) return;

    await showDialog(
      context: context,
      builder: (context) => EventsListDialog(
        date: date,
        events: events,
        onEdit: (event) {
          Navigator.pop(context);
          _showEventDialog(existingEvent: event);
        },
        onDelete: (event) {
          Navigator.pop(context);
          _deleteEvent(event);
        },
        onToggleComplete: (event) async {
          final updated = event.copyWith(isCompleted: !event.isCompleted);
          await CalendarStorage.updateEvent(updated);
          _refreshEvents();
        },
      ),
    );
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
    return _monthEvents.where((e) => e.occursOn(date)).toList();
  }

  Future<void> _showYearPicker() async {
    final selectedYear = await showDialog<int>(
      context: context,
      builder: (context) => YearPickerDialog(initialYear: _focusedMonth.year),
    );
    if (selectedYear != null) {
      setState(() {
        _focusedMonth = DateTime(selectedYear, _focusedMonth.month);
      });
      _loadEvents();
    }
  }

  Future<void> _showMonthPicker() async {
    final selectedMonth = await showDialog<int>(
      context: context,
      builder: (context) =>
          MonthPickerDialog(initialMonth: _focusedMonth.month),
    );
    if (selectedMonth != null) {
      setState(() {
        _focusedMonth = DateTime(_focusedMonth.year, selectedMonth);
      });
      _loadEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_calendarView) {
      case CalendarView.month:
        return _buildMonthView();
      case CalendarView.week:
        return _buildWeekView();
      case CalendarView.day:
        return _buildDayView();
      case CalendarView.year:
        return _buildYearView();
    }
  }

  Widget _buildMonthView() {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          // Calendar header with month navigation and view selector
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
                Expanded(
                  child: GestureDetector(
                    onTap: _showMonthPicker,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getMonthName(_focusedMonth.month),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _showYearPicker,
                          child: Text(
                            '${_focusedMonth.year}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<CalendarView>(
                  icon: const Icon(Icons.view_module),
                  onSelected: (view) {
                    setState(() {
                      _calendarView = view;
                    });
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: CalendarView.month,
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month),
                          SizedBox(width: 8),
                          Text('Month'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: CalendarView.week,
                      child: Row(
                        children: [
                          Icon(Icons.view_week),
                          SizedBox(width: 8),
                          Text('Week'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: CalendarView.day,
                      child: Row(
                        children: [
                          Icon(Icons.view_day),
                          SizedBox(width: 8),
                          Text('Day'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: CalendarView.year,
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today),
                          SizedBox(width: 8),
                          Text('Year'),
                        ],
                      ),
                    ),
                  ],
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
                      for (var i = 0; i < _daysOfWeek.length; i++)
                        Expanded(
                          child: Center(
                            child: Text(
                              _daysOfWeek[i],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    i ==
                                        0 // Sunday
                                    ? Colors.red
                                    : colorScheme.onSurfaceVariant,
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
                      final isSunday = date.weekday == 7;
                      final eventsOnDay = _getEventsForDate(date);
                      final eventCount = eventsOnDay
                          .where((e) => e.type == EventType.event)
                          .length;
                      final taskCount = eventsOnDay
                          .where((e) => e.type == EventType.task)
                          .length;

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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${date.day}',
                                style: TextStyle(
                                  color: isSunday
                                      ? Colors.red
                                      : (isCurrentMonth
                                            ? (isSelected
                                                  ? colorScheme
                                                        .onPrimaryContainer
                                                  : colorScheme.onSurface)
                                            : colorScheme.onSurfaceVariant
                                                  .withValues(alpha: 0.5)),
                                  fontWeight: isSelected || isToday
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              if (eventsOnDay.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    '${eventCount}E ${taskCount}T',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isSelected
                                          ? colorScheme.onPrimaryContainer
                                          : colorScheme.primary,
                                      fontWeight: FontWeight.bold,
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

  Widget _buildDayView() {
    final colorScheme = Theme.of(context).colorScheme;
    final dayEvents = _getEventsForDate(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(_formatDate(_selectedDate)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _calendarView = _previousView;
            });
          },
        ),
        actions: [
          if (_calendarView != CalendarView.month)
            IconButton(
              icon: const Icon(Icons.home),
              tooltip: 'Today',
              onPressed: () {
                setState(() {
                  _selectedDate = DateTime.now();
                  _focusedMonth = DateTime.now();
                  _calendarView = CalendarView.month;
                });
                _refreshEvents();
              },
            ),
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _selectedDate = DateTime.now();
              });
              _refreshEvents();
            },
          ),
          PopupMenuButton<CalendarView>(
            icon: const Icon(Icons.view_module),
            onSelected: (view) {
              setState(() {
                _calendarView = view;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: CalendarView.month,
                child: Row(
                  children: [
                    Icon(Icons.calendar_month),
                    SizedBox(width: 8),
                    Text('Month'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: CalendarView.week,
                child: Row(
                  children: [
                    Icon(Icons.view_week),
                    SizedBox(width: 8),
                    Text('Week'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: CalendarView.day,
                child: Row(
                  children: [
                    Icon(Icons.view_day),
                    SizedBox(width: 8),
                    Text('Day'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: CalendarView.year,
                child: Row(
                  children: [
                    Icon(Icons.calendar_today),
                    SizedBox(width: 8),
                    Text('Year'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Row(
        children: [
          // Time column
          Container(
            width: 60,
            color: colorScheme.surfaceContainerLow,
            child: ListView.builder(
              itemCount: 24,
              itemBuilder: (context, hour) {
                return Container(
                  height: 60,
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(right: 8, top: 4),
                  child: Text(
                    '${hour.toString().padLeft(2, '0')}:00',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
          // Events column
          Expanded(
            child: SingleChildScrollView(
              child: SizedBox(
                height: 24 * 60.0, // 24 hours * 60 pixels per hour
                child: Stack(
                  children: [
                    // Hour lines
                    Column(
                      children: List.generate(24, (hour) {
                        return Container(
                          height: 60,
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: colorScheme.outline.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    // Events
                    ...dayEvents.where((e) => !e.isAllDay).map((event) {
                      final startMinutes =
                          (event.startTime!.hour * 60) +
                          event.startTime!.minute;
                      final endMinutes =
                          (event.endTime!.hour * 60) + event.endTime!.minute;
                      final top = (startMinutes / 60) * 60.0;
                      final height = ((endMinutes - startMinutes) / 60) * 60.0;

                      return Positioned(
                        top: top,
                        left: 8,
                        right: 8,
                        height: height.clamp(40, double.infinity),
                        child: GestureDetector(
                          onTap: () => _showEventDialog(existingEvent: event),
                          child: Card(
                            color: event.type == EventType.event
                                ? colorScheme.primaryContainer
                                : colorScheme.tertiaryContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Flexible(
                                    child: Text(
                                      event.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: event.type == EventType.event
                                            ? colorScheme.onPrimaryContainer
                                            : colorScheme.onTertiaryContainer,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (height > 45 && event.description != null)
                                    Flexible(
                                      child: Text(
                                        event.description!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: event.type == EventType.event
                                              ? colorScheme.onPrimaryContainer
                                              : colorScheme.onTertiaryContainer,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    // All-day events at top
                    if (dayEvents.any((e) => e.isAllDay))
                      Positioned(
                        top: 0,
                        left: 8,
                        right: 8,
                        child: Column(
                          children: dayEvents
                              .where((e) => e.isAllDay)
                              .map(
                                (event) => Card(
                                  color: event.type == EventType.event
                                      ? colorScheme.secondaryContainer
                                      : colorScheme.tertiaryContainer,
                                  child: ListTile(
                                    dense: true,
                                    title: Text(event.title),
                                    subtitle: Text(t.calendar.allDay),
                                    onTap: () =>
                                        _showEventDialog(existingEvent: event),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    // Current time indicator (red line)
                    if (_isToday(_selectedDate))
                      Positioned(
                        top: _getCurrentTimePosition(),
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          color: Colors.red,
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(child: Container()),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
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

  Widget _buildWeekView() {
    final colorScheme = Theme.of(context).colorScheme;
    final weekStart = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday % 7),
    );
    final weekDays = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${_formatDate(weekDays.first)} - ${_formatDate(weekDays.last)}',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _calendarView = _previousView;
            });
          },
        ),
        actions: [
          if (_calendarView != CalendarView.month)
            IconButton(
              icon: const Icon(Icons.home),
              tooltip: 'Today',
              onPressed: () {
                setState(() {
                  _selectedDate = DateTime.now();
                  _focusedMonth = DateTime.now();
                  _calendarView = CalendarView.month;
                });
                _refreshEvents();
              },
            ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 7));
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.add(const Duration(days: 7));
              });
            },
          ),
          PopupMenuButton<CalendarView>(
            icon: const Icon(Icons.view_module),
            onSelected: (view) {
              setState(() {
                _calendarView = view;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: CalendarView.month,
                child: Row(
                  children: [
                    Icon(Icons.calendar_month),
                    SizedBox(width: 8),
                    Text('Month'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: CalendarView.week,
                child: Row(
                  children: [
                    Icon(Icons.view_week),
                    SizedBox(width: 8),
                    Text('Week'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: CalendarView.day,
                child: Row(
                  children: [
                    Icon(Icons.view_day),
                    SizedBox(width: 8),
                    Text('Day'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: CalendarView.year,
                child: Row(
                  children: [
                    Icon(Icons.calendar_today),
                    SizedBox(width: 8),
                    Text('Year'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Week days header
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Row(
              children: weekDays.map((day) {
                final isToday =
                    day.day == DateTime.now().day &&
                    day.month == DateTime.now().month &&
                    day.year == DateTime.now().year;
                final isSunday = day.weekday == 7;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _previousView = _calendarView;
                        _selectedDate = day;
                        _calendarView = CalendarView.day;
                      });
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          [
                            'Sun',
                            'Mon',
                            'Tue',
                            'Wed',
                            'Thu',
                            'Fri',
                            'Sat',
                          ][day.weekday % 7],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSunday
                                ? Colors.red
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isToday ? colorScheme.primary : null,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              color: isToday
                                  ? colorScheme.onPrimary
                                  : (isSunday
                                        ? Colors.red
                                        : colorScheme.onSurface),
                              fontWeight: isToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Time grid
          Expanded(
            child: Row(
              children: [
                // Time column
                Container(
                  width: 60,
                  color: colorScheme.surfaceContainerLow,
                  child: ListView.builder(
                    itemCount: 24,
                    itemBuilder: (context, hour) {
                      return Container(
                        height: 60,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 8, top: 4),
                        child: Text(
                          '${hour.toString().padLeft(2, '0')}:00',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Days grid
                Expanded(
                  child: ListView.builder(
                    itemCount: 24,
                    itemBuilder: (context, hour) {
                      return Container(
                        height: 60,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: colorScheme.outline.withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                        child: Row(
                          children: weekDays.map((day) {
                            return Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: colorScheme.outline.withValues(
                                        alpha: 0.1,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
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

  Widget _buildYearView() {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_focusedMonth.year}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _calendarView = _previousView;
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Today',
            onPressed: () {
              setState(() {
                _selectedDate = DateTime.now();
                _focusedMonth = DateTime.now();
                _calendarView = CalendarView.month;
              });
              _refreshEvents();
            },
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _focusedMonth = DateTime(
                  _focusedMonth.year - 1,
                  _focusedMonth.month,
                );
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _focusedMonth = DateTime(
                  _focusedMonth.year + 1,
                  _focusedMonth.month,
                );
              });
            },
          ),
          PopupMenuButton<CalendarView>(
            icon: const Icon(Icons.view_module),
            onSelected: (view) {
              setState(() {
                _calendarView = view;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: CalendarView.month,
                child: Row(
                  children: [
                    Icon(Icons.calendar_month),
                    SizedBox(width: 8),
                    Text('Month'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: CalendarView.week,
                child: Row(
                  children: [
                    Icon(Icons.view_week),
                    SizedBox(width: 8),
                    Text('Week'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: CalendarView.day,
                child: Row(
                  children: [
                    Icon(Icons.view_day),
                    SizedBox(width: 8),
                    Text('Day'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: CalendarView.year,
                child: Row(
                  children: [
                    Icon(Icons.calendar_today),
                    SizedBox(width: 8),
                    Text('Year'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          final month = index + 1;
          return GestureDetector(
            onTap: () {
              setState(() {
                _previousView = _calendarView;
                _focusedMonth = DateTime(_focusedMonth.year, month);
                _calendarView = CalendarView.month;
              });
              _loadEvents();
            },
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Text(
                      _getMonthName(month),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    // Weekday headers
                    Row(
                      children: _daysOfWeek.asMap().entries.map((entry) {
                        final index = entry.key;
                        final day = entry.value;
                        return Expanded(
                          child: Center(
                            child: Text(
                              day.substring(0, 1),
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: index == 0
                                    ? Colors.red
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 2),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final firstDayOfMonth = DateTime(
                            _focusedMonth.year,
                            month,
                            1,
                          );
                          final firstWeekday = firstDayOfMonth.weekday % 7;
                          final daysInMonth = DateTime(
                            _focusedMonth.year,
                            month + 1,
                            0,
                          ).day;
                          final totalCells =
                              ((firstWeekday + daysInMonth) / 7).ceil() * 7;

                          return GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 7,
                                  childAspectRatio: 1,
                                ),
                            itemCount: totalCells,
                            itemBuilder: (context, index) {
                              final dayOffset = index - firstWeekday;
                              final date = firstDayOfMonth.add(
                                Duration(days: dayOffset),
                              );

                              // Only show dates within current month
                              if (dayOffset < 0 || dayOffset >= daysInMonth) {
                                return const SizedBox.shrink();
                              }

                              final events = _monthEvents
                                  .where((e) => e.occursOn(date))
                                  .toList();
                              final hasEvents = events
                                  .where((e) => e.type == EventType.event)
                                  .isNotEmpty;
                              final hasTasks = events
                                  .where((e) => e.type == EventType.task)
                                  .isNotEmpty;
                              final completedTasks = events.where(
                                (e) =>
                                    e.type == EventType.task && e.isCompleted,
                              );
                              final incompleteTasks = events.where(
                                (e) =>
                                    e.type == EventType.task && !e.isCompleted,
                              );

                              // Check for overdue tasks
                              final hasOverdueTasks = incompleteTasks.any((
                                task,
                              ) {
                                final taskDateTime = DateTime(
                                  task.date.year,
                                  task.date.month,
                                  task.date.day,
                                  task.endTime?.hour ?? 23,
                                  task.endTime?.minute ?? 59,
                                );
                                return taskDateTime.isBefore(DateTime.now());
                              });

                              final isSunday = date.weekday == 7;

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedDate = date;
                                    _calendarView = CalendarView.day;
                                  });
                                  _refreshEvents();
                                },
                                child: Container(
                                  margin: const EdgeInsets.all(1),
                                  alignment: Alignment.center,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Text(
                                        '${date.day}',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: isSunday
                                              ? Colors.red
                                              : colorScheme.onSurface,
                                        ),
                                      ),
                                      // Event and task indicators at bottom
                                      if (hasEvents || hasTasks)
                                        Positioned(
                                          bottom: 0,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (hasEvents)
                                                Container(
                                                  width: 3,
                                                  height: 3,
                                                  margin: const EdgeInsets.only(
                                                    right: 1,
                                                  ),
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: Colors.orange,
                                                        shape: BoxShape.circle,
                                                      ),
                                                ),
                                              if (hasTasks)
                                                Container(
                                                  width: 3,
                                                  height: 3,
                                                  decoration: BoxDecoration(
                                                    color: hasOverdueTasks
                                                        ? Colors.red
                                                        : (completedTasks
                                                                      .length ==
                                                                  incompleteTasks
                                                                          .length +
                                                                      completedTasks
                                                                          .length
                                                              ? Colors.grey
                                                              : Colors.green),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getMonthName(int month) {
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
    return months[month - 1];
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  List<String> get _daysOfWeek => [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  int _getCalendarDaysCount() {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month);
    final firstWeekday = firstDayOfMonth.weekday % 7;
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;
    return ((firstWeekday + daysInMonth) / 7).ceil() * 7;
  }

  DateTime _getDateForIndex(int index) {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month);
    final firstWeekday = firstDayOfMonth.weekday % 7;
    final dayOffset = index - firstWeekday;
    return firstDayOfMonth.add(Duration(days: dayOffset));
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  double _getCurrentTimePosition() {
    final now = DateTime.now();
    final minutes = now.hour * 60 + now.minute;
    return (minutes / 60) * 60.0; // 60 pixels per hour
  }
}

// Events List Popup Dialog
class EventsListDialog extends StatefulWidget {
  const EventsListDialog({
    required this.date,
    required this.events,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleComplete,
    super.key,
  });

  final DateTime date;
  final List<CalendarEvent> events;
  final void Function(CalendarEvent) onEdit;
  final void Function(CalendarEvent) onDelete;
  final void Function(CalendarEvent) onToggleComplete;

  @override
  State<EventsListDialog> createState() => _EventsListDialogState();
}

enum EventFilter { all, events, tasks }

class _EventsListDialogState extends State<EventsListDialog> {
  var _filter = EventFilter.all;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Filter events based on selection
    var filteredEvents = widget.events;
    if (_filter == EventFilter.events) {
      filteredEvents = widget.events
          .where((e) => e.type == EventType.event)
          .toList();
    } else if (_filter == EventFilter.tasks) {
      filteredEvents = widget.events
          .where((e) => e.type == EventType.task)
          .toList();
    }

    // Sort events by time
    final sortedEvents = List<CalendarEvent>.from(filteredEvents)
      ..sort((a, b) {
        if (a.isAllDay && !b.isAllDay) return -1;
        if (!a.isAllDay && b.isAllDay) return 1;
        if (a.isAllDay && b.isAllDay) return 0;

        final aMinutes =
            (a.startTime?.hour ?? 0) * 60 + (a.startTime?.minute ?? 0);
        final bMinutes =
            (b.startTime?.hour ?? 0) * 60 + (b.startTime?.minute ?? 0);
        return aMinutes.compareTo(bMinutes);
      });

    return AlertDialog(
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.date.day}/${widget.date.month}/${widget.date.year}'),
          const SizedBox(height: 8),
          SegmentedButton<EventFilter>(
            segments: const [
              ButtonSegment(
                value: EventFilter.all,
                label: Text('All'),
                icon: Icon(Icons.list),
              ),
              ButtonSegment(
                value: EventFilter.events,
                label: Text('Events'),
                icon: Icon(Icons.event),
              ),
              ButtonSegment(
                value: EventFilter.tasks,
                label: Text('Tasks'),
                icon: Icon(Icons.task_alt),
              ),
            ],
            selected: {_filter},
            onSelectionChanged: (Set<EventFilter> newSelection) {
              setState(() {
                _filter = newSelection.first;
              });
            },
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        height: 500,
        child: sortedEvents.isEmpty
            ? Center(
                child: Text(
                  _filter == EventFilter.events
                      ? 'No events'
                      : _filter == EventFilter.tasks
                      ? 'No tasks'
                      : 'No events or tasks',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              )
            : ListView.builder(
                itemCount: sortedEvents.length,
                itemBuilder: (context, index) {
                  final event = sortedEvents[index];
                  final isOverdue =
                      event.type == EventType.task &&
                      !event.isCompleted &&
                      DateTime.now().isAfter(
                        DateTime(
                          event.date.year,
                          event.date.month,
                          event.date.day,
                          event.endTime?.hour ?? 23,
                          event.endTime?.minute ?? 59,
                        ),
                      );

                  return Card(
                    color: isOverdue
                        ? Colors.red.withValues(alpha: 0.1)
                        : (event.type == EventType.event
                              ? colorScheme.primaryContainer.withValues(
                                  alpha: 0.3,
                                )
                              : colorScheme.tertiaryContainer.withValues(
                                  alpha: 0.3,
                                )),
                    child: ListTile(
                      leading: event.type == EventType.task
                          ? Checkbox(
                              value: event.isCompleted,
                              onChanged: (_) => widget.onToggleComplete(event),
                            )
                          : Icon(Icons.event, color: colorScheme.primary),
                      title: Text(
                        event.title,
                        style: TextStyle(
                          decoration: event.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (event.description != null &&
                              event.description!.isNotEmpty)
                            Text(
                              event.description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          Text(
                            event.isAllDay
                                ? 'All Day'
                                : '${_formatTime(event.startTime!)} - ${_formatTime(event.endTime!)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isOverdue
                                  ? Colors.red
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: isOverdue
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          if (isOverdue)
                            const Text(
                              'OVERDUE',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      trailing: PopupMenuButton(
                        icon: const Icon(Icons.more_vert),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            widget.onEdit(event);
                          } else if (value == 'delete') {
                            widget.onDelete(event);
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

// Year Picker Dialog
class YearPickerDialog extends StatefulWidget {
  const YearPickerDialog({required this.initialYear, super.key});

  final int initialYear;

  @override
  State<YearPickerDialog> createState() => _YearPickerDialogState();
}

class _YearPickerDialogState extends State<YearPickerDialog> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    // Calculate initial scroll position to center current year
    // Each row has 3 items, item height is approximately 56 (48 + 8 spacing)
    const initialIndex =
        50; // Current year is at index 50 (middle of 100 years)
    const rowIndex = initialIndex ~/ 3;
    const itemHeight = 56.0;
    const initialScrollOffset =
        (rowIndex * itemHeight) - 100; // Offset to center

    _scrollController = ScrollController(
      initialScrollOffset: initialScrollOffset.clamp(0, double.infinity),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Select Year'),
      content: SizedBox(
        width: 300,
        height: 400,
        child: GridView.builder(
          controller: _scrollController,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: 100,
          itemBuilder: (context, index) {
            final year = widget.initialYear - 50 + index;
            final isSelected = year == widget.initialYear;
            return InkWell(
              onTap: () => Navigator.pop(context, year),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primaryContainer : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$year',
                  style: TextStyle(
                    color: isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurface,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Month Picker Dialog
class MonthPickerDialog extends StatelessWidget {
  const MonthPickerDialog({required this.initialMonth, super.key});

  final int initialMonth;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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

    return AlertDialog(
      title: const Text('Select Month'),
      content: SizedBox(
        width: 300,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2,
          ),
          itemCount: 12,
          itemBuilder: (context, index) {
            final month = index + 1;
            final isSelected = month == initialMonth;
            return InkWell(
              onTap: () => Navigator.pop(context, month),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primaryContainer : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  months[index].substring(0, 3),
                  style: TextStyle(
                    color: isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurface,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Event Card Widget
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
          mainAxisSize: MainAxisSize.min,
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
            if (event.recurrence != null &&
                event.recurrence!.type != RecurrenceType.none)
              Text(
                _getRecurrenceDescription(event.recurrence!),
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
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

  String _getRecurrenceDescription(RecurrenceRule recurrence) {
    switch (recurrence.type) {
      case RecurrenceType.daily:
        return 'Repeats daily';
      case RecurrenceType.weekly:
        if (recurrence.weekdays != null && recurrence.weekdays!.isNotEmpty) {
          final days = <String>[
            'Mon',
            'Tue',
            'Wed',
            'Thu',
            'Fri',
            'Sat',
            'Sun',
          ];
          final selectedDays = recurrence.weekdays!
              .map((d) => days[d - 1])
              .join(', ');
          return 'Repeats weekly on $selectedDays';
        }
        return 'Repeats weekly';
      case RecurrenceType.monthly:
        if (recurrence.nthWeekday != null) {
          return 'Repeats monthly';
        }
        return 'Repeats monthly';
      case RecurrenceType.yearly:
        return 'Repeats yearly';
      default:
        return '';
    }
  }
}

// Event Dialog Widget
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
  late RecurrenceType _recurrenceType;
  var _selectedWeekdays = <int>[];
  var _recurrenceInterval = 1;

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
    _recurrenceType = widget.event?.recurrence?.type ?? RecurrenceType.none;
    _selectedWeekdays = widget.event?.recurrence?.weekdays ?? [];
    _recurrenceInterval = widget.event?.recurrence?.interval ?? 1;
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

    RecurrenceRule? recurrence;
    if (_recurrenceType != RecurrenceType.none) {
      recurrence = RecurrenceRule(
        type: _recurrenceType,
        interval: _recurrenceInterval,
        weekdays:
            _recurrenceType == RecurrenceType.weekly &&
                _selectedWeekdays.isNotEmpty
            ? _selectedWeekdays
            : null,
      );
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
      recurrence: recurrence,
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
      contentPadding: const EdgeInsets.all(24),
      content: SizedBox(
        width: 600, // Make dialog wider
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // All-day toggle
              SwitchListTile(
                title: Text(t.calendar.allDay),
                value: _isAllDay,
                onChanged: (value) {
                  setState(() {
                    _isAllDay = value;
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Time pickers (only if not all-day)
              if (!_isAllDay) ...[
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        leading: const Icon(Icons.access_time),
                        title: Text(t.calendar.startTime),
                        subtitle: Text(_formatTimeOfDay(_startTime)),
                        onTap: _selectStartTime,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ListTile(
                        leading: const Icon(Icons.access_time),
                        title: Text(t.calendar.endTime),
                        subtitle: Text(_formatTimeOfDay(_endTime)),
                        onTap: _selectEndTime,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Meeting link
              TextField(
                controller: _meetingLinkController,
                decoration: InputDecoration(
                  labelText: t.calendar.meetingLink,
                  border: const OutlineInputBorder(),
                  hintText: 'https://...',
                ),
              ),
              const SizedBox(height: 16),

              // Recurrence section
              const Divider(),
              const SizedBox(height: 8),
              Text('Repeat', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<RecurrenceType>(
                initialValue: _recurrenceType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Recurrence',
                ),
                items: const [
                  DropdownMenuItem(
                    value: RecurrenceType.none,
                    child: Text('Does not repeat'),
                  ),
                  DropdownMenuItem(
                    value: RecurrenceType.daily,
                    child: Text('Daily'),
                  ),
                  DropdownMenuItem(
                    value: RecurrenceType.weekly,
                    child: Text('Weekly'),
                  ),
                  DropdownMenuItem(
                    value: RecurrenceType.monthly,
                    child: Text('Monthly'),
                  ),
                  DropdownMenuItem(
                    value: RecurrenceType.yearly,
                    child: Text('Yearly'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _recurrenceType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Weekday selector for weekly recurrence
              if (_recurrenceType == RecurrenceType.weekly) ...[
                Text(
                  'Repeat on',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (int i = 1; i <= 7; i++)
                      FilterChip(
                        label: Text(
                          ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i -
                              1],
                        ),
                        selected: _selectedWeekdays.contains(i),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedWeekdays.add(i);
                            } else {
                              _selectedWeekdays.remove(i);
                            }
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
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
