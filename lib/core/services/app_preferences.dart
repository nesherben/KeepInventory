import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  AppPreferences._();

  static const _privacyModeKey = 'privacy_mode_enabled';
  static const _tutorialSeenKey = 'tutorial_seen';
  static const _menuHintKey = 'menu_hint_shown';
  static const _autoBackupKey = 'auto_backup_enabled';
  static const _backupRiskKey = 'backup_risk_accepted';
  static const _lastLocalBackupKey = 'last_local_backup_at';
  static const _localSignatureKey = 'last_local_backup_signature';
  static const _lastDriveBackupKey = 'last_drive_backup_at';
  static const _driveSignatureKey = 'last_drive_backup_signature';
  static const _driveEmailKey = 'drive_account_email';
  static const _driveStatusKnownKey = 'drive_status_known';
  static const _driveStatusAccountKey = 'drive_status_account';
  static const _driveStatusBackupAtKey = 'drive_status_backup_at';
  static const _backupFailuresKey = 'backup_failures';
  static final ValueNotifier<bool> privacyModeEnabled = ValueNotifier(false);

  /// Si el usuario ya ha visto (o saltado) el tutorial de bienvenida.
  static bool tutorialSeen = false;

  /// Si ya se abrió solo el menú lateral para enseñar dónde empezar.
  static bool menuHintShown = false;

  /// Copia local automática diaria activada.
  static bool autoBackupEnabled = false;

  /// El usuario ha aceptado los riesgos de no dar el permiso de archivos:
  /// no se vuelve a avisar.
  static bool backupRiskAccepted = false;

  /// Última copia local (ms desde epoch) y firma de la BD en ese momento.
  static int? lastLocalBackupAt;
  static String? lastLocalSignature;

  /// Última subida a Drive (ms desde epoch) y firma de la BD en ese momento.
  static int? lastDriveBackupAt;
  static String? lastDriveSignature;

  /// Cuenta de Google con la sesión iniciada (solo para mostrarla).
  static String? driveEmail;
  static final ValueNotifier<String?> driveEmailNotifier = ValueNotifier(null);
  static bool driveStatusKnown = false;
  static String? driveStatusAccount;
  static int? driveStatusBackupAt;

  static bool get hasCachedDriveStatus =>
      driveStatusKnown &&
      driveEmail != null &&
      driveStatusAccount == driveEmail;

  /// Copias automáticas fallidas seguidas (0 = la última salió bien).
  static int backupFailures = 0;

  static Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    // Otro isolate (la tarea de medianoche) pudo escribir: releer del disco
    await preferences.reload();
    autoBackupEnabled = preferences.getBool(_autoBackupKey) ?? false;
    backupRiskAccepted = preferences.getBool(_backupRiskKey) ?? false;
    lastLocalBackupAt = preferences.getInt(_lastLocalBackupKey);
    lastLocalSignature = preferences.getString(_localSignatureKey);
    lastDriveBackupAt = preferences.getInt(_lastDriveBackupKey);
    lastDriveSignature = preferences.getString(_driveSignatureKey);
    driveStatusKnown = preferences.getBool(_driveStatusKnownKey) ?? false;
    driveStatusAccount = preferences.getString(_driveStatusAccountKey);
    driveStatusBackupAt = preferences.getInt(_driveStatusBackupAtKey);
    driveEmail = preferences.getString(_driveEmailKey);
    driveEmailNotifier.value = driveEmail;
    backupFailures = preferences.getInt(_backupFailuresKey) ?? 0;
    privacyModeEnabled.value = preferences.getBool(_privacyModeKey) ?? false;
    tutorialSeen = preferences.getBool(_tutorialSeenKey) ?? false;
    menuHintShown = preferences.getBool(_menuHintKey) ?? false;
  }

  static Future<void> setPrivacyModeEnabled(bool enabled) async {
    privacyModeEnabled.value = enabled;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_privacyModeKey, enabled);
  }

  static Future<void> markMenuHintShown() async {
    menuHintShown = true;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_menuHintKey, true);
  }

  static Future<void> markTutorialSeen() async {
    tutorialSeen = true;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_tutorialSeenKey, true);
  }

  static Future<void> setAutoBackupEnabled(bool enabled) async {
    autoBackupEnabled = enabled;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_autoBackupKey, enabled);
  }

  static Future<void> setBackupRiskAccepted(bool accepted) async {
    backupRiskAccepted = accepted;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_backupRiskKey, accepted);
  }

  /// Anota una copia local hecha: cuándo y con qué estado de la BD.
  static Future<void> recordLocalBackup(int at, String signature) async {
    lastLocalBackupAt = at;
    lastLocalSignature = signature;
    backupFailures = 0;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_lastLocalBackupKey, at);
    await preferences.setString(_localSignatureKey, signature);
    await preferences.setInt(_backupFailuresKey, 0);
  }

  /// Anota una subida a Drive hecha: cuándo y con qué estado de la BD.
  static Future<void> recordDriveBackup(int at, String signature) async {
    lastDriveBackupAt = at;
    lastDriveSignature = signature;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_lastDriveBackupKey, at);
    await preferences.setString(_driveSignatureKey, signature);
  }

  static Future<void> recordDriveStatus({
    required String account,
    required int? backupAt,
  }) async {
    driveStatusKnown = true;
    driveStatusAccount = account;
    driveStatusBackupAt = backupAt;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_driveStatusKnownKey, true);
    await preferences.setString(_driveStatusAccountKey, account);
    if (backupAt == null) {
      await preferences.remove(_driveStatusBackupAtKey);
    } else {
      await preferences.setInt(_driveStatusBackupAtKey, backupAt);
    }
  }

  static Future<void> setDriveEmail(String? email) async {
    driveEmail = email;
    driveEmailNotifier.value = email;
    final preferences = await SharedPreferences.getInstance();
    if (email == null) {
      await preferences.remove(_driveEmailKey);
    } else {
      await preferences.setString(_driveEmailKey, email);
    }
  }

  static Future<void> recordBackupFailure() async {
    backupFailures++;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_backupFailuresKey, backupFailures);
  }
}
