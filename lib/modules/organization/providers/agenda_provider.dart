import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/calendar_event_model.dart';
import '../../../services/local_storage_service.dart';

final agendaProvider = StateNotifierProvider<AgendaNotifier, List<CalendarEvent>>((ref) {
  return AgendaNotifier();
});

class AgendaNotifier extends StateNotifier<List<CalendarEvent>> {
  AgendaNotifier() : super([]) {
    _loadEvents();
  }

  Box<CalendarEvent>? _box;

  Future<void> _loadEvents() async {
    _box = await LocalStorageService.openBox<CalendarEvent>('calendar_events');
    state = _box!.values.toList();
  }

  Future<void> addEvent(CalendarEvent event) async {
    if (_box == null) await _loadEvents();
    await _box!.put(event.id, event);
    state = [...state, event];
  }

  Future<void> deleteEvent(String id) async {
    if (_box == null) await _loadEvents();
    await _box!.delete(id);
    state = state.where((e) => e.id != id).toList();
  }

  List<CalendarEvent> getEventsForDay(DateTime day) {
    return state.where((event) {
      return isSameDay(event.date, day);
    }).toList();
  }

  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
