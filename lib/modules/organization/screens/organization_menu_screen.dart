import 'package:flutter/material.dart';
import 'goals_screen.dart';
import 'agenda_screen.dart';
import 'finance_screen.dart';
import 'study_screen.dart';

class OrganizationMenuScreen extends StatelessWidget {
  const OrganizationMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Organização Pessoal')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildCard(
            context,
            title: 'Controle de Metas',
            description: 'Defina e acompanhe seus objetivos.',
            icon: Icons.flag,
            color: Colors.red,
            destination: const GoalsScreen(),
          ),
          _buildCard(
            context,
            title: 'Agenda Pessoal',
            description: 'Gerencie seus compromissos e eventos.',
            icon: Icons.calendar_month,
            color: Colors.blue,
            destination: const AgendaScreen(),
          ),
          _buildCard(
            context,
            title: 'Controle Financeiro',
            description: 'Acompanhe receitas e despesas.',
            icon: Icons.attach_money,
            color: Colors.green,
            destination: const FinanceScreen(),
          ),
          _buildCard(
            context,
            title: 'Controle de Estudos',
            description: 'Organize matérias e revisões.',
            icon: Icons.school,
            color: Colors.orange,
            destination: const StudyScreen(),
          ),
        ],
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
