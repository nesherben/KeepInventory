import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/core/services/backup_scheduler.dart';
import 'package:keepinventory/core/services/local_backup_service.dart';

void main() {
  group('nombres de copia', () {
    test('la copia automática lleva fecha y hora ordenables', () {
      expect(
        LocalBackupService.autoFileName(DateTime(2026, 11, 3, 0, 2)),
        'keepinventory_2026-11-03_0002.db',
      );
      expect(
        LocalBackupService.beforeRestoreFileName(DateTime(2026, 1, 9, 18, 45)),
        'antes_de_restaurar_2026-01-09_1845.db',
      );
    });

    test('distingue copias automáticas de las previas a restaurar', () {
      expect(
        LocalBackupService.isAutoName('keepinventory_2026-11-03_0002.db'),
        isTrue,
      );
      expect(
        LocalBackupService.isAutoName('antes_de_restaurar_2026-11-03_0002.db'),
        isFalse,
      );
      expect(
        LocalBackupService.isBeforeRestoreName(
          'antes_de_restaurar_2026-11-03_0002.db',
        ),
        isTrue,
      );
      expect(LocalBackupService.isAutoName('notas.txt'), isFalse);
      expect(LocalBackupService.isAutoName('keepinventory_x.db.tmp'), isFalse);
    });
  });

  group('rotación de copias automáticas', () {
    test('deja solo la última de cada día', () {
      final names = [
        'keepinventory_2026-11-03_0002.db',
        'keepinventory_2026-11-03_1830.db',
        'keepinventory_2026-11-04_0001.db',
      ];

      expect(LocalBackupService.autoBackupsToDelete(names), [
        'keepinventory_2026-11-03_0002.db',
      ]);
    });

    test('conserva los 7 días más recientes y borra el resto', () {
      final names = [
        for (var day = 1; day <= 10; day++)
          'keepinventory_2026-11-${day.toString().padLeft(2, '0')}_0001.db',
      ];

      final deleted = LocalBackupService.autoBackupsToDelete(names);

      expect(deleted, [
        'keepinventory_2026-11-01_0001.db',
        'keepinventory_2026-11-02_0001.db',
        'keepinventory_2026-11-03_0001.db',
      ]);
    });

    test('no toca archivos ajenos ni las copias previas a restaurar', () {
      final names = [
        'notas.txt',
        'antes_de_restaurar_2026-11-01_0001.db',
        'keepinventory_2026-11-02_0001.db',
      ];

      expect(LocalBackupService.autoBackupsToDelete(names), isEmpty);
    });

    test('no borra nada si hay pocas copias', () {
      expect(
        LocalBackupService.autoBackupsToDelete(['keepinventory_2026-11-02_0001.db']),
        isEmpty,
      );
      expect(LocalBackupService.autoBackupsToDelete(const []), isEmpty);
    });
  });

  group('rotación de copias previas a restaurar', () {
    test('conserva las 3 últimas', () {
      final names = [
        'antes_de_restaurar_2026-11-01_1000.db',
        'antes_de_restaurar_2026-11-02_1000.db',
        'antes_de_restaurar_2026-11-03_1000.db',
        'antes_de_restaurar_2026-11-04_1000.db',
        'keepinventory_2026-11-04_0001.db',
      ];

      expect(LocalBackupService.beforeRestoreToDelete(names), [
        'antes_de_restaurar_2026-11-01_1000.db',
      ]);
    });
  });

  group('próxima medianoche', () {
    test('es el siguiente día a las 00:00', () {
      expect(
        LocalBackupService.nextMidnight(DateTime(2026, 11, 13, 15, 30)),
        DateTime(2026, 11, 14),
      );
    });

    test('a las 00:00 en punto programa la del día siguiente', () {
      expect(
        LocalBackupService.nextMidnight(DateTime(2026, 11, 13)),
        DateTime(2026, 11, 14),
      );
    });

    test('cruza fin de mes y de año', () {
      expect(
        LocalBackupService.nextMidnight(DateTime(2026, 11, 30, 23, 59)),
        DateTime(2026, 12, 1),
      );
      expect(
        LocalBackupService.nextMidnight(DateTime(2026, 12, 31, 12)),
        DateTime(2027, 1, 1),
      );
    });
  });

  group('nombre de la tarea programada', () {
    test('días seguidos usan nombres distintos (aunque cambie el mes)', () {
      final names = [
        for (var day = 28; day <= 31; day++)
          backupTaskNameFor(DateTime(2026, 10, day)),
        backupTaskNameFor(DateTime(2026, 11, 1)),
        backupTaskNameFor(DateTime(2026, 11, 2)),
      ];

      for (var i = 1; i < names.length; i++) {
        expect(names[i], isNot(names[i - 1]));
      }
    });

    test('el mismo día siempre da el mismo nombre', () {
      expect(
        backupTaskNameFor(DateTime(2026, 11, 14)),
        backupTaskNameFor(DateTime(2026, 11, 14, 8)),
      );
    });
  });

  group('aviso de copia pendiente', () {
    final now = DateTime(2026, 11, 13, 12);

    test('sin cambios no avisa', () {
      expect(
        LocalBackupService.reminderDue(
          hasChanges: false,
          lastBackupAt: null,
          now: now,
        ),
        isFalse,
      );
    });

    test('con cambios y sin ninguna copia avisa', () {
      expect(
        LocalBackupService.reminderDue(
          hasChanges: true,
          lastBackupAt: null,
          now: now,
        ),
        isTrue,
      );
    });

    test('con cambios avisa solo si la última copia tiene un día o más', () {
      final recent = now.subtract(const Duration(hours: 5));
      final old = now.subtract(const Duration(days: 1));

      expect(
        LocalBackupService.reminderDue(
          hasChanges: true,
          lastBackupAt: recent.millisecondsSinceEpoch,
          now: now,
        ),
        isFalse,
      );
      expect(
        LocalBackupService.reminderDue(
          hasChanges: true,
          lastBackupAt: old.millisecondsSinceEpoch,
          now: now,
        ),
        isTrue,
      );
    });
  });

  test('la firma cambia con el tamaño o la fecha de modificación', () {
    final date = DateTime(2026, 11, 13, 10);

    expect(
      LocalBackupService.signatureOf(100, date),
      LocalBackupService.signatureOf(100, date),
    );
    expect(
      LocalBackupService.signatureOf(100, date),
      isNot(LocalBackupService.signatureOf(101, date)),
    );
    expect(
      LocalBackupService.signatureOf(100, date),
      isNot(LocalBackupService.signatureOf(100, date.add(const Duration(seconds: 1)))),
    );
  });
}
