import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:keepinventory/l10n/generated/app_localizations.dart';

import 'core/database/database_helper.dart';
import 'core/services/app_preferences.dart';
import 'core/services/backup_coordinator.dart';
import 'core/services/backup_scheduler.dart';
import 'core/services/backup_validator.dart';
import 'core/services/image_migration_service.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_locale_resolution.dart';

import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/inventory/presentation/inventory_screen.dart';
import 'features/packs/presentation/packs_screen.dart';
import 'features/promotions/presentation/promotions_screen.dart';
import 'features/sales/presentation/history_screen.dart';
import 'features/sales/presentation/sales_screen.dart';

// 💡 Importamos el Drawer para acceder a su ValueNotifier del tema
import 'core/shared_widgets/app_drawer.dart';
import 'features/sync/presentation/data_management_screen.dart';
import 'features/sync/presentation/first_run_restore_screen.dart';
import 'features/tutorial/presentation/tutorial_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Forzamos la inicialización de la base de datos
  await DatabaseHelper.instance.database;

  // 2. Ejecutamos el script de migración de imágenes
  await ImageMigrationService.migrateImagesToDb();

  // 3. 💡 Cargamos el tema guardado antes de arrancar la interfaz
  await AppDrawer.loadSavedTheme();
  await AppPreferences.load();

  // 4. Copia automática: tarea de las 00:00 y decisión de primer arranque
  await BackupScheduler.initialize();
  // Instalación nueva (sin tutorial visto y BD vacía): se ofrece restaurar
  final firstRun =
      !AppPreferences.tutorialSeen &&
      !await BackupValidator.currentDatabaseHasData();

  runApp(KeepInventoryApp(firstRun: firstRun));
  BackupCoordinator.onAppStarted();
}

class KeepInventoryApp extends StatefulWidget {
  const KeepInventoryApp({super.key, this.firstRun = false});

  /// Abre la pantalla de "¿Tienes una copia?" antes del tutorial.
  final bool firstRun;

  @override
  State<KeepInventoryApp> createState() => _KeepInventoryAppState();
}

class _KeepInventoryAppState extends State<KeepInventoryApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Copia silenciosa al pasar a segundo plano; al volver, se relee el estado
    if (state == AppLifecycleState.paused) {
      BackupCoordinator.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      BackupCoordinator.onAppStarted();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 💡 Envolvemos la app en un ValueListenableBuilder para escuchar los toques del huevo de pascua
    return ValueListenableBuilder<Color?>(
      valueListenable: AppDrawer.customThemeNotifier,
      builder: (context, customColor, child) {
        return DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) {
            // Si el usuario eligió un color personalizado en el huevo de pascua, tiene prioridad.
            // Si no, usa el color dinámico del sistema (Android 12+) o el por defecto de AppTheme.
            final effectiveLightPrimary = customColor ?? lightDynamic?.primary;
            final effectiveDarkPrimary = customColor ?? darkDynamic?.primary;

            return MaterialApp(
              title: 'KeepInventory',
              debugShowCheckedModeBanner: false,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              // Idioma del dispositivo (por orden de preferencia); si no hay
              // traducción, inglés
              localeListResolutionCallback: resolveAppLocaleList,
              theme: AppTheme.light(dynamicPrimary: effectiveLightPrimary),
              darkTheme: AppTheme.dark(dynamicPrimary: effectiveDarkPrimary),
              themeMode: ThemeMode.system,
              // El primer arranque abre el tutorial de bienvenida
              initialRoute: widget.firstRun
                  ? '/first-run'
                  : AppPreferences.tutorialSeen
                  ? '/'
                  : '/tutorial',
              routes: {
                '/': (context) => const DashboardScreen(),
                '/inventory': (context) => const InventoryScreen(),
                '/sales': (context) => const SalesScreen(),
                '/history': (context) => const HistoryScreen(),
                '/promotions': (context) => const PromotionsScreen(),
                '/packs': (context) => const PacksScreen(),
                '/data-management': (context) => const DataManagementScreen(),
                '/tutorial': (context) => const TutorialScreen(),
                '/first-run': (context) => const FirstRunRestoreScreen(),
              },
            );
          },
        );
      },
    );
  }
}
