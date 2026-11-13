import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'app_preferences.dart';
import 'drive_config.dart';
import 'backup_validator.dart';
import 'local_backup_service.dart';

/// Copia guardada en Drive.
class DriveBackupInfo {
  const DriveBackupInfo({
    required this.id,
    required this.modified,
    required this.sizeBytes,
  });

  final String id;
  final DateTime modified;
  final int sizeBytes;
}

enum DriveFailure {
  /// Falta configurar el cliente OAuth en [drive_config.dart].
  notConfigured,

  /// El usuario canceló el inicio de sesión o el permiso.
  cancelled,

  /// Sin conexión.
  offline,

  /// Cualquier otro fallo (token caducado, cuota, servidor…).
  failed,
}

class DriveException implements Exception {
  const DriveException(this.failure, [this.detail]);

  final DriveFailure failure;
  final String? detail;

  @override
  String toString() => 'DriveException($failure, $detail)';
}

/// Copia manual de la BD en Google Drive: un único archivo en la carpeta
/// oculta de la app (`appDataFolder`) que se sobrescribe con la última copia.
class DriveBackupService {
  DriveBackupService({
    http.Client? client,
    Future<Map<String, String>> Function()? authHeaders,
  }) : _client = client ?? http.Client(),
       _authHeaders = authHeaders ?? _googleAuthHeaders;

  static const fileName = 'keepinventory_backup.db';
  static const _api = 'https://www.googleapis.com/drive/v3/files';
  static const _upload = 'https://www.googleapis.com/upload/drive/v3/files';

  final http.Client _client;
  final Future<Map<String, String>> Function() _authHeaders;

  static bool get isConfigured => driveServerClientId.isNotEmpty;

  static bool _initialized = false;

  static Future<void> _ensureInitialized() async {
    if (!isConfigured) throw const DriveException(DriveFailure.notConfigured);
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(serverClientId: driveServerClientId);
    _initialized = true;
  }

  // ── Sesión ───────────────────────────────────────────────────────────────

  /// Inicia sesión (pide la cuenta y el permiso de Drive). Devuelve el correo.
  static Future<String> signIn() async {
    await _ensureInitialized();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      await account.authorizationClient.authorizeScopes([driveAppDataScope]);
      await AppPreferences.setDriveEmail(account.email);
      return account.email;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        throw const DriveException(DriveFailure.cancelled);
      }
      throw DriveException(DriveFailure.failed, e.toString());
    }
  }

  static Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('Error al cerrar la sesión de Google: $e');
    }
    await AppPreferences.setDriveEmail(null);
  }

  static Future<Map<String, String>> _googleAuthHeaders() async {
    await _ensureInitialized();
    try {
      // Recupera la sesión anterior sin mostrar nada si es posible
      await GoogleSignIn.instance.attemptLightweightAuthentication();
      final headers = await GoogleSignIn.instance.authorizationClient
          .authorizationHeaders([driveAppDataScope], promptIfNecessary: true);
      if (headers == null) throw const DriveException(DriveFailure.cancelled);
      return headers;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        throw const DriveException(DriveFailure.cancelled);
      }
      throw DriveException(DriveFailure.failed, e.toString());
    }
  }

  // ── Drive ────────────────────────────────────────────────────────────────

  /// La copia que hay en Drive (null si todavía no se ha subido ninguna).
  Future<DriveBackupInfo?> findBackup() async {
    final headers = await _authHeaders();
    final uri = Uri.parse(_api).replace(
      queryParameters: {
        'spaces': 'appDataFolder',
        'q': "name = '$fileName'",
        'fields': 'files(id,modifiedTime,size)',
        'orderBy': 'modifiedTime desc',
        'pageSize': '1',
      },
    );
    final response = await _send(() => _client.get(uri, headers: headers));
    final files = (jsonDecode(response.body)['files'] as List?) ?? const [];
    if (files.isEmpty) return null;
    final file = files.first as Map<String, dynamic>;
    return DriveBackupInfo(
      id: file['id'] as String,
      modified: DateTime.parse(file['modifiedTime'] as String).toLocal(),
      sizeBytes: int.tryParse('${file['size']}') ?? 0,
    );
  }

  /// Sube la copia actual sobrescribiendo la anterior. Devuelve la subida.
  Future<DriveBackupInfo> upload() async {
    final headers = await _authHeaders();
    final signature = await LocalBackupService.currentSignature();
    final temp = File(
      '${(await getTemporaryDirectory()).path}/drive_upload_$fileName',
    );
    await LocalBackupService.snapshot(temp.path);
    try {
      // Nunca se sobrescribe la copia buena de Drive con una vacía o dañada
      final check = await BackupValidator.inspect(temp);
      if (!check.isValid || check.isEmpty) {
        throw const DriveException(DriveFailure.failed, 'copia vacía o dañada');
      }
      final bytes = await temp.readAsBytes();
      final existing = await findBackup();
      final http.Response response;
      if (existing == null) {
        const boundary = 'keepinventory_backup_boundary';
        final metadata = jsonEncode({
          'name': fileName,
          'parents': ['appDataFolder'],
        });
        final body = BytesBuilder()
          ..add(
            utf8.encode(
              '--$boundary\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n'
              '$metadata\r\n--$boundary\r\nContent-Type: application/octet-stream\r\n\r\n',
            ),
          )
          ..add(bytes)
          ..add(utf8.encode('\r\n--$boundary--'));
        response = await _send(
          () => _client.post(
            Uri.parse(
              _upload,
            ).replace(queryParameters: {'uploadType': 'multipart', 'fields': 'id,modifiedTime,size'}),
            headers: {
              ...headers,
              'Content-Type': 'multipart/related; boundary=$boundary',
            },
            body: body.takeBytes(),
          ),
        );
      } else {
        response = await _send(
          () => _client.patch(
            Uri.parse('$_upload/${existing.id}').replace(
              queryParameters: {
                'uploadType': 'media',
                'fields': 'id,modifiedTime,size',
              },
            ),
            headers: {...headers, 'Content-Type': 'application/octet-stream'},
            body: bytes,
          ),
        );
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final info = DriveBackupInfo(
        id: json['id'] as String,
        modified: DateTime.parse(json['modifiedTime'] as String).toLocal(),
        sizeBytes: int.tryParse('${json['size']}') ?? bytes.length,
      );
      await AppPreferences.recordDriveBackup(
        info.modified.millisecondsSinceEpoch,
        signature ?? '',
      );
      return info;
    } finally {
      if (await temp.exists()) await temp.delete();
    }
  }

  /// Baja la copia de Drive a un archivo temporal y lo devuelve.
  Future<File> download(DriveBackupInfo info) async {
    final headers = await _authHeaders();
    final response = await _send(
      () => _client.get(
        Uri.parse('$_api/${info.id}').replace(queryParameters: {'alt': 'media'}),
        headers: headers,
      ),
    );
    final file = File(
      '${(await getTemporaryDirectory()).path}/drive_download_$fileName',
    );
    await file.writeAsBytes(response.bodyBytes, flush: true);
    return file;
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request().timeout(const Duration(minutes: 2));
    } on SocketException {
      throw const DriveException(DriveFailure.offline);
    } on http.ClientException {
      throw const DriveException(DriveFailure.offline);
    } on TimeoutException {
      throw const DriveException(DriveFailure.offline);
    } on HandshakeException {
      throw const DriveException(DriveFailure.offline);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw DriveException(
        DriveFailure.failed,
        'HTTP ${response.statusCode}: ${response.body}',
      );
    }
    return response;
  }
}
