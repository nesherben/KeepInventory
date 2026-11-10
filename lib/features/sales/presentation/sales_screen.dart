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
import '../domain/payment_method.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

enum _CartTotalAction { adjust, reset }

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

  Future<void> _adjustCartTotal() async {
    final baseTotal = _pricing.total;
    if (baseTotal <= 0) return;

    final controller = TextEditingController(
      text: context.amountInput(_cartTotal),
    );
    final agreedTotal = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        String? errorText;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void submit() {
              final value = AppNumbers.parseDecimal(controller.text);
              if (value == null || !value.isFinite || value < 0) {
                setDialogState(() {
                  errorText = context.l10n.salesInvalidAgreedTotal;
                });
                return;
              }
              Navigator.pop(dialogContext, value);
            }

            return AlertDialog(
              title: Text(context.l10n.salesAdjustTotal),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.salesCartAdjustmentHint),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: AppNumbers.decimalKeyboard,
                    inputFormatters: AppNumbers.decimalInputFormatters,
                    decoration: InputDecoration(
                      labelText: context.l10n.salesAgreedTotal,
                      errorText: errorText,
                    ),
                    onChanged: (_) {
                      if (errorText != null) {
                        setDialogState(() => errorText = null);
                      }
                    },
                    onSubmitted: (_) => submit(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(context.l10n.cancel),
                ),
                FilledButton(onPressed: submit, child: Text(context.l10n.save)),
              ],
            );
          },
        );
      },
    );
    controller.dispose();

    if (!mounted || agreedTotal == null) return;
    setState(() => _cartAdjustmentFactor = agreedTotal / baseTotal);
  }

  void _resetCartAdjustment() {
    setState(() => _cartAdjustmentFactor = 1.0);
  }

  Widget _buildCartTotalMenuButton({required bool hasAdjustment}) =>
      PopupMenuButton<_CartTotalAction>(
        enabled: _cartItemCount > 0,
        tooltip: context.l10n.salesAdjustTotal,
        padding: EdgeInsets.zero,
        iconSize: 20,
        onSelected: (action) {
          switch (action) {
            case _CartTotalAction.adjust:
              _adjustCartTotal();
            case _CartTotalAction.reset:
              _resetCartAdjustment();
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: _CartTotalAction.adjust,
            child: Text(context.l10n.salesAdjustTotal),
          ),
          if (hasAdjustment)
            PopupMenuItem(
              value: _CartTotalAction.reset,
              child: Text(context.l10n.salesResetTotalAdjustment),
            ),
        ],
      );

  Widget _buildCartTotalSummary({
    required double fontSize,
    Color? color,
    bool includeMenu = true,
  }) {
    final hasAdjustment = (_cartAdjustmentFactor - 1).abs() > 0.0000001;
    final textStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      color: color,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasAdjustment)
              Text(
                context.money(_pricing.total),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  decoration: TextDecoration.lineThrough,
                  fontSize: 12,
                ),
              ),
            Text(
              context.l10n.cartTotal(context.amount(_cartTotal)),
              style: textStyle,
            ),
          ],
        ),
        if (includeMenu)
          _buildCartTotalMenuButton(hasAdjustment: hasAdjustment)
        else
          const SizedBox(width: 48),
      ],
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
    final showCategories = _categories.isNotEmpty && _tabController.index == 0;
    if (!showCategories) return _buildSearchField();
    Widget chip(int? id, String label) => Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ChoiceChip(
        label: Text(label),
        selected: _categoryFilter == id,
        showCheckmark: false,
        onSelected: (_) => setState(() => _categoryFilter = id),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSearchField(),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 0, 4, 4),
          child: Row(
            children: [
              chip(null, context.l10n.categoryAll),
              for (final c in _categories) chip(c.id, c.name),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    final isProductTab = _tabController.index == 0;
    final controller = isProductTab
        ? _productSearchController
        : _packSearchController;
    final query = isProductTab ? _productSearchQuery : _packSearchQuery;

    void update(String value) => setState(() {
      if (isProductTab) {
        _productSearchQuery = value;
      } else {
        _packSearchQuery = value;
      }
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: TextField(
        controller: controller,
        onChanged: update,
        decoration: InputDecoration(
          hintText: isProductTab
              ? context.l10n.searchProducts
              : context.l10n.searchPacksOrComponents,
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    controller.clear();
                    update('');
                  },
                ),
          fillColor: Theme.of(context).cardColor,
        ),
      ),
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
                  Container(
                    width: 380,
                    color: Theme.of(context).cardColor,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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
                              _buildCartTotalSummary(fontSize: 22),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: CartItemsListWidget(
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
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: _buildPaymentMethodSelector(),
                        ),
                        Padding(
                          // Por encima de la barra de navegación de Android
                          padding: EdgeInsets.fromLTRB(
                            16,
                            16,
                            16,
                            16 + MediaQuery.viewPaddingOf(context).bottom,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: _buildCheckoutButton(large: false),
                          ),
                        ),
                      ],
                    ),
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
                      DraggableScrollableSheet(
                        controller: _cartSheetController,
                        initialChildSize: _cartMinSize,
                        minChildSize: _cartMinSize,
                        maxChildSize: 0.7,
                        builder: (BuildContext context, ScrollController scrollController) {
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              // Plegado = solo la cabecera (artículos y total)
                              final bool isExpanded =
                                  constraints.maxHeight >
                                  _cartMinSize * bodyConstraints.maxHeight + 8;

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
                                              ? 170 +
                                                    MediaQuery.viewPaddingOf(
                                                          context,
                                                        )
                                                        .bottom // botón + pago
                                              : 20,
                                        ),
                                        children: [
                                          // Plegado no se pinta la lista: si no,
                                          // asoma bajo la barra de navegación
                                          if (isExpanded)
                                            CartItemsListWidget(
                                              cart: _cart,
                                              catalog: _products,
                                              onAddToCart: _addToCart,
                                              onLocateProduct: _locateProduct,
                                              cartPacks: _cartPacks,
                                              promotionsMap: _promotionsMap,
                                              pricing: _pricing,
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
                                        child: Stack(
                                          children: [
                                            IgnorePointer(
                                              child: Container(
                                                color: Theme.of(context)
                                                    .cardColor,
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
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
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 18,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                          ),
                                                          _buildCartTotalSummary(
                                                            fontSize: 22,
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .primary,
                                                            includeMenu: false,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const Divider(height: 1),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Positioned.fill(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 24,
                                                    ),
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: _buildCartTotalMenuButton(
                                                    hasAdjustment:
                                                        (_cartAdjustmentFactor -
                                                                1)
                                                            .abs() >
                                                        0.0000001,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
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
                                            // Por encima de la barra de
                                            // navegación de Android
                                            padding: EdgeInsets.fromLTRB(
                                              16,
                                              16,
                                              16,
                                              16 +
                                                  MediaQuery.viewPaddingOf(
                                                    context,
                                                  ).bottom,
                                            ),
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
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                _buildPaymentMethodSelector(),
                                                const SizedBox(height: 12),
                                                SizedBox(
                                                  width: double.infinity,
                                                  child: _buildCheckoutButton(
                                                    large: true,
                                                  ),
                                                ),
                                              ],
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
                  );
                },
              ),
      ),
    );
  }
}
