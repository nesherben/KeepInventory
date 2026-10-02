import 'dart:io';

import 'package:flutter/material.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../domain/pack.dart';

class PackListItem extends StatelessWidget {
  final Pack pack;
  final Function(Pack) onEdit;
  final Function(Pack) onDelete;
  final Function(Pack, int) onQuickAdjust;

  const PackListItem({
    super.key,
    required this.pack,
    required this.onEdit,
    required this.onDelete,
    required this.onQuickAdjust,
  });

  @override
  Widget build(BuildContext context) {
    // ACTUALIZADO: Comprobamos si tiene binario (BLOB) O archivo físico
    final bool hasValidImage =
        (pack.imageBytes != null) ||
        (pack.imagePath != null && File(pack.imagePath!).existsSync());

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: hasValidImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                // ACTUALIZADO: Lógica de dibujado híbrida
                child: pack.imageBytes != null
                    ? Image.memory(
                        pack.imageBytes!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        File(pack.imagePath!),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        // 💡 EL PARACAÍDAS
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[200], // Fondo gris clarito
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                              size: 24,
                            ),
                          );
                        },
                      ),
              )
            : Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.card_giftcard,
                  color: Colors.teal,
                  size: 26,
                ),
              ),
        title: Text(
          pack.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              Text(
                '${pack.price.toStringAsFixed(2)} €',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 10),
              // CONTROL RÁPIDO DE UNIDADES MONTADAS (+ / -)
              Container(
                decoration: BoxDecoration(
                  color: pack.units > 0
                      ? Colors.teal.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: pack.units > 0
                        ? Colors.teal.shade200
                        : Colors.red.shade200,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: pack.units > 0
                          ? () => onQuickAdjust(pack, -1)
                          : null,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        child: Icon(
                          Icons.remove,
                          size: 16,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    Text(
                      context.l10n.packUnitCount(pack.units.toString()),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: pack.units > 0
                            ? Colors.teal.shade900
                            : Colors.red.shade900,
                      ),
                    ),
                    InkWell(
                      onTap: () => onQuickAdjust(pack, 1),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        child: Icon(Icons.add, size: 16, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => onEdit(pack),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => onDelete(pack),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                Text(
                  context.l10n.packComponentsPerUnit,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                ...pack.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '• ${item.productName ?? context.l10n.unknownDeleted}',
                            style: const TextStyle(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.l10n.packComponentCount(
                            item.quantity.toString(),
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
