import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../../domain/change_entry.dart';
import '../change_entry_model.dart';

class HistoryLocalDatasource {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<Database> get db async => await _databaseHelper.database;

  /// Más nuevas primero (por fecha y, a igualdad, por id).
  Future<List<ChangeEntry>> getEntries() async {
    final database = await db;
    final rows = await database.query(
      'change_log',
      orderBy: 'created_at DESC, id DESC',
    );
    return [for (final row in rows) ?ChangeEntryModel.fromMap(row)];
  }
}
