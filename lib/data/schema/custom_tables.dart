import 'package:drift/drift.dart';

@DataClassName('ChecklistItemData')
class ChecklistItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get itemText => text()();
  BoolColumn get checked => boolean().withDefault(const Constant(false))();
}

@DataClassName('CalendarEventData')
class CalendarEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get eventText => text()();
}
