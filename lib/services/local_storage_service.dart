import 'package:hive_flutter/hive_flutter.dart';
import '../modules/notes/models/note_model.dart';
import '../modules/organization/models/transaction_model.dart';
import '../modules/organization/models/calendar_event_model.dart';
import '../modules/organization/models/goal_model.dart';
import '../modules/organization/models/study_session_model.dart';

class LocalStorageService {
  // Inicializa o Hive
  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Registrar Adapters
    Hive.registerAdapter(NoteAdapter());
    Hive.registerAdapter(NoteTypeAdapter());
    Hive.registerAdapter(ChecklistItemAdapter());
    Hive.registerAdapter(TransactionAdapter());
    Hive.registerAdapter(CalendarEventAdapter());
    Hive.registerAdapter(GoalAdapter());
    Hive.registerAdapter(StudySessionAdapter());

    // Abrir boxes essenciais aqui, se necessário
    // await Hive.openBox('settings');
  }

  // Exemplo de método para obter uma box
  static Future<Box<T>> openBox<T>(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<T>(boxName);
    } else {
      return await Hive.openBox<T>(boxName);
    }
  }
}
