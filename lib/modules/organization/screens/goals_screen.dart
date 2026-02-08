import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:intl/intl.dart';
import '../models/goal_model.dart';
import '../providers/goals_provider.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);
    final notifier = ref.read(goalsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Controle de Metas')),
      body: goals.isEmpty
          ? const Center(child: Text('Nenhuma meta definida.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: goals.length,
              itemBuilder: (context, index) {
                final goal = goals[index];
                return Dismissible(
                  key: Key(goal.id),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) {
                    notifier.deleteGoal(goal.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Meta removida')),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                goal.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (goal.isCompleted)
                                const Icon(Icons.check_circle, color: Colors.green),
                            ],
                          ),
                          if (goal.description.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                goal.description,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          LinearPercentIndicator(
                            lineHeight: 20.0,
                            percent: goal.progress,
                            center: Text(
                              "${(goal.progress * 100).toStringAsFixed(1)}%",
                              style: const TextStyle(fontSize: 12.0),
                            ),
                            barRadius: const Radius.circular(10),
                            progressColor: goal.isCompleted ? Colors.green : Colors.blue,
                            backgroundColor: Colors.grey[300],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(goal.currentAmount)} / ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(goal.targetAmount)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showUpdateProgressDialog(context, ref, goal),
                              ),
                            ],
                          ),
                          if (goal.deadline != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Prazo: ${DateFormat('dd/MM/yyyy').format(goal.deadline!)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: goal.deadline!.isBefore(DateTime.now()) && !goal.isCompleted
                                      ? Colors.red
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGoalDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final targetController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Nova Meta'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Título'),
                    ),
                    TextField(
                      controller: targetController,
                      decoration: const InputDecoration(labelText: 'Valor Alvo'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Descrição'),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(selectedDate == null
                          ? 'Definir Prazo (Opcional)'
                          : 'Prazo: ${DateFormat('dd/MM/yyyy').format(selectedDate!)}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
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
                    final target = double.tryParse(targetController.text.replaceAll(',', '.')) ?? 0.0;

                    if (title.isNotEmpty && target > 0) {
                      final goal = Goal(
                        title: title,
                        targetAmount: target,
                        description: descriptionController.text,
                        deadline: selectedDate,
                      );
                      ref.read(goalsProvider.notifier).addGoal(goal);
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

  void _showUpdateProgressDialog(BuildContext context, WidgetRef ref, Goal goal) {
    final currentController = TextEditingController(text: goal.currentAmount.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Atualizar Progresso'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentController,
                decoration: const InputDecoration(labelText: 'Valor Atual'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final current = double.tryParse(currentController.text.replaceAll(',', '.')) ?? goal.currentAmount;
                goal.currentAmount = current;
                if (goal.currentAmount >= goal.targetAmount) {
                  goal.isCompleted = true;
                } else {
                  goal.isCompleted = false;
                }
                goal.save(); // HiveObject method
                ref.read(goalsProvider.notifier).updateGoal(goal); // Refresh state
                Navigator.pop(context);
              },
              child: const Text('Atualizar'),
            ),
          ],
        );
      },
    );
  }
}
