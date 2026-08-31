import 'package:flutter/material.dart';

import '../shared/app_drawer.dart'; // 1. Añadimos el import

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventario')),
      drawer: const AppDrawer(),
      body: const Center(child: Text('Tabla de productos y stock')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
