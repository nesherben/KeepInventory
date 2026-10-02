// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get drawerSubtitle => 'Inventory and POS';

  @override
  String get navSectionMain => 'MAIN';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navSales => 'Sales (POS)';

  @override
  String get navSectionStockOffers => 'STOCK & OFFERS';

  @override
  String get navInventory => 'Inventory';

  @override
  String get navPromotions => 'Promotions';

  @override
  String get navPacks => 'Packs and Bundles';

  @override
  String get navSectionRecords => 'RECORDS';

  @override
  String get navHistory => 'History and Fairs';

  @override
  String get navDataManagement => 'Data Management';

  @override
  String get navDataManagementSubtitle => 'Backups and Sync';

  @override
  String get themeNameDefault => 'Default / System';

  @override
  String get themeNameBlue => 'Electric Blue';

  @override
  String get themeNameGreen => 'Emerald Green';

  @override
  String get themeNamePurple => 'Cyber Purple';

  @override
  String get themeNameRed => 'Crimson Red';

  @override
  String get themeNameOrange => 'Epic Orange';

  @override
  String themeChanged(Object theme) {
    return '🎨 Theme changed to: $theme!';
  }

  @override
  String get updateSearching => 'Checking for updates on GitHub...';

  @override
  String get updateLatest => 'The app is already up to date!';

  @override
  String get updateUnknownVersion => 'Unknown';

  @override
  String get updateNoNotes => 'No release notes.';

  @override
  String updateReleaseHeading(Object version) {
    return '🚀 Version $version';
  }

  @override
  String get updateGenericReleaseNotes => 'General improvements and fixes.';

  @override
  String updateAvailableTitle(Object version) {
    return 'New version v$version is available!';
  }

  @override
  String get updateAvailableBody =>
      'An update with improvements and fixes is ready to install:';

  @override
  String updateDownloading(Object percent) {
    return 'Downloading... $percent%';
  }

  @override
  String get later => 'Later';

  @override
  String get updateNow => 'Update now';

  @override
  String get updateDownloadError =>
      'Could not download the update. Check your internet connection.';

  @override
  String get updateConnectionError => 'Could not connect to the server.';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get privacyOff => 'Turn privacy mode off';

  @override
  String get privacyOn => 'Turn privacy mode on';

  @override
  String get searchUpdates => 'Check for updates';

  @override
  String get metricInventoryCost => 'INVENTORY COST';

  @override
  String get metricSalesValue => 'SALES VALUE';

  @override
  String get metricNetProfit => 'ACTUAL NET PROFIT';

  @override
  String get chartButtonTitle => 'Balance by Fairs and Days';

  @override
  String get chartButtonSubtitle => 'View bar chart and net profit';

  @override
  String get cashDesk => 'TOTAL REGISTER';

  @override
  String get cumulativeBalance =>
      'Accumulated balance from fairs and direct sales';

  @override
  String get chartTotalRevenue => 'TOTAL REVENUE';

  @override
  String get chartTotalNet => 'TOTAL NET';

  @override
  String get chartDays => 'Individual days';

  @override
  String get chartFairs => 'Fairs';

  @override
  String get chartNetProfit => 'Net Profit';

  @override
  String chartDayTitle(Object date) {
    return 'Day: $date';
  }

  @override
  String chartFairTitle(Object fair) {
    return '🎪 Fair: $fair';
  }

  @override
  String chartRevenue(Object amount) {
    return 'Revenue: $amount';
  }

  @override
  String chartNet(Object amount) {
    return 'Net: $amount';
  }

  @override
  String get chartDetailsTitle => 'Detailed Balance';

  @override
  String get privacyOffShort => 'Turn privacy off';

  @override
  String get privacyOnShort => 'Turn privacy on';

  @override
  String get chartEmpty => 'There are no sales to display yet.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get update => 'Update';

  @override
  String get required => 'Required';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get inventoryTitle => 'Inventory Management';

  @override
  String get photoUpdated => '📸 Photo updated successfully!';

  @override
  String get productDeleted => '🗑️ Product permanently deleted.';

  @override
  String get deleteProductTitle => 'Delete product';

  @override
  String get deleteProductConfirm =>
      'Are you sure you want to permanently delete this product?';

  @override
  String editFieldTitle(Object field) {
    return 'Edit $field';
  }

  @override
  String get newValue => 'New value';

  @override
  String get selectPromotion => 'Select Promotion';

  @override
  String get appliedPromotion => 'Applied Promotion';

  @override
  String get noPromotion => 'No promotion';

  @override
  String get promotionUpdated => '🏷️ Promotion updated.';

  @override
  String get takeNewPhoto => 'Take a new photo';

  @override
  String get chooseGalleryPhoto => 'Choose from gallery';

  @override
  String get productUpdated => '✨ Product updated successfully!';

  @override
  String get productCreated => '🎉 Product created successfully!';

  @override
  String get searchProduct => 'Search product by name...';

  @override
  String get inventoryEmpty => 'There are no products in inventory.';

  @override
  String get productsNotFound => 'No products with that name were found.';

  @override
  String get tableActions => 'ACTIONS';

  @override
  String get tablePhoto => 'PHOTO';

  @override
  String get tableName => 'NAME';

  @override
  String get tableUnits => 'UNITS';

  @override
  String get tablePrice => 'PRICE';

  @override
  String get tableCost => 'COST';

  @override
  String get tablePromotion => 'PROMOTION';

  @override
  String get editAll => 'Edit all';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldUnits => 'Units';

  @override
  String get fieldSalePrice => 'Sale price';

  @override
  String get fieldAcquisitionCost => 'Purchase cost';

  @override
  String get nameUpdated => '✏️ Name updated.';

  @override
  String get stockUpdated => '📦 Stock updated.';

  @override
  String get salePriceUpdated => '💰 Sale price updated.';

  @override
  String get costUpdated => '📉 Cost updated.';

  @override
  String get productFormEditTitle => 'Edit Product';

  @override
  String get productFormNewTitle => 'New Product';

  @override
  String get productName => 'Product name';

  @override
  String get unitsInStock => 'Units in stock';

  @override
  String get salePrice => 'Sale price (€)';

  @override
  String get acquisitionCost => 'Purchase cost (€)';

  @override
  String get promotionFormEditTitle => 'Edit Promotion';

  @override
  String get promotionFormNewTitle => 'New Promotion';

  @override
  String get offerName => 'Offer name';

  @override
  String get promotionType => 'Promotion type';

  @override
  String get bundleFixedPrice => 'Fixed bundle price';

  @override
  String get percentageDiscount => 'Percentage discount (%)';

  @override
  String get minimumQuantity => 'Minimum quantity (units to purchase)';

  @override
  String get validNumberRequired => 'Enter a valid number';

  @override
  String get bundleTotalPrice => 'Total bundle price (€)';

  @override
  String get discountPercentage => 'Discount percentage (%)';

  @override
  String get validValueRequired => 'Enter a valid value';

  @override
  String get promotionCreated => '🎉 Promotion created successfully!';

  @override
  String get deletePromotionTitle => 'Delete promotion';

  @override
  String confirmDeletePromotion(Object name) {
    return 'Are you sure you want to delete the promotion \"$name\"? Linked products will no longer have a promotion.';
  }

  @override
  String get promotionDeleted => '🗑️ Promotion deleted successfully.';

  @override
  String get searchPromotion => 'Search promotion by name...';

  @override
  String get promotionsEmpty =>
      'No promotions yet. Create one with the + button';

  @override
  String get promotionsNotFound => 'No promotions with that name were found.';

  @override
  String promotionBundleSummary(Object quantity, Object price) {
    return 'Buy $quantity units for $price €';
  }

  @override
  String promotionPercentSummary(Object percent, Object quantity) {
    return '$percent% off from $quantity units.';
  }

  @override
  String get promotionUpdatedSuccess => '✨ Promotion updated successfully!';

  @override
  String get packsTitle => 'Pack and Bundle Management';

  @override
  String get searchPacks => 'Search packs or products inside packs...';

  @override
  String get packsEmpty => 'No packs have been created yet.';

  @override
  String get packsNotFound =>
      'No packs or components with that name were found.';

  @override
  String packDismantled(Object pack) {
    return '1 \"$pack\" unit dismantled. Components returned to inventory.';
  }

  @override
  String packStockMissing(Object product, Object quantity) {
    return 'Not enough stock for \"$product\" (you need $quantity more units in inventory).';
  }

  @override
  String packAssembled(Object pack) {
    return '1 assembled unit added to \"$pack\"!';
  }

  @override
  String get packNeedProducts => 'You need active inventory products first.';

  @override
  String get packCreated => 'Pack created successfully!';

  @override
  String get packModified => 'Pack updated successfully!';

  @override
  String get deletePackTitle => 'Delete pack';

  @override
  String confirmDeletePack(Object pack, Object quantity) {
    return 'Are you sure you want to delete \"$pack\"? Components from the $quantity assembled packs will return to inventory.';
  }

  @override
  String get packDeleted =>
      'Pack deleted and components returned to inventory.';

  @override
  String get createPackTitle => 'Create New Pack / Bundle';

  @override
  String get editPackTitle => 'Edit Pack';

  @override
  String get packComponents => 'Pack components:';

  @override
  String get addProduct => 'Add product...';

  @override
  String get packEmpty => 'There are no products in this pack.';

  @override
  String get createPack => 'Create Pack';

  @override
  String get packName => 'Pack name';

  @override
  String get packPrice => 'Price (€)';

  @override
  String get packStartingStock => 'Initial stock';

  @override
  String packStockDetails(Object available, Object required) {
    return 'Inventory: $available (Needed: $required)';
  }

  @override
  String get packComponentsPerUnit => 'Components in one unit of this pack:';

  @override
  String packUnitCount(Object count) {
    return '$count units';
  }

  @override
  String packComponentCount(Object count) {
    return '$count units/pack';
  }

  @override
  String get productOutOfStock => 'This product is out of stock.';

  @override
  String get packOutOfStock => 'This pack has no assembled stock.';

  @override
  String get noMoreProductStock =>
      'There is no more stock available for this product.';

  @override
  String get noMorePackStock =>
      'There are no more units of this pack in stock.';

  @override
  String productRemovedFromCart(Object name) {
    return '$name removed from cart';
  }

  @override
  String packRemovedFromCart(Object name) {
    return 'Pack $name removed from cart';
  }

  @override
  String get saleCompleted => 'Payment completed successfully!';

  @override
  String get salesTitle => 'Sales (POS)';

  @override
  String get salesProductsTab => 'Individual Products';

  @override
  String get salesPacksTab => 'Packs and Bundles';

  @override
  String get searchProducts => 'Search products...';

  @override
  String get searchPacksOrComponents => 'Search packs or components...';

  @override
  String get noPacksFound => 'No packs were found.';

  @override
  String cartItemsCount(Object count) {
    return 'Items: $count';
  }

  @override
  String cartTotal(Object amount) {
    return 'Total: $amount €';
  }

  @override
  String get checkout => 'CHECK OUT';

  @override
  String get cartEmpty => 'The cart is empty';

  @override
  String promoAppliedName(Object name) {
    return 'Offer applied: $name';
  }

  @override
  String promoAvailableName(Object name) {
    return 'Available offer: $name';
  }

  @override
  String pricePerUnit(Object amount) {
    return '$amount €/unit';
  }

  @override
  String pricePerPack(Object amount) {
    return '$amount €/pack';
  }

  @override
  String get stockAvailable => 'Available stock';

  @override
  String get outOfStock => 'Out of stock';

  @override
  String unitsRemaining(Object count) {
    return '$count units left';
  }

  @override
  String get inCart => 'In cart';

  @override
  String unitCount(Object count) {
    return '$count units';
  }

  @override
  String get packContents => 'Contents';

  @override
  String get promotion => 'Promotion';

  @override
  String get status => 'Status';

  @override
  String get offerApplied => 'Offer applied';

  @override
  String get promotionShortfall => 'More units needed to activate';

  @override
  String promotionShortfallCombined(Object count, Object other) {
    return 'More units needed (combined $count + $other)';
  }

  @override
  String get totalAccumulated => 'Accumulated total';

  @override
  String get added => 'Added!';

  @override
  String get addAnotherUnit => 'Add another unit';

  @override
  String get addAnotherPack => 'Add another pack';

  @override
  String get addToCart => 'Add to cart';

  @override
  String get closePreview => 'Close preview';

  @override
  String refundTitle(Object ticket) {
    return 'Refund Ticket #$ticket';
  }

  @override
  String get refundInstruction =>
      'Choose how many units of each item to return:';

  @override
  String get looseProducts => 'Individual Products';

  @override
  String get unknown => 'Unknown';

  @override
  String purchasedItemSummary(Object quantity, Object amount) {
    return 'Purchased: $quantity  •  Paid: $amount €';
  }

  @override
  String get packsBundles => 'Packs / Bundles';

  @override
  String packNameLabel(Object name) {
    return '$name (Pack)';
  }

  @override
  String purchasedPackSummary(Object quantity, Object amount) {
    return 'Purchased: $quantity  •  Paid: $amount €';
  }

  @override
  String get openPackRestock => 'Open pack (Return components)';

  @override
  String get openPackRestockSubtitle =>
      'Add stock back to individual products.';

  @override
  String get refundTotalLabel => 'Total refund to customer (€)';

  @override
  String get refundAutoHelp =>
      'Automatically recalculates broken promotions. You can edit the amount if needed.';

  @override
  String get refundCannotExceed =>
      'You cannot refund more than the ticket total.';

  @override
  String get refundSuccess => 'Refund processed and accounting rebalanced.';

  @override
  String get confirm => 'Confirm';

  @override
  String get assignFairTitle => 'Group into Fair';

  @override
  String get selectFairPrompt => 'Select a saved fair or enter a new one:';

  @override
  String get availableFairs => 'Available fairs';

  @override
  String get enterNewFairOrNone => '-- Enter new / None --';

  @override
  String get fairName => 'Fair name';

  @override
  String get fairUnassigned => 'Fair unassigned successfully.';

  @override
  String salesGroupedFair(Object fair) {
    return 'Sales grouped under \"$fair\" successfully.';
  }

  @override
  String get searchHistory => 'Search ticket, item, fair...';

  @override
  String get salesHistoryEmpty => 'No sales have been recorded yet.';

  @override
  String get historyNoResults => 'No results match your search.';

  @override
  String ticketCount(Object count) {
    return '$count registered tickets';
  }

  @override
  String get changeFair => 'Change Fair';

  @override
  String get groupIntoFair => 'Group into Fair';

  @override
  String ticketTitle(Object ticket) {
    return 'Ticket #$ticket';
  }

  @override
  String get discountApplied => 'Discount applied';

  @override
  String get refund => 'Refund';

  @override
  String get refundTitleHistory => 'History and Fairs';

  @override
  String get exportPrompt => 'Choose where to save the backup...';

  @override
  String get backupSaved => '✨ Backup saved successfully!';

  @override
  String get exportFailed => 'Export was canceled or an error occurred.';

  @override
  String get restorePrompt => 'Find the backup file on your device...';

  @override
  String get restoreFailed => 'Restore was canceled or an error occurred.';

  @override
  String get databaseRestoredTitle => '🔄 Database Restored';

  @override
  String get databaseRestoredMessage =>
      'The database was updated successfully. The app must restart to apply the changes safely.';

  @override
  String get restartNow => 'Restart now';

  @override
  String get dataManagementTitle => 'Data Management';

  @override
  String get syncByQrTitle => 'Sync by QR (Fairs)';

  @override
  String get syncByQrDescription =>
      'Clone the entire database with another nearby device over Wi-Fi or a hotspot.';

  @override
  String get backupSectionTitle => 'FILE BACKUPS';

  @override
  String get exportBackupTitle => 'Export backup';

  @override
  String get exportBackupDescription => 'Save a backup file of your database.';

  @override
  String get restoreBackupTitle => 'Restore backup';

  @override
  String get restoreBackupDescription =>
      'Load a previous backup file to restore your data.';

  @override
  String get syncServerReady =>
      '📡 Server is ready. Show the QR code to the receiving device.';

  @override
  String get syncServerStopped => 'Sync server stopped.';

  @override
  String get scannerTitle => 'Scan Sync QR Code';

  @override
  String get syncVerifyNetwork => 'Checking network...';

  @override
  String syncErrorPrefix(Object message) {
    return '❌ Error: $message';
  }

  @override
  String get syncSuccessTitle => 'Sync Successful!';

  @override
  String get syncSuccessMessage =>
      'The database was cloned successfully from the other device. The app must restart to apply the changes safely.';

  @override
  String get syncTitle => 'Device Sync';

  @override
  String get syncLocalTitle => 'Local Sync (Wi-Fi / Hotspot)';

  @override
  String get syncLocalDescription =>
      'Connect both devices to the same Wi-Fi network or enable a hotspot on one to clone the inventory instantly.';

  @override
  String get syncEmitData => '📤 Send Data (Create QR)';

  @override
  String get syncReceiveData => '📥 Receive Data (Scan QR)';

  @override
  String get syncScanFromReceiver =>
      'Scan this code from the receiving device:';

  @override
  String syncActiveIp(Object ip) {
    return 'Active IP: $ip';
  }

  @override
  String get syncStopBroadcast => 'Stop Broadcasting';

  @override
  String get syncNoIp =>
      'Could not detect the IP address. Are you connected to Wi-Fi or an active hotspot?';

  @override
  String get syncLocalDbMissing => 'The local database does not exist.';

  @override
  String get syncStartFailed => 'Could not start the local server.';

  @override
  String get syncNoNetwork =>
      '⚠️ You are offline. Connect to the sender\'s Wi-Fi or hotspot.';

  @override
  String syncDifferentNetworks(Object sender, Object receiver) {
    return '⚠️ The devices seem to be on different Wi-Fi networks (Sender: $sender.x / You: $receiver.x)';
  }

  @override
  String syncSearchingConnection(Object attempt, Object maximum) {
    return 'Searching for connection... (Attempt $attempt/$maximum)';
  }

  @override
  String syncDownloadingPercent(Object percent) {
    return 'Downloading... $percent%';
  }

  @override
  String syncDownloadingMegabytes(Object amount) {
    return 'Downloading... $amount MB';
  }

  @override
  String get syncNetworkCutRetry => 'Network interrupted. Retrying...';

  @override
  String get syncUnstableDownload =>
      'Unstable connection. The download could not be completed.';

  @override
  String get syncInstalling => 'Safely installing data...';

  @override
  String get syncCompleted => 'Sync completed successfully!';

  @override
  String get syncApplyFailed =>
      'Could not apply data. Your original database was restored.';

  @override
  String get syncServerRejected => 'The server rejected the connection.';

  @override
  String syncNetworkRetry(Object attempt) {
    return 'Network lost... (Retry $attempt)';
  }

  @override
  String get syncSenderNotFound => 'Sender not found. Check Wi-Fi/hotspot.';

  @override
  String get packAddAtLeastOne =>
      'Add at least one product to the pack using the dropdown.';

  @override
  String packInsufficientStock(Object product, Object quantity) {
    return 'Not enough stock of \"$product\" to assemble $quantity units.';
  }

  @override
  String get databaseDeleteTitle => 'Delete the entire database';

  @override
  String get databaseDeleteDescription =>
      'Removes products, packs, promotions, sales, and history.';

  @override
  String get databaseDeleteWarning =>
      'All data in this app will be permanently deleted. This action cannot be undone.';

  @override
  String get databaseDeleteContinue => 'Continue';

  @override
  String get databaseDeleteFinalTitle => 'Final confirmation';

  @override
  String get databaseDeleteFinalWarning =>
      'Are you sure you want to permanently delete the entire database?';

  @override
  String get databaseDeleteConfirm => 'Delete everything';

  @override
  String get databaseDeleteFailure => 'The database could not be deleted.';

  @override
  String get databaseDeletedTitle => 'Database deleted';

  @override
  String get databaseDeletedMessage =>
      'The database is empty. Restart the app to continue.';

  @override
  String get unknownDeleted => 'Unknown or deleted';

  @override
  String get unknownPackDeleted => 'Unknown or deleted pack';
}
