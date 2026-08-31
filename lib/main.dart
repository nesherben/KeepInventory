import 'package:flutter/material.dart';

// Importaciones de las pantallas de la capa de presentación
import 'presentation/dashboard/dashboard_screen.dart';
import 'presentation/inventory/inventory_screen.dart';
import 'presentation/sales/sales_screen.dart';

void main() async {
  // Asegura que los bindings de Flutter estén listos antes de inicializar bases de datos o servicios
  WidgetsFlutterBinding.ensureInitialized();

  // Aquí inicializaremos SQLite y la inyección de dependencias más adelante

  runApp(const KeepInventoryApp());
}

class KeepInventoryApp extends StatelessWidget {
  const KeepInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KeepInventory',
      debugShowCheckedModeBanner: false, // Oculta la etiqueta de "DEBUG"
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
        ), // Un color base profesional para POS
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 2),
      ),
      // Configuramos el Dashboard como la ruta raíz (pantalla principal)
      initialRoute: '/',
      routes: {
        '/': (context) => const DashboardScreen(),
        '/inventory': (context) => const InventoryScreen(),
        '/sales': (context) => const SalesScreen(),
      },
    );
  }
}
