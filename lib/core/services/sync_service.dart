import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:http/http.dart' as http;

import '../database/database_helper.dart';

class SyncService {
  static HttpServer? _server;

  // --- DETECCIÓN INTELIGENTE DE IP (WI-FI Y HOTSPOT) ---
  static Future<String?> _getLocalIp() async {
    try {
      final info = NetworkInfo();
      String? ip = await info.getWifiIP();

      if (ip == null || ip == '0.0.0.0' || ip == '127.0.0.1') {
        final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4,
        );
        for (var interface in interfaces) {
          for (var addr in interface.addresses) {
            if (!addr.isLoopback && !addr.isLinkLocal) {
              ip = addr.address;
              if (ip.startsWith('192.168.43.') ||
                  ip.startsWith('192.168.49.')) {
                return ip;
              }
            }
          }
        }
      }
      return ip;
    } catch (e) {
      return null;
    }
  }

  // --- 1. EL EMISOR LEVANTA EL SERVIDOR ---
  static Future<String?> startServer(Function(String) onError) async {
    try {
      final ip = await _getLocalIp();

      if (ip == null) {
        onError(
          'No se pudo detectar la IP. ¿Estás conectado a un Wi-Fi o Hotspot activo?',
        );
        return null;
      }

      await DatabaseHelper.instance.resetDatabase();

      final dbPath = await getDatabasesPath();
      final path = '$dbPath/keepinventory.db';

      final file = File(path);
      if (!await file.exists()) {
        onError('La base de datos local no existe.');
        return null;
      }

      final router = shelf_router.Router();

      router.get('/download-db', (shelf.Request request) async {
        return shelf.Response.ok(
          file.openRead(),
          headers: {
            'Content-Type': 'application/octet-stream',
            'Content-Length': file.lengthSync().toString(),
          },
        );
      });

      _server = await io.serve(router.call, InternetAddress.anyIPv4, 8080);
      print('🚀 Servidor activo en http://$ip:8080/download-db');

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
      print('🛑 Servidor de Sincronización detenido.');
    }
  }

  // --- 2. EL RECEPTOR DESCARGA EN STREAMING ---
  static Future<bool> importDatabase(
    String url,
    Function(String status, double progress) onProgress,
  ) async {
    final client = http.Client();
    try {
      onProgress('Conectando con el dispositivo emisor...', 0.0);

      final request = http.Request('GET', Uri.parse(url));
      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final totalBytes = response.contentLength ?? 0;
        int receivedBytes = 0;

        final dbPath = await getDatabasesPath();
        final path = '$dbPath/keepinventory.db';
        // 💡 Descargamos a un archivo temporal para no romper la app si falla
        final tempPath = '$dbPath/keepinventory_temp.db';

        final tempFile = File(tempPath);
        if (await tempFile.exists()) {
          await tempFile.delete();
        }

        final sink = tempFile.openWrite();
        bool hasError = false;

        try {
          await response.stream
              .listen(
                (List<int> chunk) {
                  receivedBytes += chunk.length;
                  sink.add(chunk);

                  if (totalBytes > 0) {
                    final progress = receivedBytes / totalBytes;
                    onProgress(
                      'Descargando... ${(progress * 100).toStringAsFixed(0)}%',
                      progress,
                    );
                  } else {
                    onProgress(
                      'Descargando... ${(receivedBytes / 1024 / 1024).toStringAsFixed(2)} MB',
                      -1.0,
                    );
                  }
                },
                onError: (e) {
                  hasError = true;
                  print('Error en stream: $e');
                },
                cancelOnError: true,
              )
              .asFuture();
        } catch (e) {
          hasError = true;
          print('Excepción durante la descarga: $e');
        }

        await sink.flush();
        await sink.close();
        client.close();

        // 💡 VERIFICACIÓN DE INTEGRIDAD Y CORTES DE RED
        if (hasError || (totalBytes > 0 && receivedBytes < totalBytes)) {
          if (await tempFile.exists()) await tempFile.delete();
          onProgress('Conexión inestable. Se cortó la descarga a medias.', 0.0);
          return false;
        }

        // Si la descarga es 100% íntegra, cerramos SQLite local y machacamos el archivo
        await DatabaseHelper.instance.resetDatabase();

        final realFile = File(path);
        if (await realFile.exists()) {
          await realFile.delete();
        }
        await tempFile.rename(path); // Renombramos el temporal como el oficial

        onProgress('¡Sincronización completada con éxito!', 1.0);
        return true;
      } else {
        onProgress(
          'El emisor rechazó la conexión (Código ${response.statusCode})',
          0.0,
        );
        client.close();
        return false;
      }
    } catch (e) {
      onProgress('Pérdida de conexión Wi-Fi/Hotspot con el emisor.', 0.0);
      client.close();
      return false;
    }
  }
}
