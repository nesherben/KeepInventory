import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart'
    as shelf_router; // 💡 Alias para evitar conflictos

class SyncService {
  static HttpServer? _server;

  static Future<String?> startServer(Function(String) onError) async {
    try {
      final info = NetworkInfo();
      final ip = await info.getWifiIP();

      if (ip == null) {
        onError(
          'No se pudo detectar la IP. ¿Estás conectado a una red Wi-Fi o Hotspot?',
        );
        return null;
      }

      final dbPath = await getDatabasesPath();
      final path = '$dbPath/keep_inventory.db';

      // 💡 Usamos el alias aquí
      final router = shelf_router.Router();

      router.get('/download-db', (shelf.Request request) async {
        final file = File(path);
        if (await file.exists()) {
          return shelf.Response.ok(
            file.openRead(),
            headers: {'Content-Type': 'application/octet-stream'},
          );
        }
        return shelf.Response.notFound('Base de datos no encontrada');
      });

      _server = await io.serve(router.call, ip, 8080);
      return 'http://$ip:8080/download-db';
    } catch (e) {
      onError('Error al iniciar el servidor local: $e');
      return null;
    }
  }

  static Future<void> stopServer() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
    }
  }

  static Future<bool> importDatabase(
    String url,
    Function(String) onStatus,
  ) async {
    try {
      onStatus('Conectando con el emisor...');
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        onStatus('Descargando base de datos...');

        final dbPath = await getDatabasesPath();
        final path = '$dbPath/keep_inventory.db';

        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }

        await file.writeAsBytes(response.bodyBytes);
        onStatus('¡Sincronización completada con éxito!');
        return true;
      } else {
        onStatus('Error del servidor emisor (Código ${response.statusCode})');
        return false;
      }
    } catch (e) {
      onStatus('Error de conexión: $e');
      return false;
    }
  }
}
