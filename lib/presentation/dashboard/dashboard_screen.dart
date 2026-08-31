import 'package:flutter/material.dart';

import '../shared/app_drawer.dart'; // 1. Añadimos el import

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      drawer: const AppDrawer(), // 2. Añadimos el drawer aquí
      body: const Center(
        child: Text('Desglose de ingresos, gastos y beneficios'),
      ),
    );
  }
}
