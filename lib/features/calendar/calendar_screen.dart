import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<DateTime, List<String>> _events = {};
  final TextEditingController _eventController = TextEditingController();

  List<String> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _addEvent(DateTime day, String event) {
    final key = DateTime(day.year, day.month, day.day);
    setState(() {
      _events.putIfAbsent(key, () => []).add(event);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar Scheduling')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: _getEventsForDay,
          ),
          if (_selectedDay != null) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _eventController,
                      decoration: const InputDecoration(
                        hintText: 'Add event...',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      if (_eventController.text.trim().isNotEmpty) {
                        _addEvent(_selectedDay!, _eventController.text.trim());
                        _eventController.clear();
                        setState(() {});
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: _getEventsForDay(_selectedDay!)
                    .map(
                      (e) => ListTile(
                        leading: const Icon(Icons.event),
                        title: Text(e),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
