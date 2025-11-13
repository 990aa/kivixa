import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:kivixa/data/calendar_storage.dart';
import 'package:kivixa/data/models/calendar_event.dart' as model;
import 'package:kivixa/data/models/project.dart';
import 'package:kivixa/data/project_storage.dart';
import 'package:kivixa/i18n/strings.g.dart';
import 'package:kivixa/services/notification_service.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:url_launcher/url_launcher.dart';

/// Syncfusion Calendar Page with all comprehensive features
class SyncfusionCalendarPage extends StatefulWidget {
  const SyncfusionCalendarPage({super.key});

  @override
  State<SyncfusionCalendarPage> createState() => _SyncfusionCalendarPageState();
}

class _SyncfusionCalendarPageState extends State<SyncfusionCalendarPage>
    with SingleTickerProviderStateMixin {
  final _calendarController = CalendarController();
  late CalendarEventDataSource _dataSource;
  CalendarView _currentView = CalendarView.month;
  var _selectedDate = DateTime.now();
  late TabController _tabController;
  List<Project> _projects = [];
  final List<CalendarView> _allowedViews = [
    CalendarView.day,
    CalendarView.week,
    CalendarView.workWeek,
    CalendarView.month,
    CalendarView.timelineDay,
    CalendarView.timelineWeek,
    CalendarView.timelineWorkWeek,
    CalendarView.timelineMonth,
    CalendarView.schedule,
  ];

  // Calendar settings
  int _firstDayOfWeek = DateTime.sunday;
  double _startHour = 0;
  double _endHour = 24;
  var _nonWorkingDays = <int>[DateTime.saturday, DateTime.sunday];
  var _showWeekNumber = false;
  var _showTrailingAndLeadingDates = true;
  final _blackoutDates = <DateTime>[];
  final _specialTimeRegions = <TimeRegion>[];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _calendarController.view = _currentView;
    _calendarController.displayDate = _selectedDate;
    _dataSource = CalendarEventDataSource([]);
    _loadEvents();
    _loadProjects();
    _initializeSpecialRegions();
  }

  Future<void> _loadEvents() async {
    final events = await CalendarStorage.loadEvents();
    setState(() {
      _dataSource = CalendarEventDataSource(events);
    });
  }

  Future<void> _loadProjects() async {
    final projects = await ProjectStorage.loadProjects();
    setState(() {
      _projects = projects;
    });
  }

  void _initializeSpecialRegions() {
    // Add lunch break as special time region
    final DateTime now = DateTime.now();
    final DateTime startDate = now.subtract(const Duration(days: 365));
    final DateTime endDate = now.add(const Duration(days: 365));

    for (
      DateTime date = startDate;
      date.isBefore(endDate);
      date = date.add(const Duration(days: 1))
    ) {
      if (date.weekday != DateTime.saturday &&
          date.weekday != DateTime.sunday) {
        _specialTimeRegions.add(
          TimeRegion(
            startTime: DateTime(date.year, date.month, date.day, 12, 0),
            endTime: DateTime(date.year, date.month, date.day, 13, 0),
            text: 'Lunch Break',
            color: Colors.grey.withValues(alpha: 0.2),
            enablePointerInteraction: false,
          ),
        );
      }
    }
  }

  void _onViewChanged(ViewChangedDetails details) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          // Update state if needed
        });
      }
    });
  }

  void _onCalendarTapped(CalendarTapDetails details) {
    if (details.targetElement == CalendarElement.appointment) {
      final Appointment appointment = details.appointments!.first;
      _showAppointmentDetails(appointment);
    } else if (details.targetElement == CalendarElement.calendarCell) {
      _showEventDialog(initialDate: details.date!);
    }
  }

  void _onCalendarLongPressed(CalendarLongPressDetails details) {
    if (details.targetElement == CalendarElement.appointment) {
      final Appointment appointment = details.appointments!.first;
      _showAppointmentOptions(appointment);
    }
  }

  void _showAppointmentDetails(Appointment appointment) async {
    // Find the original model.CalendarEvent from storage to get meeting link
    final events = await CalendarStorage.loadEvents();
    final event = events.firstWhere(
      (e) => e.id == appointment.id.toString(),
      orElse: () => model.CalendarEvent(
        id: appointment.id.toString(),
        title: appointment.subject,
        date: appointment.startTime,
        description: appointment.notes,
      ),
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AppointmentDetailsDialog(
        appointment: appointment,
        event: event,
        onEdit: () {
          Navigator.pop(context);
          _editAppointment(appointment);
        },
        onDelete: () {
          Navigator.pop(context);
          _deleteAppointment(appointment);
        },
      ),
    );
  }

  void _showAppointmentOptions(Appointment appointment) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit'),
            onTap: () {
              Navigator.pop(context);
              _editAppointment(appointment);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _deleteAppointment(appointment);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _editAppointment(Appointment appointment) async {
    // Implementation for editing appointment
    _showEventDialog(appointment: appointment);
  }

  Future<void> _deleteAppointment(Appointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.calendar.deleteEvent),
        content: Text(
          t.calendar.deleteConfirmation(title: appointment.subject),
        ),
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
      final eventId = appointment.id.toString();
      await CalendarStorage.deleteEvent(eventId);
      // Cancel notifications
      final events = await CalendarStorage.loadEvents();
      final event = events.firstWhere((e) => e.id == eventId);
      await NotificationService.instance.cancelEventNotifications(event);
      await _loadEvents();
    }
  }

  Future<void> _showEventDialog({
    DateTime? initialDate,
    Appointment? appointment,
  }) async {
    model.CalendarEvent? existingEvent;
    if (appointment != null) {
      final events = await CalendarStorage.loadEvents();
      existingEvent = events.firstWhere(
        (e) => e.id == appointment.id.toString(),
      );
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => EventDialog(
        event: existingEvent,
        initialDate: initialDate ?? _selectedDate,
        onSave: (event) async {
          if (existingEvent != null) {
            await CalendarStorage.updateEvent(event);
            await NotificationService.instance.cancelEventNotifications(
              existingEvent,
            );
          } else {
            await CalendarStorage.addEvent(event);
          }
          await NotificationService.instance.scheduleEventNotification(event);
          await _loadEvents();
        },
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => CalendarSettingsDialog(
        firstDayOfWeek: _firstDayOfWeek,
        startHour: _startHour,
        endHour: _endHour,
        nonWorkingDays: _nonWorkingDays,
        showWeekNumber: _showWeekNumber,
        showTrailingAndLeadingDates: _showTrailingAndLeadingDates,
        onSave: (settings) {
          setState(() {
            _firstDayOfWeek = settings['firstDayOfWeek'] as int;
            _startHour = settings['startHour'] as double;
            _endHour = settings['endHour'] as double;
            _nonWorkingDays = settings['nonWorkingDays'] as List<int>;
            _showWeekNumber = settings['showWeekNumber'] as bool;
            _showTrailingAndLeadingDates =
                settings['showTrailingAndLeadingDates'] as bool;
          });
        },
      ),
    );
  }

  Widget _buildAppointment(
    BuildContext context,
    CalendarAppointmentDetails details,
  ) {
    final appointment = details.appointments.first as Appointment;
    final colorScheme = Theme.of(context).colorScheme;

    if (_currentView == CalendarView.month) {
      return Container(
        decoration: BoxDecoration(
          color: appointment.color,
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          appointment.subject,
          style: TextStyle(
            color: colorScheme.onPrimaryContainer,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    // Timeline and day/week views
    return Container(
      decoration: BoxDecoration(
        color: appointment.color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: appointment.color.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: appointment.color.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appointment.subject,
            style: TextStyle(
              color: colorScheme.onPrimaryContainer,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (details.bounds.height > 40 && appointment.notes != null)
            Text(
              appointment.notes!,
              style: TextStyle(
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                fontSize: 11,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildMonthCellAppointment(
    BuildContext context,
    MonthCellDetails details,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isToday =
        details.date.day == DateTime.now().day &&
        details.date.month == DateTime.now().month &&
        details.date.year == DateTime.now().year;

    return Container(
      decoration: BoxDecoration(
        color: isToday
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : null,
        border: isToday
            ? Border.all(color: colorScheme.primary, width: 2)
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        details.date.day.toString(),
        style: TextStyle(
          color: isToday
              ? colorScheme.primary
              : (details.visibleDates.contains(details.date)
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildScheduleViewMonthHeader(
    BuildContext context,
    ScheduleViewMonthHeaderDetails details,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    const monthNames = [
      'JANUARY',
      'FEBRUARY',
      'MARCH',
      'APRIL',
      'MAY',
      'JUNE',
      'JULY',
      'AUGUST',
      'SEPTEMBER',
      'OCTOBER',
      'NOVEMBER',
      'DECEMBER',
    ];

    return Container(
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withValues(alpha: 0.7),
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            monthNames[details.date.month - 1],
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          Text(
            details.date.year.toString(),
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Today',
            onPressed: () {
              setState(() {
                _selectedDate = DateTime.now();
                _calendarController.displayDate = _selectedDate;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Calendar Settings',
            onPressed: _showSettingsDialog,
          ),
          PopupMenuButton<CalendarView>(
            icon: const Icon(Icons.view_module),
            tooltip: 'Change View',
            onSelected: (view) {
              setState(() {
                _currentView = view;
                _calendarController.view = view;
              });
            },
            itemBuilder: (context) => _allowedViews
                .map(
                  (view) => PopupMenuItem(
                    value: view,
                    child: Row(
                      children: [
                        Icon(_getViewIcon(view)),
                        const SizedBox(width: 8),
                        Text(_getViewName(view)),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: colorScheme.copyWith(primary: colorScheme.primary),
        ),
        child: SfCalendar(
          controller: _calendarController,
          view: _currentView,
          dataSource: _dataSource,
          allowedViews: _allowedViews,
          firstDayOfWeek: _firstDayOfWeek,
          showNavigationArrow: true,
          showDatePickerButton: true,
          showCurrentTimeIndicator: true,
          showWeekNumber: _showWeekNumber,
          showTodayButton: false,
          allowDragAndDrop: true,
          allowAppointmentResize: true,
          onTap: _onCalendarTapped,
          onLongPress: _onCalendarLongPressed,
          onViewChanged: _onViewChanged,
          appointmentBuilder: _buildAppointment,
          monthCellBuilder: _buildMonthCellAppointment,
          scheduleViewMonthHeaderBuilder: _buildScheduleViewMonthHeader,
          timeSlotViewSettings: TimeSlotViewSettings(
            startHour: _startHour,
            endHour: _endHour,
            nonWorkingDays: _nonWorkingDays,
            timeIntervalHeight: 60,
            timeIntervalWidth: 100,
            timeFormat: 'h:mm a',
            dateFormat: 'dd',
            dayFormat: 'EEE',
            minimumAppointmentDuration: const Duration(minutes: 30),
          ),
          monthViewSettings: MonthViewSettings(
            appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
            showTrailingAndLeadingDates: _showTrailingAndLeadingDates,
            numberOfWeeksInView: 6,
            appointmentDisplayCount: 4,
            showAgenda: _currentView == CalendarView.month,
            agendaViewHeight: 200,
          ),
          scheduleViewSettings: const ScheduleViewSettings(
            appointmentItemHeight: 70,
            hideEmptyScheduleWeek: true,
            monthHeaderSettings: MonthHeaderSettings(
              monthFormat: 'MMMM, yyyy',
              height: 60,
              monthTextStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          blackoutDates: _blackoutDates,
          blackoutDatesTextStyle: const TextStyle(
            decoration: TextDecoration.lineThrough,
            color: Colors.red,
          ),
          specialRegions: _specialTimeRegions,
          headerStyle: CalendarHeaderStyle(
            textAlign: TextAlign.center,
            backgroundColor: colorScheme.surfaceContainerLow,
            textStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          viewHeaderStyle: ViewHeaderStyle(
            backgroundColor: colorScheme.surfaceContainerLow,
            dayTextStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
            dateTextStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          todayHighlightColor: colorScheme.primary,
          todayTextStyle: TextStyle(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
          cellBorderColor: colorScheme.outline.withValues(alpha: 0.2),
          selectionDecoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            border: Border.all(color: colorScheme.primary, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          appointmentTextStyle: TextStyle(
            color: colorScheme.onPrimaryContainer,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          onDragEnd: (details) async {
            if (details.appointment == null) return;

            final appointment = details.appointment as Appointment;
            final events = await CalendarStorage.loadEvents();
            final event = events.firstWhere(
              (e) => e.id == appointment.id.toString(),
            );

            // Update event with new time
            final updatedEvent = event.copyWith(
              date: details.droppingTime!,
              startTime: TimeOfDay.fromDateTime(details.droppingTime!),
              endTime: TimeOfDay.fromDateTime(
                details.droppingTime!.add(
                  appointment.endTime.difference(appointment.startTime),
                ),
              ),
            );

            await CalendarStorage.updateEvent(updatedEvent);
            await _loadEvents();
          },
          onAppointmentResizeEnd: (details) async {
            if (details.appointment == null) return;

            final appointment = details.appointment as Appointment;
            final events = await CalendarStorage.loadEvents();
            final event = events.firstWhere(
              (e) => e.id == appointment.id.toString(),
            );

            // Update event with new time
            final updatedEvent = event.copyWith(
              startTime: TimeOfDay.fromDateTime(details.startTime!),
              endTime: TimeOfDay.fromDateTime(details.endTime!),
            );

            await CalendarStorage.updateEvent(updatedEvent);
            await _loadEvents();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEventDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New Event'),
      ),
    );
  }

  IconData _getViewIcon(CalendarView view) {
    switch (view) {
      case CalendarView.day:
        return Icons.view_day;
      case CalendarView.week:
      case CalendarView.workWeek:
        return Icons.view_week;
      case CalendarView.month:
        return Icons.calendar_month;
      case CalendarView.timelineDay:
      case CalendarView.timelineWeek:
      case CalendarView.timelineWorkWeek:
      case CalendarView.timelineMonth:
        return Icons.timeline;
      case CalendarView.schedule:
        return Icons.list;
    }
  }

  String _getViewName(CalendarView view) {
    switch (view) {
      case CalendarView.day:
        return 'Day';
      case CalendarView.week:
        return 'Week';
      case CalendarView.workWeek:
        return 'Work Week';
      case CalendarView.month:
        return 'Month';
      case CalendarView.timelineDay:
        return 'Timeline Day';
      case CalendarView.timelineWeek:
        return 'Timeline Week';
      case CalendarView.timelineWorkWeek:
        return 'Timeline Work Week';
      case CalendarView.timelineMonth:
        return 'Timeline Month';
      case CalendarView.schedule:
        return 'Schedule';
    }
  }
}

/// Custom Calendar Data Source
class CalendarEventDataSource extends CalendarDataSource {
  CalendarEventDataSource(List<model.CalendarEvent> source) {
    appointments = _convertToAppointments(source);
  }

  List<Appointment> _convertToAppointments(List<model.CalendarEvent> events) {
    final appointments = <Appointment>[];
    final random = Random();
    final colorCollection = <Color>[
      const Color(0xFF0F8644),
      const Color(0xFF8B1FA9),
      const Color(0xFFD20100),
      const Color(0xFFFC571D),
      const Color(0xFF36B37B),
      const Color(0xFF01A1EF),
      const Color(0xFF3D4FB5),
      const Color(0xFFE47C73),
      const Color(0xFF636363),
      const Color(0xFF0A8043),
    ];

    for (final event in events) {
      final color = event.type == model.EventType.event
          ? colorCollection[random.nextInt(colorCollection.length)]
          : colorCollection[random.nextInt(colorCollection.length)];

      // Handle recurring events - generate occurrences
      if (event.recurrence != null &&
          event.recurrence!.type != model.RecurrenceType.none) {
        // Generate recurrence rule string
        final recurrenceRule = _generateRecurrenceRule(event.recurrence!);

        final appointment = Appointment(
          id: event.id,
          startTime: DateTime(
            event.date.year,
            event.date.month,
            event.date.day,
            event.startTime?.hour ?? 0,
            event.startTime?.minute ?? 0,
          ),
          endTime: DateTime(
            event.date.year,
            event.date.month,
            event.date.day,
            event.endTime?.hour ?? 23,
            event.endTime?.minute ?? 59,
          ),
          subject: event.title,
          notes: event.description ?? '',
          color: color,
          isAllDay: event.isAllDay,
          recurrenceRule: recurrenceRule,
        );
        appointments.add(appointment);
      } else {
        // Non-recurring event
        final appointment = Appointment(
          id: event.id,
          startTime: DateTime(
            event.date.year,
            event.date.month,
            event.date.day,
            event.startTime?.hour ?? 0,
            event.startTime?.minute ?? 0,
          ),
          endTime: DateTime(
            event.date.year,
            event.date.month,
            event.date.day,
            event.endTime?.hour ?? 23,
            event.endTime?.minute ?? 59,
          ),
          subject: event.title,
          notes: event.description ?? '',
          color: color,
          isAllDay: event.isAllDay,
        );
        appointments.add(appointment);
      }
    }

    return appointments;
  }

  String _generateRecurrenceRule(model.RecurrenceRule recurrence) {
    switch (recurrence.type) {
      case model.RecurrenceType.daily:
        return 'FREQ=DAILY;INTERVAL=${recurrence.interval}';
      case model.RecurrenceType.weekly:
        if (recurrence.weekdays != null && recurrence.weekdays!.isNotEmpty) {
          final days = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
          final selectedDays = recurrence.weekdays!
              .map((d) => days[d - 1])
              .join(',');
          return 'FREQ=WEEKLY;INTERVAL=${recurrence.interval};BYDAY=$selectedDays';
        }
        return 'FREQ=WEEKLY;INTERVAL=${recurrence.interval}';
      case model.RecurrenceType.monthly:
        return 'FREQ=MONTHLY;INTERVAL=${recurrence.interval}';
      case model.RecurrenceType.yearly:
        return 'FREQ=YEARLY;INTERVAL=${recurrence.interval}';
      default:
        return '';
    }
  }
}

/// Appointment Details Dialog
class AppointmentDetailsDialog extends StatelessWidget {
  const AppointmentDetailsDialog({
    required this.appointment,
    required this.event,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Appointment appointment;
  final model.CalendarEvent event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(appointment.subject),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (appointment.notes != null && appointment.notes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(appointment.notes!),
            ),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                appointment.isAllDay
                    ? 'All Day'
                    : '${_formatTime(appointment.startTime)} - ${_formatTime(appointment.endTime)}',
              ),
            ],
          ),
          if (appointment.recurrenceRule != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.repeat, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text('Recurring event'),
                ],
              ),
            ),
          if (event.meetingLink != null && event.meetingLink!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: OutlinedButton.icon(
                onPressed: () async {
                  final url = Uri.parse(event.meetingLink!);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.link),
                label: const Text('Join Meeting'),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: onEdit, child: const Text('Edit')),
        TextButton(
          onPressed: onDelete,
          style: TextButton.styleFrom(foregroundColor: colorScheme.error),
          child: const Text('Delete'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12
        ? time.hour - 12
        : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

/// Calendar Settings Dialog
class CalendarSettingsDialog extends StatefulWidget {
  const CalendarSettingsDialog({
    required this.firstDayOfWeek,
    required this.startHour,
    required this.endHour,
    required this.nonWorkingDays,
    required this.showWeekNumber,
    required this.showTrailingAndLeadingDates,
    required this.onSave,
    super.key,
  });

  final int firstDayOfWeek;
  final double startHour;
  final double endHour;
  final List<int> nonWorkingDays;
  final bool showWeekNumber;
  final bool showTrailingAndLeadingDates;
  final Function(Map<String, dynamic>) onSave;

  @override
  State<CalendarSettingsDialog> createState() => _CalendarSettingsDialogState();
}

class _CalendarSettingsDialogState extends State<CalendarSettingsDialog> {
  late int _firstDayOfWeek;
  late double _startHour;
  late double _endHour;
  late List<int> _nonWorkingDays;
  late bool _showWeekNumber;
  late bool _showTrailingAndLeadingDates;

  @override
  void initState() {
    super.initState();
    _firstDayOfWeek = widget.firstDayOfWeek;
    _startHour = widget.startHour;
    _endHour = widget.endHour;
    _nonWorkingDays = List.from(widget.nonWorkingDays);
    _showWeekNumber = widget.showWeekNumber;
    _showTrailingAndLeadingDates = widget.showTrailingAndLeadingDates;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Calendar Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'First Day of Week',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            DropdownButton<int>(
              value: _firstDayOfWeek,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: DateTime.sunday, child: Text('Sunday')),
                DropdownMenuItem(value: DateTime.monday, child: Text('Monday')),
                DropdownMenuItem(
                  value: DateTime.saturday,
                  child: Text('Saturday'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _firstDayOfWeek = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Working Hours',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Start: ${_startHour.toInt()}:00'),
                      Slider(
                        value: _startHour,
                        min: 0,
                        max: 23,
                        divisions: 23,
                        onChanged: (value) {
                          setState(() {
                            _startHour = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('End: ${_endHour.toInt()}:00'),
                      Slider(
                        value: _endHour,
                        min: 1,
                        max: 24,
                        divisions: 23,
                        onChanged: (value) {
                          setState(() {
                            _endHour = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Non-Working Days',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            CheckboxListTile(
              title: const Text('Saturday'),
              value: _nonWorkingDays.contains(DateTime.saturday),
              onChanged: (value) {
                setState(() {
                  if (value!) {
                    _nonWorkingDays.add(DateTime.saturday);
                  } else {
                    _nonWorkingDays.remove(DateTime.saturday);
                  }
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Sunday'),
              value: _nonWorkingDays.contains(DateTime.sunday),
              onChanged: (value) {
                setState(() {
                  if (value!) {
                    _nonWorkingDays.add(DateTime.sunday);
                  } else {
                    _nonWorkingDays.remove(DateTime.sunday);
                  }
                });
              },
            ),
            SwitchListTile(
              title: const Text('Show Week Numbers'),
              value: _showWeekNumber,
              onChanged: (value) {
                setState(() {
                  _showWeekNumber = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Show Leading/Trailing Dates'),
              value: _showTrailingAndLeadingDates,
              onChanged: (value) {
                setState(() {
                  _showTrailingAndLeadingDates = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            widget.onSave({
              'firstDayOfWeek': _firstDayOfWeek,
              'startHour': _startHour,
              'endHour': _endHour,
              'nonWorkingDays': _nonWorkingDays,
              'showWeekNumber': _showWeekNumber,
              'showTrailingAndLeadingDates': _showTrailingAndLeadingDates,
            });
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Event Dialog Widget (simplified version - reuse from existing calendar.dart)
class EventDialog extends StatefulWidget {
  const EventDialog({
    required this.onSave,
    required this.initialDate,
    this.event,
    super.key,
  });

  final model.CalendarEvent? event;
  final DateTime initialDate;
  final Function(model.CalendarEvent) onSave;

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
  late model.EventType _eventType;
  late model.RecurrenceType _recurrenceType;
  DateTime? _recurrenceEndDate;

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
    _eventType = widget.event?.type ?? model.EventType.event;
    _recurrenceType =
        widget.event?.recurrence?.type ?? model.RecurrenceType.none;
    _recurrenceEndDate = widget.event?.recurrence?.endDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _meetingLinkController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(bool isStartTime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _selectRecurrenceEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _recurrenceEndDate ?? _selectedDate.add(const Duration(days: 30)),
      firstDate: _selectedDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _recurrenceEndDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(widget.event == null ? 'New Event' : 'Edit Event'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, minWidth: 500),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _meetingLinkController,
                decoration: const InputDecoration(
                  labelText: 'Meeting Link (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                  hintText: 'https://meet.example.com/...',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              // Date picker
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Date'),
                subtitle: Text(
                  '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _selectDate,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: theme.dividerColor),
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<model.EventType>(
                segments: const [
                  ButtonSegment(
                    value: model.EventType.event,
                    label: Text('Event'),
                    icon: Icon(Icons.event),
                  ),
                  ButtonSegment(
                    value: model.EventType.task,
                    label: Text('Task'),
                    icon: Icon(Icons.task_alt),
                  ),
                ],
                selected: {_eventType},
                onSelectionChanged: (Set<model.EventType> newSelection) {
                  setState(() {
                    _eventType = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('All Day'),
                value: _isAllDay,
                onChanged: (value) {
                  setState(() {
                    _isAllDay = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Recurrence selector
              DropdownButtonFormField<model.RecurrenceType>(
                decoration: const InputDecoration(
                  labelText: 'Repeat',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.repeat),
                ),
                initialValue: _recurrenceType,
                items: const [
                  DropdownMenuItem(
                    value: model.RecurrenceType.none,
                    child: Text('Does not repeat'),
                  ),
                  DropdownMenuItem(
                    value: model.RecurrenceType.daily,
                    child: Text('Daily'),
                  ),
                  DropdownMenuItem(
                    value: model.RecurrenceType.weekly,
                    child: Text('Weekly'),
                  ),
                  DropdownMenuItem(
                    value: model.RecurrenceType.monthly,
                    child: Text('Monthly'),
                  ),
                  DropdownMenuItem(
                    value: model.RecurrenceType.yearly,
                    child: Text('Yearly'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _recurrenceType = value;
                      if (value == model.RecurrenceType.none) {
                        _recurrenceEndDate = null;
                      }
                    });
                  }
                },
              ),
              if (_recurrenceType != model.RecurrenceType.none) ...[
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.event_repeat),
                  title: const Text('Ends on'),
                  subtitle: Text(
                    _recurrenceEndDate != null
                        ? '${_recurrenceEndDate!.year}-${_recurrenceEndDate!.month.toString().padLeft(2, '0')}-${_recurrenceEndDate!.day.toString().padLeft(2, '0')}'
                        : 'Never',
                  ),
                  trailing: _recurrenceEndDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            setState(() {
                              _recurrenceEndDate = null;
                            });
                          },
                        )
                      : const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _selectRecurrenceEndDate,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: theme.dividerColor),
                  ),
                ),
              ],
              if (!_isAllDay) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        leading: const Icon(Icons.access_time),
                        title: const Text('Start Time'),
                        subtitle: Text(_startTime.format(context)),
                        onTap: () => _selectTime(true),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: theme.dividerColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ListTile(
                        leading: const Icon(Icons.access_time),
                        title: const Text('End Time'),
                        subtitle: Text(_endTime.format(context)),
                        onTap: () => _selectTime(false),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: theme.dividerColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_titleController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Title is required')),
              );
              return;
            }

            final event = model.CalendarEvent(
              id:
                  widget.event?.id ??
                  DateTime.now().millisecondsSinceEpoch.toString(),
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              meetingLink: _meetingLinkController.text.trim().isEmpty
                  ? null
                  : _meetingLinkController.text.trim(),
              date: _selectedDate,
              startTime: _isAllDay ? null : _startTime,
              endTime: _isAllDay ? null : _endTime,
              isAllDay: _isAllDay,
              type: _eventType,
              recurrence: _recurrenceType != model.RecurrenceType.none
                  ? model.RecurrenceRule(
                      type: _recurrenceType,
                      endDate: _recurrenceEndDate,
                    )
                  : null,
            );

            widget.onSave(event);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
