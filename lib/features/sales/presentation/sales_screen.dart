import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'cart_session.dart';
import '../domain/insufficient_stock_exception.dart';
import '../domain/manual_line_discount.dart';
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
import '../../../core/shared_widgets/coach_marks.dart';
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

  // Guía de la pantalla (mini tutorial): elementos que se iluminan
  final _tabsKey = GlobalKey();
  final _headerKey = GlobalKey();
  final _totalKey = GlobalKey();
  bool _guideTried = false;

  final Map<Product, int> _cart = {};
  final Map<Pack, int> _cartPacks = {};
  double _cartAdjustmentFactor = 1.0;

  /// Descuentos manuales por línea (id de producto). Nunca conviven con el
  /// total acordado: uno anula al otro.
  final Map<int, ManualLineDiscount> _lineDiscounts = {};

  // Método de pago del cliente (solo informativo). Vuelve a efectivo tras cada venta.
  PaymentMethod _paymentMethod = PaymentMethod.defaultMethod;

  /// Ya se recuperó el carrito de la sesión (hasta entonces no se guarda nada,
  /// para no pisarlo con el carrito vacío del primer build).
  bool _cartRestored = false;

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
      _remapCart();
      _isLoading = false;
    });
    if (!_guideTried) {
      _guideTried = true;
      CoachGuide.showOnce(context, 'sales', _guideSteps);
    }
  }

  /// Pasos de la guía: sin productos invita a crear el primero en Inventario.
  List<CoachStep> _guideSteps() {
    final l10n = context.l10n;
    if (_products.isEmpty) {
      return [
        CoachStep(
          target: _tabsKey,
          title: l10n.coachSalesEmptyTitle,
          text: l10n.coachSalesEmptyText,
        ),
      ];
    }
    return [
      CoachStep(target: _tabsKey, text: l10n.coachSalesTabs),
      CoachStep(target: _headerKey, text: l10n.coachSalesCatalog),
      CoachStep(target: _totalKey, text: l10n.coachSalesTotal),
    ];
  }

  /// Reconstruye el carrito con los productos y packs recién cargados: la
  /// primera vez desde la sesión (volver a la caja tras abrir otra pantalla) y
  /// las siguientes desde el propio carrito (para que apunte a los objetos
  /// nuevos). Las cantidades se recortan al stock actual y lo que ya no
  /// exista se descarta.
  void _remapCart() {
    final session = CartSession.instance;
    final productQty = _cartRestored
        ? {
            for (final e in _cart.entries)
              if (e.key.id != null) e.key.id!: e.value,
          }
        : Map<int, int>.of(session.products);
    final packQty = _cartRestored
        ? {
            for (final e in _cartPacks.entries)
              if (e.key.id != null) e.key.id!: e.value,
          }
        : Map<int, int>.of(session.packs);
    if (!_cartRestored) {
      _lineDiscounts
        ..clear()
        ..addAll(session.lineDiscounts);
      _cartAdjustmentFactor = session.adjustmentFactor;
      _paymentMethod = session.paymentMethod;
    }

    var clamped = false;
    _cart.clear();
    for (final product in _products) {
      final wanted = productQty[product.id];
      if (wanted == null) continue;
      final qty = wanted < product.units ? wanted : product.units;
      if (qty != wanted) clamped = true;
      if (qty > 0) _cart[product] = qty;
    }
    _cartPacks.clear();
    for (final pack in _packs) {
      final wanted = packQty[pack.id];
      if (wanted == null) continue;
      final qty = wanted < pack.units ? wanted : pack.units;
      if (qty != wanted) clamped = true;
      if (qty > 0) _cartPacks[pack] = qty;
    }

    final present = {for (final p in _cart.keys) p.id};
    _lineDiscounts.removeWhere((id, _) => !present.contains(id));
    // Un total acordado no vale si el carrito cambió por el stock
    if (clamped || (_cart.isEmpty && _cartPacks.isEmpty)) {
      _cartAdjustmentFactor = 1.0;
    }
    _cartRestored = true;
  }

  /// Guarda el carrito en la sesión (en memoria) para recuperarlo al volver.
  void _saveCartSession() {
    if (!_cartRestored) return;
    final session = CartSession.instance;
    session.products = {
      for (final e in _cart.entries)
        if (e.key.id != null) e.key.id!: e.value,
    };
    session.packs = {
      for (final e in _cartPacks.entries)
        if (e.key.id != null) e.key.id!: e.value,
    };
    session.lineDiscounts = Map.of(_lineDiscounts);
    session.adjustmentFactor = _cartAdjustmentFactor;
    session.paymentMethod = _paymentMethod;
  }

  /// El total acordado se calculó para un carrito concreto: si cambia lo que
  /// hay dentro, deja de valer y se quita (true si había uno).
  bool _dropAgreedTotal() {
    if (!_hasAdjustment) return false;
    _cartAdjustmentFactor = 1.0;
    return true;
  }

  void _notifyAgreedTotalDropped() {
    if (mounted) {
      AppAlerts.showInfo(context, context.l10n.agreedTotalResetByChange);
    }
  }

  void _addToCart(Product product) {
    final currentQtyInCart = _cart[product] ?? 0;

    if (currentQtyInCart >= product.units) {
      AppAlerts.showError(context, context.l10n.noMoreProductStock);
      return;
    }

    var agreedDropped = false;
    setState(() {
      _cart[product] = currentQtyInCart + 1;
      agreedDropped = _dropAgreedTotal();
    });
    if (agreedDropped) _notifyAgreedTotalDropped();
    _pruneLineDiscounts();
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

    var agreedDropped = false;
    setState(() {
      if (_cart[product]! > 1) {
        _cart[product] = _cart[product]! - 1;
      } else {
        _cart.remove(product);
        _lineDiscounts.remove(product.id);
      }
      if (_cart.isEmpty && _cartPacks.isEmpty) {
        _cartAdjustmentFactor = 1.0;
      } else {
        agreedDropped = _dropAgreedTotal();
      }
    });
    if (agreedDropped) _notifyAgreedTotalDropped();
    // Con una unidad menos el lote puede pasar a cubrirlas todas
    _pruneLineDiscounts();
  }

  void _removeAllFromCart(Product product) {
    if (!_cart.containsKey(product)) return;

    var agreedDropped = false;
    setState(() {
      _cart.remove(product);
      _lineDiscounts.remove(product.id);
      if (_cart.isEmpty && _cartPacks.isEmpty) {
        _cartAdjustmentFactor = 1.0;
      } else {
        agreedDropped = _dropAgreedTotal();
      }
    });

    AppAlerts.showInfo(
      context,
      context.l10n.productRemovedFromCart(product.name),
    );
    if (agreedDropped) _notifyAgreedTotalDropped();
  }

  void _addPackToCart(Pack pack) {
    final currentQtyInCart = _cartPacks[pack] ?? 0;

    if (currentQtyInCart >= pack.units) {
      AppAlerts.showError(context, context.l10n.noMorePackStock);
      return;
    }

    var agreedDropped = false;
    setState(() {
      _cartPacks[pack] = currentQtyInCart + 1;
      agreedDropped = _dropAgreedTotal();
    });
    if (agreedDropped) _notifyAgreedTotalDropped();
  }

  void _removePackFromCart(Pack pack) {
    if (!_cartPacks.containsKey(pack)) return;

    var agreedDropped = false;
    setState(() {
      if (_cartPacks[pack]! > 1) {
        _cartPacks[pack] = _cartPacks[pack]! - 1;
      } else {
        _cartPacks.remove(pack);
      }
      if (_cart.isEmpty && _cartPacks.isEmpty) {
        _cartAdjustmentFactor = 1.0;
      } else {
        agreedDropped = _dropAgreedTotal();
      }
    });
    if (agreedDropped) _notifyAgreedTotalDropped();
  }

  void _removeAllPackFromCart(Pack pack) {
    if (!_cartPacks.containsKey(pack)) return;

    var agreedDropped = false;
    setState(() {
      _cartPacks.remove(pack);
      if (_cart.isEmpty && _cartPacks.isEmpty) {
        _cartAdjustmentFactor = 1.0;
      } else {
        agreedDropped = _dropAgreedTotal();
      }
    });

    AppAlerts.showInfo(context, context.l10n.packRemovedFromCart(pack.name));
    if (agreedDropped) _notifyAgreedTotalDropped();
  }

  CartPricing _priceCart({bool withDiscounts = true}) =>
      SaleCartPricingCalculator.price(
        products: _cart,
        packs: _cartPacks,
        promotions: _promotionsMap,
        combos: _combos,
        lineDiscounts: withDiscounts ? _lineDiscounts : const {},
      );

  CartPricing get _pricing => _priceCart();

  double get _cartTotal => _pricing.total * _cartAdjustmentFactor;

  bool get _hasAdjustment => (_cartAdjustmentFactor - 1).abs() > 0.0000001;

  Widget _buildCartTotalSummary({required double fontSize, Color? color}) {
    final pricing = _pricing;
    return KeyedSubtree(
      key: _totalKey,
      child: SalesCartTotalSummary(
        // Base SIN descuentos: al fijar un total acordado se borran
        baseTotal: _priceCart(withDiscounts: false).total,
        total: _cartTotal,
        itemCount: _cartItemCount,
        fontSize: fontSize,
        hasAdjustment: _hasAdjustment,
        savings: pricing.discountTotal,
        color: color,
        onTotalAdjusted: _applyAgreedTotal,
        onReset: () => setState(() => _cartAdjustmentFactor = 1.0),
      ),
    );
  }

  Future<bool> _confirmAction({
    required String title,
    required String body,
    required String confirmLabel,
  }) async {
    // Un segundo toque durante la animación de cierre cerraría Ventas
    var answered = false;
    void answer(BuildContext dialogContext, bool value) {
      if (answered) return;
      answered = true;
      Navigator.pop(dialogContext, value);
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => answer(dialogContext, false),
            child: Text(dialogContext.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => answer(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  /// Fija el total acordado. Si hay descuentos de línea, se pide quitarlos
  /// primero (el factor se calcula sobre el total SIN descuentos).
  Future<void> _applyAgreedTotal(double agreedTotal) async {
    final base = _priceCart(withDiscounts: false).total;
    if (base <= 0) return;
    final applied = _pricing.appliedDiscounts;
    if (applied.isNotEmpty) {
      final ok = await _confirmAction(
        title: context.l10n.lineDiscountClearTitle,
        body: context.l10n.lineDiscountClearBody(
          applied.length,
          context.amount(_pricing.discountTotal),
        ),
        confirmLabel: context.l10n.lineDiscountClearConfirm,
      );
      if (!ok || !mounted) return;
    }
    setState(() {
      _lineDiscounts.clear();
      _cartAdjustmentFactor = agreedTotal / base;
    });
  }

  /// Aplica (o quita, si [discount] es null) el descuento manual de una línea.
  /// Si había un total acordado, se pide quitarlo antes.
  Future<void> _setLineDiscount(
    Product product,
    ManualLineDiscount? discount,
  ) async {
    final id = product.id;
    if (id == null) return;
    if (discount == null) {
      setState(() => _lineDiscounts.remove(id));
      return;
    }
    if (_hasAdjustment) {
      final ok = await _confirmAction(
        title: context.l10n.agreedTotalClearTitle,
        body: context.l10n.agreedTotalClearBody,
        confirmLabel: context.l10n.agreedTotalClearConfirm,
      );
      if (!ok || !mounted) return;
    }
    setState(() {
      _cartAdjustmentFactor = 1.0;
      _lineDiscounts[id] = discount;
    });
  }

  /// Si una línea con descuento manual pasa a tener promoción o combo (p. ej.
  /// al añadir otro producto del combo), manda la promoción/combo: se quita
  /// el descuento y se avisa.
  void _pruneLineDiscounts() {
    if (_lineDiscounts.isEmpty) return;
    final dropped = SaleCartPricingCalculator.lineDiscountsToDrop(
      products: _cart,
      packs: _cartPacks,
      promotions: _promotionsMap,
      combos: _combos,
      discountedIds: _lineDiscounts.keys.toSet(),
    );
    if (dropped.isEmpty) return;
    setState(() {
      for (final product in dropped) {
        _lineDiscounts.remove(product.id);
      }
    });
    for (final product in dropped) {
      AppAlerts.showInfo(
        context,
        context.l10n.lineDiscountDroppedByPromo(product.name),
      );
    }
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

  /// Evita que un doble toque en "Cobrar" registre la venta dos veces.
  bool _processing = false;

  Future<void> _processSale() async {
    if (_processing || (_cart.isEmpty && _cartPacks.isEmpty)) return;
    setState(() => _processing = true);
    try {
      await _registerSale();
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _registerSale() async {
    final sale = SaleFromCartFactory.create(
      date: DateTime.now(),
      products: _cart,
      packs: _cartPacks,
      promotions: _promotionsMap,
      combos: _combos,
      paymentMethod: _paymentMethod,
      adjustmentFactor: _cartAdjustmentFactor,
      lineDiscounts: _lineDiscounts,
    );

    final int saleId;
    try {
      saleId = await _saleRepository.processSale(sale);
    } on InsufficientStockException catch (e) {
      // Otro cambio (sync, copia restaurada…) bajó el stock: se recarga el
      // catálogo para que el carrito se corrija con las existencias reales
      if (mounted) {
        AppAlerts.showError(context, context.l10n.saleStockChanged(e.name));
        await _loadData();
      }
      return;
    } catch (_) {
      // La transacción se deshace entera: el carrito se conserva
      if (mounted) AppAlerts.showError(context, context.l10n.saleFailed);
      return;
    }
    final method = _paymentMethod;

    setState(() {
      _cart.clear();
      _cartPacks.clear();
      _lineDiscounts.clear();
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
    return KeyedSubtree(
      key: _headerKey,
      child: SalesCatalogHeader(
        isProductTab: _tabController.index == 0,
        productSearchController: _productSearchController,
        packSearchController: _packSearchController,
        productSearchQuery: _productSearchQuery,
        packSearchQuery: _packSearchQuery,
        categories: _categories,
        categoryFilter: _categoryFilter,
        onProductSearchChanged: (value) =>
            setState(() => _productSearchQuery = value),
        onPackSearchChanged: (value) =>
            setState(() => _packSearchQuery = value),
        onCategoryChanged: (categoryId) =>
            setState(() => _categoryFilter = categoryId),
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
      onPressed: isEmpty || _processing ? null : _processSale,
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

  /// Columnas del catálogo según el ancho disponible: tarjetas de ~150 dp (en
  /// una tablet caben muchas más que en un móvil), con un mínimo por diseño.
  static int _catalogColumns(double width, {required int min}) =>
      (width / 150).floor().clamp(min, 8);

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

    // El carrito vive en memoria (CartSession): se recupera al volver a la caja
    _saveCartSession();
    final hasCart = _cart.isNotEmpty || _cartPacks.isNotEmpty;
    return PopScope(
      // "Atrás" solo pide confirmar si cierra la app (única pantalla): si hay
      // pantalla debajo, el carrito se conserva al volver
      canPop: !hasCart || Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final leave = await _confirmLeaveWithCart();
        if (!leave) return;
        // pop() directo no vuelve a pasar por este PopScope
        if (navigator.canPop()) {
          navigator.pop();
        } else {
          await SystemNavigator.pop();
        }
      },
      child: Listener(
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
            actions: [
              IconButton(
                tooltip: context.l10n.coachHelpTooltip,
                icon: const Icon(Icons.help_outline),
                onPressed: () =>
                    CoachGuide.replay(context, 'sales', _guideSteps),
              ),
            ],
            bottom: TabBar(
              key: _tabsKey,
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
                              crossAxisCount: _catalogColumns(
                                screenSize.width * 3 / 5,
                                min: 4,
                              ),
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
                        lineDiscounts: _lineDiscounts,
                        onLineDiscountChanged: _setLineDiscount,
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
                        ((_cartHeaderHeight + navBar) /
                                bodyConstraints.maxHeight)
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
                                crossAxisCount: _catalogColumns(
                                  screenSize.width,
                                  min: 3,
                                ),
                                // Que el carrito plegado no tape la última fila
                                bottomPadding:
                                    _cartMinSize * bodyConstraints.maxHeight +
                                    24,
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
                          hasExtraLine:
                              _hasAdjustment || _lineDiscounts.isNotEmpty,
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
                            lineDiscounts: _lineDiscounts,
                            onLineDiscountChanged: _setLineDiscount,
                          ),
                          paymentMethodSelector: _buildPaymentMethodSelector(),
                          checkoutButton: _buildCheckoutButton(large: true),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }

  /// Pregunta si se descarta el carrito al salir de Ventas.
  Future<bool> _confirmLeaveWithCart() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.salesLeaveCartTitle),
        content: Text(dialogContext.l10n.salesLeaveCartBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.l10n.salesLeaveCartStay),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.l10n.salesLeaveCartExit),
          ),
        ],
      ),
    );
    return leave ?? false;
  }
}
