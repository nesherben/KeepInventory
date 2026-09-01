import 'package:flutter/material.dart';

import 'app_drawer.dart';

class MainScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const MainScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AQUÍ CONFIGURAMOS EL GESTO UNA SOLA VEZ PARA TODA LA APP
      drawerEdgeDragWidth: 120.0,
      appBar: AppBar(title: Text(title), elevation: 0, actions: actions),
      drawer: const AppDrawer(),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
