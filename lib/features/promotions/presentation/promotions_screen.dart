import 'package:flutter/material.dart';

import '../../../core/shared_widgets/app_drawer.dart';
import '../domain/promotion.dart';
import '../data/datasources/promotion_local_datasource.dart';
import '../domain/repositories/promotion_repository_impl.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  final _repository = PromotionRepositoryImpl(PromotionLocalDatasource());

  // Llave y variables para el gesto global de deslizamiento
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  double? _startX;
  double? _startY;

  List<Promotion> _promotions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    setState(() => _isLoading = true);
    final promotions = await _repository.getPromotions();
    setState(() {
      _promotions = promotions;
      _isLoading = false;
    });
  }

  void _showPromotionFormDialog({Promotion? promotionToEdit}) {
    final formKey = GlobalKey<FormState>();
    final isEditing = promotionToEdit != null;

    String name = isEditing ? promotionToEdit.name : '';
    String type = isEditing ? promotionToEdit.type : 'bundle_fixed_price';
    int threshold = isEditing ? promotionToEdit.threshold : 3;
    double discountValue = isEditing ? promotionToEdit.discountValue : 0.0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Editar Promoción' : 'Nueva Promoción'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        initialValue: name,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de la oferta (ej: Pack 3x12€)',
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Requerido' : null,
                        onSaved: (value) => name = value!,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: type,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Promoción',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'bundle_fixed_price',
                            child: Text('Precio fijo por lote (Ej: 3 por 12€)'),
                          ),
                          DropdownMenuItem(
                            value: 'percentage',
                            child: Text('Descuento porcentual (%)'),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() => type = value!);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: threshold.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Cantidad mínima (Unidades a llevar)',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value == null || int.tryParse(value) == null
                            ? 'Número válido requerido'
                            : null,
                        onSaved: (value) => threshold = int.parse(value!),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: discountValue == 0.0
                            ? ''
                            : discountValue.toString(),
                        decoration: InputDecoration(
                          labelText: type == 'bundle_fixed_price'
                              ? 'Precio total del lote (€)'
                              : 'Porcentaje de descuento (%)',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) =>
                            value == null ||
                                double.tryParse(value.replaceAll(',', '.')) ==
                                    null
                            ? 'Valor válido requerido'
                            : null,
                        onSaved: (value) => discountValue = double.parse(
                          value!.replaceAll(',', '.'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();

                      final newPromo = Promotion(
                        id: isEditing ? promotionToEdit.id : null,
                        name: name,
                        type: type,
                        threshold: threshold,
                        discountValue: discountValue,
                      );

                      if (isEditing) {
                        await _repository.updatePromotion(newPromo);
                      } else {
                        await _repository.insertPromotion(newPromo);
                      }

                      if (context.mounted) {
                        Navigator.pop(context);
                        _loadPromotions();
                      }
                    }
                  },
                  child: Text(isEditing ? 'Actualizar' : 'Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deletePromotion(int id) async {
    await _repository.deletePromotion(id);
    _loadPromotions();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        _startX = event.position.dx;
        _startY = event.position.dy;
      },
      onPointerMove: (event) {
        if (_startX == null || _startY == null) return;
        final dx = event.position.dx - _startX!;
        final dy = event.position.dy - _startY!;

        // Gesto horizontal hacia la derecha de más de 50px sin desviación vertical excesiva
        if (dx > 50 && dy.abs() < 30) {
          _startX = null;
          _startY = null;
          _scaffoldKey.currentState?.openDrawer();
        }
      },
      onPointerUp: (_) {
        _startX = null;
        _startY = null;
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(title: const Text('Gestor de Promociones')),
        drawer: const AppDrawer(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _promotions.isEmpty
            ? const Center(
                child: Text(
                  'No hay promociones creadas. Crea una con el botón +',
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _promotions.length,
                itemBuilder: (context, index) {
                  final promo = _promotions[index];
                  final isBundle = promo.type == 'bundle_fixed_price';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.amber[700],
                        child: const Icon(
                          Icons.local_offer,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        promo.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        isBundle
                            ? 'Llevando ${promo.threshold} unidades por ${promo.discountValue.toStringAsFixed(2)} €'
                            : '${promo.discountValue.toStringAsFixed(0)}% de descuento a partir de ${promo.threshold} uds.',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showPromotionFormDialog(
                              promotionToEdit: promo,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deletePromotion(promo.id!),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showPromotionFormDialog(),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
