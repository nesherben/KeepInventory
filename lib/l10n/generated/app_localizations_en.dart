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
  String get navDashboard => 'Home';

  @override
  String get navSales => 'Checkout (POS)';

  @override
  String get navInventory => 'Inventory';

  @override
  String get navPromotions => 'Offers';

  @override
  String get navPacks => 'Packs';

  @override
  String get navHistory => 'Tickets and fairs';

  @override
  String get navDataManagement => 'Backups and sync';

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
  String get dashboardTitle => 'Home';

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
  String get inventoryTitle => 'Inventory';

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
  String get packsTitle => 'Packs';

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
  String get packEmpty => 'There are no products in this pack.';

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
  String get salesTitle => 'Checkout (POS)';

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
    return 'Purchased: $quantity  •  Paid: $amount €';
  }

  @override
  String get packsBundles => 'Packs / Bundles';

  @override
  String packNameLabel(Object name) {
    return '$name (Pack)';
  }

  @override
  String purchasedPackSummary(Object quantity, Object amount) {
    return 'Purchased: $quantity  •  Paid: $amount €';
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
  String get refundTitleHistory => 'Tickets and fairs';

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
  String get dataManagementTitle => 'Backups and sync';

  @override
  String get syncByQrTitle => 'Sync by QR (Fairs)';

  @override
  String get syncByQrDescription =>
      'Clone the whole database to a nearby phone by scanning a QR, no Wi‑Fi needed.';

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
  String get syncLocalTitle => 'Clone to another phone';

  @override
  String get syncLocalDescription =>
      'One phone sends, the other scans the QR. No Wi‑Fi needed: the app creates its own hotspot.';

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

  @override
  String get paymentMethodTitle => 'Payment method';

  @override
  String get paymentCash => 'Cash';

  @override
  String get paymentPaypal => 'PayPal';

  @override
  String get paymentBizum => 'Bizum';

  @override
  String refundViaMethod(String method) {
    return 'Refund via $method (original method)';
  }

  @override
  String get revenueByPaymentMethod => 'REVENUE BY PAYMENT METHOD';

  @override
  String get paymentUnspecified => 'Unspecified';

  @override
  String get refundMethodUnknown =>
      'No payment method recorded: refund the way it was paid';

  @override
  String get chartFilterAll => 'All';

  @override
  String get chartMargin => 'MARGIN';

  @override
  String get chartTapHint => 'Tap a bar to see its details';

  @override
  String get chartHistory => 'HISTORY';

  @override
  String get chartNoDataForFilter => 'No data for this filter.';

  @override
  String get inventoryFilterAll => 'All';

  @override
  String get inventoryFilterLow => 'Low stock';

  @override
  String get inventoryFilterOut => 'Out of stock';

  @override
  String get inventoryFilterPromo => 'On promotion';

  @override
  String inventorySummary(String products, String units, String out) {
    return '$products products · $units units · $out out of stock';
  }

  @override
  String get inventoryMargin => 'Margin';

  @override
  String inventoryCostMargin(String cost, String margin) {
    return 'Cost $cost · margin $margin';
  }

  @override
  String get invalidNumber => 'Enter a valid number (e.g. 12.50)';

  @override
  String get trashSlideTitle => 'Last step';

  @override
  String get trashSlideHint =>
      'Slide the database into the bin to delete everything';

  @override
  String get trashSlideRelease => 'Release to delete';

  @override
  String get trashSlideDrag => 'Slide →';

  @override
  String get syncEmitHotspot => 'Send without Wi‑Fi';

  @override
  String get syncEmitHotspotHint =>
      'Creates a temporary hotspot: no network needed';

  @override
  String get syncEmitSameWifi => 'Send over the same Wi‑Fi';

  @override
  String get syncHotspotStarting => 'Creating hotspot…';

  @override
  String syncHotspotNetwork(String ssid) {
    return 'Network: $ssid';
  }

  @override
  String syncHotspotPassword(String password) {
    return 'Password: $password';
  }

  @override
  String get syncConnectingToSender =>
      'Connecting to the sender\'s network… accept the Android prompt';

  @override
  String get syncHotspotPermissionDenied =>
      'Without the nearby devices permission the hotspot can\'t be created.';

  @override
  String get syncHotspotLocationOff =>
      'Turn on location to create the hotspot.';

  @override
  String get syncHotspotIncompatible =>
      'Turn off the phone\'s hotspot or tethering and try again.';

  @override
  String get syncHotspotUnsupported =>
      'This phone can\'t create the hotspot. Use the same Wi‑Fi option.';

  @override
  String get syncHotspotFailed => 'Couldn\'t create the hotspot.';

  @override
  String get syncConnectFailed =>
      'Couldn\'t connect to the sender\'s network. Did you accept the connection?';

  @override
  String get syncManualConnectTitle => 'Connect to the sender\'s network';

  @override
  String get syncManualConnectBody =>
      'This phone can\'t connect on its own. Go to Settings › Wi‑Fi, join this network and come back:';

  @override
  String get syncManualConnectDone => 'I\'m connected';

  @override
  String get syncOpenSettings => 'Open settings';

  @override
  String get syncInvalidQr => 'This QR code isn\'t from KeepInventory.';

  @override
  String get syncApprovalTitle => 'Allow copying your data?';

  @override
  String syncApprovalBody(String device) {
    return '$device wants to copy your whole inventory, packs, promotions and sales.';
  }

  @override
  String syncApprovalCode(String code) {
    return 'Code: $code';
  }

  @override
  String get syncApprovalCodeHint =>
      'Only allow if the other phone shows the same code.';

  @override
  String get syncApprovalAllow => 'Allow';

  @override
  String get syncApprovalDeny => 'Deny';

  @override
  String syncWaitingApproval(String code) {
    return 'Waiting for the sender to accept… Code: $code';
  }

  @override
  String get syncDeniedBySender => 'The sender denied the request.';

  @override
  String get syncApprovalTimeout => 'The sender didn\'t respond in time.';

  @override
  String get syncRequestDenied => 'Request denied';

  @override
  String syncRequestApproved(String device) {
    return 'Sending authorised to $device';
  }

  @override
  String get navTutorial => 'Tutorial';

  @override
  String get navTutorialSubtitle => 'How to use the app';

  @override
  String get tutorialSkip => 'Skip';

  @override
  String get tutorialNext => 'Next';

  @override
  String get tutorialBack => 'Back';

  @override
  String get tutorialStart => 'Get started';

  @override
  String get tutorialWelcomeTitle => 'Welcome to KeepInventory';

  @override
  String get tutorialWelcomeBody =>
      'Your inventory and till on your phone, fully offline. Everything is in the side menu: Selling, Catalog and Data. Here are the basics in one minute.';

  @override
  String get tutorialInventoryTitle => '1. Add your products';

  @override
  String get tutorialInventoryBody =>
      'In Inventory tap + and enter name, price, cost and units; you\'ll see your margin right away. Optionally group them into categories (🏷️ button at the top). To adjust, tap − / + or the value itself.';

  @override
  String get tutorialOffersTitle => '2. Offers and packs';

  @override
  String get tutorialOffersBody =>
      'In Offers create promotions (10% off, 3 for €12…) and combos (T-shirt + cap = €20, or any product of a category). They apply automatically when selling. From a promotion\'s ⋮ menu you can set it on a whole category. In Packs group products with their own price.';

  @override
  String get tutorialSalesTitle => '3. Sell in seconds';

  @override
  String get tutorialSalesBody =>
      'In Checkout tap products to add them to the cart, press CHECK OUT and choose how the customer pays. If something is missing to complete a combo, the cart tells you: tap the hint to go to the product or ＋ Add to put it in.';

  @override
  String get tutorialHistoryTitle => '4. Tickets and fairs';

  @override
  String get tutorialHistoryBody =>
      'In Tickets and fairs you have every sale\'s ticket. Group a fair\'s days with the fair button (fairs are saved for next time). From a ticket you can refund units and the amount is recalculated with offers.';

  @override
  String get tutorialDashboardTitle => '5. Balance the till';

  @override
  String get tutorialDashboardBody =>
      'Home shows revenue, profit and what was paid with each method. Perfect for balancing the till at the end of the day.';

  @override
  String get tutorialDataTitle => '6. Keep your data safe';

  @override
  String get tutorialDataBody =>
      'In Backups and sync back up your data or move everything to another phone with a QR code, no Wi‑Fi needed (both phones must have the same app version). You can replay this tutorial from the menu, under Help.';

  @override
  String get inventorySortReset => 'Tap to restore the default order';

  @override
  String get inventorySortTitle => 'Sort';

  @override
  String get inventorySortDefault => 'Default';

  @override
  String get inventorySortName => 'Name';

  @override
  String get inventorySortUnits => 'Units';

  @override
  String get inventorySortPrice => 'Price';

  @override
  String get inventorySortCost => 'Cost';

  @override
  String get promotionsTab => 'Promotions';

  @override
  String get combosTab => 'Combos';

  @override
  String get comboNewTitle => 'New combo';

  @override
  String get comboEditTitle => 'Edit combo';

  @override
  String get comboNameLabel => 'Combo name';

  @override
  String get comboSlotsSection => 'Combo products';

  @override
  String get comboSlotAdd => 'Add product';

  @override
  String get comboSlotQuantity => 'Quantity';

  @override
  String get comboSlotNoProducts => 'Tap to choose the product';

  @override
  String get comboPriceLabel => 'Combo price';

  @override
  String comboSeparateTotal(String amount) {
    return 'Separately €$amount';
  }

  @override
  String comboSaving(String amount) {
    return 'You save €$amount';
  }

  @override
  String get comboNoSavingWarning =>
      'This combo saves nothing compared to buying separately. Save anyway?';

  @override
  String get comboErrorName => 'Give the combo a name';

  @override
  String get comboErrorMinSlots => 'Add at least 2 products';

  @override
  String get comboErrorEmptySlot => 'Choose a product for each slot';

  @override
  String comboOwnPromoWarning(String products) {
    return '$products already have their own promotion. Inside the combo the combo price applies and loose units keep their promotion. If you\'d rather not mix them, remove the product\'s promotion in Inventory.';
  }

  @override
  String get comboOwnPromoTitle => 'Products with a promotion';

  @override
  String comboProductInOtherCombo(String name) {
    return 'Already in “$name”';
  }

  @override
  String get comboProductInOtherSlot => 'Already in this combo';

  @override
  String get comboDeleteTitle => 'Delete combo';

  @override
  String comboDeleteConfirm(String name) {
    return 'Delete “$name”? Past sales are not affected.';
  }

  @override
  String get comboSaved => 'Combo saved';

  @override
  String get comboDeleted => 'Combo deleted';

  @override
  String get combosEmpty =>
      'No combos yet. Create one to sell sets at a fixed price without building packs.';

  @override
  String get comboBadge => 'Combo';

  @override
  String comboCartTitle(String name) {
    return 'Combo · $name';
  }

  @override
  String comboRefundBreaks(String name) {
    return 'This breaks the “$name” combo: what\'s left is charged at the normal price';
  }

  @override
  String get comboRefundWhole => 'Refund combo';

  @override
  String comboCount(int count) {
    return '×$count';
  }

  @override
  String get comboNoSavingTitle => 'This combo saves nothing';

  @override
  String productFormMargin(String amount, String percent) {
    return 'Margin per unit: €$amount ($percent)';
  }

  @override
  String productFormLoss(String amount) {
    return 'Selling at a loss: €$amount per unit';
  }

  @override
  String get promotionTypeBundle => 'Fixed-price bundle';

  @override
  String get promotionTypePercent => '% discount';

  @override
  String promotionPreviewBundle(int count, String price) {
    return 'Buying $count units, they pay €$price in total';
  }

  @override
  String promotionPreviewPercent(int count, String percent) {
    return 'From $count units, $percent off each';
  }

  @override
  String promotionAutoNameBundle(int count, String price) {
    return '$count for €$price';
  }

  @override
  String promotionAutoNamePercent(int count, String percent) {
    return '−$percent from $count units';
  }

  @override
  String packSeparatePrice(String amount) {
    return 'Separately €$amount';
  }

  @override
  String get packAddProductButton => 'Add product';

  @override
  String get productPickerTitle => 'Choose a product';

  @override
  String get fairSearchOrCreate => 'Search or type a new fair';

  @override
  String fairCreate(String name) {
    return 'Create “$name”';
  }

  @override
  String get fairRemove => 'Remove fair';

  @override
  String get fairCurrent => 'Current';

  @override
  String drawerMadeBy(String name) {
    return 'Made with ❤️ by $name';
  }

  @override
  String get drawerFreeApp =>
      'KeepInventory is free. If it helps at your fairs, you can support the project.';

  @override
  String get drawerDonate => 'Buy me a coffee';

  @override
  String get drawerSourceCode => 'Source on GitHub';

  @override
  String get linkOpenError => 'Couldn\'t open the link';

  @override
  String get versionMismatchTitle => 'Different versions';

  @override
  String backupVersionMismatch(String backup, String app) {
    return 'This backup is from version $backup and the app is on $app. To restore it, use the same app version. Nothing has been changed.';
  }

  @override
  String get backupVersionUnknownTitle => 'Backup from an older version';

  @override
  String backupVersionUnknown(String app) {
    return 'This backup was made with a version older than 1.14.1, so it can\'t be checked against yours ($app). If you restore it, the app will try to adapt it. Restore anyway?';
  }

  @override
  String get backupRestoreAnyway => 'Restore anyway';

  @override
  String get backupNotRestored => 'The backup was not restored';

  @override
  String syncVersionMismatch(String other, String mine) {
    return 'The other phone is on version $other and this one on $mine. Update both to the same version to sync.';
  }

  @override
  String get syncVersionUnknown =>
      'The other phone has a version older than 1.14.1. Update both to the same version to sync.';

  @override
  String get understood => 'Got it';

  @override
  String get fairDeleteTitle => 'Delete fair';

  @override
  String fairDeleteConfirmUsed(int count, String name) {
    return '“$name” has $count tickets. They will be removed from the fair (tickets are not deleted). Delete the fair from the list?';
  }

  @override
  String fairDeleteConfirmEmpty(String name) {
    return 'Delete “$name” from the fairs list?';
  }

  @override
  String get fairDeleted => 'Fair deleted';

  @override
  String get comboAddMissing => 'Add';

  @override
  String comboMissingShort(String slots) {
    return 'missing $slots';
  }

  @override
  String get productCategory => 'Category';

  @override
  String get categoryNone => 'No category';

  @override
  String get categoryPickTitle => 'Product category';

  @override
  String get categorySearchOrCreate => 'Search or type a new category';

  @override
  String categoryCreate(String name) {
    return 'Create “$name”';
  }

  @override
  String get categoryRemove => 'Remove category';

  @override
  String get categoryDeleteTitle => 'Delete category';

  @override
  String categoryDeleteConfirmUsed(int count, String name) {
    return '“$name” has $count products. They will be left without a category (not deleted) and it will be removed from combos that use it. Delete the category?';
  }

  @override
  String categoryDeleteConfirmEmpty(String name) {
    return 'Delete “$name” from the categories list?';
  }

  @override
  String get categoryDeleted => 'Category deleted';

  @override
  String get categoryAll => 'All';

  @override
  String comboSlotAnyOf(String name) {
    return 'Any $name';
  }

  @override
  String get comboSlotCategories => 'Categories (any product of…)';

  @override
  String get comboSlotProducts => 'Products';

  @override
  String get tableCategory => 'CATEGORY';

  @override
  String get promotionApplyToCategory => 'Apply to a category…';

  @override
  String promotionAppliedToCategory(int count, String name) {
    return 'Promotion applied to $count products in “$name”';
  }

  @override
  String packCanAssemble(int count) {
    return 'With current stock you can assemble $count more';
  }

  @override
  String get packCannotAssemble => 'Not enough stock to assemble another';

  @override
  String packComponentStock(int count) {
    return '$count in stock';
  }

  @override
  String get comboSlotNoCategories =>
      'You have no categories yet. Create them from a product (Inventory → product → Category) to pick “any product of…”.';

  @override
  String get comboSlotEmptyCategory => 'No products yet';

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get categoryNew => 'New category';

  @override
  String get categoryRename => 'Rename category';

  @override
  String get categoryNameLabel => 'Category name';

  @override
  String get categoryNameTaken => 'A category with that name already exists';

  @override
  String categoryProductsCount(int count) {
    return '$count products';
  }

  @override
  String get categoriesEmpty =>
      'No categories. Create one to group products (e.g. T-shirts, Mugs). They are optional.';

  @override
  String categoryProductsTitle(String name) {
    return 'Products in “$name”';
  }

  @override
  String get categoryUpdated => 'Category updated';

  @override
  String categoryInOther(String name) {
    return 'Currently in “$name”';
  }

  @override
  String get navInventorySubtitle => 'Products and categories';

  @override
  String get navPromotionsSubtitle => 'Promotions and combos';

  @override
  String get navHistorySubtitle => 'History and refunds';

  @override
  String get navSectionSell => 'SELLING';

  @override
  String get navSectionCatalog => 'CATALOG';

  @override
  String get navSectionData => 'DATA';

  @override
  String get navSectionHelp => 'HELP';

  @override
  String get edit => 'Edit';

  @override
  String promotionProductsCount(int count) {
    return 'Applies to $count products';
  }

  @override
  String get promotionApplyConfirmTitle => 'Apply promotion';

  @override
  String promotionApplyConfirm(int count, String promo, String category) {
    return 'Set “$promo” on the $count products in “$category”? You can still change any of them individually.';
  }

  @override
  String get apply => 'Apply';

  @override
  String promotionRefundBreaks(String promo) {
    return 'This refund undoes the “$promo” offer: what the customer keeps goes back to the normal price, so less is refunded.';
  }

  @override
  String saleRegistered(String id, String amount, String method) {
    return 'Sale #$id saved · €$amount · $method';
  }
}
