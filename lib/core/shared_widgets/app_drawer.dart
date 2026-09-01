import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).colorScheme.primary;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'KeepInventory',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Gestión y POS',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // --- SECCIÓN 1: PRINCIPAL Y VENTAS ---
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'PRINCIPAL',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard_outlined, color: iconColor),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
          ListTile(
            leading: Icon(Icons.point_of_sale_outlined, color: iconColor),
            title: const Text('Panel de Ventas (TPV)'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/sales');
            },
          ),

          const Divider(height: 24, indent: 16, endIndent: 16),

          // --- SECCIÓN 2: ALMACÉN Y CATÁLOGO ---
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'ALMACÉN Y OFERTAS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.inventory_2_outlined, color: iconColor),
            title: const Text('Gestión de Inventario'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/inventory');
            },
          ),
          ListTile(
            leading: Icon(Icons.local_offer_outlined, color: iconColor),
            title: const Text('Gestor de Promociones'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/promotions');
            },
          ),
          ListTile(
            leading: Icon(Icons.card_giftcard, color: iconColor),
            title: const Text('Packs y Bundles'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/packs');
            },
          ),
          const Divider(height: 24, indent: 16, endIndent: 16),

          // --- SECCIÓN 3: HISTORIAL Y REGISTROS ---
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'REGISTROS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.history_outlined, color: iconColor),
            title: const Text('Historial y Ferias'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/history');
            },
          ),
        ],
      ),
    );
  }
}
