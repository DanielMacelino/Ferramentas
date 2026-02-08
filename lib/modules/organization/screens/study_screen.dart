import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/study_session_model.dart';
import '../providers/study_provider.dart';

class StudyScreen extends ConsumerStatefulWidget {
  const StudyScreen({super.key});

  @override
  ConsumerState<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends ConsumerState<StudyScreen> {
  int? _selectedMonth;
  int? _selectedYear;

  List<StudySession> _applyFilters(List<StudySession> items) {
    return items.where((s) {
      final m = s.date.month;
      final y = s.date.year;
      final monthOk = _selectedMonth == null || _selectedMonth == m;
      final yearOk = _selectedYear == null || _selectedYear == y;
      return monthOk && yearOk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(studyProvider);
    final notifier = ref.read(studyProvider.notifier);
    final filtered = _applyFilters(sessions);
    final totalHours = filtered.fold(0, (sum, s) => sum + s.durationMinutes) / 60;

    return Scaffold(
      appBar: AppBar(title: const Text('Controle de Estudos')),
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
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        'Total de Horas',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        totalHours.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        'Sessões',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        sessions.length.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('Nenhuma sessão de estudo registrada.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final session = filtered[index];
                      return Dismissible(
                        key: Key(session.id),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) {
                          notifier.deleteSession(session.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sessão removida')),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                session.subject.isNotEmpty
                                    ? session.subject[0].toUpperCase()
                                    : '?',
                              ),
                            ),
                            title: Text(session.subject),
                            subtitle: Text(
                              '${DateFormat('dd/MM/yyyy HH:mm').format(session.date)} • ${session.durationMinutes} min',
                            ),
                            trailing: session.notes.isNotEmpty
                                ? const Icon(Icons.note)
                                : null,
                            onTap: session.notes.isNotEmpty
                                ? () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text(session.subject),
                                        content: Text(session.notes),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Fechar'),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSessionDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddSessionDialog(BuildContext context, WidgetRef ref) {
    final subjectController = TextEditingController();
    final durationController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nova Sessão de Estudo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(labelText: 'Matéria/Assunto'),
                  autofocus: true,
                ),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(labelText: 'Duração (minutos)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Anotações (opcional)'),
                  maxLines: 3,
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
                final subject = subjectController.text;
                final duration = int.tryParse(durationController.text) ?? 0;

                if (subject.isNotEmpty && duration > 0) {
                  final session = StudySession(
                    subject: subject,
                    date: DateTime.now(),
                    durationMinutes: duration,
                    notes: notesController.text,
                  );
                  ref.read(studyProvider.notifier).addSession(session);
                  Navigator.pop(context);
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }
}
