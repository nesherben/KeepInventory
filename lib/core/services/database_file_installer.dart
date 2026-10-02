import 'dart:io';

class DatabaseFileInstaller {
  const DatabaseFileInstaller._();

  static Future<bool> installDownloadedFile({
    required File temporaryFile,
    required File databaseFile,
    required File backupFile,
    required void Function(String status, double progress) onProgress,
    required String completedMessage,
    required String failedMessage,
  }) async {
    try {
      await temporaryFile.copy(databaseFile.path);
      if (await temporaryFile.exists()) await temporaryFile.delete();
      if (await backupFile.exists()) await backupFile.delete();
      onProgress(completedMessage, 1.0);
      return true;
    } catch (_) {
      if (await backupFile.exists()) {
        await backupFile.copy(databaseFile.path);
      }
      onProgress(failedMessage, -1.0);
      return false;
    }
  }
}
