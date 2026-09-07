import 'package:flutter/material.dart';

import '../../../core/shared_widgets/app_drawer.dart';
import '../../../core/shared_widgets/app_alerts.dart';

// --- IMPORTS MODULARES ---
// Sales
import '../../inventory/data/repositories/product_repository_impl.dart';
import '../../packs/data/repositories/pack_repository_impl.dart';
import '../../promotions/data/repositories/promotion_repository_impl.dart';
import '../data/repositories/sale_repository_imp.dart';
import '../domain/sale.dart';
import '../data/datasources/sale_local_datasource.dart';

// Inventory (Products)
import '../../inventory/domain/product.dart';
import '../../inventory/data/datasources/product_local_datasource.dart';

// Packs
import '../../packs/domain/pack.dart';
import '../../packs/data/datasources/pack_local_datasource.dart';

// Promotions
import '../../promotions/domain/promotion.dart';
import '../../promotions/data/datasources/promotion_local_datasource.dart';

// Widget Composition
import 'widgets/product_grid_widget.dart';
import 'widgets/packs_grid_widget.dart';
import 'widgets/cart_items_list_widget.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _saleRepository = SaleRepositoryImpl(SaleLocalDatasource());
  final _productRepository = ProductRepositoryImpl(ProductLocalDatasource());
  final _packRepository = PackRepositoryImpl(PackLocalDatasource());
  final _promotionRepository = PromotionRepositoryImpl(
    PromotionLocalDatasource(),
  );

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // 💡 Controladores de búsqueda independientes para cada pestaña
  final TextEditingController _productSearchController =
      TextEditingController();
  final TextEditingController _packSearchController = TextEditingController();

  double? _startX;
  double? _startY;

  List<Product> _products = [];
  List<Pack> _packs = [];
  Map<int, Promotion> _promotionsMap = {};
  bool _isLoading = true;

  // 💡 Textos de búsqueda actuales
  String _productSearchQuery = '';
  String _packSearchQuery = '';

  final Map<Product, int> _cart = {};
  final Map<Pack, int> _cartPacks = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _productSearchController.dispose();
    _packSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final products = await _productRepository.getProducts();
    final packs = await _packRepository.getPacks();
    final promotions = await _promotionRepository.getPromotions();

    final Map<int, Promotion> promoMap = {for (var p in promotions) p.id!: p};

    if (!mounted) return;
    setState(() {
      _products = products;
      _packs = packs;
      _promotionsMap = promoMap;
      _isLoading = false;
    });
  }

  void _addToCart(Product product) {
    final currentQtyInCart = _cart[product] ?? 0;

    if (currentQtyInCart >= product.units) {
      AppAlerts.showError(
        context,
        'No hay más stock disponible de este producto.',
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

    AppAlerts.showInfo(context, '${product.name} eliminado del carrito');
  }

  void _addPackToCart(Pack pack) {
    final currentQtyInCart = _cartPacks[pack] ?? 0;

    if (currentQtyInCart >= pack.units) {
      AppAlerts.showError(
        context,
        'No hay más unidades en stock de este pack.',
      );
      return;
    }

    setState(() {
      _cartPacks[pack] = currentQtyInCart + 1;
    });
  }

  void _removePackFromCart(Pack pack) {
    if (!_cartPacks.containsKey(pack)) return;

    setState(() {
      if (_cartPacks[pack]! > 1) {
        _cartPacks[pack] = _cartPacks[pack]! - 1;
      } else {
        _cartPacks.remove(pack);
      }
    });
  }

  void _removeAllPackFromCart(Pack pack) {
    if (!_cartPacks.containsKey(pack)) return;

    setState(() {
      _cartPacks.remove(pack);
    });

    AppAlerts.showInfo(context, 'Pack ${pack.name} eliminado del carrito');
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
    final productsTotal = _cart.entries.fold(0.0, (total, entry) {
      return total + _calculateItemTotal(entry.key, entry.value);
    });
    final packsTotal = _cartPacks.entries.fold(0.0, (total, entry) {
      return total + (entry.key.price * entry.value);
    });
    return productsTotal + packsTotal;
  }

  int get _cartItemCount {
    final prodCount = _cart.entries.fold(
      0,
      (total, entry) => total + entry.value,
    );
    final packCount = _cartPacks.entries.fold(
      0,
      (total, entry) => total + entry.value,
    );
    return prodCount + packCount;
  }

  Future<void> _processSale() async {
    if (_cart.isEmpty && _cartPacks.isEmpty) return;

    final saleItems = _cart.entries.map((entry) {
      final product = entry.key;
      final qty = entry.value;
      final finalSubtotal = _calculateItemTotal(product, qty);
      final effectiveUnitPrice = finalSubtotal / qty;

      String? pType;
      int? pThresh;
      double? pDisc;

      if (product.promotionId != null &&
          _promotionsMap.containsKey(product.promotionId)) {
        final promo = _promotionsMap[product.promotionId!]!;
        pType = promo.type;
        pThresh = promo.threshold;
        pDisc = promo.discountValue;
      }

      return SaleItem(
        saleId: 0,
        productId: product.id!,
        productName: product.name,
        quantity: qty,
        historicalPrice: effectiveUnitPrice,
        originalPrice: product.price,
        promotionId: product.promotionId,
        promoType: pType,
        promoThreshold: pThresh,
        promoDiscount: pDisc,
      );
    }).toList();

    final salePackItems = _cartPacks.entries.map((entry) {
      return SalePackItem(
        saleId: 0,
        packId: entry.key.id!,
        packName: entry.key.name,
        quantity: entry.value,
        historicalPrice: entry.key.price,
      );
    }).toList();

    final sale = Sale(
      date: DateTime.now(),
      totalAmount: _cartTotal,
      items: saleItems,
      packItems: salePackItems,
    );

    await _saleRepository.processSale(sale);

    setState(() {
      _cart.clear();
      _cartPacks.clear();
    });

    await _loadData();

    if (mounted) {
      AppAlerts.showSuccess(context, '¡Cobro realizado con éxito!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isLandscape = screenSize.width > screenSize.height;

    // 💡 Filtrado dinámico de productos y packs según la búsqueda
    final filteredProducts = _products.where((p) {
      return p.name.toLowerCase().contains(_productSearchQuery.toLowerCase());
    }).toList();

    final filteredPacks = _packs.where((pack) {
      final query = _packSearchQuery.toLowerCase();
      final matchesPackName = pack.name.toLowerCase().contains(query);
      final matchesItemName = pack.items.any(
        (item) => item.productName.toLowerCase().contains(query),
      );
      return matchesPackName || matchesItemName;
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

        if (_tabController.index == 0 && dx > 50 && dy.abs() < 30) {
          _startX = null;
          _startY = null;
          _scaffoldKey.currentState?.openDrawer();
        }
      },
      onPointerUp: (_) {
        _startX = null;
        _startY = null;
      },
      onPointerCancel: (_) {
        _startX = null;
        _startY = null;
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawerEnableOpenDragGesture: _tabController.index == 0,
        appBar: AppBar(
          title: const Text('Panel de Ventas (TPV)'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.inventory_2), text: 'Productos Sueltos'),
              Tab(icon: Icon(Icons.card_giftcard), text: 'Packs y Bundles'),
            ],
          ),
        ),
        drawer: const AppDrawer(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : isLandscape
            ? Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        // 💡 Barra de búsqueda superior para Landscape según pestaña activa
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.3),
                          child: TextField(
                            controller: _tabController.index == 0
                                ? _productSearchController
                                : _packSearchController,
                            onChanged: (value) => setState(() {
                              if (_tabController.index == 0) {
                                _productSearchQuery = value;
                              } else {
                                _packSearchQuery = value;
                              }
                            }),
                            decoration: InputDecoration(
                              hintText: _tabController.index == 0
                                  ? 'Buscar producto...'
                                  : 'Buscar pack o componente...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Theme.of(context).cardColor,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              ProductGridWidget(
                                products: filteredProducts,
                                cart: _cart,
                                bottomPadding: 16,
                                crossAxisCount: 4,
                                onAddToCart: _addToCart,
                                onRemoveFromCart: _removeFromCart,
                                onRemoveAllFromCart: _removeAllFromCart,
                              ),
                              filteredPacks.isEmpty
                                  ? Center(
                                      child: Text(
                                        _packs.isEmpty
                                            ? 'No hay packs creados todavía.'
                                            : 'No se encontraron packs.',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                    )
                                  : PacksGridWidget(
                                      packs: filteredPacks,
                                      cartPacks: _cartPacks,
                                      bottomPadding: 16,
                                      crossAxisCount: 4,
                                      onAddToCart: _addPackToCart,
                                      onRemoveFromCart: _removePackFromCart,
                                      onRemoveAllFromCart:
                                          _removeAllPackFromCart,
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                  Container(
                    width: 380,
                    color: Theme.of(context).cardColor,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
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
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: CartItemsListWidget(
                            cart: _cart,
                            cartPacks: _cartPacks,
                            promotionsMap: _promotionsMap,
                            calculateItemTotal: _calculateItemTotal,
                            onRemoveFromCart: _removeFromCart,
                            onRemoveAllFromCart: _removeAllFromCart,
                            onRemovePackFromCart: _removePackFromCart,
                            onRemoveAllPackFromCart: _removeAllPackFromCart,
                          ),
                        ),
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
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primary,
                                foregroundColor: Theme.of(context)
                                    .colorScheme
                                    .onPrimary,
                                elevation: 0,
                              ),
                              onPressed: (_cart.isEmpty && _cartPacks.isEmpty)
                                  ? null
                                  : _processSale,
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
            : Stack(
                children: [
                  Column(
                    children: [
                      // 💡 Barra de búsqueda superior en Portrait
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        child: TextField(
                          controller: _tabController.index == 0
                              ? _productSearchController
                              : _packSearchController,
                          onChanged: (value) => setState(() {
                            if (_tabController.index == 0) {
                              _productSearchQuery = value;
                            } else {
                              _packSearchQuery = value;
                            }
                          }),
                          decoration: InputDecoration(
                            hintText: _tabController.index == 0
                                ? 'Buscar producto...'
                                : 'Buscar pack o componente...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Theme.of(context).cardColor,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            ProductGridWidget(
                              products: filteredProducts,
                              cart: _cart,
                              bottomPadding: 120,
                              crossAxisCount: 3,
                              onAddToCart: _addToCart,
                              onRemoveFromCart: _removeFromCart,
                              onRemoveAllFromCart: _removeAllFromCart,
                            ),
                            filteredPacks.isEmpty
                                ? Center(
                                    child: Text(
                                      _packs.isEmpty
                                          ? 'No hay packs creados todavía.'
                                          : 'No se encontraron packs.',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                  )
                                : PacksGridWidget(
                                    packs: filteredPacks,
                                    cartPacks: _cartPacks,
                                    bottomPadding: 120,
                                    crossAxisCount: 3,
                                    onAddToCart: _addPackToCart,
                                    onRemoveFromCart: _removePackFromCart,
                                    onRemoveAllFromCart: _removeAllPackFromCart,
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
                              color: Theme.of(context).cardColor,
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
                                      bottom:
                                          (isExpanded &&
                                              (_cart.isNotEmpty ||
                                                  _cartPacks.isNotEmpty))
                                          ? 90
                                          : 20,
                                    ),
                                    children: [
                                      (_cart.isEmpty && _cartPacks.isEmpty)
                                          ? Padding(
                                              padding: const EdgeInsets.only(
                                                top: 32.0,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  'El carrito está vacío',
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Column(
                                              children: [
                                                // PRODUCTOS (CON PROMOS)
                                                ..._cart.keys.map((product) {
                                                  final qty = _cart[product]!;
                                                  final itemTotal =
                                                      _calculateItemTotal(
                                                        product,
                                                        qty,
                                                      );

                                                  final hasPromo =
                                                      product.promotionId !=
                                                          null &&
                                                      _promotionsMap
                                                          .containsKey(
                                                            product.promotionId,
                                                          );
                                                  final promoName = hasPromo
                                                      ? _promotionsMap[product
                                                                .promotionId!]!
                                                            .name
                                                      : '';

                                                  return ListTile(
                                                    title: Text(product.name),
                                                    subtitle: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          '${product.price.toStringAsFixed(2)} € x $qty uds',
                                                        ),
                                                        if (hasPromo)
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets.only(
                                                                  top: 2.0,
                                                                ),
                                                            child: Text(
                                                              '🏷️ $promoName',
                                                              style: TextStyle(
                                                                color: Theme.of(
                                                                  context,
                                                                ).colorScheme.tertiary,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    trailing: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          '${itemTotal.toStringAsFixed(2)} €',
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 16,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        GestureDetector(
                                                          onTap: () =>
                                                              _removeFromCart(
                                                                product,
                                                              ),
                                                          onLongPress: () =>
                                                              _removeAllFromCart(
                                                                product,
                                                              ),
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets.all(
                                                                  8.0,
                                                                ),
                                                            child: Icon(
                                                              Icons
                                                                  .remove_circle,
                                                              color: Theme.of(
                                                                context,
                                                              ).colorScheme.error,
                                                              size: 28,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }),
                                                // PACKS
                                                ..._cartPacks.keys.map((pack) {
                                                  final qty = _cartPacks[pack]!;
                                                  final itemTotal =
                                                      pack.price * qty;
                                                  return ListTile(
                                                    title: Text(pack.name),
                                                    subtitle: Text(
                                                      '${pack.price.toStringAsFixed(2)} € x $qty uds (Pack)',
                                                    ),
                                                    trailing: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          '${itemTotal.toStringAsFixed(2)} €',
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 16,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        GestureDetector(
                                                          onTap: () =>
                                                              _removePackFromCart(
                                                                pack,
                                                              ),
                                                          onLongPress: () =>
                                                              _removeAllPackFromCart(
                                                                pack,
                                                              ),
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets.all(
                                                                  8.0,
                                                                ),
                                                            child: Icon(
                                                              Icons
                                                                  .remove_circle,
                                                              color: Theme.of(
                                                                context,
                                                              ).colorScheme.error,
                                                              size: 28,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }),
                                              ],
                                            ),
                                    ],
                                  ),
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    child: IgnorePointer(
                                      child: Container(
                                        color: Theme.of(context).cardColor,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const SizedBox(height: 8),
                                            Container(
                                              width: 40,
                                              height: 5,
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .outlineVariant,
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
                                                          .colorScheme
                                                          .primary,
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
                                  if (isExpanded &&
                                      (_cart.isNotEmpty ||
                                          _cartPacks.isNotEmpty))
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(16.0),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).cardColor,
                                          border: Border(
                                            top: BorderSide(
                                              color: Theme.of(context)
                                                  .dividerColor,
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
                                                  .colorScheme
                                                  .primary,
                                              foregroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary,
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
