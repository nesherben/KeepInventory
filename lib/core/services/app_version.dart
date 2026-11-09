import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Resultado de comparar la versión de otro dispositivo o backup con la
/// de esta app.
enum VersionMatch { same, different, unknown }

/// Versión de la app ("1.14.1"), para exigir la misma versión en backups y
/// sincronización.
abstract final class AppVersion {
  static String? _cached;

  static Future<String> current() async {
    return _cached ??= (await PackageInfo.fromPlatform()).version;
  }

  @visibleForTesting
  static set currentForTesting(String? version) => _cached = version;

  /// [other] null = no lleva marca (creado con una versión anterior a 1.14.1).
  static VersionMatch compare(String? other, String mine) {
    if (other == null || other.trim().isEmpty) return VersionMatch.unknown;
    return other.trim() == mine.trim()
        ? VersionMatch.same
        : VersionMatch.different;
  }
}
