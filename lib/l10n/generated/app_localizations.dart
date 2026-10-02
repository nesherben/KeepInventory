import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @drawerSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Gestión y POS'**
  String get drawerSubtitle;

  /// No description provided for @navSectionMain.
  ///
  /// In es, this message translates to:
  /// **'PRINCIPAL'**
  String get navSectionMain;

  /// No description provided for @navDashboard.
  ///
  /// In es, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navSales.
  ///
  /// In es, this message translates to:
  /// **'Panel de Ventas (TPV)'**
  String get navSales;

  /// No description provided for @navSectionStockOffers.
  ///
  /// In es, this message translates to:
  /// **'ALMACÉN Y OFERTAS'**
  String get navSectionStockOffers;

  /// No description provided for @navInventory.
  ///
  /// In es, this message translates to:
  /// **'Gestión de Inventario'**
  String get navInventory;

  /// No description provided for @navPromotions.
  ///
  /// In es, this message translates to:
  /// **'Gestor de Promociones'**
  String get navPromotions;

  /// No description provided for @navPacks.
  ///
  /// In es, this message translates to:
  /// **'Packs y Bundles'**
  String get navPacks;

  /// No description provided for @navSectionRecords.
  ///
  /// In es, this message translates to:
  /// **'REGISTROS'**
  String get navSectionRecords;

  /// No description provided for @navHistory.
  ///
  /// In es, this message translates to:
  /// **'Historial y Ferias'**
  String get navHistory;

  /// No description provided for @navDataManagement.
  ///
  /// In es, this message translates to:
  /// **'Gestión de Datos'**
  String get navDataManagement;

  /// No description provided for @navDataManagementSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Copias de seguridad y Sync'**
  String get navDataManagementSubtitle;

  /// No description provided for @themeNameDefault.
  ///
  /// In es, this message translates to:
  /// **'Por defecto / Sistema'**
  String get themeNameDefault;

  /// No description provided for @themeNameBlue.
  ///
  /// In es, this message translates to:
  /// **'Azul Eléctrico'**
  String get themeNameBlue;

  /// No description provided for @themeNameGreen.
  ///
  /// In es, this message translates to:
  /// **'Verde Esmeralda'**
  String get themeNameGreen;

  /// No description provided for @themeNamePurple.
  ///
  /// In es, this message translates to:
  /// **'Púrpura Ciber'**
  String get themeNamePurple;

  /// No description provided for @themeNameRed.
  ///
  /// In es, this message translates to:
  /// **'Rojo Carmesí'**
  String get themeNameRed;

  /// No description provided for @themeNameOrange.
  ///
  /// In es, this message translates to:
  /// **'Naranja Épico'**
  String get themeNameOrange;

  /// No description provided for @themeChanged.
  ///
  /// In es, this message translates to:
  /// **'🎨 ¡Tema cambiado a: {theme}!'**
  String themeChanged(Object theme);

  /// No description provided for @updateSearching.
  ///
  /// In es, this message translates to:
  /// **'Buscando actualizaciones en GitHub...'**
  String get updateSearching;

  /// No description provided for @updateLatest.
  ///
  /// In es, this message translates to:
  /// **'¡La aplicación ya está en la última versión!'**
  String get updateLatest;

  /// No description provided for @updateUnknownVersion.
  ///
  /// In es, this message translates to:
  /// **'Desconocida'**
  String get updateUnknownVersion;

  /// No description provided for @updateNoNotes.
  ///
  /// In es, this message translates to:
  /// **'Sin notas de la versión.'**
  String get updateNoNotes;

  /// No description provided for @updateReleaseHeading.
  ///
  /// In es, this message translates to:
  /// **'🚀 Versión {version}'**
  String updateReleaseHeading(Object version);

  /// No description provided for @updateGenericReleaseNotes.
  ///
  /// In es, this message translates to:
  /// **'Mejoras y correcciones generales.'**
  String get updateGenericReleaseNotes;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Nueva versión v{version} disponible!'**
  String updateAvailableTitle(Object version);

  /// No description provided for @updateAvailableBody.
  ///
  /// In es, this message translates to:
  /// **'Hay una actualización lista para instalar con mejoras y correcciones:'**
  String get updateAvailableBody;

  /// No description provided for @updateDownloading.
  ///
  /// In es, this message translates to:
  /// **'Descargando... {percent}%'**
  String updateDownloading(Object percent);

  /// No description provided for @later.
  ///
  /// In es, this message translates to:
  /// **'Más tarde'**
  String get later;

  /// No description provided for @updateNow.
  ///
  /// In es, this message translates to:
  /// **'Actualizar ahora'**
  String get updateNow;

  /// No description provided for @updateDownloadError.
  ///
  /// In es, this message translates to:
  /// **'Error al descargar la actualización. Revisa tu conexión a internet.'**
  String get updateDownloadError;

  /// No description provided for @updateConnectionError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo conectar con el servidor.'**
  String get updateConnectionError;

  /// No description provided for @dashboardTitle.
  ///
  /// In es, this message translates to:
  /// **'Panel de Control'**
  String get dashboardTitle;

  /// No description provided for @privacyOff.
  ///
  /// In es, this message translates to:
  /// **'Desactivar modo privacidad'**
  String get privacyOff;

  /// No description provided for @privacyOn.
  ///
  /// In es, this message translates to:
  /// **'Activar modo privacidad'**
  String get privacyOn;

  /// No description provided for @searchUpdates.
  ///
  /// In es, this message translates to:
  /// **'Buscar actualizaciones'**
  String get searchUpdates;

  /// No description provided for @metricInventoryCost.
  ///
  /// In es, this message translates to:
  /// **'COSTE ALMACÉN'**
  String get metricInventoryCost;

  /// No description provided for @metricSalesValue.
  ///
  /// In es, this message translates to:
  /// **'VALOR VENTA'**
  String get metricSalesValue;

  /// No description provided for @metricNetProfit.
  ///
  /// In es, this message translates to:
  /// **'BENEFICIO NETO REAL'**
  String get metricNetProfit;

  /// No description provided for @chartButtonTitle.
  ///
  /// In es, this message translates to:
  /// **'Balance por Ferias y Días'**
  String get chartButtonTitle;

  /// No description provided for @chartButtonSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ver gráfico de barras y beneficio neto'**
  String get chartButtonSubtitle;

  /// No description provided for @cashDesk.
  ///
  /// In es, this message translates to:
  /// **'CAJA GENERAL'**
  String get cashDesk;

  /// No description provided for @cumulativeBalance.
  ///
  /// In es, this message translates to:
  /// **'Balance acumulado de ferias y ventas directas'**
  String get cumulativeBalance;

  /// No description provided for @chartTotalRevenue.
  ///
  /// In es, this message translates to:
  /// **'TOTAL INGRESOS'**
  String get chartTotalRevenue;

  /// No description provided for @chartTotalNet.
  ///
  /// In es, this message translates to:
  /// **'TOTAL NETO'**
  String get chartTotalNet;

  /// No description provided for @chartDays.
  ///
  /// In es, this message translates to:
  /// **'Días sueltos'**
  String get chartDays;

  /// No description provided for @chartFairs.
  ///
  /// In es, this message translates to:
  /// **'Ferias'**
  String get chartFairs;

  /// No description provided for @chartNetProfit.
  ///
  /// In es, this message translates to:
  /// **'Beneficio Neto'**
  String get chartNetProfit;

  /// No description provided for @chartDayTitle.
  ///
  /// In es, this message translates to:
  /// **'Día: {date}'**
  String chartDayTitle(Object date);

  /// No description provided for @chartFairTitle.
  ///
  /// In es, this message translates to:
  /// **'🎪 Feria: {fair}'**
  String chartFairTitle(Object fair);

  /// No description provided for @chartRevenue.
  ///
  /// In es, this message translates to:
  /// **'Ingresos: {amount}'**
  String chartRevenue(Object amount);

  /// No description provided for @chartNet.
  ///
  /// In es, this message translates to:
  /// **'Neto: {amount}'**
  String chartNet(Object amount);

  /// No description provided for @chartDetailsTitle.
  ///
  /// In es, this message translates to:
  /// **'Balance Detallado'**
  String get chartDetailsTitle;

  /// No description provided for @privacyOffShort.
  ///
  /// In es, this message translates to:
  /// **'Desactivar privacidad'**
  String get privacyOffShort;

  /// No description provided for @privacyOnShort.
  ///
  /// In es, this message translates to:
  /// **'Activar privacidad'**
  String get privacyOnShort;

  /// No description provided for @chartEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay ventas para mostrar.'**
  String get chartEmpty;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @update.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get update;

  /// No description provided for @required.
  ///
  /// In es, this message translates to:
  /// **'Requerido'**
  String get required;

  /// No description provided for @camera.
  ///
  /// In es, this message translates to:
  /// **'Cámara'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In es, this message translates to:
  /// **'Galería'**
  String get gallery;

  /// No description provided for @inventoryTitle.
  ///
  /// In es, this message translates to:
  /// **'Gestión de Inventario'**
  String get inventoryTitle;

  /// No description provided for @photoUpdated.
  ///
  /// In es, this message translates to:
  /// **'📸 ¡Foto actualizada con éxito!'**
  String get photoUpdated;

  /// No description provided for @productDeleted.
  ///
  /// In es, this message translates to:
  /// **'🗑️ Producto eliminado permanentemente.'**
  String get productDeleted;

  /// No description provided for @deleteProductTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar producto'**
  String get deleteProductTitle;

  /// No description provided for @deleteProductConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas eliminar este producto de forma permanente?'**
  String get deleteProductConfirm;

  /// No description provided for @editFieldTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar {field}'**
  String editFieldTitle(Object field);

  /// No description provided for @newValue.
  ///
  /// In es, this message translates to:
  /// **'Nuevo valor'**
  String get newValue;

  /// No description provided for @selectPromotion.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar Promoción'**
  String get selectPromotion;

  /// No description provided for @appliedPromotion.
  ///
  /// In es, this message translates to:
  /// **'Promoción Aplicada'**
  String get appliedPromotion;

  /// No description provided for @noPromotion.
  ///
  /// In es, this message translates to:
  /// **'Sin promoción'**
  String get noPromotion;

  /// No description provided for @promotionUpdated.
  ///
  /// In es, this message translates to:
  /// **'🏷️ Promoción actualizada.'**
  String get promotionUpdated;

  /// No description provided for @takeNewPhoto.
  ///
  /// In es, this message translates to:
  /// **'Tomar nueva foto'**
  String get takeNewPhoto;

  /// No description provided for @chooseGalleryPhoto.
  ///
  /// In es, this message translates to:
  /// **'Elegir de la galería'**
  String get chooseGalleryPhoto;

  /// No description provided for @productUpdated.
  ///
  /// In es, this message translates to:
  /// **'✨ ¡Producto actualizado con éxito!'**
  String get productUpdated;

  /// No description provided for @productCreated.
  ///
  /// In es, this message translates to:
  /// **'🎉 ¡Producto creado con éxito!'**
  String get productCreated;

  /// No description provided for @searchProduct.
  ///
  /// In es, this message translates to:
  /// **'Buscar producto por nombre...'**
  String get searchProduct;

  /// No description provided for @inventoryEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay productos en el inventario.'**
  String get inventoryEmpty;

  /// No description provided for @productsNotFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron productos con ese nombre.'**
  String get productsNotFound;

  /// No description provided for @tableActions.
  ///
  /// In es, this message translates to:
  /// **'ACCIONES'**
  String get tableActions;

  /// No description provided for @tablePhoto.
  ///
  /// In es, this message translates to:
  /// **'FOTO'**
  String get tablePhoto;

  /// No description provided for @tableName.
  ///
  /// In es, this message translates to:
  /// **'NOMBRE'**
  String get tableName;

  /// No description provided for @tableUnits.
  ///
  /// In es, this message translates to:
  /// **'UNIDADES'**
  String get tableUnits;

  /// No description provided for @tablePrice.
  ///
  /// In es, this message translates to:
  /// **'PRECIO'**
  String get tablePrice;

  /// No description provided for @tableCost.
  ///
  /// In es, this message translates to:
  /// **'COSTE'**
  String get tableCost;

  /// No description provided for @tablePromotion.
  ///
  /// In es, this message translates to:
  /// **'PROMOCIÓN'**
  String get tablePromotion;

  /// No description provided for @editAll.
  ///
  /// In es, this message translates to:
  /// **'Editar todo'**
  String get editAll;

  /// No description provided for @fieldName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get fieldName;

  /// No description provided for @fieldUnits.
  ///
  /// In es, this message translates to:
  /// **'Unidades'**
  String get fieldUnits;

  /// No description provided for @fieldSalePrice.
  ///
  /// In es, this message translates to:
  /// **'Precio de venta'**
  String get fieldSalePrice;

  /// No description provided for @fieldAcquisitionCost.
  ///
  /// In es, this message translates to:
  /// **'Coste de adquisición'**
  String get fieldAcquisitionCost;

  /// No description provided for @nameUpdated.
  ///
  /// In es, this message translates to:
  /// **'✏️ Nombre actualizado.'**
  String get nameUpdated;

  /// No description provided for @stockUpdated.
  ///
  /// In es, this message translates to:
  /// **'📦 Stock actualizado.'**
  String get stockUpdated;

  /// No description provided for @salePriceUpdated.
  ///
  /// In es, this message translates to:
  /// **'💰 Precio de venta actualizado.'**
  String get salePriceUpdated;

  /// No description provided for @costUpdated.
  ///
  /// In es, this message translates to:
  /// **'📉 Coste actualizado.'**
  String get costUpdated;

  /// No description provided for @productFormEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar Producto'**
  String get productFormEditTitle;

  /// No description provided for @productFormNewTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo Producto'**
  String get productFormNewTitle;

  /// No description provided for @productName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del producto'**
  String get productName;

  /// No description provided for @unitsInStock.
  ///
  /// In es, this message translates to:
  /// **'Unidades en stock'**
  String get unitsInStock;

  /// No description provided for @salePrice.
  ///
  /// In es, this message translates to:
  /// **'Precio de venta (€)'**
  String get salePrice;

  /// No description provided for @acquisitionCost.
  ///
  /// In es, this message translates to:
  /// **'Coste de adquisición (€)'**
  String get acquisitionCost;

  /// No description provided for @promotionFormEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar Promoción'**
  String get promotionFormEditTitle;

  /// No description provided for @promotionFormNewTitle.
  ///
  /// In es, this message translates to:
  /// **'Nueva Promoción'**
  String get promotionFormNewTitle;

  /// No description provided for @offerName.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la oferta'**
  String get offerName;

  /// No description provided for @promotionType.
  ///
  /// In es, this message translates to:
  /// **'Tipo de Promoción'**
  String get promotionType;

  /// No description provided for @bundleFixedPrice.
  ///
  /// In es, this message translates to:
  /// **'Precio fijo por lote'**
  String get bundleFixedPrice;

  /// No description provided for @percentageDiscount.
  ///
  /// In es, this message translates to:
  /// **'Descuento porcentual (%)'**
  String get percentageDiscount;

  /// No description provided for @minimumQuantity.
  ///
  /// In es, this message translates to:
  /// **'Cantidad mínima (Unidades a llevar)'**
  String get minimumQuantity;

  /// No description provided for @validNumberRequired.
  ///
  /// In es, this message translates to:
  /// **'Número válido requerido'**
  String get validNumberRequired;

  /// No description provided for @bundleTotalPrice.
  ///
  /// In es, this message translates to:
  /// **'Precio total del lote (€)'**
  String get bundleTotalPrice;

  /// No description provided for @discountPercentage.
  ///
  /// In es, this message translates to:
  /// **'Porcentaje de descuento (%)'**
  String get discountPercentage;

  /// No description provided for @validValueRequired.
  ///
  /// In es, this message translates to:
  /// **'Valor válido requerido'**
  String get validValueRequired;

  /// No description provided for @promotionCreated.
  ///
  /// In es, this message translates to:
  /// **'🎉 ¡Promoción creada con éxito!'**
  String get promotionCreated;

  /// No description provided for @deletePromotionTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar Promoción'**
  String get deletePromotionTitle;

  /// No description provided for @confirmDeletePromotion.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que deseas eliminar la promoción \"{name}\"? Los productos vinculados se quedarán sin promoción.'**
  String confirmDeletePromotion(Object name);

  /// No description provided for @promotionDeleted.
  ///
  /// In es, this message translates to:
  /// **'🗑️ Promoción eliminada correctamente.'**
  String get promotionDeleted;

  /// No description provided for @searchPromotion.
  ///
  /// In es, this message translates to:
  /// **'Buscar promoción por nombre...'**
  String get searchPromotion;

  /// No description provided for @promotionsEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay promociones creadas. Crea una con el botón +'**
  String get promotionsEmpty;

  /// No description provided for @promotionsNotFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron promociones con ese nombre.'**
  String get promotionsNotFound;

  /// No description provided for @promotionBundleSummary.
  ///
  /// In es, this message translates to:
  /// **'Llevando {quantity} unidades por {price} €'**
  String promotionBundleSummary(Object quantity, Object price);

  /// No description provided for @promotionPercentSummary.
  ///
  /// In es, this message translates to:
  /// **'{percent}% de descuento a partir de {quantity} uds.'**
  String promotionPercentSummary(Object percent, Object quantity);

  /// No description provided for @promotionUpdatedSuccess.
  ///
  /// In es, this message translates to:
  /// **'✨ ¡Promoción actualizada con éxito!'**
  String get promotionUpdatedSuccess;

  /// No description provided for @packsTitle.
  ///
  /// In es, this message translates to:
  /// **'Gestión de Packs y Bundles'**
  String get packsTitle;

  /// No description provided for @searchPacks.
  ///
  /// In es, this message translates to:
  /// **'Buscar pack o producto dentro de los packs...'**
  String get searchPacks;

  /// No description provided for @packsEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay packs creados todavía.'**
  String get packsEmpty;

  /// No description provided for @packsNotFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron packs o componentes con ese nombre.'**
  String get packsNotFound;

  /// No description provided for @packDismantled.
  ///
  /// In es, this message translates to:
  /// **'1 unidad de \"{pack}\" desmontada. Componentes devueltos al almacén.'**
  String packDismantled(Object pack);

  /// No description provided for @packStockMissing.
  ///
  /// In es, this message translates to:
  /// **'Falta stock de \"{product}\" (necesitas {quantity} uds más en almacén).'**
  String packStockMissing(Object product, Object quantity);

  /// No description provided for @packAssembled.
  ///
  /// In es, this message translates to:
  /// **'¡1 unidad montada añadida a \"{pack}\"!'**
  String packAssembled(Object pack);

  /// No description provided for @packNeedProducts.
  ///
  /// In es, this message translates to:
  /// **'Primero necesitas productos activos en el inventario.'**
  String get packNeedProducts;

  /// No description provided for @packCreated.
  ///
  /// In es, this message translates to:
  /// **'¡Pack creado con éxito!'**
  String get packCreated;

  /// No description provided for @packModified.
  ///
  /// In es, this message translates to:
  /// **'¡Pack modificado con éxito!'**
  String get packModified;

  /// No description provided for @deletePackTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar Pack'**
  String get deletePackTitle;

  /// No description provided for @confirmDeletePack.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que deseas eliminar \"{pack}\"? Los componentes de los {quantity} packs montados volverán al almacén.'**
  String confirmDeletePack(Object pack, Object quantity);

  /// No description provided for @packDeleted.
  ///
  /// In es, this message translates to:
  /// **'Pack eliminado y componentes devueltos al almacén.'**
  String get packDeleted;

  /// No description provided for @createPackTitle.
  ///
  /// In es, this message translates to:
  /// **'Crear Nuevo Pack / Bundle'**
  String get createPackTitle;

  /// No description provided for @editPackTitle.
  ///
  /// In es, this message translates to:
  /// **'Modificar Pack'**
  String get editPackTitle;

  /// No description provided for @packComponents.
  ///
  /// In es, this message translates to:
  /// **'Componentes del Pack:'**
  String get packComponents;

  /// No description provided for @addProduct.
  ///
  /// In es, this message translates to:
  /// **'Añadir producto...'**
  String get addProduct;

  /// No description provided for @packEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay productos en este pack.'**
  String get packEmpty;

  /// No description provided for @createPack.
  ///
  /// In es, this message translates to:
  /// **'Crear Pack'**
  String get createPack;

  /// No description provided for @packName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del Pack'**
  String get packName;

  /// No description provided for @packPrice.
  ///
  /// In es, this message translates to:
  /// **'Precio (€)'**
  String get packPrice;

  /// No description provided for @packStartingStock.
  ///
  /// In es, this message translates to:
  /// **'Stock inicial'**
  String get packStartingStock;

  /// No description provided for @packStockDetails.
  ///
  /// In es, this message translates to:
  /// **'Almacén: {available} (Req: {required})'**
  String packStockDetails(Object available, Object required);

  /// No description provided for @packComponentsPerUnit.
  ///
  /// In es, this message translates to:
  /// **'Componentes de 1 unidad de este pack:'**
  String get packComponentsPerUnit;

  /// No description provided for @packUnitCount.
  ///
  /// In es, this message translates to:
  /// **'{count} uds'**
  String packUnitCount(Object count);

  /// No description provided for @packComponentCount.
  ///
  /// In es, this message translates to:
  /// **'{count} uds/pack'**
  String packComponentCount(Object count);

  /// No description provided for @productOutOfStock.
  ///
  /// In es, this message translates to:
  /// **'Este producto está sin stock.'**
  String get productOutOfStock;

  /// No description provided for @packOutOfStock.
  ///
  /// In es, this message translates to:
  /// **'Este pack no tiene stock montado.'**
  String get packOutOfStock;

  /// No description provided for @noMoreProductStock.
  ///
  /// In es, this message translates to:
  /// **'No hay más stock disponible de este producto.'**
  String get noMoreProductStock;

  /// No description provided for @noMorePackStock.
  ///
  /// In es, this message translates to:
  /// **'No hay más unidades en stock de este pack.'**
  String get noMorePackStock;

  /// No description provided for @productRemovedFromCart.
  ///
  /// In es, this message translates to:
  /// **'{name} eliminado del carrito'**
  String productRemovedFromCart(Object name);

  /// No description provided for @packRemovedFromCart.
  ///
  /// In es, this message translates to:
  /// **'Pack {name} eliminado del carrito'**
  String packRemovedFromCart(Object name);

  /// No description provided for @saleCompleted.
  ///
  /// In es, this message translates to:
  /// **'¡Cobro realizado con éxito!'**
  String get saleCompleted;

  /// No description provided for @salesTitle.
  ///
  /// In es, this message translates to:
  /// **'Panel de Ventas (TPV)'**
  String get salesTitle;

  /// No description provided for @salesProductsTab.
  ///
  /// In es, this message translates to:
  /// **'Productos Sueltos'**
  String get salesProductsTab;

  /// No description provided for @salesPacksTab.
  ///
  /// In es, this message translates to:
  /// **'Packs y Bundles'**
  String get salesPacksTab;

  /// No description provided for @searchProducts.
  ///
  /// In es, this message translates to:
  /// **'Buscar producto...'**
  String get searchProducts;

  /// No description provided for @searchPacksOrComponents.
  ///
  /// In es, this message translates to:
  /// **'Buscar pack o componente...'**
  String get searchPacksOrComponents;

  /// No description provided for @noPacksFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron packs.'**
  String get noPacksFound;

  /// No description provided for @cartItemsCount.
  ///
  /// In es, this message translates to:
  /// **'Items: {count}'**
  String cartItemsCount(Object count);

  /// No description provided for @cartTotal.
  ///
  /// In es, this message translates to:
  /// **'Total: {amount} €'**
  String cartTotal(Object amount);

  /// No description provided for @checkout.
  ///
  /// In es, this message translates to:
  /// **'COBRAR'**
  String get checkout;

  /// No description provided for @cartEmpty.
  ///
  /// In es, this message translates to:
  /// **'El carrito está vacío'**
  String get cartEmpty;

  /// No description provided for @promoAppliedName.
  ///
  /// In es, this message translates to:
  /// **'Oferta aplicada: {name}'**
  String promoAppliedName(Object name);

  /// No description provided for @promoAvailableName.
  ///
  /// In es, this message translates to:
  /// **'Promo disponible: {name}'**
  String promoAvailableName(Object name);

  /// No description provided for @pricePerUnit.
  ///
  /// In es, this message translates to:
  /// **'{amount} €/ud'**
  String pricePerUnit(Object amount);

  /// No description provided for @pricePerPack.
  ///
  /// In es, this message translates to:
  /// **'{amount} €/pack'**
  String pricePerPack(Object amount);

  /// No description provided for @stockAvailable.
  ///
  /// In es, this message translates to:
  /// **'Stock disponible'**
  String get stockAvailable;

  /// No description provided for @outOfStock.
  ///
  /// In es, this message translates to:
  /// **'Agotado'**
  String get outOfStock;

  /// No description provided for @unitsRemaining.
  ///
  /// In es, this message translates to:
  /// **'Quedan {count} uds'**
  String unitsRemaining(Object count);

  /// No description provided for @inCart.
  ///
  /// In es, this message translates to:
  /// **'En el carrito'**
  String get inCart;

  /// No description provided for @unitCount.
  ///
  /// In es, this message translates to:
  /// **'{count} uds'**
  String unitCount(Object count);

  /// No description provided for @packContents.
  ///
  /// In es, this message translates to:
  /// **'Contenido'**
  String get packContents;

  /// No description provided for @promotion.
  ///
  /// In es, this message translates to:
  /// **'Promoción'**
  String get promotion;

  /// No description provided for @status.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get status;

  /// No description provided for @offerApplied.
  ///
  /// In es, this message translates to:
  /// **'Oferta aplicada'**
  String get offerApplied;

  /// No description provided for @promotionShortfall.
  ///
  /// In es, this message translates to:
  /// **'Faltan uds para activar'**
  String get promotionShortfall;

  /// No description provided for @promotionShortfallCombined.
  ///
  /// In es, this message translates to:
  /// **'Faltan uds (combinando {count} + {other})'**
  String promotionShortfallCombined(Object count, Object other);

  /// No description provided for @totalAccumulated.
  ///
  /// In es, this message translates to:
  /// **'Total acumulado'**
  String get totalAccumulated;

  /// No description provided for @added.
  ///
  /// In es, this message translates to:
  /// **'¡Añadido!'**
  String get added;

  /// No description provided for @addAnotherUnit.
  ///
  /// In es, this message translates to:
  /// **'Añadir otra unidad'**
  String get addAnotherUnit;

  /// No description provided for @addAnotherPack.
  ///
  /// In es, this message translates to:
  /// **'Añadir otro pack'**
  String get addAnotherPack;

  /// No description provided for @addToCart.
  ///
  /// In es, this message translates to:
  /// **'Añadir al carrito'**
  String get addToCart;

  /// No description provided for @closePreview.
  ///
  /// In es, this message translates to:
  /// **'Cerrar vista previa'**
  String get closePreview;

  /// No description provided for @refundTitle.
  ///
  /// In es, this message translates to:
  /// **'Devolución Ticket #{ticket}'**
  String refundTitle(Object ticket);

  /// No description provided for @refundInstruction.
  ///
  /// In es, this message translates to:
  /// **'Indica cuántas unidades devuelves de cada artículo:'**
  String get refundInstruction;

  /// No description provided for @looseProducts.
  ///
  /// In es, this message translates to:
  /// **'Productos Sueltos'**
  String get looseProducts;

  /// No description provided for @unknown.
  ///
  /// In es, this message translates to:
  /// **'Desconocido'**
  String get unknown;

  /// No description provided for @purchasedItemSummary.
  ///
  /// In es, this message translates to:
  /// **'Compradas: {quantity}  •  Abonado: {amount} €'**
  String purchasedItemSummary(Object quantity, Object amount);

  /// No description provided for @packsBundles.
  ///
  /// In es, this message translates to:
  /// **'Packs / Bundles'**
  String get packsBundles;

  /// No description provided for @packNameLabel.
  ///
  /// In es, this message translates to:
  /// **'{name} (Pack)'**
  String packNameLabel(Object name);

  /// No description provided for @purchasedPackSummary.
  ///
  /// In es, this message translates to:
  /// **'Comprados: {quantity}  •  Abonado: {amount} €'**
  String purchasedPackSummary(Object quantity, Object amount);

  /// No description provided for @openPackRestock.
  ///
  /// In es, this message translates to:
  /// **'Pack abierto (Devolver piezas)'**
  String get openPackRestock;

  /// No description provided for @openPackRestockSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Suma stock a los artículos individuales.'**
  String get openPackRestockSubtitle;

  /// No description provided for @refundTotalLabel.
  ///
  /// In es, this message translates to:
  /// **'Total a Reembolsar al cliente (€)'**
  String get refundTotalLabel;

  /// No description provided for @refundAutoHelp.
  ///
  /// In es, this message translates to:
  /// **'Cálculo automático de ruptura de promoción. Editable si es necesario.'**
  String get refundAutoHelp;

  /// No description provided for @refundCannotExceed.
  ///
  /// In es, this message translates to:
  /// **'No puedes devolver más de lo que cobró el ticket.'**
  String get refundCannotExceed;

  /// No description provided for @refundSuccess.
  ///
  /// In es, this message translates to:
  /// **'Devolución procesada y contabilidad rebalanceada.'**
  String get refundSuccess;

  /// No description provided for @confirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get confirm;

  /// No description provided for @assignFairTitle.
  ///
  /// In es, this message translates to:
  /// **'Agrupar en Feria'**
  String get assignFairTitle;

  /// No description provided for @selectFairPrompt.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una feria guardada o escribe una nueva:'**
  String get selectFairPrompt;

  /// No description provided for @availableFairs.
  ///
  /// In es, this message translates to:
  /// **'Ferias disponibles'**
  String get availableFairs;

  /// No description provided for @enterNewFairOrNone.
  ///
  /// In es, this message translates to:
  /// **'-- Escribir nueva / Ninguna --'**
  String get enterNewFairOrNone;

  /// No description provided for @fairName.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la Feria'**
  String get fairName;

  /// No description provided for @fairUnassigned.
  ///
  /// In es, this message translates to:
  /// **'Feria desasignada correctamente.'**
  String get fairUnassigned;

  /// No description provided for @salesGroupedFair.
  ///
  /// In es, this message translates to:
  /// **'Ventas agrupadas en \"{fair}\" con éxito.'**
  String salesGroupedFair(Object fair);

  /// No description provided for @searchHistory.
  ///
  /// In es, this message translates to:
  /// **'Buscar ticket, artículo, feria...'**
  String get searchHistory;

  /// No description provided for @salesHistoryEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay ventas registradas aún.'**
  String get salesHistoryEmpty;

  /// No description provided for @historyNoResults.
  ///
  /// In es, this message translates to:
  /// **'No hay resultados para tu búsqueda.'**
  String get historyNoResults;

  /// No description provided for @ticketCount.
  ///
  /// In es, this message translates to:
  /// **'{count} tickets registrados'**
  String ticketCount(Object count);

  /// No description provided for @changeFair.
  ///
  /// In es, this message translates to:
  /// **'Cambiar Feria'**
  String get changeFair;

  /// No description provided for @groupIntoFair.
  ///
  /// In es, this message translates to:
  /// **'Agrupar en Feria'**
  String get groupIntoFair;

  /// No description provided for @ticketTitle.
  ///
  /// In es, this message translates to:
  /// **'Ticket #{ticket}'**
  String ticketTitle(Object ticket);

  /// No description provided for @discountApplied.
  ///
  /// In es, this message translates to:
  /// **'Dto aplicado'**
  String get discountApplied;

  /// No description provided for @refund.
  ///
  /// In es, this message translates to:
  /// **'Devolución'**
  String get refund;

  /// No description provided for @refundTitleHistory.
  ///
  /// In es, this message translates to:
  /// **'Historial y Ferias'**
  String get refundTitleHistory;

  /// No description provided for @exportPrompt.
  ///
  /// In es, this message translates to:
  /// **'Selecciona dónde guardar la copia...'**
  String get exportPrompt;

  /// No description provided for @backupSaved.
  ///
  /// In es, this message translates to:
  /// **'✨ ¡Copia de seguridad guardada con éxito!'**
  String get backupSaved;

  /// No description provided for @exportFailed.
  ///
  /// In es, this message translates to:
  /// **'Exportación cancelada u ocurrió un error.'**
  String get exportFailed;

  /// No description provided for @restorePrompt.
  ///
  /// In es, this message translates to:
  /// **'Busca el archivo de respaldo en tu dispositivo...'**
  String get restorePrompt;

  /// No description provided for @restoreFailed.
  ///
  /// In es, this message translates to:
  /// **'Restauración cancelada u ocurrió un error.'**
  String get restoreFailed;

  /// No description provided for @databaseRestoredTitle.
  ///
  /// In es, this message translates to:
  /// **'🔄 Base de Datos Restaurada'**
  String get databaseRestoredTitle;

  /// No description provided for @databaseRestoredMessage.
  ///
  /// In es, this message translates to:
  /// **'La base de datos se ha actualizado correctamente. Es necesario reiniciar la aplicación para aplicar los cambios de forma segura.'**
  String get databaseRestoredMessage;

  /// No description provided for @restartNow.
  ///
  /// In es, this message translates to:
  /// **'Reiniciar ahora'**
  String get restartNow;

  /// No description provided for @dataManagementTitle.
  ///
  /// In es, this message translates to:
  /// **'Gestión de Datos'**
  String get dataManagementTitle;

  /// No description provided for @syncByQrTitle.
  ///
  /// In es, this message translates to:
  /// **'Sincronización por QR (Ferias)'**
  String get syncByQrTitle;

  /// No description provided for @syncByQrDescription.
  ///
  /// In es, this message translates to:
  /// **'Clona la base de datos completa con otro dispositivo cercano vía Wi-Fi o Hotspot.'**
  String get syncByQrDescription;

  /// No description provided for @backupSectionTitle.
  ///
  /// In es, this message translates to:
  /// **'COPIAS DE SEGURIDAD EN ARCHIVO'**
  String get backupSectionTitle;

  /// No description provided for @exportBackupTitle.
  ///
  /// In es, this message translates to:
  /// **'Exportar copia de seguridad'**
  String get exportBackupTitle;

  /// No description provided for @exportBackupDescription.
  ///
  /// In es, this message translates to:
  /// **'Guarda un archivo de respaldo de tu base de datos.'**
  String get exportBackupDescription;

  /// No description provided for @restoreBackupTitle.
  ///
  /// In es, this message translates to:
  /// **'Restaurar copia de seguridad'**
  String get restoreBackupTitle;

  /// No description provided for @restoreBackupDescription.
  ///
  /// In es, this message translates to:
  /// **'Carga un archivo de respaldo previo para recuperar datos.'**
  String get restoreBackupDescription;

  /// No description provided for @syncServerReady.
  ///
  /// In es, this message translates to:
  /// **'📡 Servidor listo. Muestra el QR al dispositivo receptor.'**
  String get syncServerReady;

  /// No description provided for @syncServerStopped.
  ///
  /// In es, this message translates to:
  /// **'Servidor de sincronización cerrado.'**
  String get syncServerStopped;

  /// No description provided for @scannerTitle.
  ///
  /// In es, this message translates to:
  /// **'Escanear QR de Sincronización'**
  String get scannerTitle;

  /// No description provided for @syncVerifyNetwork.
  ///
  /// In es, this message translates to:
  /// **'Verificando red...'**
  String get syncVerifyNetwork;

  /// No description provided for @syncErrorPrefix.
  ///
  /// In es, this message translates to:
  /// **'❌ Error: {message}'**
  String syncErrorPrefix(Object message);

  /// No description provided for @syncSuccessTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Sincronización Exitosa!'**
  String get syncSuccessTitle;

  /// No description provided for @syncSuccessMessage.
  ///
  /// In es, this message translates to:
  /// **'La base de datos se ha clonado correctamente desde el otro dispositivo. Es necesario reiniciar la aplicación para aplicar los cambios de forma segura.'**
  String get syncSuccessMessage;

  /// No description provided for @syncTitle.
  ///
  /// In es, this message translates to:
  /// **'Sincronización de Dispositivos'**
  String get syncTitle;

  /// No description provided for @syncLocalTitle.
  ///
  /// In es, this message translates to:
  /// **'Sincronización Local (Wi-Fi / Hotspot)'**
  String get syncLocalTitle;

  /// No description provided for @syncLocalDescription.
  ///
  /// In es, this message translates to:
  /// **'Conecta ambos dispositivos a la misma red Wi-Fi o activa un Hotspot en uno de ellos para clonar el inventario al instante.'**
  String get syncLocalDescription;

  /// No description provided for @syncEmitData.
  ///
  /// In es, this message translates to:
  /// **'📤 Emitir Datos (Crear QR)'**
  String get syncEmitData;

  /// No description provided for @syncReceiveData.
  ///
  /// In es, this message translates to:
  /// **'📥 Recibir Datos (Escanear QR)'**
  String get syncReceiveData;

  /// No description provided for @syncScanFromReceiver.
  ///
  /// In es, this message translates to:
  /// **'Escanea este código desde el receptor:'**
  String get syncScanFromReceiver;

  /// No description provided for @syncActiveIp.
  ///
  /// In es, this message translates to:
  /// **'IP Activa: {ip}'**
  String syncActiveIp(Object ip);

  /// No description provided for @syncStopBroadcast.
  ///
  /// In es, this message translates to:
  /// **'Detener Emisión'**
  String get syncStopBroadcast;

  /// No description provided for @syncNoIp.
  ///
  /// In es, this message translates to:
  /// **'No se pudo detectar la IP. ¿Estás conectado a un Wi-Fi o Hotspot activo?'**
  String get syncNoIp;

  /// No description provided for @syncLocalDbMissing.
  ///
  /// In es, this message translates to:
  /// **'La base de datos local no existe.'**
  String get syncLocalDbMissing;

  /// No description provided for @syncStartFailed.
  ///
  /// In es, this message translates to:
  /// **'Error al iniciar el servidor local.'**
  String get syncStartFailed;

  /// No description provided for @syncNoNetwork.
  ///
  /// In es, this message translates to:
  /// **'⚠️ No tienes red. Conéctate al Wi-Fi o Hotspot del emisor.'**
  String get syncNoNetwork;

  /// No description provided for @syncDifferentNetworks.
  ///
  /// In es, this message translates to:
  /// **'⚠️ Parece que estáis en Wi-Fis distintas (Emisor: {sender}.x / Tú: {receiver}.x)'**
  String syncDifferentNetworks(Object sender, Object receiver);

  /// No description provided for @syncSearchingConnection.
  ///
  /// In es, this message translates to:
  /// **'Buscando conexión... (Intento {attempt}/{maximum})'**
  String syncSearchingConnection(Object attempt, Object maximum);

  /// No description provided for @syncDownloadingPercent.
  ///
  /// In es, this message translates to:
  /// **'Descargando... {percent}%'**
  String syncDownloadingPercent(Object percent);

  /// No description provided for @syncDownloadingMegabytes.
  ///
  /// In es, this message translates to:
  /// **'Descargando... {amount} MB'**
  String syncDownloadingMegabytes(Object amount);

  /// No description provided for @syncNetworkCutRetry.
  ///
  /// In es, this message translates to:
  /// **'Corte de red. Reintentando...'**
  String get syncNetworkCutRetry;

  /// No description provided for @syncUnstableDownload.
  ///
  /// In es, this message translates to:
  /// **'Conexión inestable. No se pudo completar la descarga.'**
  String get syncUnstableDownload;

  /// No description provided for @syncInstalling.
  ///
  /// In es, this message translates to:
  /// **'Instalando datos de forma segura...'**
  String get syncInstalling;

  /// No description provided for @syncCompleted.
  ///
  /// In es, this message translates to:
  /// **'¡Sincronización completada con éxito!'**
  String get syncCompleted;

  /// No description provided for @syncApplyFailed.
  ///
  /// In es, this message translates to:
  /// **'Error al aplicar datos. Se restauró tu BD original.'**
  String get syncApplyFailed;

  /// No description provided for @syncServerRejected.
  ///
  /// In es, this message translates to:
  /// **'El servidor rechazó la conexión.'**
  String get syncServerRejected;

  /// No description provided for @syncNetworkRetry.
  ///
  /// In es, this message translates to:
  /// **'Pérdida de red... (Reintento {attempt})'**
  String syncNetworkRetry(Object attempt);

  /// No description provided for @syncSenderNotFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontró el emisor. Revisa el Wi-Fi/Hotspot.'**
  String get syncSenderNotFound;

  /// No description provided for @packAddAtLeastOne.
  ///
  /// In es, this message translates to:
  /// **'Añade al menos 1 producto al pack usando el desplegable.'**
  String get packAddAtLeastOne;

  /// No description provided for @packInsufficientStock.
  ///
  /// In es, this message translates to:
  /// **'Stock insuficiente de \"{product}\" para montar {quantity} unidades.'**
  String packInsufficientStock(Object product, Object quantity);

  /// No description provided for @databaseDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'Borrar toda la base de datos'**
  String get databaseDeleteTitle;

  /// No description provided for @databaseDeleteDescription.
  ///
  /// In es, this message translates to:
  /// **'Eliminará productos, packs, promociones, ventas e historial.'**
  String get databaseDeleteDescription;

  /// No description provided for @databaseDeleteWarning.
  ///
  /// In es, this message translates to:
  /// **'Se eliminarán permanentemente todos los datos de esta aplicación. Esta acción no se puede deshacer.'**
  String get databaseDeleteWarning;

  /// No description provided for @databaseDeleteContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get databaseDeleteContinue;

  /// No description provided for @databaseDeleteFinalTitle.
  ///
  /// In es, this message translates to:
  /// **'Confirmación final'**
  String get databaseDeleteFinalTitle;

  /// No description provided for @databaseDeleteFinalWarning.
  ///
  /// In es, this message translates to:
  /// **'¿Confirmas que quieres borrar definitivamente toda la base de datos?'**
  String get databaseDeleteFinalWarning;

  /// No description provided for @databaseDeleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'Borrar todo'**
  String get databaseDeleteConfirm;

  /// No description provided for @databaseDeleteFailure.
  ///
  /// In es, this message translates to:
  /// **'No se pudo borrar la base de datos.'**
  String get databaseDeleteFailure;

  /// No description provided for @databaseDeletedTitle.
  ///
  /// In es, this message translates to:
  /// **'Base de datos borrada'**
  String get databaseDeletedTitle;

  /// No description provided for @databaseDeletedMessage.
  ///
  /// In es, this message translates to:
  /// **'La base de datos está vacía. Reinicia la aplicación para continuar.'**
  String get databaseDeletedMessage;

  /// No description provided for @unknownDeleted.
  ///
  /// In es, this message translates to:
  /// **'Desconocido o eliminado'**
  String get unknownDeleted;

  /// No description provided for @unknownPackDeleted.
  ///
  /// In es, this message translates to:
  /// **'Pack desconocido o eliminado'**
  String get unknownPackDeleted;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
