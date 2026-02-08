import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/study_session_model.dart';
import '../../../services/local_storage_service.dart';

final studyProvider = StateNotifierProvider<StudyNotifier, List<StudySession>>((ref) {
  return StudyNotifier();
});

class StudyNotifier extends StateNotifier<List<StudySession>> {
  StudyNotifier() : super([]) {
    _loadSessions();
  }

  Box<StudySession>? _box;

  Future<void> _loadSessions() async {
    _box = await LocalStorageService.openBox<StudySession>('study_sessions');
    state = _box!.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> addSession(StudySession session) async {
    if (_box == null) await _loadSessions();
    await _box!.put(session.id, session);
    state = [...state, session]..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> deleteSession(String id) async {
    if (_box == null) await _loadSessions();
    await _box!.delete(id);
    state = state.where((s) => s.id != id).toList();
  }

  int get totalMinutes => state.fold(0, (sum, session) => sum + session.durationMinutes);
}
