import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class GithubUpdateService {
  // Tu repositorio de GitHub
  static const String _repoUrl =
      'https://api.github.com/repos/nesherben/KeepInventory/releases/latest';

  static Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      // 1. Obtenemos la versión local de tu pubspec.yaml
      final packageInfo = await PackageInfo.fromPlatform();
      final localVersion = packageInfo.version;

      // 2. Consultamos la última release en GitHub (con Timeout de 10s para no colgar la app)
      final response = await http
          .get(
            Uri.parse(_repoUrl),
            headers: {'User-Agent': 'KeepInventory-App'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String remoteTag = data['tag_name'];

        // Limpiamos la "v" para que "v1.0.1" se quede en "1.0.1"
        remoteTag = remoteTag.replaceAll('v', '').replaceAll('V', '').trim();

        // 3. Comparamos matemáticamente si la versión de GitHub es mayor
        if (_isVersionGreater(localVersion, remoteTag)) {
          // Buscamos el link directo al APK (.apk) si lo subiste en los assets
          String downloadUrl = data['html_url']; // Fallback a la web
          if (data['assets'] != null && data['assets'].isNotEmpty) {
            downloadUrl = data['assets'][0]['browser_download_url'];
          }

          // Devolvemos los datos con las claves que espera tu Dashboard
          return {
            'version': remoteTag,
            'notes': data['body'] ?? 'Mejoras y correcciones.',
            'url': downloadUrl,
          };
        }
      }
      return null; // Si estamos en la última versión o falla, no hace nada
    } catch (e) {
      print("❌ Error comprobando actualizaciones: $e");
      return null; // Falla en silencio para que el Dashboard cargue normal
    }
  }

  // Compara "1.0.0" con "1.0.1" a prueba de fallos
  static bool _isVersionGreater(String local, String remote) {
    List<int> localParts = local
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    List<int> remoteParts = remote
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();

    // Aseguramos que ambas listas tengan la misma longitud para comparar bien
    final maxLength = localParts.length > remoteParts.length
        ? localParts.length
        : remoteParts.length;

    for (int i = 0; i < maxLength; i++) {
      int l = i < localParts.length ? localParts[i] : 0;
      int r = i < remoteParts.length ? remoteParts[i] : 0;
      if (r > l) return true;
      if (r < l) return false;
    }
    return false;
  }

  // 💡 MEJORA: Ahora devuelve un bool para que la UI sepa si hubo éxito o error
  static Future<bool> downloadAndInstall(
    String apkUrl,
    Function(double) onProgress,
  ) async {
    File? file;
    IOSink? sink;

    try {
      print("📥 Iniciando descarga desde: $apkUrl");
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(apkUrl));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        print("❌ Error del servidor: Código ${response.statusCode}");
        client.close();
        return false;
      }

      final contentLength = response.contentLength ?? 0;
      int downloaded = 0;

      // Usamos el directorio temporal
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/update.apk';
      file = File(filePath);

      if (await file.exists()) {
        await file.delete();
      }

      sink = file.openWrite();

      // 💡 SOLUCIÓN: Usar 'await for' obliga al Future a esperar a que el stream acabe
      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloaded += chunk.length;
        if (contentLength > 0) {
          onProgress(downloaded / contentLength);
        } else {
          onProgress(0.5); // Animación indeterminada si no hay longitud
        }
      }

      // 💡 Importante limpiar y cerrar recursos al terminar
      await sink.flush();
      await sink.close();
      client.close();

      print("✅ Descarga completada al 100%. Guardando archivo...");
      print("📦 Abriendo instalador en: $filePath");

      final result = await OpenFilex.open(filePath);
      print("📱 Resultado de OpenFilex: ${result.message}");

      // Si todo fue bien, devolvemos true
      return result.type == ResultType.done;
    } catch (e) {
      print("❌ Excepción crítica al iniciar descarga: $e");

      // 💡 LIMPIEZA EN CASO DE ERROR (Ej: se cortó el WiFi)
      await sink?.close();
      if (file != null && await file.exists()) {
        await file
            .delete(); // Borramos el APK a medias para que no ocupe espacio
      }

      return false;
    }
  }
}
