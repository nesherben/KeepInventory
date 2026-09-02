import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart'; // 💡 NUEVO IMPORT

import '../services/database_backup_service.dart';

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 💡 AQUÍ ESTÁ LA MAGIA: Un Row para poner la versión junto al nombre
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'KeepInventory',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder: (context, snapshot) {
                        final version = snapshot.hasData
                            ? snapshot.data!.version
                            : '';
                        if (version.isEmpty) return const SizedBox.shrink();

                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: 4.0,
                          ), // Lo alineamos a la base del texto grande
                          child: Text(
                            'v$version',
                            style: const TextStyle(
                              color: Colors
                                  .white70, // Discreto y un poco translúcido
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
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
          const Divider(height: 24, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.backup, color: Colors.teal),
            title: const Text('Hacer copia de seguridad'),
            subtitle: const Text('Exporta tu base de datos actual'),
            onTap: () async {
              bool success = await DatabaseBackupService.exportDatabase();
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '¡Copia generada correctamente! Guárdala bien.',
                    ),
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.restore, color: Colors.amber),
            title: const Text('Restaurar base de datos'),
            subtitle: const Text('Carga un archivo .db guardado'),
            onTap: () async {
              // 1. Guardamos las referencias de forma segura ANTES del await
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final currentRoute = ModalRoute.of(context)?.settings.name ?? '/';

              // Cerramos el Drawer
              navigator.pop();

              // 2. Esperamos a que termine la importación nativa
              bool success = await DatabaseBackupService.importDatabase();

              // 3. Usamos las referencias guardadas con total seguridad
              if (success) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('¡Base de datos restaurada con éxito!'),
                  ),
                );
                // Recargamos la ruta actual para refrescar la UI al instante
                navigator.pushReplacementNamed(currentRoute);
              } else {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('No se seleccionó ningún archivo.'),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
