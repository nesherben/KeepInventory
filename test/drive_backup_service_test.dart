import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:keepinventory/core/services/drive_backup_service.dart';
import 'package:keepinventory/core/services/drive_config.dart';

DriveBackupService _service(MockClient client) => DriveBackupService(
  client: client,
  authHeaders: () async => {'Authorization': 'Bearer test-token'},
);

void main() {
  test('findBackup pide solo el archivo de la app en la carpeta oculta', () async {
    late http.Request captured;
    final service = _service(
      MockClient((request) async {
        captured = request;
        return http.Response('{"files": []}', 200);
      }),
    );

    await service.findBackup();

    expect(captured.method, 'GET');
    expect(captured.url.queryParameters['spaces'], 'appDataFolder');
    expect(
      captured.url.queryParameters['q'],
      "name = '${DriveBackupService.fileName}'",
    );
    expect(captured.headers['Authorization'], 'Bearer test-token');
  });

  test('findBackup devuelve null si todavía no hay copia', () async {
    final service = _service(
      MockClient((_) async => http.Response('{"files": []}', 200)),
    );

    expect(await service.findBackup(), isNull);
  });

  test('findBackup lee id, fecha y tamaño de la copia', () async {
    final service = _service(
      MockClient(
        (_) async => http.Response(
          '{"files": [{"id": "abc", "modifiedTime": "2026-11-13T00:02:00.000Z", "size": "2048"}]}',
          200,
        ),
      ),
    );

    final info = await service.findBackup();

    expect(info, isNotNull);
    expect(info!.id, 'abc');
    expect(info.sizeBytes, 2048);
    expect(info.modified.toUtc(), DateTime.utc(2026, 11, 13, 0, 2));
  });

  test('sin conexión se traduce a DriveFailure.offline', () async {
    final service = _service(
      MockClient((_) async => throw const SocketException('sin red')),
    );

    await expectLater(
      service.findBackup(),
      throwsA(
        isA<DriveException>().having(
          (e) => e.failure,
          'failure',
          DriveFailure.offline,
        ),
      ),
    );
  });

  test('un error HTTP se traduce a DriveFailure.failed', () async {
    final service = _service(
      MockClient((_) async => http.Response('{"error": "quota"}', 403)),
    );

    await expectLater(
      service.findBackup(),
      throwsA(
        isA<DriveException>().having(
          (e) => e.failure,
          'failure',
          DriveFailure.failed,
        ),
      ),
    );
  });

  test('Drive está configurado con un ID de cliente web de Google', () {
    expect(DriveBackupService.isConfigured, isTrue);
    expect(driveServerClientId, endsWith('.apps.googleusercontent.com'));
  });
}
