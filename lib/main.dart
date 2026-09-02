import 'package:flutter/material.dart';

import 'core/database/database_helper.dart';
import 'core/services/image_migration_service.dart';

import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/inventory/presentation/inventory_screen.dart';
import 'features/packs/presentation/packs_screen.dart';
import 'features/promotions/presentation/promotions_screen.dart';
import 'features/sales/presentation/history_screen.dart';
import 'features/sales/presentation/sales_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Forzamos la inicialización de la base de datos
  await DatabaseHelper.instance.database;

  // 2. Ejecutamos el script que comprime y guarda las imágenes en BLOB
  await ImageMigrationService.migrateImagesToDb();

  runApp(const KeepInventoryApp());
}

class KeepInventoryApp extends StatelessWidget {
  const KeepInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KeepInventory',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 2),
      ),
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
  }
}
