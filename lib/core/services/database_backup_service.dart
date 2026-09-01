import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

class DatabaseBackupService {
  static const platform = MethodChannel('com.example.keepinventory/database');

  static Future<String> _getDatabasePath() async {
    final databasesPath = await getDatabasesPath();
    // 💡 ¡AQUÍ ESTABA EL ERROR! TODO JUNTO, SIN GUION BAJO
    return join(databasesPath, 'keepinventory.db');
  }

  /// EXPORTAR
  static Future<bool> exportDatabase() async {
    try {
      // Al cerrar, SQLite coge todo el WAL y lo guarda físicamente en el archivo
      await DatabaseHelper.instance.resetDatabase();

      final dbPath = await _getDatabasePath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        print("❌ La base de datos no existe.");
        return false;
      }

      final bool success = await platform.invokeMethod('saveDatabase', {
        'sourcePath': dbFile.path,
      });

      return success;
    } catch (e) {
      print("❌ Error al exportar: $e");
      return false;
    }
  }

  /// IMPORTAR / RESTAURAR
  static Future<bool> importDatabase() async {
    try {
      // 1. Apagamos y borramos la conexión actual de la memoria de Dart
      await DatabaseHelper.instance.resetDatabase();

      // 2. Android machaca el archivo físico viejo e inyecta el backup limpio
      final bool success = await platform.invokeMethod('restoreDatabase');

      if (success) {
        // 3. No hace falta abrirla a mano, al hacer pushReplacement en la UI
        // el Helper verá que _database es null y cargará el archivo nuevo automáticamente.
        print("✅ Base de datos restaurada con éxito.");
        return true;
      }
      return false;
    } catch (e) {
      print("❌ Error al importar: $e");
      return false;
    }
  }
}
