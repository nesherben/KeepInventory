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

  // --- DETECCIÓN INTELIGENTE DE IP ---
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

  // --- 2. EL RECEPTOR DESCARGA EN STREAMING (CON RETRY Y FAILSAFE) ---
  static Future<bool> importDatabase(
    String url,
    Function(String status, double progress) onProgress,
  ) async {
    // 💡 Lógica de auto-reintento
    const int maxRetries = 3;
    const int delayBetweenRetries = 2; // Segundos

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      final client = http.Client();
      try {
        onProgress('Conectando... (Intento $attempt/$maxRetries)', 0.0);

        final request = http.Request('GET', Uri.parse(url));
        // Timeout de 15 segundos para dar tiempo al hotspot a enrutar
        final response = await client
            .send(request)
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final totalBytes = response.contentLength ?? 0;
          int receivedBytes = 0;

          final dbPath = await getDatabasesPath();
          final realPath = '$dbPath/keepinventory.db';
          final tempPath = '$dbPath/keepinventory_temp.db';

          final tempFile = File(tempPath);
          if (await tempFile.exists()) await tempFile.delete();

          final sink = tempFile.openWrite();
          bool hasStreamError = false;

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
                    hasStreamError = true;
                    print('Error en stream: $e');
                  },
                  cancelOnError: true,
                )
                .asFuture();
          } catch (e) {
            hasStreamError = true;
          }

          await sink.flush();
          await sink.close();
          client.close();

          // 💡 VERIFICACIÓN DE INTEGRIDAD
          if (hasStreamError ||
              (totalBytes > 0 && receivedBytes < totalBytes)) {
            if (await tempFile.exists()) await tempFile.delete();

            if (attempt < maxRetries) {
              onProgress('Corte de red. Reintentando en breve...', 0.0);
              await Future.delayed(
                const Duration(seconds: delayBetweenRetries),
              );
              continue; // Salta al siguiente intento del bucle
            } else {
              onProgress(
                'Conexión inestable. No se pudo completar la descarga.',
                0.0,
              );
              return false;
            }
          }

          // --- LLEGAMOS AQUÍ: DESCARGA 100% PERFECTA ---
          onProgress('Instalando datos de forma segura...', 1.0);

          // 1. Apagamos la base de datos actual para soltar bloqueos
          await DatabaseHelper.instance.resetDatabase();

          final realFile = File(realPath);
          final backupPath = '$dbPath/keepinventory_failsafe.db';

          // 2. Hacemos copia de seguridad exprés de la BD original (ANTI-DESTRUCCIÓN)
          if (await realFile.exists()) {
            await realFile.copy(backupPath);
          }

          try {
            // 3. Sustituimos usando copy() que es 100x más seguro que rename() en Android
            await tempFile.copy(realPath);

            // 4. Limpiamos la basura temporal y el backup exprés
            if (await tempFile.exists()) await tempFile.delete();
            final failsafeFile = File(backupPath);
            if (await failsafeFile.exists()) await failsafeFile.delete();

            onProgress('¡Sincronización completada con éxito!', 1.0);
            return true;
          } catch (copyError) {
            // 🚨 MODO PÁNICO: Si falla la sobreescritura, restauramos la vieja
            print('Catástrofe en sobreescritura: $copyError');
            final failsafeFile = File(backupPath);
            if (await failsafeFile.exists()) {
              await failsafeFile.copy(realPath);
            }
            onProgress(
              'Error al aplicar datos. Se restauró el estado anterior.',
              0.0,
            );
            return false;
          }
        } else {
          client.close();
          if (attempt < maxRetries) {
            await Future.delayed(const Duration(seconds: delayBetweenRetries));
            continue;
          }
          onProgress('Conexión rechazada (Código ${response.statusCode})', 0.0);
          return false;
        }
      } catch (e) {
        client.close();
        if (attempt < maxRetries) {
          onProgress('Buscando emisor... (Reintento $attempt)', 0.0);
          await Future.delayed(const Duration(seconds: delayBetweenRetries));
          continue;
        }
        onProgress(
          'No se pudo conectar tras $maxRetries intentos. Verifica el Hotspot.',
          0.0,
        );
        return false;
      }
    }
    return false;
  }
}
