import 'package:flutter/material.dart';

import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/inventory/presentation/inventory_screen.dart';
import 'features/packs/presentation/packs_screen.dart';
import 'features/promotions/presentation/promotions_screen.dart';
import 'features/sales/presentation/history_screen.dart';
import 'features/sales/presentation/sales_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
