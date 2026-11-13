import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';

import 'app_preferences.dart';
import 'backup_validator.dart';

enum LocalBackupStatus {
  /// Copia creada.
  created,

  /// No hay cambios desde la última copia.
  unchanged,

  /// La base de datos no tiene productos ni ventas: no se copia para no
  /// desplazar copias buenas con una vacía.
  empty,

  /// No se pudo crear la copia.
  failed,
}

class LocalBackupResult {
  const LocalBackupResult(this.status, {this.file, this.inSharedFolder = false});

  final LocalBackupStatus status;
  final File? file;

  /// Se guardó en Documentos/KeepInventory (sobrevive a desinstalar la app).
  final bool inSharedFolder;
}

/// Una copia encontrada en el móvil.
class LocalBackupFile {
  const LocalBackupFile({
    required this.file,
    required this.modified,
    required this.sizeBytes,
    required this.beforeRestore,
  });

  final File file;
  final DateTime modified;
  final int sizeBytes;

  /// Copia de seguridad hecha automáticamente antes de restaurar otra.
  final bool beforeRestore;
}

/// Copia automática de la base de datos en el propio móvil.
///
/// Las fotos van dentro de la BD (BLOB), así que una copia es un solo archivo.
/// Se guarda en `Documentos/KeepInventory` si la app tiene "Acceso a todos los
/// archivos" (así sobrevive a desinstalar); si no, en la carpeta privada de la
/// app, que protege de errores pero no de desinstalar.
class LocalBackupService {
  const LocalBackupService._();

  static const sharedFolderPath = '/storage/emulated/0/Documents/KeepInventory';
  static const _autoPrefix = 'keepinventory_';
  static const _beforeRestorePrefix = 'antes_de_restaurar_';

  /// Días de copias automáticas que se conservan (una por día).
  static const keepDays = 7;

  /// Copias "antes de restaurar" que se conservan.
  static const keepBeforeRestore = 3;

  // ── Lógica pura (testeable) ──────────────────────────────────────────────

  static String autoFileName(DateTime when) =>
      '$_autoPrefix${_stamp(when)}.db';

  static String beforeRestoreFileName(DateTime when) =>
      '$_beforeRestorePrefix${_stamp(when)}.db';

  static bool isBeforeRestoreName(String name) =>
      name.startsWith(_beforeRestorePrefix) && name.endsWith('.db');

  static bool isAutoName(String name) =>
      name.startsWith(_autoPrefix) && name.endsWith('.db');

  static String _stamp(DateTime w) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${w.year}-${two(w.month)}-${two(w.day)}_${two(w.hour)}${two(w.minute)}';
  }

  /// Nombres a borrar de las copias automáticas: solo queda la última de cada
  /// día y los [days] días más recientes.
  static List<String> autoBackupsToDelete(
    Iterable<String> names, {
    int days = keepDays,
  }) {
    // El nombre lleva la fecha y la hora, así que ordenar por nombre = por fecha
    final sorted = names.where(isAutoName).toList()..sort();
    final newestPerDay = <String, String>{};
    for (final name in sorted) {
      final day = name.substring(_autoPrefix.length).split('_').first;
      newestPerDay[day] = name;
    }
    final keptDays = newestPerDay.keys.toList()..sort();
    final keep = keptDays.reversed
        .take(days)
        .map((day) => newestPerDay[day]!)
        .toSet();
    return sorted.where((name) => !keep.contains(name)).toList();
  }

  /// Nombres a borrar de las copias "antes de restaurar" (quedan las últimas).
  static List<String> beforeRestoreToDelete(
    Iterable<String> names, {
    int keep = keepBeforeRestore,
  }) {
    final sorted = names.where(isBeforeRestoreName).toList()..sort();
    return sorted.length <= keep
        ? const []
        : sorted.sublist(0, sorted.length - keep);
  }

  /// Próximas 00:00 locales tras [now].
  static DateTime nextMidnight(DateTime now) =>
      DateTime(now.year, now.month, now.day + 1);

  /// Firma del estado de la BD: cambia con cualquier escritura.
  static String signatureOf(int sizeBytes, DateTime modified) =>
      '$sizeBytes:${modified.millisecondsSinceEpoch}';

  // ── Estado ───────────────────────────────────────────────────────────────

  static Future<File> databaseFile() async =>
      File(join(await getDatabasesPath(), 'keepinventory.db'));

  static Future<String?> currentSignature() async {
    final file = await databaseFile();
    if (!await file.exists()) return null;
    final stat = await file.stat();
    return signatureOf(stat.size, stat.modified);
  }

  /// ¿Hay cambios desde la última copia local?
  static Future<bool> hasUnsavedChanges() async {
    final signature = await currentSignature();
    if (signature == null) return false;
    return signature != AppPreferences.lastLocalSignature;
  }

  /// ¿Hay que avisar de que falta una copia? Solo si hay cambios sin copiar y
  /// la última copia tiene más de un día (o no existe).
  static bool reminderDue({
    required bool hasChanges,
    required int? lastBackupAt,
    required DateTime now,
  }) {
    if (!hasChanges) return false;
    if (lastBackupAt == null) return true;
    final last = DateTime.fromMillisecondsSinceEpoch(lastBackupAt);
    return now.difference(last) >= const Duration(days: 1);
  }

  // ── Permiso de archivos ──────────────────────────────────────────────────

  /// ¿Tiene la app acceso real a todos los archivos? Solo con él una copia en
  /// Documentos/KeepInventory se puede leer tras desinstalar y reinstalar: sin
  /// él, Android 11+ deja escribir archivos propios pero la app nueva no los ve.
  static Future<bool> hasFilesAccess() async {
    try {
      final manage = await Permission.manageExternalStorage.status;
      if (manage.isGranted) return true;
      // Android 10 o anterior: no existe ese permiso y vale el clásico
      if (manage.isRestricted) return await Permission.storage.isGranted;
    } catch (e) {
      debugPrint('No se pudo leer el permiso de archivos: $e');
    }
    return false;
  }

  /// ¿Se puede guardar de forma duradera en Documentos/KeepInventory? Hace
  /// falta el permiso y, además, que se pueda escribir de verdad.
  static Future<bool> canWriteSharedFolder() async {
    if (!await hasFilesAccess()) return false;
    try {
      final dir = Directory(sharedFolderPath);
      await dir.create(recursive: true);
      final probe = File(join(dir.path, '.probe'));
      await probe.writeAsString('ok');
      await probe.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Pide "Acceso a todos los archivos" (abre Ajustes en Android 11+). Devuelve
  /// si al volver ya se puede guardar en la carpeta compartida.
  static Future<bool> requestFilesAccess() async {
    try {
      final manage = await Permission.manageExternalStorage.request();
      // Android 10 o anterior: permiso de almacenamiento clásico
      if (manage.isRestricted) await Permission.storage.request();
    } catch (e) {
      debugPrint('No se pudo pedir el permiso de archivos: $e');
    }
    return canWriteSharedFolder();
  }

  /// Abre los ajustes de la app para dar el permiso a mano.
  static Future<void> openSettings() => openAppSettings();

  // ── Carpetas ─────────────────────────────────────────────────────────────

  static Future<Directory> _privateFolder() async {
    final base =
        await getExternalStorageDirectory() ??
        await getApplicationSupportDirectory();
    return Directory(join(base.path, 'backups'));
  }

  /// Carpeta donde se guarda ahora: la compartida si hay permiso.
  static Future<({Directory dir, bool shared})> _targetFolder() async {
    if (await canWriteSharedFolder()) {
      return (dir: Directory(sharedFolderPath), shared: true);
    }
    return (dir: await _privateFolder(), shared: false);
  }

  // ── Copias ───────────────────────────────────────────────────────────────

  /// Copia consistente de la BD en [destPath]: bloquea las escrituras mientras
  /// se copia el archivo (así no queda a medias si se vende justo entonces).
  static Future<void> snapshot(String destPath) async {
    final source = await databaseFile();
    if (!await source.exists()) {
      throw const FileSystemException('La base de datos no existe');
    }
    final temp = File('$destPath.tmp');
    Database? db;
    try {
      db = await openDatabase(source.path, singleInstance: false);
      await db.transaction((txn) async {
        await source.copy(temp.path);
      }, exclusive: true);
    } catch (_) {
      // Sin dejar copias a medias en la carpeta
      if (await temp.exists()) await temp.delete();
      rethrow;
    } finally {
      await db?.close();
    }
    if (await File(destPath).exists()) await File(destPath).delete();
    await temp.rename(destPath);
  }

  /// Crea una copia local. Sin [force], no hace nada si no hay cambios desde
  /// la última.
  static Future<LocalBackupResult> createBackup({bool force = false}) async {
    try {
      final signature = await currentSignature();
      if (signature == null) {
        return const LocalBackupResult(LocalBackupStatus.failed);
      }
      if (!force &&
          AppPreferences.lastLocalBackupAt != null &&
          signature == AppPreferences.lastLocalSignature) {
        return const LocalBackupResult(LocalBackupStatus.unchanged);
      }

      final target = await _targetFolder();
      await target.dir.create(recursive: true);
      final now = DateTime.now();
      final dest = join(target.dir.path, autoFileName(now));
      await snapshot(dest);

      // Una copia vacía o dañada no debe desplazar a las buenas
      final info = await BackupValidator.inspect(File(dest));
      if (!info.isValid || info.isEmpty) {
        await File(dest).delete();
        return LocalBackupResult(
          info.isValid ? LocalBackupStatus.empty : LocalBackupStatus.failed,
        );
      }

      await _applyRetention(target.dir);
      await AppPreferences.recordLocalBackup(
        now.millisecondsSinceEpoch,
        signature,
      );
      return LocalBackupResult(
        LocalBackupStatus.created,
        file: File(dest),
        inSharedFolder: target.shared,
      );
    } catch (e) {
      debugPrint('Error al crear la copia local: $e');
      return const LocalBackupResult(LocalBackupStatus.failed);
    }
  }

  /// Guarda los datos actuales antes de sustituirlos por una restauración.
  /// Devuelve el archivo, o null si no había datos que guardar.
  static Future<File?> saveBeforeRestore() async {
    final source = await databaseFile();
    if (!await source.exists()) return null;
    final target = await _targetFolder();
    await target.dir.create(recursive: true);
    final dest = File(
      join(target.dir.path, beforeRestoreFileName(DateTime.now())),
    );
    try {
      await source.copy(dest.path);
    } catch (_) {
      if (await dest.exists()) await dest.delete();
      rethrow;
    }
    final info = await BackupValidator.inspect(dest);
    if (!info.isValid || info.isEmpty) {
      // Nada que merezca conservarse
      await dest.delete();
      return null;
    }
    await _applyRetention(target.dir);
    return dest;
  }

  static Future<void> _applyRetention(Directory dir) async {
    final names = [
      await for (final entity in dir.list())
        if (entity is File) basename(entity.path),
    ];
    for (final name in [
      ...autoBackupsToDelete(names),
      ...beforeRestoreToDelete(names),
    ]) {
      try {
        await File(join(dir.path, name)).delete();
      } catch (_) {}
    }
  }

  /// Copias encontradas (carpeta compartida si hay permiso, y la privada),
  /// de la más nueva a la más antigua.
  static Future<List<LocalBackupFile>> listBackups() async {
    final folders = <Directory>[
      if (await canWriteSharedFolder()) Directory(sharedFolderPath),
      await _privateFolder(),
    ];
    final found = <LocalBackupFile>[];
    for (final folder in folders) {
      if (!await folder.exists()) continue;
      await for (final entity in folder.list()) {
        if (entity is! File) continue;
        final name = basename(entity.path);
        if (!isAutoName(name) && !isBeforeRestoreName(name)) continue;
        final stat = await entity.stat();
        found.add(
          LocalBackupFile(
            file: entity,
            modified: stat.modified,
            sizeBytes: stat.size,
            beforeRestore: isBeforeRestoreName(name),
          ),
        );
      }
    }
    found.sort((a, b) => b.modified.compareTo(a.modified));
    return found;
  }
}
