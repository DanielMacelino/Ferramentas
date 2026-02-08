import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/goal_model.dart';
import '../../../services/local_storage_service.dart';

final goalsProvider = StateNotifierProvider<GoalsNotifier, List<Goal>>((ref) {
  return GoalsNotifier();
});

class GoalsNotifier extends StateNotifier<List<Goal>> {
  GoalsNotifier() : super([]) {
    _loadGoals();
  }

  Box<Goal>? _box;

  Future<void> _loadGoals() async {
    _box = await LocalStorageService.openBox<Goal>('goals');
    state = _box!.values.toList();
  }

  Future<void> addGoal(Goal goal) async {
    if (_box == null) await _loadGoals();
    await _box!.put(goal.id, goal);
    state = [...state, goal];
  }

  Future<void> updateGoal(Goal goal) async {
    if (_box == null) await _loadGoals();
    await _box!.put(goal.id, goal);
    state = state.map((g) => g.id == goal.id ? goal : g).toList();
  }

  Future<void> deleteGoal(String id) async {
    if (_box == null) await _loadGoals();
    await _box!.delete(id);
    state = state.where((g) => g.id != id).toList();
  }
}
