import 'package:flutter/material.dart';

import '../shared/app_drawer.dart'; // 1. Añadimos el import

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel de Ventas')),
      drawer: const AppDrawer(),
      body: const Center(child: Text('Panel de comandas y cobro')),
    );
  }
}
