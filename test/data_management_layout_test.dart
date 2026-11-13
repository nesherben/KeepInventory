import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/features/sync/presentation/data_management_screen.dart';
import 'package:keepinventory/l10n/generated/app_localizations.dart';

Future<AppLocalizations> _pump(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const DataManagementScreen(),
    ),
  );
  await tester.pump();
  return AppLocalizations.delegate.load(const Locale('es'));
}

void main() {
  testWidgets('en móvil QR va primero y borrar queda al final', (tester) async {
    final l10n = await _pump(tester, const Size(400, 900));

    final qr = tester.getTopLeft(find.text(l10n.syncByQrTitle));
    final backup = tester.getTopLeft(find.text(l10n.backupNowTitle));
    final daily = tester.getTopLeft(find.text(l10n.backupAutoTitle));
    final drive = tester.getTopLeft(
      find.text(l10n.driveSectionTitle.toUpperCase()),
    );
    final restore = tester.getTopLeft(
      find.text(l10n.backupRestoreChooseAction),
    );
    final delete = tester.getTopLeft(find.text(l10n.databaseDeleteTitle));

    expect(qr.dy, lessThan(backup.dy));
    expect(backup.dy, lessThan(daily.dy));
    expect(daily.dy, lessThan(restore.dy));
    expect(restore.dy, lessThan(drive.dy));
    expect(drive.dy, lessThan(delete.dy));
    expect(find.text(l10n.driveUploadTitle), findsNothing);
  });

  testWidgets('en tablet la tarjeta de copias queda a la izquierda; '
      'copia diaria, restauración y Google a la derecha', (tester) async {
    final l10n = await _pump(tester, const Size(1280, 900));

    final qr = tester.getTopLeft(find.text(l10n.syncByQrTitle));
    final backup = tester.getTopLeft(find.text(l10n.backupNowTitle));
    final daily = tester.getTopLeft(find.text(l10n.backupAutoTitle));
    final drive = tester.getTopLeft(
      find.text(l10n.driveSectionTitle.toUpperCase()),
    );
    final restore = tester.getTopLeft(
      find.text(l10n.backupRestoreChooseAction),
    );
    final delete = tester.getTopLeft(find.text(l10n.databaseDeleteTitle));

    expect(backup.dy, greaterThan(qr.dy));
    expect(drive.dy, greaterThan(qr.dy));
    expect(backup.dx, lessThan(daily.dx));
    expect(restore.dy, greaterThan(daily.dy));
    expect(daily.dx, greaterThan(backup.dx));
    expect(restore.dx, greaterThan(backup.dx));
    expect(drive.dx, greaterThan(backup.dx));
    expect(find.text(l10n.driveUploadTitle), findsNothing);
    expect(delete.dy, greaterThan(backup.dy));
    expect(delete.dy, greaterThan(drive.dy));
    expect(delete.dy, greaterThan(restore.dy));
  });
}
