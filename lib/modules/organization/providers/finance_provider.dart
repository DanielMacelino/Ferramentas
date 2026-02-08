import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/transaction_model.dart';
import '../../../services/local_storage_service.dart';

final financeProvider = StateNotifierProvider<FinanceNotifier, List<Transaction>>((ref) {
  return FinanceNotifier();
});

class FinanceNotifier extends StateNotifier<List<Transaction>> {
  FinanceNotifier() : super([]) {
    _loadTransactions();
  }

  Box<Transaction>? _box;

  Future<void> _loadTransactions() async {
    _box = await LocalStorageService.openBox<Transaction>('transactions');
    state = _box!.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> addTransaction(Transaction transaction) async {
    if (_box == null) await _loadTransactions();
    await _box!.put(transaction.id, transaction);
    state = [...state, transaction]..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> deleteTransaction(String id) async {
    if (_box == null) await _loadTransactions();
    await _box!.delete(id);
    state = state.where((t) => t.id != id).toList();
  }

  double get totalBalance {
    return state.fold(0, (sum, item) {
      return sum + (item.isIncome ? item.amount : -item.amount);
    });
  }

  double get totalIncome {
    return state.where((item) => item.isIncome).fold(0, (sum, item) => sum + item.amount);
  }

  double get totalExpense {
    return state.where((item) => !item.isIncome).fold(0, (sum, item) => sum + item.amount);
  }
}
