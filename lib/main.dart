import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';

import 'core/database/database_helper.dart';
import 'core/services/image_migration_service.dart';
import 'core/theme/app_theme.dart';

import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/inventory/presentation/inventory_screen.dart';
import 'features/packs/presentation/packs_screen.dart';
import 'features/promotions/presentation/promotions_screen.dart';
import 'features/sales/presentation/history_screen.dart';
import 'features/sales/presentation/sales_screen.dart';

// 💡 Importamos el Drawer para acceder a su ValueNotifier del tema
import 'core/shared_widgets/app_drawer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Forzamos la inicialización de la base de datos
  await DatabaseHelper.instance.database;

  // 2. Ejecutamos el script de migración de imágenes
  await ImageMigrationService.migrateImagesToDb();

  // 3. 💡 Cargamos el tema guardado antes de arrancar la interfaz
  await AppDrawer.loadSavedTheme();

  runApp(const KeepInventoryApp());
}

class KeepInventoryApp extends StatelessWidget {
  const KeepInventoryApp({super.key});

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
              theme: AppTheme.light(dynamicPrimary: effectiveLightPrimary),
              darkTheme: AppTheme.dark(dynamicPrimary: effectiveDarkPrimary),
              themeMode: ThemeMode.system,
              initialRoute: '/',
              routes: {
                '/': (context) => const DashboardScreen(),
                '/inventory': (context) => const InventoryScreen(),
                '/sales': (context) => const SalesScreen(),
                '/history': (context) => const HistoryScreen(),
                '/promotions': (context) => const PromotionsScreen(),
                '/packs': (context) => const PacksScreen(),
              },
            );
          },
        );
      },
    );
  }
}
