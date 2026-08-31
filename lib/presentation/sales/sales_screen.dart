import 'dart:io';

import 'package:flutter/material.dart';

import '../shared/app_drawer.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/promotion.dart';
import '../../data/datasources/local_database_datasource.dart';
import '../../data/repositories/inventory_repository_impl.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final _repository = InventoryRepositoryImpl(LocalDatabaseDatasource());

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  double? _startX;
  double? _startY;

  List<Product> _products = [];
  Map<int, Promotion> _promotionsMap = {};
  bool _isLoading = true;

  final Map<Product, int> _cart = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final products = await _repository.getProducts();
    final promotions = await _repository.getPromotions();

    final Map<int, Promotion> promoMap = {for (var p in promotions) p.id!: p};

    setState(() {
      _products = products;
      _promotionsMap = promoMap;
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

  void _removeAllFromCart(Product product) {
    if (!_cart.containsKey(product)) return;

    setState(() {
      _cart.remove(product);
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} eliminado del carrito'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  double _calculateItemTotal(Product product, int qty) {
    if (product.promotionId == null ||
        !_promotionsMap.containsKey(product.promotionId)) {
      return product.price * qty;
    }

    final promo = _promotionsMap[product.promotionId!]!;

    if (promo.type == 'bundle_fixed_price') {
      final int bundles = qty ~/ promo.threshold;
      final int remainder = qty % promo.threshold;

      final double bundleTotal = bundles * promo.discountValue;
      final double remainderTotal = remainder * product.price;

      return bundleTotal + remainderTotal;
    } else if (promo.type == 'percentage') {
      if (qty >= promo.threshold) {
        final double discountedUnitPrice =
            product.price * (1 - (promo.discountValue / 100));
        return qty * discountedUnitPrice;
      }
    }

    return product.price * qty;
  }

  double get _cartTotal {
    return _cart.entries.fold(0.0, (total, entry) {
      return total + _calculateItemTotal(entry.key, entry.value);
    });
  }

  int get _cartItemCount {
    return _cart.entries.fold(0, (total, entry) => total + entry.value);
  }

  Future<void> _processSale() async {
    if (_cart.isEmpty) return;

    final saleItems = _cart.entries.map((entry) {
      final finalSubtotal = _calculateItemTotal(entry.key, entry.value);
      final effectiveUnitPrice = finalSubtotal / entry.value;

      return SaleItem(
        productId: entry.key.id!,
        quantity: entry.value,
        historicalPrice: effectiveUnitPrice,
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

    await _loadData();

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

  // Widget reutilizable para pintar la cuadrícula de productos
  Widget _buildProductGrid({
    required double bottomPadding,
    required int crossAxisCount,
  }) {
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(12, 12, 12, bottomPadding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.75,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        final hasStock = product.units > 0;
        final qtyInCart = _cart[product] ?? 0;
        final isInCart = qtyInCart > 0;

        Widget cardContent = Card(
          elevation: isInCart ? 6 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isInCart
                  ? Theme.of(context).primaryColor
                  : Colors.transparent,
              width: isInCart ? 3.0 : 0.0,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: product.imagePath != null
                    ? Image.file(File(product.imagePath!), fit: BoxFit.cover)
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
                padding: const EdgeInsets.all(6.0),
                child: Column(
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '${product.price.toStringAsFixed(2)} €',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
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
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
              if (isInCart)
                Positioned(
                  top: 4,
                  left: 4,
                  child: CircleAvatar(
                    radius: 13,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      '$qtyInCart',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              if (isInCart)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Material(
                    color: Colors.red.shade700,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _removeFromCart(product),
                      onLongPress: () => _removeAllFromCart(product),
                      child: const Padding(
                        padding: EdgeInsets.all(6.0),
                        child: Icon(
                          Icons.remove,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Widget reutilizable para la lista de elementos del carrito
  Widget _buildCartItemsList() {
    if (_cart.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 48.0),
        child: Center(
          child: Text(
            'El carrito está vacío',
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _cart.length,
      itemBuilder: (context, index) {
        final product = _cart.keys.elementAt(index);
        final qty = _cart[product]!;
        final itemTotal = _calculateItemTotal(product, qty);

        String? promoText;
        bool promoActive = false;
        if (product.promotionId != null &&
            _promotionsMap.containsKey(product.promotionId)) {
          final promo = _promotionsMap[product.promotionId!]!;
          promoText = promo.name;
          if ((promo.type == 'bundle_fixed_price' ||
                  promo.type == 'percentage') &&
              qty >= promo.threshold) {
            promoActive = true;
          }
        }

        return ListTile(
          title: Text(
            product.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${product.price.toStringAsFixed(2)} € x $qty uds'),
              if (promoText != null) ...[
                const SizedBox(height: 2),
                Text(
                  promoActive ? 'Oferta: $promoText' : 'Disponible: $promoText',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: promoActive ? Colors.amber.shade800 : Colors.grey,
                  ),
                ),
              ],
            ],
          ),
          isThreeLine: promoText != null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${itemTotal.toStringAsFixed(2)} €',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(
                  Icons.remove_circle,
                  color: Colors.redAccent,
                  size: 24,
                ),
                onPressed: () => _removeFromCart(product),
                onLongPress: () => _removeAllFromCart(product),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final bool isTablet = shortestSide >= 600;

    return Listener(
      onPointerDown: (event) {
        _startX = event.position.dx;
        _startY = event.position.dy;
      },
      onPointerMove: (event) {
        if (_startX == null || _startY == null) return;
        final dx = event.position.dx - _startX!;
        final dy = event.position.dy - _startY!;

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
        appBar: AppBar(title: const Text('Panel de Ventas (TPV)')),
        drawer: const AppDrawer(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : isTablet
            ?
              // --- DISEÑO TABLET: TPV DE DOBLE PANEL (SPLIT VIEW) ---
              Row(
                children: [
                  // Izquierda: Catálogo de productos (más ancho)
                  Expanded(
                    flex: 3,
                    child: _buildProductGrid(
                      bottomPadding: 16,
                      crossAxisCount: 4,
                    ),
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                  // Derecha: Panel de Carrito y Cobro fijo
                  Container(
                    width: 380,
                    color: Colors.white,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          color: Colors.grey.shade50,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Items: $_cartItemCount',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Total: ${_cartTotal.toStringAsFixed(2)} €',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(child: _buildCartItemsList()),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                              ),
                              onPressed: _cart.isEmpty ? null : _processSale,
                              child: const Text(
                                'COBRAR',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            :
              // --- DISEÑO MÓVIL: GRID + CARRITO FLOTANTE DESPLEGABLE ---
              Stack(
                children: [
                  _buildProductGrid(bottomPadding: 120, crossAxisCount: 3),
                  DraggableScrollableSheet(
                    initialChildSize: 0.12,
                    minChildSize: 0.12,
                    maxChildSize: 0.7,
                    builder: (BuildContext context, ScrollController scrollController) {
                      return LayoutBuilder(
                        builder: (context, constraints) {
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
                                  ListView(
                                    controller: scrollController,
                                    padding: EdgeInsets.only(
                                      top: 75,
                                      bottom: (isExpanded && _cart.isNotEmpty)
                                          ? 90
                                          : 20,
                                    ),
                                    children: [
                                      _cart.isEmpty
                                          ? const Padding(
                                              padding: EdgeInsets.only(
                                                top: 32.0,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  'El carrito está vacío',
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Column(
                                              children: _cart.keys.map((
                                                product,
                                              ) {
                                                final qty = _cart[product]!;
                                                final itemTotal =
                                                    _calculateItemTotal(
                                                      product,
                                                      qty,
                                                    );
                                                return ListTile(
                                                  title: Text(product.name),
                                                  subtitle: Text(
                                                    '${product.price.toStringAsFixed(2)} € x $qty uds',
                                                  ),
                                                  trailing: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        '${itemTotal.toStringAsFixed(2)} €',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      GestureDetector(
                                                        onTap: () =>
                                                            _removeFromCart(
                                                              product,
                                                            ),
                                                        onLongPress: () =>
                                                            _removeAllFromCart(
                                                              product,
                                                            ),
                                                        child: const Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                8.0,
                                                              ),
                                                          child: Icon(
                                                            Icons.remove_circle,
                                                            color: Colors
                                                                .redAccent,
                                                            size: 28,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                    ],
                                  ),
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    child: IgnorePointer(
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
                                              padding:
                                                  const EdgeInsets.symmetric(
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
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Total: ${_cartTotal.toStringAsFixed(2)} €',
                                                    style: TextStyle(
                                                      fontSize: 22,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                              padding:
                                                  const EdgeInsets.symmetric(
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
      ),
    );
  }
}
