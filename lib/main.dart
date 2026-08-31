import 'package:flutter/material.dart';
import 'package:keepinventory/presentation/promotions/promotions_screen.dart';

import 'presentation/dashboard/dashboard_screen.dart';
import 'presentation/inventory/inventory_screen.dart';
import 'presentation/sales/sales_screen.dart';
import 'presentation/history/history_screen.dart';
import 'presentation/packs/packs_screen.dart';

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
