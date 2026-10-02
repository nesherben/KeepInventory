import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/features/dashboard/presentation/widgets/update_available_dialog.dart';
import 'package:keepinventory/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('reports download progress and failure', (tester) async {
    const locale = Locale('es');
    final localizations = await AppLocalizations.delegate.load(locale);
    final downloadResult = Completer<bool>();
    var failureShown = false;

    await tester.pumpWidget(
      _TestApp(
        locale: locale,
        dialog: UpdateAvailableDialog(
          version: '2.0.0',
          notes: 'Cambios incluidos',
          url: 'https://example.invalid/update.apk',
          download: (url, onProgress) {
            expect(url, 'https://example.invalid/update.apk');
            onProgress(0.45);
            return downloadResult.future;
          },
          onDownloadFailure: () => failureShown = true,
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(localizations.updateNow));
    await tester.pump();

    expect(find.text(localizations.updateDownloading('45')), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    downloadResult.complete(false);
    await tester.pumpAndSettle();
    expect(failureShown, isTrue);
  });

  testWidgets('closes without starting a download when later is chosen', (
    tester,
  ) async {
    const locale = Locale('es');
    final localizations = await AppLocalizations.delegate.load(locale);
    var downloadStarted = false;

    await tester.pumpWidget(
      _TestApp(
        locale: locale,
        dialog: UpdateAvailableDialog(
          version: '2.0.0',
          notes: 'Cambios incluidos',
          url: 'https://example.invalid/update.apk',
          download: (_, _) async {
            downloadStarted = true;
            return true;
          },
          onDownloadFailure: () {},
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(localizations.later));
    await tester.pumpAndSettle();

    expect(downloadStarted, isFalse);
    expect(find.text(localizations.updateAvailableBody), findsNothing);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.locale, required this.dialog});

  final Locale locale;
  final Widget dialog;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () =>
                showDialog<void>(context: context, builder: (_) => dialog),
            child: const Text('Abrir'),
          ),
        ),
      ),
    );
  }
}
