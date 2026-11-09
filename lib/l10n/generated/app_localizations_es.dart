// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get drawerSubtitle => 'Gestión y POS';

  @override
  String get navSectionMain => 'PRINCIPAL';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navSales => 'Panel de Ventas (TPV)';

  @override
  String get navSectionStockOffers => 'ALMACÉN Y OFERTAS';

  @override
  String get navInventory => 'Gestión de Inventario';

  @override
  String get navPromotions => 'Gestor de Promociones';

  @override
  String get navPacks => 'Packs y Bundles';

  @override
  String get navSectionRecords => 'REGISTROS';

  @override
  String get navHistory => 'Historial y Ferias';

  @override
  String get navDataManagement => 'Gestión de Datos';

  @override
  String get navDataManagementSubtitle => 'Copias de seguridad y Sync';

  @override
  String get themeNameDefault => 'Por defecto / Sistema';

  @override
  String get themeNameBlue => 'Azul Eléctrico';

  @override
  String get themeNameGreen => 'Verde Esmeralda';

  @override
  String get themeNamePurple => 'Púrpura Ciber';

  @override
  String get themeNameRed => 'Rojo Carmesí';

  @override
  String get themeNameOrange => 'Naranja Épico';

  @override
  String themeChanged(Object theme) {
    return '🎨 ¡Tema cambiado a: $theme!';
  }

  @override
  String get updateSearching => 'Buscando actualizaciones en GitHub...';

  @override
  String get updateLatest => '¡La aplicación ya está en la última versión!';

  @override
  String get updateUnknownVersion => 'Desconocida';

  @override
  String get updateNoNotes => 'Sin notas de la versión.';

  @override
  String updateReleaseHeading(Object version) {
    return '🚀 Versión $version';
  }

  @override
  String get updateGenericReleaseNotes => 'Mejoras y correcciones generales.';

  @override
  String updateAvailableTitle(Object version) {
    return '¡Nueva versión v$version disponible!';
  }

  @override
  String get updateAvailableBody =>
      'Hay una actualización lista para instalar con mejoras y correcciones:';

  @override
  String updateDownloading(Object percent) {
    return 'Descargando... $percent%';
  }

  @override
  String get later => 'Más tarde';

  @override
  String get updateNow => 'Actualizar ahora';

  @override
  String get updateDownloadError =>
      'Error al descargar la actualización. Revisa tu conexión a internet.';

  @override
  String get updateConnectionError => 'No se pudo conectar con el servidor.';

  @override
  String get dashboardTitle => 'Panel de Control';

  @override
  String get privacyOff => 'Desactivar modo privacidad';

  @override
  String get privacyOn => 'Activar modo privacidad';

  @override
  String get searchUpdates => 'Buscar actualizaciones';

  @override
  String get metricInventoryCost => 'COSTE ALMACÉN';

  @override
  String get metricSalesValue => 'VALOR VENTA';

  @override
  String get metricNetProfit => 'BENEFICIO NETO REAL';

  @override
  String get chartButtonTitle => 'Balance por Ferias y Días';

  @override
  String get chartButtonSubtitle => 'Ver gráfico de barras y beneficio neto';

  @override
  String get cashDesk => 'CAJA GENERAL';

  @override
  String get cumulativeBalance =>
      'Balance acumulado de ferias y ventas directas';

  @override
  String get chartTotalRevenue => 'TOTAL INGRESOS';

  @override
  String get chartTotalNet => 'TOTAL NETO';

  @override
  String get chartDays => 'Días sueltos';

  @override
  String get chartFairs => 'Ferias';

  @override
  String get chartNetProfit => 'Beneficio Neto';

  @override
  String chartDayTitle(Object date) {
    return 'Día: $date';
  }

  @override
  String chartFairTitle(Object fair) {
    return '🎪 Feria: $fair';
  }

  @override
  String chartRevenue(Object amount) {
    return 'Ingresos: $amount';
  }

  @override
  String chartNet(Object amount) {
    return 'Neto: $amount';
  }

  @override
  String get chartDetailsTitle => 'Balance Detallado';

  @override
  String get privacyOffShort => 'Desactivar privacidad';

  @override
  String get privacyOnShort => 'Activar privacidad';

  @override
  String get chartEmpty => 'Aún no hay ventas para mostrar.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get save => 'Guardar';

  @override
  String get update => 'Actualizar';

  @override
  String get required => 'Requerido';

  @override
  String get camera => 'Cámara';

  @override
  String get gallery => 'Galería';

  @override
  String get inventoryTitle => 'Gestión de Inventario';

  @override
  String get photoUpdated => '📸 ¡Foto actualizada con éxito!';

  @override
  String get productDeleted => '🗑️ Producto eliminado permanentemente.';

  @override
  String get deleteProductTitle => 'Eliminar producto';

  @override
  String get deleteProductConfirm =>
      '¿Estás seguro de que deseas eliminar este producto de forma permanente?';

  @override
  String editFieldTitle(Object field) {
    return 'Editar $field';
  }

  @override
  String get newValue => 'Nuevo valor';

  @override
  String get selectPromotion => 'Seleccionar Promoción';

  @override
  String get appliedPromotion => 'Promoción Aplicada';

  @override
  String get noPromotion => 'Sin promoción';

  @override
  String get promotionUpdated => '🏷️ Promoción actualizada.';

  @override
  String get takeNewPhoto => 'Tomar nueva foto';

  @override
  String get chooseGalleryPhoto => 'Elegir de la galería';

  @override
  String get productUpdated => '✨ ¡Producto actualizado con éxito!';

  @override
  String get productCreated => '🎉 ¡Producto creado con éxito!';

  @override
  String get searchProduct => 'Buscar producto por nombre...';

  @override
  String get inventoryEmpty => 'No hay productos en el inventario.';

  @override
  String get productsNotFound => 'No se encontraron productos con ese nombre.';

  @override
  String get tableActions => 'ACCIONES';

  @override
  String get tablePhoto => 'FOTO';

  @override
  String get tableName => 'NOMBRE';

  @override
  String get tableUnits => 'UNIDADES';

  @override
  String get tablePrice => 'PRECIO';

  @override
  String get tableCost => 'COSTE';

  @override
  String get tablePromotion => 'PROMOCIÓN';

  @override
  String get editAll => 'Editar todo';

  @override
  String get fieldName => 'Nombre';

  @override
  String get fieldUnits => 'Unidades';

  @override
  String get fieldSalePrice => 'Precio de venta';

  @override
  String get fieldAcquisitionCost => 'Coste de adquisición';

  @override
  String get nameUpdated => '✏️ Nombre actualizado.';

  @override
  String get stockUpdated => '📦 Stock actualizado.';

  @override
  String get salePriceUpdated => '💰 Precio de venta actualizado.';

  @override
  String get costUpdated => '📉 Coste actualizado.';

  @override
  String get productFormEditTitle => 'Editar Producto';

  @override
  String get productFormNewTitle => 'Nuevo Producto';

  @override
  String get productName => 'Nombre del producto';

  @override
  String get unitsInStock => 'Unidades en stock';

  @override
  String get salePrice => 'Precio de venta (€)';

  @override
  String get acquisitionCost => 'Coste de adquisición (€)';

  @override
  String get promotionFormEditTitle => 'Editar Promoción';

  @override
  String get promotionFormNewTitle => 'Nueva Promoción';

  @override
  String get offerName => 'Nombre de la oferta';

  @override
  String get minimumQuantity => 'Cantidad mínima (Unidades a llevar)';

  @override
  String get validNumberRequired => 'Número válido requerido';

  @override
  String get bundleTotalPrice => 'Precio total del lote (€)';

  @override
  String get discountPercentage => 'Porcentaje de descuento (%)';

  @override
  String get validValueRequired => 'Valor válido requerido';

  @override
  String get promotionCreated => '🎉 ¡Promoción creada con éxito!';

  @override
  String get deletePromotionTitle => 'Eliminar Promoción';

  @override
  String confirmDeletePromotion(Object name) {
    return '¿Seguro que deseas eliminar la promoción \"$name\"? Los productos vinculados se quedarán sin promoción.';
  }

  @override
  String get promotionDeleted => '🗑️ Promoción eliminada correctamente.';

  @override
  String get searchPromotion => 'Buscar promoción por nombre...';

  @override
  String get promotionsEmpty =>
      'No hay promociones creadas. Crea una con el botón +';

  @override
  String get promotionsNotFound =>
      'No se encontraron promociones con ese nombre.';

  @override
  String promotionBundleSummary(Object quantity, Object price) {
    return 'Llevando $quantity unidades por $price €';
  }

  @override
  String promotionPercentSummary(Object percent, Object quantity) {
    return '$percent% de descuento a partir de $quantity uds.';
  }

  @override
  String get promotionUpdatedSuccess => '✨ ¡Promoción actualizada con éxito!';

  @override
  String get packsTitle => 'Gestión de Packs y Bundles';

  @override
  String get searchPacks => 'Buscar pack o producto dentro de los packs...';

  @override
  String get packsEmpty => 'No hay packs creados todavía.';

  @override
  String get packsNotFound =>
      'No se encontraron packs o componentes con ese nombre.';

  @override
  String packDismantled(Object pack) {
    return '1 unidad de \"$pack\" desmontada. Componentes devueltos al almacén.';
  }

  @override
  String packStockMissing(Object product, Object quantity) {
    return 'Falta stock de \"$product\" (necesitas $quantity uds más en almacén).';
  }

  @override
  String packAssembled(Object pack) {
    return '¡1 unidad montada añadida a \"$pack\"!';
  }

  @override
  String get packNeedProducts =>
      'Primero necesitas productos activos en el inventario.';

  @override
  String get packCreated => '¡Pack creado con éxito!';

  @override
  String get packModified => '¡Pack modificado con éxito!';

  @override
  String get deletePackTitle => 'Eliminar Pack';

  @override
  String confirmDeletePack(Object pack, Object quantity) {
    return '¿Seguro que deseas eliminar \"$pack\"? Los componentes de los $quantity packs montados volverán al almacén.';
  }

  @override
  String get packDeleted =>
      'Pack eliminado y componentes devueltos al almacén.';

  @override
  String get createPackTitle => 'Crear Nuevo Pack / Bundle';

  @override
  String get editPackTitle => 'Modificar Pack';

  @override
  String get packComponents => 'Componentes del Pack:';

  @override
  String get packEmpty => 'No hay productos en este pack.';

  @override
  String get createPack => 'Crear Pack';

  @override
  String get packName => 'Nombre del Pack';

  @override
  String get packPrice => 'Precio (€)';

  @override
  String get packStartingStock => 'Stock inicial';

  @override
  String packStockDetails(Object available, Object required) {
    return 'Almacén: $available (Req: $required)';
  }

  @override
  String get packComponentsPerUnit => 'Componentes de 1 unidad de este pack:';

  @override
  String packUnitCount(Object count) {
    return '$count uds';
  }

  @override
  String packComponentCount(Object count) {
    return '$count uds/pack';
  }

  @override
  String get productOutOfStock => 'Este producto está sin stock.';

  @override
  String get packOutOfStock => 'Este pack no tiene stock montado.';

  @override
  String get noMoreProductStock =>
      'No hay más stock disponible de este producto.';

  @override
  String get noMorePackStock => 'No hay más unidades en stock de este pack.';

  @override
  String productRemovedFromCart(Object name) {
    return '$name eliminado del carrito';
  }

  @override
  String packRemovedFromCart(Object name) {
    return 'Pack $name eliminado del carrito';
  }

  @override
  String get saleCompleted => '¡Cobro realizado con éxito!';

  @override
  String get salesTitle => 'Panel de Ventas (TPV)';

  @override
  String get salesProductsTab => 'Productos Sueltos';

  @override
  String get salesPacksTab => 'Packs y Bundles';

  @override
  String get searchProducts => 'Buscar producto...';

  @override
  String get searchPacksOrComponents => 'Buscar pack o componente...';

  @override
  String get noPacksFound => 'No se encontraron packs.';

  @override
  String cartItemsCount(Object count) {
    return 'Items: $count';
  }

  @override
  String cartTotal(Object amount) {
    return 'Total: $amount €';
  }

  @override
  String get checkout => 'COBRAR';

  @override
  String get cartEmpty => 'El carrito está vacío';

  @override
  String promoAppliedName(Object name) {
    return 'Oferta aplicada: $name';
  }

  @override
  String promoAvailableName(Object name) {
    return 'Promo disponible: $name';
  }

  @override
  String pricePerUnit(Object amount) {
    return '$amount €/ud';
  }

  @override
  String pricePerPack(Object amount) {
    return '$amount €/pack';
  }

  @override
  String get stockAvailable => 'Stock disponible';

  @override
  String get outOfStock => 'Agotado';

  @override
  String unitsRemaining(Object count) {
    return 'Quedan $count uds';
  }

  @override
  String get inCart => 'En el carrito';

  @override
  String unitCount(Object count) {
    return '$count uds';
  }

  @override
  String get packContents => 'Contenido';

  @override
  String get promotion => 'Promoción';

  @override
  String get status => 'Estado';

  @override
  String get offerApplied => 'Oferta aplicada';

  @override
  String get promotionShortfall => 'Faltan uds para activar';

  @override
  String promotionShortfallCombined(Object count, Object other) {
    return 'Faltan uds (combinando $count + $other)';
  }

  @override
  String get totalAccumulated => 'Total acumulado';

  @override
  String get added => '¡Añadido!';

  @override
  String get addAnotherUnit => 'Añadir otra unidad';

  @override
  String get addAnotherPack => 'Añadir otro pack';

  @override
  String get addToCart => 'Añadir al carrito';

  @override
  String get closePreview => 'Cerrar vista previa';

  @override
  String refundTitle(Object ticket) {
    return 'Devolución Ticket #$ticket';
  }

  @override
  String get refundInstruction =>
      'Indica cuántas unidades devuelves de cada artículo:';

  @override
  String get looseProducts => 'Productos Sueltos';

  @override
  String get unknown => 'Desconocido';

  @override
  String purchasedItemSummary(Object quantity, Object amount) {
    return 'Compradas: $quantity  •  Abonado: $amount €';
  }

  @override
  String get packsBundles => 'Packs / Bundles';

  @override
  String packNameLabel(Object name) {
    return '$name (Pack)';
  }

  @override
  String purchasedPackSummary(Object quantity, Object amount) {
    return 'Comprados: $quantity  •  Abonado: $amount €';
  }

  @override
  String get openPackRestock => 'Pack abierto (Devolver piezas)';

  @override
  String get openPackRestockSubtitle =>
      'Suma stock a los artículos individuales.';

  @override
  String get refundTotalLabel => 'Total a Reembolsar al cliente (€)';

  @override
  String get refundAutoHelp =>
      'Cálculo automático de ruptura de promoción. Editable si es necesario.';

  @override
  String get refundCannotExceed =>
      'No puedes devolver más de lo que cobró el ticket.';

  @override
  String get refundSuccess =>
      'Devolución procesada y contabilidad rebalanceada.';

  @override
  String get confirm => 'Confirmar';

  @override
  String get assignFairTitle => 'Agrupar en Feria';

  @override
  String get fairUnassigned => 'Feria desasignada correctamente.';

  @override
  String salesGroupedFair(Object fair) {
    return 'Ventas agrupadas en \"$fair\" con éxito.';
  }

  @override
  String get searchHistory => 'Buscar ticket, artículo, feria...';

  @override
  String get salesHistoryEmpty => 'No hay ventas registradas aún.';

  @override
  String get historyNoResults => 'No hay resultados para tu búsqueda.';

  @override
  String ticketCount(Object count) {
    return '$count tickets registrados';
  }

  @override
  String get changeFair => 'Cambiar Feria';

  @override
  String get groupIntoFair => 'Agrupar en Feria';

  @override
  String ticketTitle(Object ticket) {
    return 'Ticket #$ticket';
  }

  @override
  String get discountApplied => 'Dto aplicado';

  @override
  String get refund => 'Devolución';

  @override
  String get refundTitleHistory => 'Historial y Ferias';

  @override
  String get exportPrompt => 'Selecciona dónde guardar la copia...';

  @override
  String get backupSaved => '✨ ¡Copia de seguridad guardada con éxito!';

  @override
  String get exportFailed => 'Exportación cancelada u ocurrió un error.';

  @override
  String get restorePrompt =>
      'Busca el archivo de respaldo en tu dispositivo...';

  @override
  String get restoreFailed => 'Restauración cancelada u ocurrió un error.';

  @override
  String get databaseRestoredTitle => '🔄 Base de Datos Restaurada';

  @override
  String get databaseRestoredMessage =>
      'La base de datos se ha actualizado correctamente. Es necesario reiniciar la aplicación para aplicar los cambios de forma segura.';

  @override
  String get restartNow => 'Reiniciar ahora';

  @override
  String get dataManagementTitle => 'Gestión de Datos';

  @override
  String get syncByQrTitle => 'Sincronización por QR (Ferias)';

  @override
  String get syncByQrDescription =>
      'Clona la base de datos completa en otro móvil cercano escaneando un QR, sin necesidad de Wi‑Fi.';

  @override
  String get backupSectionTitle => 'COPIAS DE SEGURIDAD EN ARCHIVO';

  @override
  String get exportBackupTitle => 'Exportar copia de seguridad';

  @override
  String get exportBackupDescription =>
      'Guarda un archivo de respaldo de tu base de datos.';

  @override
  String get restoreBackupTitle => 'Restaurar copia de seguridad';

  @override
  String get restoreBackupDescription =>
      'Carga un archivo de respaldo previo para recuperar datos.';

  @override
  String get syncServerReady =>
      '📡 Servidor listo. Muestra el QR al dispositivo receptor.';

  @override
  String get syncServerStopped => 'Servidor de sincronización cerrado.';

  @override
  String get scannerTitle => 'Escanear QR de Sincronización';

  @override
  String get syncVerifyNetwork => 'Verificando red...';

  @override
  String syncErrorPrefix(Object message) {
    return '❌ Error: $message';
  }

  @override
  String get syncSuccessTitle => '¡Sincronización Exitosa!';

  @override
  String get syncSuccessMessage =>
      'La base de datos se ha clonado correctamente desde el otro dispositivo. Es necesario reiniciar la aplicación para aplicar los cambios de forma segura.';

  @override
  String get syncTitle => 'Sincronización de Dispositivos';

  @override
  String get syncLocalTitle => 'Clonar a otro móvil';

  @override
  String get syncLocalDescription =>
      'Uno emite y el otro escanea el QR. No hace falta Wi‑Fi: la app crea su propio punto de acceso.';

  @override
  String get syncEmitData => '📤 Emitir Datos (Crear QR)';

  @override
  String get syncReceiveData => '📥 Recibir Datos (Escanear QR)';

  @override
  String get syncScanFromReceiver => 'Escanea este código desde el receptor:';

  @override
  String syncActiveIp(Object ip) {
    return 'IP Activa: $ip';
  }

  @override
  String get syncStopBroadcast => 'Detener Emisión';

  @override
  String get syncNoIp =>
      'No se pudo detectar la IP. ¿Estás conectado a un Wi-Fi o Hotspot activo?';

  @override
  String get syncLocalDbMissing => 'La base de datos local no existe.';

  @override
  String get syncStartFailed => 'Error al iniciar el servidor local.';

  @override
  String get syncNoNetwork =>
      '⚠️ No tienes red. Conéctate al Wi-Fi o Hotspot del emisor.';

  @override
  String syncDifferentNetworks(Object sender, Object receiver) {
    return '⚠️ Parece que estáis en Wi-Fis distintas (Emisor: $sender.x / Tú: $receiver.x)';
  }

  @override
  String syncSearchingConnection(Object attempt, Object maximum) {
    return 'Buscando conexión... (Intento $attempt/$maximum)';
  }

  @override
  String syncDownloadingPercent(Object percent) {
    return 'Descargando... $percent%';
  }

  @override
  String syncDownloadingMegabytes(Object amount) {
    return 'Descargando... $amount MB';
  }

  @override
  String get syncNetworkCutRetry => 'Corte de red. Reintentando...';

  @override
  String get syncUnstableDownload =>
      'Conexión inestable. No se pudo completar la descarga.';

  @override
  String get syncInstalling => 'Instalando datos de forma segura...';

  @override
  String get syncCompleted => '¡Sincronización completada con éxito!';

  @override
  String get syncApplyFailed =>
      'Error al aplicar datos. Se restauró tu BD original.';

  @override
  String get syncServerRejected => 'El servidor rechazó la conexión.';

  @override
  String syncNetworkRetry(Object attempt) {
    return 'Pérdida de red... (Reintento $attempt)';
  }

  @override
  String get syncSenderNotFound =>
      'No se encontró el emisor. Revisa el Wi-Fi/Hotspot.';

  @override
  String get packAddAtLeastOne =>
      'Añade al menos 1 producto al pack usando el desplegable.';

  @override
  String packInsufficientStock(Object product, Object quantity) {
    return 'Stock insuficiente de \"$product\" para montar $quantity unidades.';
  }

  @override
  String get databaseDeleteTitle => 'Borrar toda la base de datos';

  @override
  String get databaseDeleteDescription =>
      'Eliminará productos, packs, promociones, ventas e historial.';

  @override
  String get databaseDeleteWarning =>
      'Se eliminarán permanentemente todos los datos de esta aplicación. Esta acción no se puede deshacer.';

  @override
  String get databaseDeleteContinue => 'Continuar';

  @override
  String get databaseDeleteFinalTitle => 'Confirmación final';

  @override
  String get databaseDeleteFinalWarning =>
      '¿Confirmas que quieres borrar definitivamente toda la base de datos?';

  @override
  String get databaseDeleteConfirm => 'Borrar todo';

  @override
  String get databaseDeleteFailure => 'No se pudo borrar la base de datos.';

  @override
  String get databaseDeletedTitle => 'Base de datos borrada';

  @override
  String get databaseDeletedMessage =>
      'La base de datos está vacía. Reinicia la aplicación para continuar.';

  @override
  String get unknownDeleted => 'Desconocido o eliminado';

  @override
  String get unknownPackDeleted => 'Pack desconocido o eliminado';

  @override
  String get paymentMethodTitle => 'Método de pago';

  @override
  String get paymentCash => 'Efectivo';

  @override
  String get paymentPaypal => 'PayPal';

  @override
  String get paymentBizum => 'Bizum';

  @override
  String refundViaMethod(String method) {
    return 'Se devolverá por $method (método original)';
  }

  @override
  String get revenueByPaymentMethod => 'INGRESOS POR MÉTODO DE PAGO';

  @override
  String get paymentUnspecified => 'Sin especificar';

  @override
  String get refundMethodUnknown =>
      'Venta sin método registrado: devuelve por donde se cobró';

  @override
  String get chartFilterAll => 'Todo';

  @override
  String get chartMargin => 'MARGEN';

  @override
  String get chartTapHint => 'Toca una barra para ver su detalle';

  @override
  String get chartHistory => 'HISTORIAL';

  @override
  String get chartNoDataForFilter => 'No hay datos para este filtro.';

  @override
  String get inventoryFilterAll => 'Todos';

  @override
  String get inventoryFilterLow => 'Stock bajo';

  @override
  String get inventoryFilterOut => 'Agotados';

  @override
  String get inventoryFilterPromo => 'Con promoción';

  @override
  String inventorySummary(String products, String units, String out) {
    return '$products productos · $units uds · $out agotados';
  }

  @override
  String get inventoryMargin => 'Margen';

  @override
  String inventoryCostMargin(String cost, String margin) {
    return 'Coste $cost · margen $margin';
  }

  @override
  String get invalidNumber => 'Introduce un número válido (ej. 12,50)';

  @override
  String get trashSlideTitle => 'Último paso';

  @override
  String get trashSlideHint =>
      'Desliza la base de datos hasta la papelera para borrarlo todo';

  @override
  String get trashSlideRelease => 'Suelta para borrar';

  @override
  String get trashSlideDrag => 'Desliza →';

  @override
  String get syncEmitHotspot => 'Emitir sin Wi‑Fi';

  @override
  String get syncEmitHotspotHint =>
      'Crea un punto de acceso temporal: no hace falta ninguna red';

  @override
  String get syncEmitSameWifi => 'Emitir por la misma red Wi‑Fi';

  @override
  String get syncHotspotStarting => 'Creando punto de acceso…';

  @override
  String syncHotspotNetwork(String ssid) {
    return 'Red: $ssid';
  }

  @override
  String syncHotspotPassword(String password) {
    return 'Contraseña: $password';
  }

  @override
  String get syncConnectingToSender =>
      'Conectando a la red del emisor… acepta el aviso de Android';

  @override
  String get syncHotspotPermissionDenied =>
      'Sin el permiso de dispositivos cercanos no se puede crear el punto de acceso.';

  @override
  String get syncHotspotLocationOff =>
      'Activa la ubicación del móvil para crear el punto de acceso.';

  @override
  String get syncHotspotIncompatible =>
      'Desactiva el punto de acceso o compartir conexión del móvil e inténtalo de nuevo.';

  @override
  String get syncHotspotUnsupported =>
      'Este móvil no puede crear el punto de acceso. Usa la opción de misma red Wi‑Fi.';

  @override
  String get syncHotspotFailed => 'No se pudo crear el punto de acceso.';

  @override
  String get syncConnectFailed =>
      'No se pudo conectar a la red del emisor. ¿Aceptaste la conexión?';

  @override
  String get syncManualConnectTitle => 'Conéctate a la red del emisor';

  @override
  String get syncManualConnectBody =>
      'Este móvil no puede conectarse solo. Ve a Ajustes › Wi‑Fi, conéctate a esta red y vuelve aquí:';

  @override
  String get syncManualConnectDone => 'Ya estoy conectado';

  @override
  String get syncOpenSettings => 'Abrir ajustes';

  @override
  String get syncInvalidQr => 'Este QR no es de KeepInventory.';

  @override
  String get syncApprovalTitle => '¿Permitir copiar tus datos?';

  @override
  String syncApprovalBody(String device) {
    return '$device quiere copiar todo tu inventario, packs, promociones y ventas.';
  }

  @override
  String syncApprovalCode(String code) {
    return 'Código: $code';
  }

  @override
  String get syncApprovalCodeHint =>
      'Permite solo si el otro móvil muestra el mismo código.';

  @override
  String get syncApprovalAllow => 'Permitir';

  @override
  String get syncApprovalDeny => 'Rechazar';

  @override
  String syncWaitingApproval(String code) {
    return 'Esperando a que el emisor acepte… Código: $code';
  }

  @override
  String get syncDeniedBySender => 'El emisor ha rechazado la solicitud.';

  @override
  String get syncApprovalTimeout => 'El emisor no respondió a tiempo.';

  @override
  String get syncRequestDenied => 'Solicitud rechazada';

  @override
  String syncRequestApproved(String device) {
    return 'Envío autorizado a $device';
  }

  @override
  String get navTutorial => 'Tutorial';

  @override
  String get navTutorialSubtitle => 'Cómo usar la app';

  @override
  String get tutorialSkip => 'Saltar';

  @override
  String get tutorialNext => 'Siguiente';

  @override
  String get tutorialBack => 'Atrás';

  @override
  String get tutorialStart => 'Empezar';

  @override
  String get tutorialWelcomeTitle => 'Bienvenido a KeepInventory';

  @override
  String get tutorialWelcomeBody =>
      'Tu inventario y tu caja en el móvil, sin conexión. Te enseñamos lo básico en un minuto.';

  @override
  String get tutorialInventoryTitle => '1. Da de alta tus productos';

  @override
  String get tutorialInventoryBody =>
      'En Inventario pulsa + y pon nombre, unidades, precio y coste. Con el coste la app calcula tu margen y te avisa cuando queda poco stock.';

  @override
  String get tutorialOffersTitle => '2. Packs y promociones';

  @override
  String get tutorialOffersBody =>
      'Agrupa productos en Packs con su propio precio, o crea Promociones (10 % de descuento, 3 por 12 €…) y asígnalas a tus productos. Se aplican solas al vender.';

  @override
  String get tutorialSalesTitle => '3. Vende en segundos';

  @override
  String get tutorialSalesBody =>
      'En Ventas toca los productos para añadirlos al carrito, pulsa COBRAR y elige cómo paga el cliente. El stock se descuenta automáticamente.';

  @override
  String get tutorialHistoryTitle => '4. Historial y devoluciones';

  @override
  String get tutorialHistoryBody =>
      'En Historial tienes el ticket de cada venta. Desde ahí puedes devolver unidades y el importe se recalcula con las promociones.';

  @override
  String get tutorialDashboardTitle => '5. Cuadra la caja';

  @override
  String get tutorialDashboardBody =>
      'El Panel resume ingresos, beneficio y lo cobrado por cada método de pago. Ideal para el final del día.';

  @override
  String get tutorialDataTitle => '6. Tus datos, a salvo';

  @override
  String get tutorialDataBody =>
      'En Gestión de Datos puedes hacer copias de seguridad o clonar todo a otro móvil con un QR, sin Wi‑Fi. Puedes volver a ver este tutorial desde el menú.';

  @override
  String get inventorySortReset => 'Tocar para volver al orden por defecto';

  @override
  String get inventorySortTitle => 'Ordenar';

  @override
  String get inventorySortDefault => 'Por defecto';

  @override
  String get inventorySortName => 'Nombre';

  @override
  String get inventorySortUnits => 'Unidades';

  @override
  String get inventorySortPrice => 'Precio';

  @override
  String get inventorySortCost => 'Coste';

  @override
  String get promotionsTab => 'Promociones';

  @override
  String get combosTab => 'Combos';

  @override
  String get comboNewTitle => 'Nuevo combo';

  @override
  String get comboEditTitle => 'Editar combo';

  @override
  String get comboNameLabel => 'Nombre del combo';

  @override
  String get comboSlotsSection => 'Productos del combo';

  @override
  String get comboSlotAdd => 'Añadir producto';

  @override
  String get comboSlotQuantity => 'Cantidad';

  @override
  String get comboSlotNoProducts => 'Toca para elegir el producto';

  @override
  String get comboPriceLabel => 'Precio del combo';

  @override
  String comboSeparateTotal(String amount) {
    return 'Por separado $amount €';
  }

  @override
  String comboSaving(String amount) {
    return 'Ahorras $amount €';
  }

  @override
  String get comboNoSavingWarning =>
      'Este combo no ahorra nada frente a comprar por separado. ¿Guardar igualmente?';

  @override
  String get comboErrorName => 'Pon un nombre al combo';

  @override
  String get comboErrorMinSlots => 'Añade al menos 2 productos';

  @override
  String get comboErrorEmptySlot => 'Elige un producto en cada hueco';

  @override
  String comboOwnPromoWarning(String products) {
    return '$products ya tiene(n) promoción propia. Dentro del combo se cobra el precio del combo y las unidades sueltas mantienen su promoción. Si prefieres que no se mezclen, quita la promoción del producto en Inventario.';
  }

  @override
  String get comboOwnPromoTitle => 'Productos con promoción';

  @override
  String comboProductInOtherCombo(String name) {
    return 'Ya está en «$name»';
  }

  @override
  String get comboProductInOtherSlot => 'Ya está en este combo';

  @override
  String get comboDeleteTitle => 'Eliminar combo';

  @override
  String comboDeleteConfirm(String name) {
    return '¿Eliminar «$name»? Las ventas anteriores no cambian.';
  }

  @override
  String get comboSaved => 'Combo guardado';

  @override
  String get comboDeleted => 'Combo eliminado';

  @override
  String get combosEmpty =>
      'Sin combos. Crea uno para vender conjuntos a precio fijo sin montar packs.';

  @override
  String get comboBadge => 'Combo';

  @override
  String comboCartTitle(String name) {
    return 'Combo · $name';
  }

  @override
  String comboRefundBreaks(String name) {
    return 'Esto rompe el combo «$name»: lo que queda se cobra a precio normal';
  }

  @override
  String get comboRefundWhole => 'Devolver combo';

  @override
  String comboCount(int count) {
    return '×$count';
  }

  @override
  String get comboNoSavingTitle => 'El combo no ahorra';

  @override
  String productFormMargin(String amount, String percent) {
    return 'Margen por unidad: $amount € ($percent)';
  }

  @override
  String productFormLoss(String amount) {
    return 'Vendes a pérdidas: $amount € por unidad';
  }

  @override
  String get promotionTypeBundle => 'Lote a precio fijo';

  @override
  String get promotionTypePercent => '% de descuento';

  @override
  String promotionPreviewBundle(int count, String price) {
    return 'Llevando $count unidades, pagan $price € en total';
  }

  @override
  String promotionPreviewPercent(int count, String percent) {
    return 'Desde $count unidades, $percent de descuento en cada una';
  }

  @override
  String promotionAutoNameBundle(int count, String price) {
    return '$count por $price €';
  }

  @override
  String promotionAutoNamePercent(int count, String percent) {
    return '−$percent desde $count uds';
  }

  @override
  String packSeparatePrice(String amount) {
    return 'Por separado $amount €';
  }

  @override
  String get packAddProductButton => 'Añadir producto';

  @override
  String get productPickerTitle => 'Elige un producto';

  @override
  String get fairSearchOrCreate => 'Busca o escribe una feria nueva';

  @override
  String fairCreate(String name) {
    return 'Crear «$name»';
  }

  @override
  String get fairRemove => 'Quitar feria';

  @override
  String get fairCurrent => 'Actual';

  @override
  String drawerMadeBy(String name) {
    return 'Hecho con ❤️ por $name';
  }

  @override
  String get drawerFreeApp =>
      'KeepInventory es gratis. Si te ayuda en tus ferias, puedes apoyar el proyecto.';

  @override
  String get drawerDonate => 'Invítame a un café';

  @override
  String get drawerSourceCode => 'Código en GitHub';

  @override
  String get linkOpenError => 'No se pudo abrir el enlace';

  @override
  String get versionMismatchTitle => 'Versiones distintas';

  @override
  String backupVersionMismatch(String backup, String app) {
    return 'Este backup es de la versión $backup y la app está en la $app. Para restaurarlo, usa la misma versión de la app. No se ha cambiado nada.';
  }

  @override
  String get backupVersionUnknownTitle => 'Backup de una versión anterior';

  @override
  String backupVersionUnknown(String app) {
    return 'Este backup se hizo con una versión anterior a la 1.14.1 y no se puede comprobar si coincide con la tuya ($app). Si lo restauras, la app intentará adaptarlo. ¿Restaurar igualmente?';
  }

  @override
  String get backupRestoreAnyway => 'Restaurar igualmente';

  @override
  String get backupNotRestored => 'No se ha restaurado el backup';

  @override
  String syncVersionMismatch(String other, String mine) {
    return 'El otro móvil tiene la versión $other y este la $mine. Actualiza los dos a la misma versión para sincronizar.';
  }

  @override
  String get syncVersionUnknown =>
      'El otro móvil tiene una versión anterior a la 1.14.1. Actualiza los dos a la misma versión para sincronizar.';

  @override
  String get understood => 'Entendido';

  @override
  String get fairDeleteTitle => 'Eliminar feria';

  @override
  String fairDeleteConfirmUsed(int count, String name) {
    return '«$name» tiene $count tickets. Se quitarán de la feria (los tickets no se borran). ¿Eliminar la feria de la lista?';
  }

  @override
  String fairDeleteConfirmEmpty(String name) {
    return '¿Eliminar «$name» de la lista de ferias?';
  }

  @override
  String get fairDeleted => 'Feria eliminada';

  @override
  String get comboAddMissing => 'Añadir';

  @override
  String comboMissingShort(String slots) {
    return 'falta $slots';
  }

  @override
  String get productCategory => 'Categoría';

  @override
  String get categoryNone => 'Sin categoría';

  @override
  String get categoryPickTitle => 'Categoría del producto';

  @override
  String get categorySearchOrCreate => 'Busca o escribe una categoría nueva';

  @override
  String categoryCreate(String name) {
    return 'Crear «$name»';
  }

  @override
  String get categoryRemove => 'Quitar categoría';

  @override
  String get categoryDeleteTitle => 'Eliminar categoría';

  @override
  String categoryDeleteConfirmUsed(int count, String name) {
    return '«$name» tiene $count productos. Se quedarán sin categoría (no se borran) y se quitará de los combos que la usen. ¿Eliminar la categoría?';
  }

  @override
  String categoryDeleteConfirmEmpty(String name) {
    return '¿Eliminar «$name» de la lista de categorías?';
  }

  @override
  String get categoryDeleted => 'Categoría eliminada';

  @override
  String get categoryAll => 'Todas';

  @override
  String comboSlotAnyOf(String name) {
    return 'Cualquier $name';
  }

  @override
  String get comboSlotCategories => 'Categorías (cualquier producto de…)';

  @override
  String get comboSlotProducts => 'Productos';

  @override
  String get tableCategory => 'CATEGORÍA';

  @override
  String get promotionApplyToCategory => 'Aplicar a una categoría (opcional)';

  @override
  String get promotionApplyToCategoryHint =>
      'Todos sus productos tendrán esta promoción; luego puedes cambiar cualquiera por separado.';

  @override
  String promotionAppliedToCategory(int count, String name) {
    return 'Promoción aplicada a $count productos de «$name»';
  }
}
