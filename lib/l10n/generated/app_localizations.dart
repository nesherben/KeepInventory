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

  /// No description provided for @navDashboard.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get navDashboard;

  /// No description provided for @navSales.
  ///
  /// In es, this message translates to:
  /// **'Caja (TPV)'**
  String get navSales;

  /// No description provided for @navInventory.
  ///
  /// In es, this message translates to:
  /// **'Inventario'**
  String get navInventory;

  /// No description provided for @navPromotions.
  ///
  /// In es, this message translates to:
  /// **'Ofertas'**
  String get navPromotions;

  /// No description provided for @navPacks.
  ///
  /// In es, this message translates to:
  /// **'Packs'**
  String get navPacks;

  /// No description provided for @navHistory.
  ///
  /// In es, this message translates to:
  /// **'Tickets y ferias'**
  String get navHistory;

  /// No description provided for @navDataManagement.
  ///
  /// In es, this message translates to:
  /// **'Copias y sincronización'**
  String get navDataManagement;

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
  /// **'Inicio'**
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
  /// **'Inventario'**
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
  /// **'Packs'**
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

  /// No description provided for @packEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay productos en este pack.'**
  String get packEmpty;

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
  /// **'Caja (TPV)'**
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
  /// **'Tickets y ferias'**
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
  /// **'Copias y sincronización'**
  String get dataManagementTitle;

  /// No description provided for @syncByQrTitle.
  ///
  /// In es, this message translates to:
  /// **'Sincronización por QR (Ferias)'**
  String get syncByQrTitle;

  /// No description provided for @syncByQrDescription.
  ///
  /// In es, this message translates to:
  /// **'Clona la base de datos completa en otro móvil cercano escaneando un QR, sin necesidad de Wi‑Fi.'**
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
  /// **'Clonar a otro móvil'**
  String get syncLocalTitle;

  /// No description provided for @syncLocalDescription.
  ///
  /// In es, this message translates to:
  /// **'Uno emite y el otro escanea el QR. No hace falta Wi‑Fi: la app crea su propio punto de acceso.'**
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

  /// No description provided for @paymentMethodTitle.
  ///
  /// In es, this message translates to:
  /// **'Método de pago'**
  String get paymentMethodTitle;

  /// No description provided for @paymentCash.
  ///
  /// In es, this message translates to:
  /// **'Efectivo'**
  String get paymentCash;

  /// No description provided for @paymentPaypal.
  ///
  /// In es, this message translates to:
  /// **'PayPal'**
  String get paymentPaypal;

  /// No description provided for @paymentBizum.
  ///
  /// In es, this message translates to:
  /// **'Bizum'**
  String get paymentBizum;

  /// No description provided for @refundViaMethod.
  ///
  /// In es, this message translates to:
  /// **'Se devolverá por {method} (método original)'**
  String refundViaMethod(String method);

  /// No description provided for @revenueByPaymentMethod.
  ///
  /// In es, this message translates to:
  /// **'INGRESOS POR MÉTODO DE PAGO'**
  String get revenueByPaymentMethod;

  /// No description provided for @paymentUnspecified.
  ///
  /// In es, this message translates to:
  /// **'Sin especificar'**
  String get paymentUnspecified;

  /// No description provided for @refundMethodUnknown.
  ///
  /// In es, this message translates to:
  /// **'Venta sin método registrado: devuelve por donde se cobró'**
  String get refundMethodUnknown;

  /// No description provided for @chartFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todo'**
  String get chartFilterAll;

  /// No description provided for @chartMargin.
  ///
  /// In es, this message translates to:
  /// **'MARGEN'**
  String get chartMargin;

  /// No description provided for @chartTapHint.
  ///
  /// In es, this message translates to:
  /// **'Toca una barra para ver su detalle'**
  String get chartTapHint;

  /// No description provided for @chartHistory.
  ///
  /// In es, this message translates to:
  /// **'HISTORIAL'**
  String get chartHistory;

  /// No description provided for @chartNoDataForFilter.
  ///
  /// In es, this message translates to:
  /// **'No hay datos para este filtro.'**
  String get chartNoDataForFilter;

  /// No description provided for @inventoryFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get inventoryFilterAll;

  /// No description provided for @inventoryFilterLow.
  ///
  /// In es, this message translates to:
  /// **'Stock bajo'**
  String get inventoryFilterLow;

  /// No description provided for @inventoryFilterOut.
  ///
  /// In es, this message translates to:
  /// **'Agotados'**
  String get inventoryFilterOut;

  /// No description provided for @inventoryFilterPromo.
  ///
  /// In es, this message translates to:
  /// **'Con promoción'**
  String get inventoryFilterPromo;

  /// No description provided for @inventorySummary.
  ///
  /// In es, this message translates to:
  /// **'{products} productos · {units} uds · {out} agotados'**
  String inventorySummary(String products, String units, String out);

  /// No description provided for @inventoryMargin.
  ///
  /// In es, this message translates to:
  /// **'Margen'**
  String get inventoryMargin;

  /// No description provided for @inventoryCostMargin.
  ///
  /// In es, this message translates to:
  /// **'Coste {cost} · margen {margin}'**
  String inventoryCostMargin(String cost, String margin);

  /// No description provided for @invalidNumber.
  ///
  /// In es, this message translates to:
  /// **'Introduce un número válido (ej. 12,50)'**
  String get invalidNumber;

  /// No description provided for @trashSlideTitle.
  ///
  /// In es, this message translates to:
  /// **'Último paso'**
  String get trashSlideTitle;

  /// No description provided for @trashSlideHint.
  ///
  /// In es, this message translates to:
  /// **'Desliza la base de datos hasta la papelera para borrarlo todo'**
  String get trashSlideHint;

  /// No description provided for @trashSlideRelease.
  ///
  /// In es, this message translates to:
  /// **'Suelta para borrar'**
  String get trashSlideRelease;

  /// No description provided for @trashSlideDrag.
  ///
  /// In es, this message translates to:
  /// **'Desliza →'**
  String get trashSlideDrag;

  /// No description provided for @syncEmitHotspot.
  ///
  /// In es, this message translates to:
  /// **'Emitir sin Wi‑Fi'**
  String get syncEmitHotspot;

  /// No description provided for @syncEmitHotspotHint.
  ///
  /// In es, this message translates to:
  /// **'Crea un punto de acceso temporal: no hace falta ninguna red'**
  String get syncEmitHotspotHint;

  /// No description provided for @syncEmitSameWifi.
  ///
  /// In es, this message translates to:
  /// **'Emitir por la misma red Wi‑Fi'**
  String get syncEmitSameWifi;

  /// No description provided for @syncHotspotStarting.
  ///
  /// In es, this message translates to:
  /// **'Creando punto de acceso…'**
  String get syncHotspotStarting;

  /// No description provided for @syncHotspotNetwork.
  ///
  /// In es, this message translates to:
  /// **'Red: {ssid}'**
  String syncHotspotNetwork(String ssid);

  /// No description provided for @syncHotspotPassword.
  ///
  /// In es, this message translates to:
  /// **'Contraseña: {password}'**
  String syncHotspotPassword(String password);

  /// No description provided for @syncConnectingToSender.
  ///
  /// In es, this message translates to:
  /// **'Conectando a la red del emisor… acepta el aviso de Android'**
  String get syncConnectingToSender;

  /// No description provided for @syncHotspotPermissionDenied.
  ///
  /// In es, this message translates to:
  /// **'Sin el permiso de dispositivos cercanos no se puede crear el punto de acceso.'**
  String get syncHotspotPermissionDenied;

  /// No description provided for @syncHotspotLocationOff.
  ///
  /// In es, this message translates to:
  /// **'Activa la ubicación del móvil para crear el punto de acceso.'**
  String get syncHotspotLocationOff;

  /// No description provided for @syncHotspotIncompatible.
  ///
  /// In es, this message translates to:
  /// **'Desactiva el punto de acceso o compartir conexión del móvil e inténtalo de nuevo.'**
  String get syncHotspotIncompatible;

  /// No description provided for @syncHotspotUnsupported.
  ///
  /// In es, this message translates to:
  /// **'Este móvil no puede crear el punto de acceso. Usa la opción de misma red Wi‑Fi.'**
  String get syncHotspotUnsupported;

  /// No description provided for @syncHotspotFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo crear el punto de acceso.'**
  String get syncHotspotFailed;

  /// No description provided for @syncConnectFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo conectar a la red del emisor. ¿Aceptaste la conexión?'**
  String get syncConnectFailed;

  /// No description provided for @syncManualConnectTitle.
  ///
  /// In es, this message translates to:
  /// **'Conéctate a la red del emisor'**
  String get syncManualConnectTitle;

  /// No description provided for @syncManualConnectBody.
  ///
  /// In es, this message translates to:
  /// **'Este móvil no puede conectarse solo. Ve a Ajustes › Wi‑Fi, conéctate a esta red y vuelve aquí:'**
  String get syncManualConnectBody;

  /// No description provided for @syncManualConnectDone.
  ///
  /// In es, this message translates to:
  /// **'Ya estoy conectado'**
  String get syncManualConnectDone;

  /// No description provided for @syncOpenSettings.
  ///
  /// In es, this message translates to:
  /// **'Abrir ajustes'**
  String get syncOpenSettings;

  /// No description provided for @syncInvalidQr.
  ///
  /// In es, this message translates to:
  /// **'Este QR no es de KeepInventory.'**
  String get syncInvalidQr;

  /// No description provided for @syncApprovalTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Permitir copiar tus datos?'**
  String get syncApprovalTitle;

  /// No description provided for @syncApprovalBody.
  ///
  /// In es, this message translates to:
  /// **'{device} quiere copiar todo tu inventario, packs, promociones y ventas.'**
  String syncApprovalBody(String device);

  /// No description provided for @syncApprovalCode.
  ///
  /// In es, this message translates to:
  /// **'Código: {code}'**
  String syncApprovalCode(String code);

  /// No description provided for @syncApprovalCodeHint.
  ///
  /// In es, this message translates to:
  /// **'Permite solo si el otro móvil muestra el mismo código.'**
  String get syncApprovalCodeHint;

  /// No description provided for @syncApprovalAllow.
  ///
  /// In es, this message translates to:
  /// **'Permitir'**
  String get syncApprovalAllow;

  /// No description provided for @syncApprovalDeny.
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get syncApprovalDeny;

  /// No description provided for @syncWaitingApproval.
  ///
  /// In es, this message translates to:
  /// **'Esperando a que el emisor acepte… Código: {code}'**
  String syncWaitingApproval(String code);

  /// No description provided for @syncDeniedBySender.
  ///
  /// In es, this message translates to:
  /// **'El emisor ha rechazado la solicitud.'**
  String get syncDeniedBySender;

  /// No description provided for @syncApprovalTimeout.
  ///
  /// In es, this message translates to:
  /// **'El emisor no respondió a tiempo.'**
  String get syncApprovalTimeout;

  /// No description provided for @syncRequestDenied.
  ///
  /// In es, this message translates to:
  /// **'Solicitud rechazada'**
  String get syncRequestDenied;

  /// No description provided for @syncRequestApproved.
  ///
  /// In es, this message translates to:
  /// **'Envío autorizado a {device}'**
  String syncRequestApproved(String device);

  /// No description provided for @navTutorial.
  ///
  /// In es, this message translates to:
  /// **'Tutorial'**
  String get navTutorial;

  /// No description provided for @navTutorialSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Cómo usar la app'**
  String get navTutorialSubtitle;

  /// No description provided for @tutorialSkip.
  ///
  /// In es, this message translates to:
  /// **'Saltar'**
  String get tutorialSkip;

  /// No description provided for @tutorialNext.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get tutorialNext;

  /// No description provided for @tutorialBack.
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get tutorialBack;

  /// No description provided for @tutorialStart.
  ///
  /// In es, this message translates to:
  /// **'Empezar'**
  String get tutorialStart;

  /// No description provided for @tutorialWelcomeTitle.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido a KeepInventory'**
  String get tutorialWelcomeTitle;

  /// No description provided for @tutorialWelcomeBody.
  ///
  /// In es, this message translates to:
  /// **'Tu inventario y tu caja en el móvil, sin conexión. Todo está en el menú lateral: Venta, Catálogo y Datos. Te enseñamos lo básico en un minuto.'**
  String get tutorialWelcomeBody;

  /// No description provided for @tutorialInventoryTitle.
  ///
  /// In es, this message translates to:
  /// **'1. Da de alta tus productos'**
  String get tutorialInventoryTitle;

  /// No description provided for @tutorialInventoryBody.
  ///
  /// In es, this message translates to:
  /// **'En Inventario pulsa + y pon nombre, precio, coste y unidades; verás tu margen al momento. Si quieres, agrúpalos por categorías (opcional, botón 🏷️ arriba). Para retocar, toca − / + o directamente el dato.'**
  String get tutorialInventoryBody;

  /// No description provided for @tutorialOffersTitle.
  ///
  /// In es, this message translates to:
  /// **'2. Ofertas y packs'**
  String get tutorialOffersTitle;

  /// No description provided for @tutorialOffersBody.
  ///
  /// In es, this message translates to:
  /// **'En Ofertas crea promociones (10 % de descuento, 3 por 12 €…) y combos (teclado + ratón = 10 €, o cualquier producto de una categoría). Se aplican solas al vender. Desde el menú ⋮ de una promoción puedes ponérsela a toda una categoría. En Packs agrupa productos con su propio precio.'**
  String get tutorialOffersBody;

  /// No description provided for @tutorialSalesTitle.
  ///
  /// In es, this message translates to:
  /// **'3. Vende en segundos'**
  String get tutorialSalesTitle;

  /// No description provided for @tutorialSalesBody.
  ///
  /// In es, this message translates to:
  /// **'En Caja toca los productos para añadirlos al carrito, pulsa COBRAR y elige cómo paga el cliente. Si falta algo para completar un combo, el carrito te avisa: toca el aviso para ir al producto o ＋ Añadir para meterlo.'**
  String get tutorialSalesBody;

  /// No description provided for @tutorialHistoryTitle.
  ///
  /// In es, this message translates to:
  /// **'4. Tickets y ferias'**
  String get tutorialHistoryTitle;

  /// No description provided for @tutorialHistoryBody.
  ///
  /// In es, this message translates to:
  /// **'En Tickets y ferias tienes el ticket de cada venta. Agrupa los días de una feria con el botón de feria (las ferias quedan guardadas para la próxima). Desde un ticket puedes devolver unidades y el importe se recalcula con las ofertas.'**
  String get tutorialHistoryBody;

  /// No description provided for @tutorialDashboardTitle.
  ///
  /// In es, this message translates to:
  /// **'5. Cuadra la caja'**
  String get tutorialDashboardTitle;

  /// No description provided for @tutorialDashboardBody.
  ///
  /// In es, this message translates to:
  /// **'En Inicio ves ingresos, beneficio y lo cobrado por cada método de pago. Ideal para cuadrar la caja al final del día.'**
  String get tutorialDashboardBody;

  /// No description provided for @tutorialDataTitle.
  ///
  /// In es, this message translates to:
  /// **'6. Tus datos, a salvo'**
  String get tutorialDataTitle;

  /// No description provided for @tutorialDataBody.
  ///
  /// In es, this message translates to:
  /// **'En Copias y sincronización haz copias de seguridad o pasa todo a otro móvil con un QR, sin Wi‑Fi (los dos móviles deben tener la misma versión de la app). Puedes volver a ver este tutorial desde el menú, en Ayuda.'**
  String get tutorialDataBody;

  /// No description provided for @inventorySortReset.
  ///
  /// In es, this message translates to:
  /// **'Tocar para volver al orden por defecto'**
  String get inventorySortReset;

  /// No description provided for @inventorySortTitle.
  ///
  /// In es, this message translates to:
  /// **'Ordenar'**
  String get inventorySortTitle;

  /// No description provided for @inventorySortDefault.
  ///
  /// In es, this message translates to:
  /// **'Por defecto'**
  String get inventorySortDefault;

  /// No description provided for @inventorySortName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get inventorySortName;

  /// No description provided for @inventorySortUnits.
  ///
  /// In es, this message translates to:
  /// **'Unidades'**
  String get inventorySortUnits;

  /// No description provided for @inventorySortPrice.
  ///
  /// In es, this message translates to:
  /// **'Precio'**
  String get inventorySortPrice;

  /// No description provided for @inventorySortCost.
  ///
  /// In es, this message translates to:
  /// **'Coste'**
  String get inventorySortCost;

  /// No description provided for @promotionsTab.
  ///
  /// In es, this message translates to:
  /// **'Promociones'**
  String get promotionsTab;

  /// No description provided for @combosTab.
  ///
  /// In es, this message translates to:
  /// **'Combos'**
  String get combosTab;

  /// No description provided for @comboNewTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo combo'**
  String get comboNewTitle;

  /// No description provided for @comboEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar combo'**
  String get comboEditTitle;

  /// No description provided for @comboNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre del combo'**
  String get comboNameLabel;

  /// No description provided for @comboSlotsSection.
  ///
  /// In es, this message translates to:
  /// **'Productos del combo'**
  String get comboSlotsSection;

  /// No description provided for @comboSlotAdd.
  ///
  /// In es, this message translates to:
  /// **'Añadir producto'**
  String get comboSlotAdd;

  /// No description provided for @comboSlotQuantity.
  ///
  /// In es, this message translates to:
  /// **'Cantidad'**
  String get comboSlotQuantity;

  /// No description provided for @comboSlotNoProducts.
  ///
  /// In es, this message translates to:
  /// **'Toca para elegir el producto'**
  String get comboSlotNoProducts;

  /// No description provided for @comboPriceLabel.
  ///
  /// In es, this message translates to:
  /// **'Precio del combo'**
  String get comboPriceLabel;

  /// No description provided for @comboSeparateTotal.
  ///
  /// In es, this message translates to:
  /// **'Por separado {amount} €'**
  String comboSeparateTotal(String amount);

  /// No description provided for @comboSaving.
  ///
  /// In es, this message translates to:
  /// **'Ahorras {amount} €'**
  String comboSaving(String amount);

  /// No description provided for @comboNoSavingWarning.
  ///
  /// In es, this message translates to:
  /// **'Este combo no ahorra nada frente a comprar por separado. ¿Guardar igualmente?'**
  String get comboNoSavingWarning;

  /// No description provided for @comboErrorName.
  ///
  /// In es, this message translates to:
  /// **'Pon un nombre al combo'**
  String get comboErrorName;

  /// No description provided for @comboErrorMinSlots.
  ///
  /// In es, this message translates to:
  /// **'Añade al menos 2 productos'**
  String get comboErrorMinSlots;

  /// No description provided for @comboErrorEmptySlot.
  ///
  /// In es, this message translates to:
  /// **'Elige un producto en cada hueco'**
  String get comboErrorEmptySlot;

  /// No description provided for @comboOwnPromoWarning.
  ///
  /// In es, this message translates to:
  /// **'{products} ya tiene(n) promoción propia. Dentro del combo se cobra el precio del combo y las unidades sueltas mantienen su promoción. Si prefieres que no se mezclen, quita la promoción del producto en Inventario.'**
  String comboOwnPromoWarning(String products);

  /// No description provided for @comboOwnPromoTitle.
  ///
  /// In es, this message translates to:
  /// **'Productos con promoción'**
  String get comboOwnPromoTitle;

  /// No description provided for @comboProductInOtherCombo.
  ///
  /// In es, this message translates to:
  /// **'Ya está en «{name}»'**
  String comboProductInOtherCombo(String name);

  /// No description provided for @comboProductInOtherSlot.
  ///
  /// In es, this message translates to:
  /// **'Ya está en este combo'**
  String get comboProductInOtherSlot;

  /// No description provided for @comboDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar combo'**
  String get comboDeleteTitle;

  /// No description provided for @comboDeleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar «{name}»? Las ventas anteriores no cambian.'**
  String comboDeleteConfirm(String name);

  /// No description provided for @comboSaved.
  ///
  /// In es, this message translates to:
  /// **'Combo guardado'**
  String get comboSaved;

  /// No description provided for @comboDeleted.
  ///
  /// In es, this message translates to:
  /// **'Combo eliminado'**
  String get comboDeleted;

  /// No description provided for @combosEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin combos. Crea uno para vender conjuntos a precio fijo sin montar packs.'**
  String get combosEmpty;

  /// No description provided for @comboBadge.
  ///
  /// In es, this message translates to:
  /// **'Combo'**
  String get comboBadge;

  /// No description provided for @comboCartTitle.
  ///
  /// In es, this message translates to:
  /// **'Combo · {name}'**
  String comboCartTitle(String name);

  /// No description provided for @comboRefundBreaks.
  ///
  /// In es, this message translates to:
  /// **'Esto rompe el combo «{name}»: lo que queda se cobra a precio normal'**
  String comboRefundBreaks(String name);

  /// No description provided for @comboRefundWhole.
  ///
  /// In es, this message translates to:
  /// **'Devolver combo'**
  String get comboRefundWhole;

  /// No description provided for @comboCount.
  ///
  /// In es, this message translates to:
  /// **'×{count}'**
  String comboCount(int count);

  /// No description provided for @comboNoSavingTitle.
  ///
  /// In es, this message translates to:
  /// **'El combo no ahorra'**
  String get comboNoSavingTitle;

  /// No description provided for @productFormMargin.
  ///
  /// In es, this message translates to:
  /// **'Margen por unidad: {amount} € ({percent})'**
  String productFormMargin(String amount, String percent);

  /// No description provided for @productFormLoss.
  ///
  /// In es, this message translates to:
  /// **'Vendes a pérdidas: {amount} € por unidad'**
  String productFormLoss(String amount);

  /// No description provided for @promotionTypeBundle.
  ///
  /// In es, this message translates to:
  /// **'Lote a precio fijo'**
  String get promotionTypeBundle;

  /// No description provided for @promotionTypePercent.
  ///
  /// In es, this message translates to:
  /// **'% de descuento'**
  String get promotionTypePercent;

  /// No description provided for @promotionPreviewBundle.
  ///
  /// In es, this message translates to:
  /// **'Llevando {count} unidades, pagan {price} € en total'**
  String promotionPreviewBundle(int count, String price);

  /// No description provided for @promotionPreviewPercent.
  ///
  /// In es, this message translates to:
  /// **'Desde {count} unidades, {percent} de descuento en cada una'**
  String promotionPreviewPercent(int count, String percent);

  /// No description provided for @promotionAutoNameBundle.
  ///
  /// In es, this message translates to:
  /// **'{count} por {price} €'**
  String promotionAutoNameBundle(int count, String price);

  /// No description provided for @promotionAutoNamePercent.
  ///
  /// In es, this message translates to:
  /// **'−{percent} desde {count} uds'**
  String promotionAutoNamePercent(int count, String percent);

  /// No description provided for @packSeparatePrice.
  ///
  /// In es, this message translates to:
  /// **'Por separado {amount} €'**
  String packSeparatePrice(String amount);

  /// No description provided for @packAddProductButton.
  ///
  /// In es, this message translates to:
  /// **'Añadir producto'**
  String get packAddProductButton;

  /// No description provided for @productPickerTitle.
  ///
  /// In es, this message translates to:
  /// **'Elige un producto'**
  String get productPickerTitle;

  /// No description provided for @fairSearchOrCreate.
  ///
  /// In es, this message translates to:
  /// **'Busca o escribe una feria nueva'**
  String get fairSearchOrCreate;

  /// No description provided for @fairCreate.
  ///
  /// In es, this message translates to:
  /// **'Crear «{name}»'**
  String fairCreate(String name);

  /// No description provided for @fairRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar feria'**
  String get fairRemove;

  /// No description provided for @fairCurrent.
  ///
  /// In es, this message translates to:
  /// **'Actual'**
  String get fairCurrent;

  /// No description provided for @drawerMadeBy.
  ///
  /// In es, this message translates to:
  /// **'Hecho con ❤️ por {name}'**
  String drawerMadeBy(String name);

  /// No description provided for @drawerFreeApp.
  ///
  /// In es, this message translates to:
  /// **'KeepInventory es gratis. Si te ayuda en tus ferias, puedes apoyar el proyecto.'**
  String get drawerFreeApp;

  /// No description provided for @drawerDonate.
  ///
  /// In es, this message translates to:
  /// **'Invítame a un café'**
  String get drawerDonate;

  /// No description provided for @drawerSourceCode.
  ///
  /// In es, this message translates to:
  /// **'Código en GitHub'**
  String get drawerSourceCode;

  /// No description provided for @linkOpenError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir el enlace'**
  String get linkOpenError;

  /// No description provided for @versionMismatchTitle.
  ///
  /// In es, this message translates to:
  /// **'Versiones distintas'**
  String get versionMismatchTitle;

  /// No description provided for @backupVersionMismatch.
  ///
  /// In es, this message translates to:
  /// **'Este backup es de la versión {backup} y la app está en la {app}. Para restaurarlo, usa la misma versión de la app. No se ha cambiado nada.'**
  String backupVersionMismatch(String backup, String app);

  /// No description provided for @backupVersionUnknownTitle.
  ///
  /// In es, this message translates to:
  /// **'Backup de una versión anterior'**
  String get backupVersionUnknownTitle;

  /// No description provided for @backupVersionUnknown.
  ///
  /// In es, this message translates to:
  /// **'Este backup se hizo con una versión anterior a la 1.14.1 y no se puede comprobar si coincide con la tuya ({app}). Si lo restauras, la app intentará adaptarlo. ¿Restaurar igualmente?'**
  String backupVersionUnknown(String app);

  /// No description provided for @backupRestoreAnyway.
  ///
  /// In es, this message translates to:
  /// **'Restaurar igualmente'**
  String get backupRestoreAnyway;

  /// No description provided for @backupNotRestored.
  ///
  /// In es, this message translates to:
  /// **'No se ha restaurado el backup'**
  String get backupNotRestored;

  /// No description provided for @syncVersionMismatch.
  ///
  /// In es, this message translates to:
  /// **'El otro móvil tiene la versión {other} y este la {mine}. Actualiza los dos a la misma versión para sincronizar.'**
  String syncVersionMismatch(String other, String mine);

  /// No description provided for @syncVersionUnknown.
  ///
  /// In es, this message translates to:
  /// **'El otro móvil tiene una versión anterior a la 1.14.1. Actualiza los dos a la misma versión para sincronizar.'**
  String get syncVersionUnknown;

  /// No description provided for @understood.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get understood;

  /// No description provided for @fairDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar feria'**
  String get fairDeleteTitle;

  /// No description provided for @fairDeleteConfirmUsed.
  ///
  /// In es, this message translates to:
  /// **'«{name}» tiene {count} tickets. Se quitarán de la feria (los tickets no se borran). ¿Eliminar la feria de la lista?'**
  String fairDeleteConfirmUsed(int count, String name);

  /// No description provided for @fairDeleteConfirmEmpty.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar «{name}» de la lista de ferias?'**
  String fairDeleteConfirmEmpty(String name);

  /// No description provided for @fairDeleted.
  ///
  /// In es, this message translates to:
  /// **'Feria eliminada'**
  String get fairDeleted;

  /// No description provided for @comboAddMissing.
  ///
  /// In es, this message translates to:
  /// **'Añadir'**
  String get comboAddMissing;

  /// No description provided for @comboMissingShort.
  ///
  /// In es, this message translates to:
  /// **'falta {slots}'**
  String comboMissingShort(String slots);

  /// No description provided for @productCategory.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get productCategory;

  /// No description provided for @categoryNone.
  ///
  /// In es, this message translates to:
  /// **'Sin categoría'**
  String get categoryNone;

  /// No description provided for @categoryPickTitle.
  ///
  /// In es, this message translates to:
  /// **'Categoría del producto'**
  String get categoryPickTitle;

  /// No description provided for @categorySearchOrCreate.
  ///
  /// In es, this message translates to:
  /// **'Busca o escribe una categoría nueva'**
  String get categorySearchOrCreate;

  /// No description provided for @categoryCreate.
  ///
  /// In es, this message translates to:
  /// **'Crear «{name}»'**
  String categoryCreate(String name);

  /// No description provided for @categoryRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar categoría'**
  String get categoryRemove;

  /// No description provided for @categoryDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar categoría'**
  String get categoryDeleteTitle;

  /// No description provided for @categoryDeleteConfirmUsed.
  ///
  /// In es, this message translates to:
  /// **'«{name}» tiene {count} productos. Se quedarán sin categoría (no se borran) y se quitará de los combos que la usen. ¿Eliminar la categoría?'**
  String categoryDeleteConfirmUsed(int count, String name);

  /// No description provided for @categoryDeleteConfirmEmpty.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar «{name}» de la lista de categorías?'**
  String categoryDeleteConfirmEmpty(String name);

  /// No description provided for @categoryDeleted.
  ///
  /// In es, this message translates to:
  /// **'Categoría eliminada'**
  String get categoryDeleted;

  /// No description provided for @categoryAll.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get categoryAll;

  /// No description provided for @comboSlotAnyOf.
  ///
  /// In es, this message translates to:
  /// **'Cualquier {name}'**
  String comboSlotAnyOf(String name);

  /// No description provided for @comboSlotCategories.
  ///
  /// In es, this message translates to:
  /// **'Categorías (cualquier producto de…)'**
  String get comboSlotCategories;

  /// No description provided for @comboSlotProducts.
  ///
  /// In es, this message translates to:
  /// **'Productos'**
  String get comboSlotProducts;

  /// No description provided for @tableCategory.
  ///
  /// In es, this message translates to:
  /// **'CATEGORÍA'**
  String get tableCategory;

  /// No description provided for @promotionApplyToCategory.
  ///
  /// In es, this message translates to:
  /// **'Aplicar a una categoría…'**
  String get promotionApplyToCategory;

  /// No description provided for @promotionAppliedToCategory.
  ///
  /// In es, this message translates to:
  /// **'Promoción aplicada a {count} productos de «{name}»'**
  String promotionAppliedToCategory(int count, String name);

  /// No description provided for @packCanAssemble.
  ///
  /// In es, this message translates to:
  /// **'Con el stock actual se pueden montar {count} más'**
  String packCanAssemble(int count);

  /// No description provided for @packCannotAssemble.
  ///
  /// In es, this message translates to:
  /// **'No hay stock para montar otro'**
  String get packCannotAssemble;

  /// No description provided for @packComponentStock.
  ///
  /// In es, this message translates to:
  /// **'{count} en stock'**
  String packComponentStock(int count);

  /// No description provided for @comboSlotNoCategories.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes categorías. Créalas desde el producto (Inventario → producto → Categoría) para elegir «cualquier producto de…».'**
  String get comboSlotNoCategories;

  /// No description provided for @comboSlotEmptyCategory.
  ///
  /// In es, this message translates to:
  /// **'Sin productos todavía'**
  String get comboSlotEmptyCategory;

  /// No description provided for @categoriesTitle.
  ///
  /// In es, this message translates to:
  /// **'Categorías'**
  String get categoriesTitle;

  /// No description provided for @categoryNew.
  ///
  /// In es, this message translates to:
  /// **'Nueva categoría'**
  String get categoryNew;

  /// No description provided for @categoryRename.
  ///
  /// In es, this message translates to:
  /// **'Renombrar categoría'**
  String get categoryRename;

  /// No description provided for @categoryNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la categoría'**
  String get categoryNameLabel;

  /// No description provided for @categoryNameTaken.
  ///
  /// In es, this message translates to:
  /// **'Ya existe una categoría con ese nombre'**
  String get categoryNameTaken;

  /// No description provided for @categoryProductsCount.
  ///
  /// In es, this message translates to:
  /// **'{count} productos'**
  String categoryProductsCount(int count);

  /// No description provided for @categoriesEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin categorías. Crea una para agrupar productos (p. ej. Polaroid, Print A5). Son opcionales.'**
  String get categoriesEmpty;

  /// No description provided for @categoryProductsTitle.
  ///
  /// In es, this message translates to:
  /// **'Productos de «{name}»'**
  String categoryProductsTitle(String name);

  /// No description provided for @categoryUpdated.
  ///
  /// In es, this message translates to:
  /// **'Categoría actualizada'**
  String get categoryUpdated;

  /// No description provided for @categoryInOther.
  ///
  /// In es, this message translates to:
  /// **'Ahora en «{name}»'**
  String categoryInOther(String name);

  /// No description provided for @navInventorySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Productos y categorías'**
  String get navInventorySubtitle;

  /// No description provided for @navPromotionsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Promociones y combos'**
  String get navPromotionsSubtitle;

  /// No description provided for @navHistorySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Historial y devoluciones'**
  String get navHistorySubtitle;

  /// No description provided for @navSectionSell.
  ///
  /// In es, this message translates to:
  /// **'VENTA'**
  String get navSectionSell;

  /// No description provided for @navSectionCatalog.
  ///
  /// In es, this message translates to:
  /// **'CATÁLOGO'**
  String get navSectionCatalog;

  /// No description provided for @navSectionData.
  ///
  /// In es, this message translates to:
  /// **'DATOS'**
  String get navSectionData;

  /// No description provided for @navSectionHelp.
  ///
  /// In es, this message translates to:
  /// **'AYUDA'**
  String get navSectionHelp;

  /// No description provided for @edit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get edit;

  /// No description provided for @promotionProductsCount.
  ///
  /// In es, this message translates to:
  /// **'Se aplica a {count} productos'**
  String promotionProductsCount(int count);

  /// No description provided for @promotionApplyConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'Aplicar promoción'**
  String get promotionApplyConfirmTitle;

  /// No description provided for @promotionApplyConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Poner «{promo}» a los {count} productos de «{category}»? Después puedes cambiar cualquiera por separado.'**
  String promotionApplyConfirm(int count, String promo, String category);

  /// No description provided for @apply.
  ///
  /// In es, this message translates to:
  /// **'Aplicar'**
  String get apply;
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
