import 'package:flutter/material.dart';

import '../../../core/shared_widgets/app_drawer.dart';
import '../../../core/shared_widgets/app_alerts.dart'; // 💡 Sistema de alertas en cola

import '../data/repositories/promotion_repository_impl.dart';
import '../domain/promotion.dart';
import '../data/datasources/promotion_local_datasource.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  final _repository = PromotionRepositoryImpl(PromotionLocalDatasource());

  // Llave y variables para el gesto global de deslizamiento
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  double? _startX;
  double? _startY;

  List<Promotion> _promotions = [];
  bool _isLoading = true;
  String _searchQuery = ''; // 💡 Variable para el buscador

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPromotions() async {
    setState(() => _isLoading = true);
    final promotions = await _repository.getPromotions();
    if (!mounted) return;
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
            final isLandscape =
                MediaQuery.of(context).size.width >
                MediaQuery.of(context).size.height;
            final fieldWidth = isLandscape ? 320.0 : 520.0;

            return AlertDialog(
              title: Text(isEditing ? 'Editar Promoción' : 'Nueva Promoción'),
              content: SizedBox(
                width: isLandscape ? 680 : 520,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: fieldWidth,
                          child: TextFormField(
                            initialValue: name,
                            decoration: const InputDecoration(
                              labelText: 'Nombre de la oferta',
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Requerido'
                                : null,
                            onSaved: (value) => name = value!,
                          ),
                        ),
                        SizedBox(
                          width: fieldWidth,
                          child: DropdownButtonFormField<String>(
                            initialValue: type,
                            decoration: const InputDecoration(
                              labelText: 'Tipo de Promoción',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'bundle_fixed_price',
                                child: Text('Precio fijo por lote'),
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
                        ),
                        SizedBox(
                          width: fieldWidth,
                          child: TextFormField(
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
                        ),
                        SizedBox(
                          width: fieldWidth,
                          child: TextFormField(
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
                                    double.tryParse(
                                          value.replaceAll(',', '.'),
                                        ) ==
                                        null
                                ? 'Valor válido requerido'
                                : null,
                            onSaved: (value) => discountValue = double.parse(
                              value!.replaceAll(',', '.'),
                            ),
                          ),
                        ),
                      ],
                    ),
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
                        // 💡 Alerta de éxito unificada
                        AppAlerts.showSuccess(
                          context,
                          isEditing
                              ? '✨ ¡Promoción actualizada con éxito!'
                              : '🎉 ¡Promoción creada con éxito!',
                        );
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

  // --- DIÁLOGO DE CONFIRMACIÓN DE BORRADO ---
  void _confirmDelete(Promotion promotion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Promoción'),
        content: Text(
          '¿Seguro que deseas eliminar la promoción "${promotion.name}"? Los productos vinculados se quedarán sin promoción.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              await _repository.deletePromotion(promotion.id!);
              if (context.mounted) {
                Navigator.pop(context);
                _loadPromotions();
                // 💡 Alerta de advertencia/borrado
                AppAlerts.showWarning(
                  context,
                  '🗑️ Promoción eliminada correctamente.',
                );
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 💡 Filtrado instantáneo por texto
    final filteredPromotions = _promotions.where((promo) {
      return promo.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

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
            : Column(
                children: [
                  // --- 💡 BARRA DE BÚSQUEDA ---
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Buscar promoción por nombre...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                      ),
                    ),
                  ),

                  // --- LISTADO DE PROMOCIONES ---
                  Expanded(
                    child: filteredPromotions.isEmpty
                        ? Center(
                            child: Text(
                              _promotions.isEmpty
                                  ? 'No hay promociones creadas. Crea una con el botón +'
                                  : 'No se encontraron promociones con ese nombre.',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: filteredPromotions.length,
                            itemBuilder: (context, index) {
                              final promo = filteredPromotions[index];
                              final isBundle =
                                  promo.type == 'bundle_fixed_price';

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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
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
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () =>
                                            _showPromotionFormDialog(
                                              promotionToEdit: promo,
                                            ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _confirmDelete(promo),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showPromotionFormDialog(),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
