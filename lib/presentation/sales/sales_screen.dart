import 'dart:io';

import 'package:flutter/material.dart';

import '../shared/app_drawer.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/sale.dart';
import '../../data/datasources/local_database_datasource.dart';
import '../../data/repositories/inventory_repository_impl.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final _repository = InventoryRepositoryImpl(LocalDatabaseDatasource());

  List<Product> _products = [];
  bool _isLoading = true;

  final Map<Product, int> _cart = {};

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final products = await _repository.getProducts();
    setState(() {
      _products = products;
      _isLoading = false;
    });
  }

  void _addToCart(Product product) {
    final currentQtyInCart = _cart[product] ?? 0;

    if (currentQtyInCart >= product.units) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay más stock disponible de este producto.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _cart[product] = currentQtyInCart + 1;
    });
  }

  void _removeFromCart(Product product) {
    if (!_cart.containsKey(product)) return;

    setState(() {
      if (_cart[product]! > 1) {
        _cart[product] = _cart[product]! - 1;
      } else {
        _cart.remove(product);
      }
    });
  }

  double get _cartTotal {
    return _cart.entries.fold(
      0.0,
      (total, entry) => total + (entry.key.price * entry.value),
    );
  }

  int get _cartItemCount {
    return _cart.entries.fold(0, (total, entry) => total + entry.value);
  }

  Future<void> _processSale() async {
    if (_cart.isEmpty) return;

    final saleItems = _cart.entries.map((entry) {
      return SaleItem(
        productId: entry.key.id!,
        quantity: entry.value,
        historicalPrice: entry.key.price,
      );
    }).toList();

    final sale = Sale(
      date: DateTime.now(),
      totalAmount: _cartTotal,
      items: saleItems,
    );

    await _repository.processSale(sale);

    setState(() {
      _cart.clear();
    });

    await _loadProducts();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Cobro realizado con éxito!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel de Ventas')),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // CAPA INFERIOR: El Grid con los productos
                GridView.builder(
                  padding: const EdgeInsets.only(
                    left: 8,
                    right: 8,
                    top: 8,
                    bottom: 120,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    final hasStock = product.units > 0;

                    Widget cardContent = Card(
                      elevation: 2,
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: product.imagePath != null
                                ? Image.file(
                                    File(product.imagePath!),
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.inventory,
                                      color: Colors.grey,
                                      size: 40,
                                    ),
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  '${product.price.toStringAsFixed(2)} €',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );

                    if (!hasStock) {
                      return GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Este producto está sin stock.'),
                              backgroundColor: Colors.redAccent,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: ColorFiltered(
                          colorFilter: const ColorFilter.matrix([
                            0.2126,
                            0.7152,
                            0.0722,
                            0,
                            0,
                            0.2126,
                            0.7152,
                            0.0722,
                            0,
                            0,
                            0.2126,
                            0.7152,
                            0.0722,
                            0,
                            0,
                            0,
                            0,
                            0,
                            1,
                            0,
                          ]),
                          child: Opacity(opacity: 0.6, child: cardContent),
                        ),
                      );
                    }

                    return InkWell(
                      onTap: () => _addToCart(product),
                      child: Stack(
                        children: [
                          Positioned.fill(child: cardContent),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${product.units}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          if (_cart.containsKey(product))
                            Positioned(
                              top: 4,
                              left: 4,
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: Theme.of(context).primaryColor,
                                child: Text(
                                  '${_cart[product]}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),

                // CAPA SUPERIOR: El carrito desplegable
                DraggableScrollableSheet(
                  initialChildSize: 0.12,
                  minChildSize: 0.12,
                  maxChildSize: 0.7,
                  builder: (BuildContext context, ScrollController scrollController) {
                    // LayoutBuilder nos da la altura real del panel en cada momento
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        // Consideramos que está "desplegado" si supera los 150 píxeles de alto
                        final bool isExpanded = constraints.maxHeight > 150;

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                spreadRadius: 2,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                            child: Stack(
                              children: [
                                // 1. LA LISTA SCROLLEABLE (Fondo)
                                ListView.builder(
                                  controller: scrollController,
                                  // Ajustamos el margen inferior para que no quede tapado por el botón
                                  padding: EdgeInsets.only(
                                    top: 75,
                                    bottom: (isExpanded && _cart.isNotEmpty)
                                        ? 90
                                        : 20,
                                  ),
                                  itemCount: _cart.isEmpty ? 1 : _cart.length,
                                  itemBuilder: (context, index) {
                                    if (_cart.isEmpty) {
                                      return const Padding(
                                        padding: EdgeInsets.only(top: 32.0),
                                        child: Center(
                                          child: Text(
                                            'El carrito está vacío',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    final product = _cart.keys.elementAt(index);
                                    final qty = _cart[product]!;
                                    return ListTile(
                                      title: Text(product.name),
                                      subtitle: Text(
                                        '${product.price.toStringAsFixed(2)} € x $qty',
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${(product.price * qty).toStringAsFixed(2)} €',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.remove_circle,
                                              color: Colors.redAccent,
                                            ),
                                            onPressed: () =>
                                                _removeFromCart(product),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),

                                // 2. LA CABECERA FIJA (Arriba)
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  child: IgnorePointer(
                                    // Deja pasar el toque hacia la lista
                                    child: Container(
                                      color: Colors.white,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SizedBox(height: 8),
                                          Container(
                                            width: 40,
                                            height: 5,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[400],
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24.0,
                                              vertical: 12.0,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Items: $_cartItemCount',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  'Total: ${_cartTotal.toStringAsFixed(2)} €',
                                                  style: TextStyle(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context)
                                                        .primaryColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Divider(height: 1),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // 3. EL BOTÓN FIJO (Abajo del todo, solo si está desplegado y hay items)
                                if (isExpanded && _cart.isNotEmpty)
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(16.0),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border(
                                          top: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                      ),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            backgroundColor: Theme.of(context)
                                                .primaryColor,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                          ),
                                          onPressed: _processSale,
                                          child: const Text(
                                            'COBRAR',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
    );
  }
}
