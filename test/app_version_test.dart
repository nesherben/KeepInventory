import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/core/services/app_version.dart';

void main() {
  test('compares app versions for backups and sync', () {
    expect(AppVersion.compare('1.14.1', '1.14.1'), VersionMatch.same);
    expect(AppVersion.compare(' 1.14.1 ', '1.14.1'), VersionMatch.same);
    expect(AppVersion.compare('1.14.0', '1.14.1'), VersionMatch.different);
    expect(AppVersion.compare('1.15.0', '1.14.1'), VersionMatch.different);
    // Sin marca: backup o QR de antes de la 1.14.1
    expect(AppVersion.compare(null, '1.14.1'), VersionMatch.unknown);
    expect(AppVersion.compare('', '1.14.1'), VersionMatch.unknown);
  });
}
