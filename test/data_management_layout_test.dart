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
  testWidgets('en móvil la sincronización por QR va lo primero', (
    tester,
  ) async {
    final l10n = await _pump(tester, const Size(400, 900));

    final qr = tester.getTopLeft(find.text(l10n.syncByQrTitle));
    final backup = tester.getTopLeft(find.text(l10n.backupNowTitle));

    expect(qr.dy, lessThan(backup.dy));
  });

  testWidgets('en tablet hay dos columnas: QR y copias a la izquierda, Drive '
      'a la derecha', (tester) async {
    final l10n = await _pump(tester, const Size(1280, 900));

    final qr = tester.getTopLeft(find.text(l10n.syncByQrTitle));
    final drive = tester.getTopLeft(
      find.text(l10n.driveSectionTitle.toUpperCase()),
    );

    // Drive empieza arriba, a la derecha de la tarjeta del QR
    expect(drive.dx, greaterThan(qr.dx + 300));
    expect(drive.dy, lessThan(qr.dy));
  });
}
