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

      // Si no detecta Wi-Fi normal, escaneamos las interfaces de red (Hotspot)
      if (ip == null || ip == '0.0.0.0' || ip == '127.0.0.1') {
        final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4,
        );
        for (var interface in interfaces) {
          for (var addr in interface.addresses) {
            if (!addr.isLoopback && !addr.isLinkLocal) {
              ip = addr.address;
              // Las IPs de Hotspot en Android suelen empezar por estas subredes:
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

      // Aseguramos volcado de memoria de SQLite antes de enviar
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
            'Content-Length': file
                .lengthSync()
                .toString(), // Fundamental para la barra de progreso
          },
        );
      });

      // 💡 Bind a 0.0.0.0 permite que escuche en todas las tarjetas de red (Hotspot y Wi-Fi)
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
  // Añadimos 'progress' para actualizar la UI en tiempo real
  static Future<bool> importDatabase(
    String url,
    Function(String status, double progress) onProgress,
  ) async {
    final client = http.Client();
    try {
      onProgress('Conectando con el dispositivo emisor...', 0.0);

      final request = http.Request('GET', Uri.parse(url));
      // Timeout de 10 seg solo para establecer conexión inicial
      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final totalBytes = response.contentLength ?? 0;
        int receivedBytes = 0;

        // Cerramos conexión local
        await DatabaseHelper.instance.resetDatabase();

        final dbPath = await getDatabasesPath();
        final path = '$dbPath/keepinventory.db';

        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }

        // 💡 Descarga en streaming (trozos) directo al disco
        final sink = file.openWrite();

        await response.stream.listen((List<int> chunk) {
          receivedBytes += chunk.length;
          sink.add(chunk);

          if (totalBytes > 0) {
            final progress = receivedBytes / totalBytes;
            onProgress(
              'Descargando... ${(progress * 100).toStringAsFixed(0)}%',
              progress,
            );
          } else {
            // Si el servidor no manda el peso total, mostramos MB bajados
            onProgress(
              'Descargando... ${(receivedBytes / 1024 / 1024).toStringAsFixed(2)} MB',
              -1.0,
            );
          }
        }).asFuture();

        await sink.flush();
        await sink.close();
        client.close();

        onProgress('¡Sincronización completada con éxito!', 1.0);
        return true;
      } else {
        onProgress('Error del servidor (Código ${response.statusCode})', 0.0);
        client.close();
        return false;
      }
    } catch (e) {
      onProgress(
        'Error de red: Comprueba que estás en el mismo Wi-Fi/Hotspot',
        0.0,
      );
      client.close();
      return false;
    }
  }
}
