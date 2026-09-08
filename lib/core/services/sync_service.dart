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
    // 💡 1. VERIFICACIÓN DE REDES (Misma Wi-Fi / Subred)
    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    final targetIp = uri.host;
    final receiverIp = await _getLocalIp();

    if (receiverIp == null ||
        receiverIp == '127.0.0.1' ||
        receiverIp == '0.0.0.0') {
      onProgress(
        '⚠️ No tienes red. Conéctate al Wi-Fi o Hotspot del emisor.',
        0.0,
      );
      await Future.delayed(const Duration(seconds: 2));
    } else {
      // Extraemos la subred (ej: 192.168.1 de 192.168.1.55)
      final targetSubnet = targetIp.contains('.')
          ? targetIp.substring(0, targetIp.lastIndexOf('.'))
          : '';
      final receiverSubnet = receiverIp.contains('.')
          ? receiverIp.substring(0, receiverIp.lastIndexOf('.'))
          : '';

      if (targetSubnet.isNotEmpty && targetSubnet != receiverSubnet) {
        onProgress(
          '⚠️ Parece que estáis en Wi-Fis distintas (Emisor: $targetSubnet.x / Tú: $receiverSubnet.x)',
          0.0,
        );
        await Future.delayed(const Duration(seconds: 3));
      }
    }

    // 💡 2. DESCARGA CON AUTO-REINTENTO
    const int maxRetries = 3;
    const int delayBetweenRetries = 2; // Segundos

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      final client = http.Client();
      try {
        onProgress('Buscando conexión... (Intento $attempt/$maxRetries)', 0.0);

        final request = http.Request('GET', Uri.parse(url));
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
              onProgress('Corte de red. Reintentando...', 0.0);
              await Future.delayed(
                const Duration(seconds: delayBetweenRetries),
              );
              continue;
            } else {
              onProgress(
                'Conexión inestable. No se pudo completar la descarga.',
                -1.0,
              );
              return false;
            }
          }

          // --- INSTALACIÓN SEGURA ---
          onProgress('Instalando datos de forma segura...', 1.0);

          await DatabaseHelper.instance.resetDatabase();

          final realFile = File(realPath);
          final backupPath = '$dbPath/keepinventory_failsafe.db';

          if (await realFile.exists()) {
            await realFile.copy(backupPath);
          }

          try {
            await tempFile.copy(realPath);

            if (await tempFile.exists()) await tempFile.delete();
            final failsafeFile = File(backupPath);
            if (await failsafeFile.exists()) await failsafeFile.delete();

            onProgress('¡Sincronización completada con éxito!', 1.0);
            return true;
          } catch (copyError) {
            final failsafeFile = File(backupPath);
            if (await failsafeFile.exists()) {
              await failsafeFile.copy(realPath);
            }
            onProgress(
              'Error al aplicar datos. Se restauró tu BD original.',
              -1.0,
            );
            return false;
          }
        } else {
          client.close();
          if (attempt < maxRetries) {
            await Future.delayed(const Duration(seconds: delayBetweenRetries));
            continue;
          }
          onProgress('El servidor rechazó la conexión.', -1.0);
          return false;
        }
      } catch (e) {
        client.close();
        if (attempt < maxRetries) {
          onProgress('Pérdida de red... (Reintento $attempt)', 0.0);
          await Future.delayed(const Duration(seconds: delayBetweenRetries));
          continue;
        }
        onProgress('No se encontró el emisor. Revisa el Wi-Fi/Hotspot.', -1.0);
        return false;
      }
    }
    return false;
  }
}
