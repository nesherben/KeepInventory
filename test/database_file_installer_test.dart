import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/core/services/database_file_installer.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('keepinventory-test-');
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test('installs the temporary database and removes temporary files', () async {
    final temporaryFile = File('${directory.path}/download.db');
    final databaseFile = File('${directory.path}/keepinventory.db');
    final backupFile = File('${directory.path}/backup.db');
    await temporaryFile.writeAsString('new database');
    await databaseFile.writeAsString('old database');
    await backupFile.writeAsString('old database');
    final progress = <(String, double)>[];

    final success = await DatabaseFileInstaller.installDownloadedFile(
      temporaryFile: temporaryFile,
      databaseFile: databaseFile,
      backupFile: backupFile,
      onProgress: (status, value) => progress.add((status, value)),
      completedMessage: 'completed',
      failedMessage: 'failed',
    );

    expect(success, isTrue);
    expect(await databaseFile.readAsString(), 'new database');
    expect(await temporaryFile.exists(), isFalse);
    expect(await backupFile.exists(), isFalse);
    expect(progress, [('completed', 1.0)]);
  });

  test(
    'restores the backup when the temporary database cannot be copied',
    () async {
      final temporaryFile = File('${directory.path}/missing.db');
      final databaseFile = File('${directory.path}/keepinventory.db');
      final backupFile = File('${directory.path}/backup.db');
      await databaseFile.writeAsString('partial database');
      await backupFile.writeAsString('backup database');
      final progress = <(String, double)>[];

      final success = await DatabaseFileInstaller.installDownloadedFile(
        temporaryFile: temporaryFile,
        databaseFile: databaseFile,
        backupFile: backupFile,
        onProgress: (status, value) => progress.add((status, value)),
        completedMessage: 'completed',
        failedMessage: 'failed',
      );

      expect(success, isFalse);
      expect(await databaseFile.readAsString(), 'backup database');
      expect(await backupFile.readAsString(), 'backup database');
      expect(progress, [('failed', -1.0)]);
    },
  );
}
