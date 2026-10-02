import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:sqflite/sqflite.dart';

// Asegúrate de que la ruta a tu DatabaseHelper es correcta
import '../database/database_helper.dart';

class ImageMigrationService {
  static Future<void> migrateImagesToDb() async {
    final db = await DatabaseHelper.instance.database;

    debugPrint('Iniciando migración de imágenes de PRODUCTOS...');
    await _migrateTable(db, 'products');

    debugPrint('Iniciando migración de imágenes de PACKS...');
    await _migrateTable(db, 'packs');

    debugPrint('Migración de imágenes completada.');
  }

  static Future<void> _migrateTable(Database db, String tableName) async {
    // Filtramos para coger solo los que tienen ruta de imagen pero aún no tienen BLOB
    final List<Map<String, dynamic>> records = await db.query(
      tableName,
      where:
          "image_path IS NOT NULL AND image_path != '' AND image_bytes IS NULL",
    );

    if (records.isEmpty) {
      debugPrint('No hay imágenes pendientes de migrar en $tableName.');
      return;
    }

    for (var record in records) {
      final String path = record['image_path'];
      final int id = record['id'];

      final file = File(path);
      if (await file.exists()) {
        try {
          final bytes = await file.readAsBytes();

          // Comprimimos al estándar que estás usando (400x400, 70% calidad)
          final Uint8List compressedBytes =
              await FlutterImageCompress.compressWithList(
                bytes,
                minWidth: 400,
                minHeight: 400,
                quality: 70,
              );

          // Guardamos el BLOB directamente en la columna image_bytes
          await db.update(
            tableName,
            {'image_bytes': compressedBytes},
            where: 'id = ?',
            whereArgs: [id],
          );
          debugPrint('Migrada imagen en $tableName (ID: $id)');
        } catch (e) {
          debugPrint('Error comprimiendo la imagen del ID $id: $e');
        }
      } else {
        debugPrint('Archivo no encontrado para el ID $id en la ruta: $path');
      }
    }
  }
}
