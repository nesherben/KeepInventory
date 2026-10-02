import 'package:flutter/material.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../core/shared_widgets/app_drawer.dart';
import '../../../core/shared_widgets/app_alerts.dart';

// --- IMPORTS MODULARES ---
// Sales
import '../../inventory/data/repositories/product_repository_impl.dart';
import '../../packs/data/repositories/pack_repository_impl.dart';
import '../../promotions/data/repositories/promotion_repository_impl.dart';
import '../data/repositories/sale_repository_imp.dart';
import '../domain/sale_catalog_filter.dart';
import '../domain/sale_cart_pricing_calculator.dart';
import '../domain/sale_from_cart_factory.dart';
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

  final TextEditingController _productSearchController =
      TextEditingController();
  final TextEditingController _packSearchController = TextEditingController();

  double? _startX;
  double? _startY;

  List<Product> _products = [];
  List<Pack> _packs = [];
  Map<int, Promotion> _promotionsMap = {};
  bool _isLoading = true;

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
      AppAlerts.showError(context, context.l10n.noMoreProductStock);
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

    AppAlerts.showInfo(
      context,
      context.l10n.productRemovedFromCart(product.name),
    );
  }

  void _addPackToCart(Pack pack) {
    final currentQtyInCart = _cartPacks[pack] ?? 0;

    if (currentQtyInCart >= pack.units) {
      AppAlerts.showError(context, context.l10n.noMorePackStock);
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

    AppAlerts.showInfo(context, context.l10n.packRemovedFromCart(pack.name));
  }

  double get _cartTotal => SaleCartPricingCalculator.calculateCartTotal(
    products: _cart,
    packs: _cartPacks,
    promotions: _promotionsMap,
  );

  int get _cartItemCount =>
      SaleCartPricingCalculator.countItems(products: _cart, packs: _cartPacks);

  Future<void> _processSale() async {
    if (_cart.isEmpty && _cartPacks.isEmpty) return;
    final sale = SaleFromCartFactory.create(
      date: DateTime.now(),
      products: _cart,
      packs: _cartPacks,
      promotions: _promotionsMap,
    );

    await _saleRepository.processSale(sale);

    setState(() {
      _cart.clear();
      _cartPacks.clear();
    });

    await _loadData();

    if (mounted) {
      AppAlerts.showSuccess(context, context.l10n.saleCompleted);
    }
  }

  Widget _buildSearchField() {
    final isProductTab = _tabController.index == 0;
    return Container(
      padding: const EdgeInsets.all(8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest
          .withValues(alpha: 0.3),
      child: TextField(
        controller: isProductTab
            ? _productSearchController
            : _packSearchController,
        onChanged: (value) => setState(() {
          if (isProductTab) {
            _productSearchQuery = value;
          } else {
            _packSearchQuery = value;
          }
        }),
        decoration: InputDecoration(
          hintText: isProductTab
              ? context.l10n.searchProducts
              : context.l10n.searchPacksOrComponents,
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
    );
  }

  Widget _buildCatalogTabs({
    required List<Product> filteredProducts,
    required List<Pack> filteredPacks,
    required int crossAxisCount,
    required double bottomPadding,
  }) {
    return TabBarView(
      controller: _tabController,
      children: [
        ProductGridWidget(
          products: filteredProducts,
          cart: _cart,
          bottomPadding: bottomPadding,
          crossAxisCount: crossAxisCount,
          onAddToCart: _addToCart,
          onRemoveFromCart: _removeFromCart,
          onRemoveAllFromCart: _removeAllFromCart,
        ),
        filteredPacks.isEmpty
            ? Center(
                child: Text(
                  _packs.isEmpty
                      ? context.l10n.packsEmpty
                      : context.l10n.noPacksFound,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            : PacksGridWidget(
                packs: filteredPacks,
                cartPacks: _cartPacks,
                bottomPadding: bottomPadding,
                crossAxisCount: crossAxisCount,
                onAddToCart: _addPackToCart,
                onRemoveFromCart: _removePackFromCart,
                onRemoveAllFromCart: _removeAllPackFromCart,
              ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isLandscape = screenSize.width > screenSize.height;
    final filteredProducts = SaleCatalogFilter.filterProducts(
      _products,
      _productSearchQuery,
    );
    final filteredPacks = SaleCatalogFilter.filterPacks(
      _packs,
      _packSearchQuery,
    );

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
          title: Text(context.l10n.salesTitle),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                icon: const Icon(Icons.inventory_2),
                text: context.l10n.salesProductsTab,
              ),
              Tab(
                icon: const Icon(Icons.card_giftcard),
                text: context.l10n.salesPacksTab,
              ),
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
                        _buildSearchField(),
                        Expanded(
                          child: _buildCatalogTabs(
                            filteredProducts: filteredProducts,
                            filteredPacks: filteredPacks,
                            crossAxisCount: 4,
                            bottomPadding: 16,
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
                                context.l10n.cartItemsCount(
                                  _cartItemCount.toString(),
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                context.l10n.cartTotal(
                                  _cartTotal.toStringAsFixed(2),
                                ),
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
                            calculateItemTotal:
                                SaleCartPricingCalculator.calculateItemTotal,
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
                              child: Text(
                                context.l10n.checkout,
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
                      _buildSearchField(),
                      Expanded(
                        child: _buildCatalogTabs(
                          filteredProducts: filteredProducts,
                          filteredPacks: filteredPacks,
                          crossAxisCount: 3,
                          bottomPadding: 120,
                        ),
                      ),
                    ],
                  ),
                  DraggableScrollableSheet(
                    initialChildSize: 0.12,
                    minChildSize: 0.12,
                    maxChildSize: 0.7,
                    builder:
                        (
                          BuildContext context,
                          ScrollController scrollController,
                        ) {
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final bool isExpanded =
                                  constraints.maxHeight > 150;

                              return Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(24),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.2,
                                      ),
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
                                          CartItemsListWidget(
                                            cart: _cart,
                                            cartPacks: _cartPacks,
                                            promotionsMap: _promotionsMap,
                                            calculateItemTotal:
                                                SaleCartPricingCalculator
                                                    .calculateItemTotal,
                                            onRemoveFromCart: _removeFromCart,
                                            onRemoveAllFromCart:
                                                _removeAllFromCart,
                                            onRemovePackFromCart:
                                                _removePackFromCart,
                                            onRemoveAllPackFromCart:
                                                _removeAllPackFromCart,
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
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
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
                                                        context.l10n
                                                            .cartItemsCount(
                                                              _cartItemCount
                                                                  .toString(),
                                                            ),
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      Text(
                                                        context.l10n.cartTotal(
                                                          _cartTotal
                                                              .toStringAsFixed(
                                                                2,
                                                              ),
                                                        ),
                                                        style: TextStyle(
                                                          fontSize: 22,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Theme.of(
                                                            context,
                                                          ).colorScheme.primary,
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
                                              color: Theme.of(context)
                                                  .cardColor,
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
                                                  backgroundColor: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                  foregroundColor: Theme.of(
                                                    context,
                                                  ).colorScheme.onPrimary,
                                                  elevation: 0,
                                                ),
                                                onPressed: _processSale,
                                                child: Text(
                                                  context.l10n.checkout,
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
