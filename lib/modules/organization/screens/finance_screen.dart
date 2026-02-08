import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../providers/finance_provider.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  int? _selectedMonth;
  int? _selectedYear;

  List<Transaction> _applyFilters(List<Transaction> items) {
    return items.where((t) {
      final m = t.date.month;
      final y = t.date.year;
      final monthOk = _selectedMonth == null || _selectedMonth == m;
      final yearOk = _selectedYear == null || _selectedYear == y;
      return monthOk && yearOk;
    }).toList();
  }

  double _sumFiltered(List<Transaction> items, {bool? isIncome}) {
    return items.fold(0.0, (sum, t) {
      if (isIncome == null || t.isIncome == isIncome) {
        return sum + (t.isIncome ? t.amount : -t.amount);
      }
      return sum;
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(financeProvider);
    final notifier = ref.read(financeProvider.notifier);
    final filtered = _applyFilters(transactions);

    return Scaffold(
      appBar: AppBar(title: const Text('Controle Financeiro')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<int>(
                    value: _selectedMonth,
                    isExpanded: true,
                    hint: const Text('Mês'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos')),
                      for (int m = 1; m <= 12; m++)
                        DropdownMenuItem(value: m, child: Text(m.toString().padLeft(2, '0'))),
                    ],
                    onChanged: (val) => setState(() => _selectedMonth = val),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<int>(
                    value: _selectedYear,
                    isExpanded: true,
                    hint: const Text('Ano'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos')),
                      for (int y = DateTime.now().year - 5; y <= DateTime.now().year + 1; y++)
                        DropdownMenuItem(value: y, child: Text(y.toString())),
                    ],
                    onChanged: (val) => setState(() => _selectedYear = val),
                  ),
                ),
              ],
            ),
          ),
          _buildFilteredSummaryCard(context, filtered),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('Nenhuma transação registrada.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final transaction = filtered[index];
                      return Dismissible(
                        key: Key(transaction.id),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) {
                          notifier.deleteTransaction(transaction.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Transação removida')),
                          );
                        },
                        child: Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: transaction.isIncome
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              child: Icon(
                                transaction.isIncome
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color: transaction.isIncome
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            title: Text(transaction.title),
                            subtitle: Text(
                              DateFormat('dd/MM/yyyy').format(transaction.date),
                            ),
                            trailing: Text(
                              NumberFormat.currency(
                                      locale: 'pt_BR', symbol: 'R\$')
                                  .format(transaction.amount),
                              style: TextStyle(
                                color: transaction.isIncome
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilteredSummaryCard(BuildContext context, List<Transaction> filtered) {
    final total = _sumFiltered(filtered);
    final income = _sumFiltered(filtered, isIncome: true);
    final expense = _sumFiltered(filtered, isIncome: false).abs();
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                const Text('Receitas'),
                Text(
                  NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(income),
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Column(
              children: [
                const Text('Despesas'),
                Text(
                  NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(expense),
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Column(
              children: [
                const Text('Saldo'),
                Text(
                  NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(total),
                  style: TextStyle(
                    color: total >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, FinanceNotifier notifier) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Saldo Total', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                  .format(notifier.totalBalance),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: notifier.totalBalance >= 0 ? Colors.green : Colors.red,
              ),
            ),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(
                  context,
                  'Receitas',
                  notifier.totalIncome,
                  Colors.green,
                  Icons.arrow_upward,
                ),
                _buildSummaryItem(
                  context,
                  'Despesas',
                  notifier.totalExpense,
                  Colors.red,
                  Icons.arrow_downward,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, double value,
      Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text(
              NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                  .format(value),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showAddTransactionDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    bool isIncome = false;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Nova Transação'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Descrição'),
                    ),
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(labelText: 'Valor'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Despesa'),
                            selected: !isIncome,
                            onSelected: (selected) {
                              setState(() => isIncome = !selected);
                            },
                            selectedColor: Colors.red.withOpacity(0.2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Receita'),
                            selected: isIncome,
                            onSelected: (selected) {
                              setState(() => isIncome = selected);
                            },
                            selectedColor: Colors.green.withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(
                          'Data: ${DateFormat('dd/MM/yyyy').format(selectedDate)}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setState(() => selectedDate = date);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text;
                    final amount =
                        double.tryParse(amountController.text.replaceAll(',', '.')) ??
                            0.0;

                    if (title.isNotEmpty && amount > 0) {
                      final transaction = Transaction(
                        title: title,
                        amount: amount,
                        date: selectedDate,
                        isIncome: isIncome,
                      );
                      ref
                          .read(financeProvider.notifier)
                          .addTransaction(transaction);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
