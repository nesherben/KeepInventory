import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import 'dart:convert';

class GithubUpdateService {
  // Configuración directa de tu repositorio público de GitHub
  static const String githubOwner = 'nesherben';
  static const String githubRepo = 'KeepInventory';

  // Fecha de compilación por defecto para desarrollo local (ej: año 2000)
  // En producción se sobrescribe automáticamente al compilar con --dart-define
  static const String buildTimestampString = String.fromEnvironment(
    'BUILD_TIMESTAMP',
    defaultValue: '2000-01-01T00:00:00Z',
  );

  static Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      final currentBuildDate = DateTime.parse(buildTimestampString);

      final url = Uri.parse(
        'https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest',
      );
      final response = await http.get(
        url,
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Fecha en la que se publicó la Release en GitHub (ej: "2026-09-01T12:00:00Z")
        final String publishedAtStr = data['published_at'] ?? '';
        if (publishedAtStr.isEmpty) return null;

        final remoteReleaseDate = DateTime.parse(publishedAtStr);

        // Si la release de GitHub es más reciente que la fecha de compilación de la app actual:
        if (remoteReleaseDate.isAfter(currentBuildDate)) {
          final assets = data['assets'] as List;
          String? apkUrl;
          for (var asset in assets) {
            if (asset['name'].toString().endsWith('.apk')) {
              apkUrl = asset['browser_download_url'];
              break;
            }
          }

          if (apkUrl != null) {
            return {
              'version': data['tag_name'] ?? 'Nueva versión',
              'notes':
                  data['body'] ??
                  'Actualización disponible por fecha de compilación.',
              'url': apkUrl,
            };
          }
        }
      }
    } catch (e) {
      // Error silencioso de red
    }
    return null;
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
      List<int> bytes = [];
      int downloaded = 0;

      response.stream.listen(
        (List<int> chunk) {
          bytes.addAll(chunk);
          downloaded += chunk.length;
          if (contentLength > 0) {
            onProgress(downloaded / contentLength);
          }
        },
        onDone: () async {
          final dir =
              await getExternalStorageDirectory() ??
              await getTemporaryDirectory();
          final filePath = '${dir.path}/update.apk';
          final file = File(filePath);
          await file.writeAsBytes(bytes);

          await OpenFilex.open(filePath);
        },
        onError: (e) {},
        cancelOnError: true,
      );
    } catch (e) {}
  }
}
