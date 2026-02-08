import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../modules/image_tools/screens/image_tools_screen.dart';
import '../modules/notes/screens/notes_menu_screen.dart';
import '../modules/notes/providers/notes_provider.dart';
import '../modules/notes/models/note_model.dart';
import '../modules/organization/screens/organization_menu_screen.dart';
import '../modules/organization/providers/agenda_provider.dart';
import '../modules/organization/models/calendar_event_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _weatherSummary;
  String? _lastModule;
  CalendarEvent? _nextEvent;
  int _pendingTasksToday = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _fetchWeather();
  }

  Future<void> _loadSettings() async {
    final box = await Hive.openBox('settings');
    setState(() {
      _lastModule = box.get('last_module') as String?;
    });
  }

  Future<void> _fetchWeather() async {
    try {
      double lat = -7.0339;
      double lon = -39.4089;
      final box = await Hive.openBox('settings');
      final coords = box.get('weather_coords');
      if (coords is Map && coords['lat'] is num && coords['lon'] is num) {
        lat = (coords['lat'] as num).toDouble();
        lon = (coords['lon'] as num).toDouble();
      } else {
        await box.put('weather_coords', {'lat': lat, 'lon': lon});
      }
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,weather_code,wind_speed_10m&timezone=auto',
      );
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final current = data['current'] as Map<String, dynamic>?;
        if (current != null) {
          final temp = current['temperature_2m'];
          final code = current['weather_code'];
          final wind = current['wind_speed_10m'];
          final time = current['time'];
          setState(() {
            _weatherSummary = '${temp?.round()}°C · ${_codeToText(code)} · Vento ${wind?.round()} km/h · $time';
          });
        }
      }
    } catch (_) {
      setState(() {
        _weatherSummary = 'Clima indisponível';
      });
    }
  }

  String _codeToText(dynamic code) {
    final c = (code is num) ? code.toInt() : -1;
    if (c == 0) return 'Céu limpo';
    if (c == 1 || c == 2) return 'Parcialmente nublado';
    if (c == 3) return 'Nublado';
    if (c == 45 || c == 48) return 'Neblina';
    if (c == 51 || c == 53 || c == 55) return 'Garoa';
    if (c == 61 || c == 63 || c == 65) return 'Chuva';
    if (c == 71 || c == 73 || c == 75) return 'Neve';
    if (c == 95) return 'Trovoadas';
    return 'Condição desconhecida';
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(notesProvider);
    final events = ref.watch(agendaProvider);
    final now = DateTime.now();

    final sorted = [...events]..sort((a, b) => a.date.compareTo(b.date));
    final upcoming = sorted.where((e) => e.date.isAfter(now));
    _nextEvent = upcoming.isNotEmpty ? upcoming.first : null;

    _pendingTasksToday = notes
        .where((n) => n.type == NoteType.checklist && n.reminderDateTime != null && _sameDay(n.reminderDateTime!, now))
        .fold(0, (sum, n) => sum + n.checklistItems.where((i) => !i.isDone).length);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Menu de Módulos',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                showDragHandle: true,
                builder: (context) {
                  return SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Acessar Módulos', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildShortcut(
                                  context,
                                  icon: Icons.image_search,
                                  label: 'Ferramentas de Imagem',
                                  color: Colors.blue,
                                  onTap: () async {
                                    final box = await Hive.openBox('settings');
                                    await box.put('last_module', 'Ferramentas de Imagem');
                                    if (mounted) {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ImageToolsScreen()));
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildShortcut(
                                  context,
                                  icon: Icons.note_alt,
                                  label: 'Bloco de Notas',
                                  color: Colors.amber,
                                  onTap: () async {
                                    final box = await Hive.openBox('settings');
                                    await box.put('last_module', 'Bloco de Notas');
                                    if (mounted) {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesMenuScreen()));
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildShortcut(
                                  context,
                                  icon: Icons.dashboard_customize,
                                  label: 'Organização Pessoal',
                                  color: Colors.teal,
                                  onTap: () async {
                                    final box = await Hive.openBox('settings');
                                    await box.put('last_module', 'Organização Pessoal');
                                    if (mounted) {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const OrganizationMenuScreen()));
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final nameController = TextEditingController();
          String? selected;
          await showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Novo Atalho'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nome do atalho'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selected,
                      items: const [
                        DropdownMenuItem(value: 'image_tools', child: Text('Ferramentas de Imagem')),
                        DropdownMenuItem(value: 'notes', child: Text('Bloco de Notas')),
                        DropdownMenuItem(value: 'organization', child: Text('Organização Pessoal')),
                      ],
                      onChanged: (v) => selected = v,
                      decoration: const InputDecoration(labelText: 'Destino'),
                    ),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty || selected == null) return;
                      final box = await Hive.openBox('settings');
                      final list = (box.get('custom_shortcuts') as List?)?.cast<Map>() ?? [];
                      list.add({'name': nameController.text, 'dest': selected});
                      await box.put('custom_shortcuts', list);
                      if (mounted) Navigator.pop(context);
                      _loadSettings();
                    },
                    child: const Text('Salvar'),
                  ),
                ],
              );
            },
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Adicionar novo módulo',
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        children: [
          Wrap(
            runSpacing: 16,
            spacing: 16,
            children: [
              _metricCard(
                context,
                icon: Icons.checklist,
                color: Colors.green,
                title: 'Hoje',
                value: '$_pendingTasksToday tarefas pendentes',
                buttonText: 'Abrir',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesMenuScreen()));
                },
              ),
              _metricCard(
                context,
                icon: Icons.event,
                color: Colors.blue,
                title: 'Próximo compromisso',
                value: _nextEvent != null
                    ? DateFormat('dd/MM · HH:mm').format(_nextEvent!.date)
                    : 'Nenhum',
                buttonText: 'Ver agenda',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const OrganizationMenuScreen()));
                },
              ),
              _metricCard(
                context,
                icon: Icons.cloud,
                color: Colors.orange,
                title: 'Clima agora',
                value: _weatherSummary ?? 'Carregando...',
                buttonText: 'Atualizar',
                onTap: _fetchWeather,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Atalhos Rápidos', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildShortcut(
                  context,
                  icon: Icons.image_search,
                  label: 'Ferramentas de Imagem',
                  color: Colors.blue,
                  onTap: () async {
                    final box = await Hive.openBox('settings');
                    await box.put('last_module', 'Ferramentas de Imagem');
                    if (mounted) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ImageToolsScreen()));
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildShortcut(
                  context,
                  icon: Icons.note_alt,
                  label: 'Bloco de Notas',
                  color: Colors.amber,
                  onTap: () async {
                    final box = await Hive.openBox('settings');
                    await box.put('last_module', 'Bloco de Notas');
                    if (mounted) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesMenuScreen()));
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildShortcut(
                  context,
                  icon: Icons.dashboard_customize,
                  label: 'Organização Pessoal',
                  color: Colors.teal,
                  onTap: () async {
                    final box = await Hive.openBox('settings');
                    await box.put('last_module', 'Organização Pessoal');
                    if (mounted) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const OrganizationMenuScreen()));
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? buttonText,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      width: 320,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(value),
                    ],
                  ),
                ),
                if (buttonText != null && onTap != null)
                  TextButton(onPressed: onTap, child: Text(buttonText)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShortcut(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
