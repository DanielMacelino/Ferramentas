import 'package:flutter/material.dart';
import 'notes_screen.dart';

class NotesMenuScreen extends StatelessWidget {
  const NotesMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bloco de Notas Inteligente')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildCard(
            context,
            title: 'Todas as Notas',
            description: 'Visualize todas as suas notas e listas.',
            icon: Icons.notes,
            color: Colors.amber,
            destination: const NotesScreen(),
          ),
          _buildCard(
            context,
            title: 'Notas Simples',
            description: 'Crie anotações rápidas de texto.',
            icon: Icons.description,
            color: Colors.blue,
            destination: const NotesScreen(filter: NotesFilter.text),
          ),
          _buildCard(
            context,
            title: 'Lista de Tarefas',
            description: 'Gerencie suas checklists.',
            icon: Icons.checklist,
            color: Colors.green,
            destination: const NotesScreen(filter: NotesFilter.checklist),
          ),
          _buildCard(
            context,
            title: 'Lembretes',
            description: 'Notas com notificações agendadas.',
            icon: Icons.notifications_active,
            color: Colors.purple,
            destination: const NotesScreen(filter: NotesFilter.reminders),
          ),
          _buildCard(
            context,
            title: 'Notas Fixadas',
            description: 'Acesse rapidamente o que é importante.',
            icon: Icons.push_pin,
            color: Colors.red,
            destination: const NotesScreen(filter: NotesFilter.pinned),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NotesScreen()),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Criar Nova Nota',
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required Widget destination,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
