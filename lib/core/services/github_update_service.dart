import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class GithubUpdateService {
  // 💡 CAMBIO 1: Quitamos '/latest' del final para obtener la lista completa de releases
  static const String _repoUrl =
      'https://api.github.com/repos/nesherben/KeepInventory/releases';

  static Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final localVersion = packageInfo.version;

      final response = await http
          .get(
            Uri.parse(_repoUrl),
            headers: {'User-Agent': 'KeepInventory-App'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // 💡 CAMBIO 2: Ahora recibimos una LISTA de releases
        final List<dynamic> releases = json.decode(response.body);

        // Filtramos para ignorar versiones "draft" o "pre-releases" si las hubiera
        final validReleases = releases
            .where((r) => r['draft'] == false && r['prerelease'] == false)
            .toList();

        if (validReleases.isEmpty) return null;

        // La versión más reciente siempre es la primera de la lista
        final latestRelease = validReleases.first;
        String latestTag = latestRelease['tag_name']
            .replaceAll(RegExp(r'[vV]'), '')
            .trim();

        // 💡 CAMBIO 3: Si la más reciente es mayor que la nuestra, recopilamos TODO el historial
        if (_isVersionGreater(localVersion, latestTag)) {
          // Buscamos el link directo al APK
          String downloadUrl = latestRelease['html_url'];
          if (latestRelease['assets'] != null &&
              latestRelease['assets'].isNotEmpty) {
            downloadUrl = latestRelease['assets'][0]['browser_download_url'];
          }

          // Construimos el CHANGELOG ACUMULATIVO
          StringBuffer cumulativeNotes = StringBuffer();

          for (var release in validReleases) {
            String currentLoopTag = release['tag_name']
                .replaceAll(RegExp(r'[vV]'), '')
                .trim();

            // Si esta versión de la iteración es MAYOR que la que tenemos instalada, sumamos sus notas
            if (_isVersionGreater(localVersion, currentLoopTag)) {
              cumulativeNotes.writeln('🚀 VERSIÓN $currentLoopTag');
              cumulativeNotes.writeln(
                release['body']?.trim() ?? 'Mejoras y correcciones generales.',
              );
              cumulativeNotes.writeln(
                '\n---------------------------\n',
              ); // Separador visual
            } else {
              // Si llegamos a la versión actual (o una más vieja), cortamos el bucle.
              break;
            }
          }

          return {
            'version': latestTag,
            'notes': cumulativeNotes.toString().trim(),
            'url': downloadUrl,
          };
        }
      }
      return null;
    } catch (e) {
      print("❌ Error comprobando actualizaciones: $e");
      return null;
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

      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/update.apk';
      file = File(filePath);

      if (await file.exists()) {
        await file.delete();
      }

      sink = file.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloaded += chunk.length;
        if (contentLength > 0) {
          onProgress(downloaded / contentLength);
        } else {
          onProgress(0.5);
        }
      }

      await sink.flush();
      await sink.close();
      client.close();

      print("✅ Descarga completada al 100%. Guardando archivo...");
      print("📦 Abriendo instalador en: $filePath");

      final result = await OpenFilex.open(filePath);
      print("📱 Resultado de OpenFilex: ${result.message}");

      return result.type == ResultType.done;
    } catch (e) {
      print("❌ Excepción crítica al iniciar descarga: $e");

      await sink?.close();
      if (file != null && await file.exists()) {
        await file.delete();
      }

      return false;
    }
  }
}
