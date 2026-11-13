import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/core/services/app_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppPreferences.privacyModeEnabled.value = false;
    AppPreferences.tutorialSeen = false;
  });

  test('loads the saved privacy mode preference', () async {
    SharedPreferences.setMockInitialValues({'privacy_mode_enabled': true});

    await AppPreferences.load();

    expect(AppPreferences.privacyModeEnabled.value, isTrue);
  });

  test('updates listeners and persists privacy mode changes', () async {
    var notifications = 0;
    void listener() => notifications++;
    AppPreferences.privacyModeEnabled.addListener(listener);

    await AppPreferences.setPrivacyModeEnabled(true);

    final preferences = await SharedPreferences.getInstance();
    expect(AppPreferences.privacyModeEnabled.value, isTrue);
    expect(preferences.getBool('privacy_mode_enabled'), isTrue);
    expect(notifications, 1);

    AppPreferences.privacyModeEnabled.removeListener(listener);
  });

  test('tutorial is pending on a fresh install', () async {
    await AppPreferences.load();

    expect(AppPreferences.tutorialSeen, isFalse);
  });

  test('marking the tutorial as seen persists across loads', () async {
    await AppPreferences.markTutorialSeen();
    AppPreferences.tutorialSeen = false;

    await AppPreferences.load();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('tutorial_seen'), isTrue);
    expect(AppPreferences.tutorialSeen, isTrue);
  });

  group('copias de seguridad', () {
    setUp(() {
      AppPreferences.autoBackupEnabled = false;
      AppPreferences.backupRiskAccepted = false;
      AppPreferences.lastLocalBackupAt = null;
      AppPreferences.lastLocalSignature = null;
      AppPreferences.lastDriveBackupAt = null;
      AppPreferences.lastDriveSignature = null;
      AppPreferences.driveEmail = null;
      AppPreferences.backupFailures = 0;
    });

    test('por defecto no hay copia automática ni copias anotadas', () async {
      await AppPreferences.load();

      expect(AppPreferences.autoBackupEnabled, isFalse);
      expect(AppPreferences.backupRiskAccepted, isFalse);
      expect(AppPreferences.lastLocalBackupAt, isNull);
      expect(AppPreferences.lastDriveBackupAt, isNull);
      expect(AppPreferences.backupFailures, 0);
    });

    test('guarda y recupera la copia local y la subida a Drive', () async {
      await AppPreferences.setAutoBackupEnabled(true);
      await AppPreferences.setBackupRiskAccepted(true);
      await AppPreferences.recordLocalBackup(1000, 'sig-local');
      await AppPreferences.recordDriveBackup(2000, 'sig-drive');
      await AppPreferences.setDriveEmail('a@b.c');

      AppPreferences.autoBackupEnabled = false;
      AppPreferences.lastLocalBackupAt = null;
      await AppPreferences.load();

      expect(AppPreferences.autoBackupEnabled, isTrue);
      expect(AppPreferences.backupRiskAccepted, isTrue);
      expect(AppPreferences.lastLocalBackupAt, 1000);
      expect(AppPreferences.lastLocalSignature, 'sig-local');
      expect(AppPreferences.lastDriveBackupAt, 2000);
      expect(AppPreferences.lastDriveSignature, 'sig-drive');
      expect(AppPreferences.driveEmail, 'a@b.c');
    });

    test('cerrar sesión de Drive borra el correo', () async {
      await AppPreferences.setDriveEmail('a@b.c');
      await AppPreferences.setDriveEmail(null);
      await AppPreferences.load();

      expect(AppPreferences.driveEmail, isNull);
    });

    test('los fallos se acumulan y una copia buena los pone a cero', () async {
      await AppPreferences.recordBackupFailure();
      await AppPreferences.recordBackupFailure();
      expect(AppPreferences.backupFailures, 2);

      await AppPreferences.recordLocalBackup(1, 'sig');

      await AppPreferences.load();
      expect(AppPreferences.backupFailures, 0);
    });
  });
}
