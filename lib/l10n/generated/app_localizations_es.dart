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
  String get promotionType => 'Tipo de Promoción';

  @override
  String get bundleFixedPrice => 'Precio fijo por lote';

  @override
  String get percentageDiscount => 'Descuento porcentual (%)';

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
  String get addProduct => 'Añadir producto...';

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
  String get selectFairPrompt =>
      'Selecciona una feria guardada o escribe una nueva:';

  @override
  String get availableFairs => 'Ferias disponibles';

  @override
  String get enterNewFairOrNone => '-- Escribir nueva / Ninguna --';

  @override
  String get fairName => 'Nombre de la Feria';

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
      'Clona la base de datos completa con otro dispositivo cercano vía Wi-Fi o Hotspot.';

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
  String get syncLocalTitle => 'Sincronización Local (Wi-Fi / Hotspot)';

  @override
  String get syncLocalDescription =>
      'Conecta ambos dispositivos a la misma red Wi-Fi o activa un Hotspot en uno de ellos para clonar el inventario al instante.';

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
}
