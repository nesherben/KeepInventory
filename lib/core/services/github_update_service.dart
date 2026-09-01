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
      // 1. Obtenemos la versión local de tu pubspec.yaml (ej: "1.0.0")
      final packageInfo = await PackageInfo.fromPlatform();
      final localVersion = packageInfo.version;

      // 2. Consultamos la última release en GitHub
      final response = await http.get(Uri.parse(_repoUrl));

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

          // Devolvemos los datos justo con las claves que espera tu Dashboard
          return {
            'version': remoteTag,
            'notes': data['body'] ?? 'Mejoras y correcciones.',
            'url': downloadUrl,
          };
        }
      }
      return null; // Si estamos en la última versión, no hace nada
    } catch (e) {
      print("❌ Error comprobando actualizaciones: $e");
      return null; // Si no hay internet, falla en silencio y el Dashboard carga normal
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

    for (int i = 0; i < remoteParts.length; i++) {
      int l = i < localParts.length ? localParts[i] : 0;
      int r = remoteParts[i];
      if (r > l) return true;
      if (r < l) return false;
    }
    return false;
  }

  static Future<void> downloadAndInstall(
    String apkUrl,
    Function(double) onProgress,
  ) async {
    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(apkUrl));
      final response = await client.send(request);

      final contentLength = response.contentLength ?? 0;
      int downloaded = 0;

      // 1. Preparamos el archivo ANTES de empezar a descargar
      final dir =
          await getExternalStorageDirectory() ?? await getTemporaryDirectory();
      final filePath = '${dir.path}/update.apk';
      final file = File(filePath);

      // 2. Abrimos un "grifo" (sink) para escribir directamente en el disco
      final sink = file.openWrite();

      response.stream.listen(
        (List<int> chunk) {
          // 3. Escribimos el trozo en el disco instantáneamente (salva la RAM)
          sink.add(chunk);
          downloaded += chunk.length;
          if (contentLength > 0) {
            onProgress(downloaded / contentLength);
          }
        },
        onDone: () async {
          // 4. Cerramos grifos e instalamos
          await sink.close();
          client.close();

          await OpenFilex.open(filePath);
        },
        onError: (e) async {
          print("❌ Error en la descarga: $e");
          await sink.close();
          client.close();
        },
        cancelOnError: true,
      );
    } catch (e) {
      print("❌ Excepción al iniciar descarga: $e");
    }
  }
}
