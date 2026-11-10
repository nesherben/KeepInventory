import 'dart:async';

import 'package:flutter/material.dart';
import 'package:keepinventory/core/utils/app_numbers.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../core/shared_widgets/app_drawer.dart';
import '../../../core/shared_widgets/app_alerts.dart';
import '../../../core/shared_widgets/app_ui.dart';

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
import '../../inventory/data/datasources/category_local_datasource.dart';
import '../../inventory/data/repositories/category_repository_impl.dart';
import '../../inventory/domain/product_category.dart';
import '../../inventory/domain/product.dart';
import '../../inventory/data/datasources/product_local_datasource.dart';

// Packs
import '../../packs/domain/pack.dart';
import '../../packs/data/datasources/pack_local_datasource.dart';

// Promotions
import '../../promotions/domain/promotion.dart';
import '../../promotions/data/datasources/promotion_local_datasource.dart';
import '../../promotions/data/datasources/combo_local_datasource.dart';
import '../../promotions/data/repositories/combo_repository_impl.dart';
import '../../promotions/domain/combo.dart';

// Widget Composition
import 'widgets/product_grid_widget.dart';
import 'widgets/packs_grid_widget.dart';
import 'widgets/cart_items_list_widget.dart';
import 'widgets/payment_method_widgets.dart';
import 'widgets/sales_cart_sheet.dart';
import 'widgets/sales_cart_total_summary.dart';
import 'widgets/sales_catalog_header.dart';
import 'widgets/sales_landscape_cart_panel.dart';
import '../domain/payment_method.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// Carrito desplegable (móvil): se recoge al ir a un producto.
  final _cartSheetController = DraggableScrollableController();

  /// Altura del carrito plegado (fracción): la cabecera (asa + artículos y
  /// total) más la barra de navegación de Android, para que no la tape.
  double _cartMinSize = 0.12;
  static const double _cartHeaderHeight = 96;
  int? _focusedProductId;
  int _focusRequest = 0;
  Timer? _focusTimer;

  final _saleRepository = SaleRepositoryImpl(SaleLocalDatasource());
  final _productRepository = ProductRepositoryImpl(ProductLocalDatasource());
  final _packRepository = PackRepositoryImpl(PackLocalDatasource());
  final _comboRepository = ComboRepositoryImpl(ComboLocalDatasource());
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
  List<Combo> _combos = [];

  /// Categorías del catálogo y filtro elegido (null = todas).
  List<ProductCategory> _categories = [];
  int? _categoryFilter;
  bool _isLoading = true;

  String _productSearchQuery = '';
  String _packSearchQuery = '';

  final Map<Product, int> _cart = {};
  final Map<Pack, int> _cartPacks = {};
  double _cartAdjustmentFactor = 1.0;

  // Método de pago del cliente (solo informativo). Vuelve a efectivo tras cada venta.
  PaymentMethod _paymentMethod = PaymentMethod.defaultMethod;

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
    _focusTimer?.cancel();
    _cartSheetController.dispose();
    _tabController.dispose();
    _productSearchController.dispose();
    _packSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Sin indicador de carga al recargar: se conserva la posición del scroll

    final products = await _productRepository.getProducts();
    final packs = await _packRepository.getPacks();
    final promotions = await _promotionRepository.getPromotions();
    final combos = await _comboRepository.getCombos();
    final categories = await CategoryRepositoryImpl(CategoryLocalDatasource())
        .getCategories();

    final Map<int, Promotion> promoMap = {for (var p in promotions) p.id!: p};

    if (!mounted) return;
    setState(() {
      _products = products;
      _packs = packs;
      _promotionsMap = promoMap;
      _combos = combos.where((c) => c.isComplete).toList();
      // Solo categorías con algún producto a la venta
      final used = {for (final p in products) p.categoryId};
      _categories = categories.where((c) => used.contains(c.id)).toList();
      if (!_categories.any((c) => c.id == _categoryFilter)) {
        _categoryFilter = null;
      }
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
    // Aviso al meter la última unidad que queda
    if (currentQtyInCart + 1 == product.units) {
      AppAlerts.showWarning(
        context,
        context.l10n.stockLastUnit(product.name),
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _removeFromCart(Product product) {
    if (!_cart.containsKey(product)) return;

    setState(() {
      if (_cart[product]! > 1) {
        _cart[product] = _cart[product]! - 1;
      } else {
        _cart.remove(product);
      }
      if (_cart.isEmpty && _cartPacks.isEmpty) {
        _cartAdjustmentFactor = 1.0;
      }
    });
  }

  void _removeAllFromCart(Product product) {
    if (!_cart.containsKey(product)) return;

    setState(() {
      _cart.remove(product);
      if (_cartPacks.isEmpty) _cartAdjustmentFactor = 1.0;
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
      if (_cart.isEmpty && _cartPacks.isEmpty) {
        _cartAdjustmentFactor = 1.0;
      }
    });
  }

  void _removeAllPackFromCart(Pack pack) {
    if (!_cartPacks.containsKey(pack)) return;

    setState(() {
      _cartPacks.remove(pack);
      if (_cart.isEmpty) _cartAdjustmentFactor = 1.0;
    });

    AppAlerts.showInfo(context, context.l10n.packRemovedFromCart(pack.name));
  }

  CartPricing get _pricing => SaleCartPricingCalculator.price(
    products: _cart,
    packs: _cartPacks,
    promotions: _promotionsMap,
    combos: _combos,
  );

  double get _cartTotal => _pricing.total * _cartAdjustmentFactor;

  Widget _buildCartTotalSummary({required double fontSize, Color? color}) {
    return SalesCartTotalSummary(
      baseTotal: _pricing.total,
      total: _cartTotal,
      itemCount: _cartItemCount,
      fontSize: fontSize,
      hasAdjustment: (_cartAdjustmentFactor - 1).abs() > 0.0000001,
      color: color,
      onTotalAdjusted: (agreedTotal) => setState(
        () => _cartAdjustmentFactor = agreedTotal / _pricing.total,
      ),
      onReset: () => setState(() => _cartAdjustmentFactor = 1.0),
    );
  }

  /// Lleva al producto en el catálogo (desde el aviso de combo a medias):
  /// pestaña Productos, sin búsqueda que lo oculte, carrito recogido, scroll
  /// hasta él y resaltado unos segundos.
  void _locateProduct(Product product) {
    final hidden = !SaleCatalogFilter.filterProducts(
      _products,
      _productSearchQuery,
      categoryId: _categoryFilter,
    ).any((p) => p.id == product.id);
    setState(() {
      if (hidden) {
        _productSearchController.clear();
        _productSearchQuery = '';
        _categoryFilter = null;
      }
      _focusedProductId = product.id;
      _focusRequest++;
    });
    if (_tabController.index != 0) _tabController.animateTo(0);
    if (_cartSheetController.isAttached &&
        _cartSheetController.size > _cartMinSize + 0.01) {
      _cartSheetController.animateTo(
        _cartMinSize,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    _focusTimer?.cancel();
    _focusTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _focusedProductId = null);
    });
  }

  int get _cartItemCount =>
      SaleCartPricingCalculator.countItems(products: _cart, packs: _cartPacks);

  Widget _buildPaymentMethodSelector() => PaymentMethodSelector(
    selected: _paymentMethod,
    onChanged: (method) => setState(() => _paymentMethod = method),
  );

  Future<void> _processSale() async {
    if (_cart.isEmpty && _cartPacks.isEmpty) return;
    final sale = SaleFromCartFactory.create(
      date: DateTime.now(),
      products: _cart,
      packs: _cartPacks,
      promotions: _promotionsMap,
      combos: _combos,
      paymentMethod: _paymentMethod,
      adjustmentFactor: _cartAdjustmentFactor,
    );

    final saleId = await _saleRepository.processSale(sale);
    final method = _paymentMethod;

    setState(() {
      _cart.clear();
      _cartPacks.clear();
      _cartAdjustmentFactor = 1.0;
      _paymentMethod = PaymentMethod.defaultMethod;
    });

    await _loadData();

    if (!mounted) return;
    AppAlerts.showSuccess(
      context,
      context.l10n.saleRegistered(
        saleId.toString(),
        context.amount(sale.totalAmount),
        method.label(context),
      ),
    );
    // Carrito plegado: el catálogo queda listo para la siguiente venta
    if (_cartSheetController.isAttached) {
      _cartSheetController.animateTo(
        _cartMinSize,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Buscador y, en Productos, chips de categoría.
  Widget _buildCatalogHeader() {
    return SalesCatalogHeader(
      isProductTab: _tabController.index == 0,
      productSearchController: _productSearchController,
      packSearchController: _packSearchController,
      productSearchQuery: _productSearchQuery,
      packSearchQuery: _packSearchQuery,
      categories: _categories,
      categoryFilter: _categoryFilter,
      onProductSearchChanged: (value) =>
          setState(() => _productSearchQuery = value),
      onPackSearchChanged: (value) => setState(() => _packSearchQuery = value),
      onCategoryChanged: (categoryId) =>
          setState(() => _categoryFilter = categoryId),
    );
  }

  /// Botón de cobrar con el total visible (confirma el importe de un vistazo).
  Widget _buildCheckoutButton({required bool large}) {
    final isEmpty = _cart.isEmpty && _cartPacks.isEmpty;
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: large ? 18 : 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      onPressed: isEmpty ? null : _processSale,
      icon: const Icon(Icons.point_of_sale),
      label: Text(
        isEmpty
            ? context.l10n.checkout
            : '${context.l10n.checkout} · ${context.money(_cartTotal)}',
        style: TextStyle(
          fontSize: large ? 19 : 17,
          fontWeight: FontWeight.w800,
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
          comboProductIds: {for (final c in _combos) ...c.productIds},
          focusedProductId: _focusedProductId,
          focusRequest: _focusRequest,
          missingProductIds: {
            for (final hint in _pricing.combos.hints)
              for (final slot in hint.missing) ...slot.productIds,
          },
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
      categoryId: _categoryFilter,
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
                        _buildCatalogHeader(),
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
                  SalesLandscapeCartPanel(
                    itemCountLabel: context.l10n.cartItemsCount(
                      _cartItemCount.toString(),
                    ),
                    totalSummary: _buildCartTotalSummary(fontSize: 22),
                    cartItems: CartItemsListWidget(
                      cart: _cart,
                      catalog: _products,
                      onAddToCart: _addToCart,
                      onLocateProduct: _locateProduct,
                      cartPacks: _cartPacks,
                      promotionsMap: _promotionsMap,
                      pricing: _pricing,
                      onRemoveFromCart: _removeFromCart,
                      onRemoveAllFromCart: _removeAllFromCart,
                      onRemovePackFromCart: _removePackFromCart,
                      onRemoveAllPackFromCart: _removeAllPackFromCart,
                    ),
                    paymentMethodSelector: _buildPaymentMethodSelector(),
                    checkoutButton: _buildCheckoutButton(large: false),
                  ),
                ],
              )
            : LayoutBuilder(
                builder: (context, bodyConstraints) {
                  final navBar = MediaQuery.viewPaddingOf(context).bottom;
                  _cartMinSize =
                      ((_cartHeaderHeight + navBar) / bodyConstraints.maxHeight)
                          .clamp(0.08, 0.3);
                  return Stack(
                    children: [
                      Column(
                        children: [
                          _buildCatalogHeader(),
                          Expanded(
                            child: _buildCatalogTabs(
                              filteredProducts: filteredProducts,
                              filteredPacks: filteredPacks,
                              crossAxisCount: 3,
                              // Que el carrito plegado no tape la última fila
                              bottomPadding:
                                  _cartMinSize * bodyConstraints.maxHeight + 24,
                            ),
                          ),
                        ],
                      ),
                      SalesCartSheet(
                        controller: _cartSheetController,
                        minSize: _cartMinSize,
                        bodyHeight: bodyConstraints.maxHeight,
                        itemCountLabel: context.l10n.cartItemsCount(
                          _cartItemCount.toString(),
                        ),
                        hasAdjustment:
                            (_cartAdjustmentFactor - 1).abs() > 0.0000001,
                        hasItems: _cart.isNotEmpty || _cartPacks.isNotEmpty,
                        totalSummary: _buildCartTotalSummary(
                          fontSize: 22,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        cartItems: CartItemsListWidget(
                          cart: _cart,
                          catalog: _products,
                          onAddToCart: _addToCart,
                          onLocateProduct: _locateProduct,
                          cartPacks: _cartPacks,
                          promotionsMap: _promotionsMap,
                          pricing: _pricing,
                          onRemoveFromCart: _removeFromCart,
                          onRemoveAllFromCart: _removeAllFromCart,
                          onRemovePackFromCart: _removePackFromCart,
                          onRemoveAllPackFromCart: _removeAllPackFromCart,
                        ),
                        paymentMethodSelector: _buildPaymentMethodSelector(),
                        checkoutButton: _buildCheckoutButton(large: true),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
