# Núcleo (core)

Base de datos, preferencias, formato numérico, tema, idioma, arranque, imágenes y actualizaciones. Ver convenciones generales en [README.md](README.md).

---

### CORE-001 · Esquema de la base de datos (instalación nueva)
- **Propósito:** definir las tablas de una instalación limpia; es la verdad del esquema actual (versión **21**).
- **Reglas de negocio:**
  - `DatabaseHelper.schemaVersion = 21`. Archivo `keepinventory.db` en `getDatabasesPath()`.
  - Claves foráneas activas (`PRAGMA foreign_keys = ON` en `onConfigure`).
  - Tablas: `categories`, `promotions`, `products`, `sales`, `sale_items`, `packs`, `pack_items`, `sale_packs`, `combos`, `combo_slots`, `combo_slot_products`, `sale_combos`, `app_meta`, `fairs`, `sale_refunds`.
  - Borrados en cascada relevantes: `products.category_id` → `SET NULL` al borrar categoría; `products.promotion_id` → `SET NULL` al borrar promoción; `sale_items.product_id` → `RESTRICT` (por eso los productos se borran lógicamente, ver INV-004); `pack_items.product_id` → `RESTRICT`; `sale_packs.pack_id` → `CASCADE` (ya no se borran packs físicamente, ver PACK-005); `sale_items/sale_packs/sale_combos/sale_refunds.sale_id` → `CASCADE`; `combo_slots.category_id` → `CASCADE`.
  - `fairs.name` y `categories.name` son `COLLATE NOCASE` (únicos: la PK de `fairs`, `UNIQUE` en `categories`).
- **Datos:** columnas clave: `products(id, name, units, price, cost, image_path, image_bytes BLOB, promotion_id, is_active DEFAULT 1, category_id)`; `sales(id, date TEXT ISO‑8601, total_amount, adjustment_factor DEFAULT 1.0, fair_name, payment_method)`; `sale_items(sale_id, product_id, quantity, historical_price, original_price, promotion_id, promo_type, promo_threshold, promo_discount, sale_combo_id)`; `packs(name, price, units DEFAULT 1, image_path, image_bytes)`; `pack_items(pack_id, product_id, quantity)`; `sale_packs(sale_id, pack_id, quantity, historical_price)`; `combos(name, price)`, `combo_slots(combo_id, name, quantity, position, category_id)`, `combo_slot_products(slot_id, product_id)`, `sale_combos(sale_id, combo_id, name, price, quantity, definition JSON)`; `app_meta(key, value)`; `fairs(name)`; `sale_refunds(sale_id, date, amount, summary)`; `promotions(name, type, threshold, discount_value)`.
- **Flujo:** al primer acceso a `DatabaseHelper.database`, sqflite llama a `onCreate` → `DatabaseSchemaCreator.create`.
- **Casos límite y errores:** cambiar el esquema exige subir versión + añadir migración (CORE-002) + actualizar el creador + tests.
- **Código:** `lib/core/database/database_helper.dart`, `lib/core/database/database_schema_creator.dart` (`DatabaseSchemaCreator.create`, `comboTables`, `metaTable`, `fairsTable`, `categoriesTable`, `saleRefundsTable`).
- **Tests:** `test/database_schema_creator_test.dart`.

### CORE-002 · Migraciones de esquema
- **Propósito:** llevar bases de datos antiguas a la versión 21 sin perder datos.
- **Reglas de negocio:** `DatabaseMigrationRunner.upgrade` ejecuta, en orden y cada una solo si `oldVersion` es menor que su versión:
  - v2 promociones (+`products.promotion_id`); v3 `products.is_active`; v4 `sales.fair_name`; v5 `packs`/`pack_items`; v6 `sale_packs`; v7 `packs.units`; v8 `sale_items.original_price/promotion_id`; v9–v10 `promo_type/promo_threshold/promo_discount` (reparación idempotente); v11 `image_bytes` en productos y packs; v12 `sales.payment_method` (ventas antiguas quedan NULL = "sin especificar"); v13 tablas de combos + `sale_items.sale_combo_id`; v14 `app_meta`; v15 `fairs` (se rellena con los `fair_name` distintos y no vacíos de `sales`, `TRIM`); v16 `categories` + `products.category_id` + `combo_slots.category_id`; v17 `sale_refunds`; v18 `sales.adjustment_factor REAL NOT NULL DEFAULT 1.0`; v19 `packs.is_active INTEGER NOT NULL DEFAULT 1` (borrado lógico de packs); v20 `sale_items.manual_discount_type TEXT` y `manual_discount_value REAL` (descuento manual por línea, NULL = sin descuento); v21 tabla `change_log` + índices (historial de cambios, HIST-001). La migración solo crea la tabla: el historial empieza vacío.
  - Los `ALTER TABLE ADD COLUMN` toleran "columna duplicada" (se ignoran errores) para ser re-ejecutables; de v18 a v20 solo se ignora el error "duplicate column", cualquier otro se relanza.
- **Datos:** `PRAGMA user_version` (gestionado por sqflite).
- **Flujo:** `onUpgrade` → `DatabaseMigrationRunner.upgrade`. También se usa para migrar una copia restaurada de un esquema antiguo antes de instalarla (BKP-005).
- **Casos límite y errores:** una BD con `user_version` mayor que 21 no se migra hacia atrás; el validador de copias la rechaza como "más nueva" (BKP-004).
- **Código:** `lib/core/database/database_migration_runner.dart`.
- **Tests:** `test/database_migration_runner_test.dart`.

### CORE-003 · Apertura de la BD, sello de versión y reinicio de conexión
- **Propósito:** singleton de acceso a SQLite y marca de la versión de la app que escribió el archivo.
- **Reglas de negocio:**
  - Singleton `DatabaseHelper.instance`; la conexión se abre perezosamente.
  - `onOpen` → sello: guarda `app_meta('app_version') = versión de la app`, **solo si cambia** (no escribir en cada apertura, porque la firma de cambios de las copias es tamaño+mtime del archivo).
  - `readAppVersionOf(path)` abre un archivo en solo lectura y devuelve su versión (null si no hay marca: archivo anterior a 1.14.1).
  - `resetDatabase()` cierra y anula la conexión (obliga a reabrir el archivo, necesario tras sustituir el archivo por restauración/sync). `deleteDatabaseFile()` cierra y borra el archivo.
- **Datos:** `app_meta` (`app_version`).
- **Flujo:** `main` fuerza la apertura al arrancar (CORE-006).
- **Casos límite y errores:** `readAppVersionOf` traga errores y devuelve null.
- **Código:** `lib/core/database/database_helper.dart` (`DatabaseHelper._stampAppVersion`, `readAppVersionOf`, `resetDatabase`, `deleteDatabaseFile`).
- **Tests:** sin tests directos (cubierto indirectamente por `test/backup_validator_test.dart`).

### CORE-004 · Preferencias de la app
- **Propósito:** ajustes locales persistentes (no se copian en los backups porque no van en la BD).
- **Reglas de negocio:**
  - Claves en `SharedPreferences`: `privacy_mode_enabled`, `tutorial_seen`, `menu_hint_shown`, `auto_backup_enabled`, `backup_risk_accepted`, `last_local_backup_at`, `last_local_backup_signature`, `last_drive_backup_at`, `last_drive_backup_signature`, `drive_account_email`, `drive_status_known`, `drive_status_account`, `drive_status_backup_at`, `backup_failures`; además `selected_theme_key` (tema, gestionada en `AppDrawer`, ver CORE-007).
  - `AppPreferences.load()` hace `reload()` previo (otro isolate, la tarea de medianoche, pudo escribir).
  - `recordLocalBackup` pone `backupFailures = 0`; `recordBackupFailure` lo incrementa.
  - `hasCachedDriveStatus` = estado conocido **y** hay sesión **y** la cuenta del estado coincide con la sesión actual.
  - `privacyModeEnabled` y `driveEmailNotifier` son `ValueNotifier`.
  - Las prefs de copias van **siempre** en `AppPreferences`, nunca en `app_meta`.
- **Datos:** `SharedPreferences`.
- **Flujo:** `main` llama a `load()`; las pantallas escuchan los notifiers.
- **Casos límite y errores:** valores ausentes → defaults (`false`/`null`/`0`).
- **Código:** `lib/core/services/app_preferences.dart`; `lib/core/shared_widgets/app_drawer.dart` (clave del tema).
- **Tests:** `test/app_preferences_test.dart`.

### CORE-005 · Formato y lectura de números y dinero
- **Propósito:** mostrar y leer importes de forma coherente con el idioma.
- **Reglas de negocio:**
  - Mostrar: `AppNumbers.amount` (`#,##0.00` con el locale: es `1.234,50`, en `1,234.50`), `money` = `amount + " €"` (el símbolo va detrás en ambos idiomas), `input` = `0.00` sin miles (para rellenar campos), `percent` (`75 %`, con `maxDecimals` opcional).
  - Leer: `parseDecimal` acepta coma o punto decimal y separadores de miles (`12,5`, `12.5`, `1.234,56`, `1,234.56`, `12 €`); ignora cualquier carácter que no sea dígito/`,`/`.`/`-`; **un único separador seguido de exactamente 3 cifras se interpreta como miles** (`1.250` → 1250) salvo que la parte entera sea `0` (`0,125` → 0.125); devuelve null si no es número o mezcla separadores incoherentes (`1,2.3,4`).
  - `parseInt` = `parseDecimal` y exige que no tenga decimales.
  - Teclado y formatters: `decimalInputFormatters` (solo dígitos, `,` y `.`), `integerInputFormatters`, `decimalKeyboard`.
  - Atajos `context.money/amount/amountInput/percent`.
  - Prohibido `toStringAsFixed`+"€" y `double.parse` para importes.
- **Datos:** ninguno.
- **Flujo:** transversal a todos los formularios y pantallas.
- **Casos límite y errores:** entradas vacías/`null` → null.
- **Código:** `lib/core/utils/app_numbers.dart` (`AppNumbers`, extensión `AppNumbersContext`).
- **Tests:** `test/app_numbers_test.dart`.

### CORE-006 · Arranque, rutas y ciclo de vida
- **Propósito:** inicializar la app y decidir la pantalla inicial.
- **Reglas de negocio:**
  - Orden en `main`: abrir BD → `ImageMigrationService.migrateImagesToDb` → `AppDrawer.loadSavedTheme` → `AppPreferences.load` → `BackupScheduler.initialize` → calcular `firstRun`.
  - `firstRun` = tutorial **no** visto **y** la BD sin ningún dato (productos, ventas, categorías, ferias, promociones, packs, combos o devoluciones).
  - Ruta inicial: `/first-run` si `firstRun`; si no `/` cuando el tutorial ya se vio, o `/tutorial` si no.
  - Rutas: `/` dashboard, `/inventory`, `/sales`, `/history`, `/promotions`, `/packs`, `/data-management`, `/tutorial`, `/first-run`.
  - Tras `runApp`, `BackupCoordinator.onAppStarted()`; al pasar a `paused` → `onAppPaused()`; al volver a `resumed` → `onAppStarted()`.
- **Datos:** `tutorial_seen`; BD vacía (`BackupValidator.currentDatabaseHasData`).
- **Flujo:** primer arranque con backup disponible → pantalla de restaurar (BKP-009); sin él → tutorial → dashboard.
- **Casos límite y errores:** sin tests directos de `main`.
- **Código:** `lib/main.dart` (`main`, `_KeepInventoryAppState`), `lib/features/tutorial/presentation/tutorial_screen.dart`.
- **Tests:** `test/widget_test.dart` (POR CONFIRMAR: alcance exacto no revisado).

### CORE-007 · Tema visual
- **Propósito:** apariencia Material 3 con color de identidad personalizable.
- **Reglas de negocio:**
  - `themeMode = ThemeMode.system` (claro/oscuro según el sistema).
  - Color primario efectivo: color personalizado elegido (si hay) > color dinámico del sistema (Android 12+) > por defecto (`AppColors.primary` 0xFF009688 en claro, `darkPrimary` en oscuro).
  - Selector oculto: tocar la cabecera del menú lateral cicla entre `default`, `blue`, `teal`, `purple`, `red`, `orange`; se guarda en `selected_theme_key` y se avisa con un mensaje.
  - Estilo: tarjetas planas con borde de 1 px sin sombras, texto en colores de tinta, color de identidad solo en iconos/marcas; `AppColors.warning` para avisos de copia pendiente, rojo (`danger`/`error`) reservado a borrar.
  - Componentes compartidos: `app_ui.dart` (AppCard, StatTile, SectionLabel, IconBadge, QuantityStepper, EmptyState, AppRadius/AppSpacing).
- **Datos:** pref `selected_theme_key`.
- **Flujo:** toque en cabecera del drawer → siguiente color.
- **Casos límite y errores:** clave desconocida guardada → se mantiene el tema por defecto.
- **Código:** `lib/core/theme/app_colors.dart`, `lib/core/theme/app_theme.dart` (`AppTheme.light/dark`), `lib/core/shared_widgets/app_drawer.dart` (`AppDrawer.customThemeNotifier`, `loadSavedTheme`, `_cycleTheme`), `lib/core/shared_widgets/app_ui.dart`.
- **Tests:** `test/app_drawer_test.dart` (menú).
- **Nota:** `BackupReminderBanner` usa `AppColors.warning` tanto para el aviso de fallos como para el recordatorio.

### CORE-008 · Localización (es / en)
- **Propósito:** UI en español (plantilla) e inglés.
- **Reglas de negocio:**
  - Plantilla `lib/l10n/app_es.arb`; traducción `app_en.arb`; código generado en `lib/l10n/generated/` (nunca se edita a mano).
  - Resolución de idioma: de la lista de idiomas preferidos del dispositivo se elige el primero con soporte (por código de idioma); si ninguno, **inglés**.
  - Textos nuevos: skill `l10n-add`. Los importes dentro de textos usan `context.amount(x)` cuando la cadena ya lleva "€".
- **Datos:** ninguno.
- **Flujo:** `localeListResolutionCallback: resolveAppLocaleList`.
- **Casos límite y errores:** idioma no soportado → inglés.
- **Código:** `lib/l10n/app_locale_resolution.dart` (`resolveAppLocale`, `resolveAppLocaleList`), `lib/l10n/app_localizations_ext.dart` (`context.l10n`), `l10n.yaml`.
- **Tests:** `test/localization_test.dart`.

### CORE-009 · Versión de la app y comparación
- **Propósito:** exigir/comprobar la versión de la app entre backups y sincronización.
- **Reglas de negocio:** `AppVersion.current()` (de `package_info_plus`, cacheada); `compare(other, mine)`: `other` null o vacío → `unknown`; igual tras `trim` → `same`; si no → `different`.
- **Datos:** `app_meta('app_version')` (CORE-003), `pubspec.yaml` `version`.
- **Flujo:** usado en SYNC-001/SYNC-005 y BKP-006.
- **Casos límite y errores:** copias anteriores a 1.14.1 no llevan versión → `unknown`.
- **Código:** `lib/core/services/app_version.dart`.
- **Tests:** `test/app_version_test.dart`.

### CORE-010 · Imágenes de productos y packs
- **Propósito:** guardar fotos dentro de la BD (BLOB) para que viajen en backups y sync.
- **Reglas de negocio:**
  - Compresión: `compressWithList` con `minWidth 400`, `minHeight 400`, `quality 70`; si falla o devuelve vacío, se usan los bytes originales.
  - Migración al arrancar: para productos y packs con `image_path` no vacío y `image_bytes` NULL, si el archivo existe se comprime y se guarda en `image_bytes`; archivos inexistentes o errores se ignoran (log).
- **Datos:** `products.image_path/image_bytes`, `packs.image_path/image_bytes`.
- **Flujo:** al elegir foto (cámara/galería) en inventario o packs → comprimir → guardar BLOB.
- **Casos límite y errores:** imagen inexistente en disco → se omite sin fallar.
- **Código:** `lib/core/services/image_compression_service.dart`, `lib/core/services/image_migration_service.dart`.
- **Tests:** sin tests.

### CORE-011 · Búsqueda e instalación de actualizaciones (GitHub Releases)
- **Propósito:** avisar de una versión nueva y descargarla/instalarla.
- **Reglas de negocio:**
  - Consulta `https://api.github.com/repos/nesherben/KeepInventory/releases` (timeout 10 s, `User-Agent: KeepInventory-App`).
  - Ignora `draft` y `prerelease`; la más reciente es la primera de la lista.
  - Hay actualización si la versión del tag (sin `v`/`V`) es mayor que la local, comparando por partes numéricas (rellenando con 0; partes no numéricas = 0).
  - Notas acumuladas: concatena las notas de todas las releases mayores que la instalada (hasta llegar a la actual).
  - URL de descarga: `browser_download_url` del primer asset, o `html_url` si no hay assets.
  - Descarga a `update.apk` en el directorio temporal con progreso y abre el instalador (`OpenFilex`); devuelve éxito si el resultado es `done`.
  - Dashboard: comprobación automática silenciosa **una vez por sesión** (2 s tras el arranque); el botón de la barra lo hace de forma manual con avisos (buscando / ya es la última / error de conexión).
- **Datos:** ninguno.
- **Flujo:** diálogo no descartable con versión, notas y botón de descarga; fallo de descarga → mensaje de error.
- **Casos límite y errores:** cualquier excepción → se trata como "sin actualización" (y aviso de conexión solo en modo manual); URL vacía → no se muestra diálogo.
- **Código:** `lib/core/services/github_update_service.dart` (`GithubUpdateService.checkForUpdate`, `downloadAndInstall`), `lib/features/dashboard/presentation/dashboard_screen.dart` (`_checkForAppUpdates`), `lib/features/dashboard/presentation/widgets/update_available_dialog.dart`.
- **Tests:** `test/update_available_dialog_test.dart`.

### CORE-012 · Menú lateral, navegación y ayudas de primer uso
- **Propósito:** navegación principal y guía inicial.
- **Reglas de negocio:**
  - El menú lleva a `/sales`, `/history`, `/inventory`, `/promotions`, `/packs`, `/data-management`, tutorial; ir a la ruta actual solo cierra el menú; otra ruta usa `pushNamedAndRemoveUntil` (borra la pila).
  - Gesto: deslizar desde la izquierda (dx > 50 y |dy| < 30) abre el menú en dashboard, historial, inventario y ventas.
  - `AppDrawer.catalogEmpty`: mientras no hay productos, la entrada Inventario parpadea con un mensaje de empezar. El dashboard abre el menú **una sola vez** (pref `menu_hint_shown`) si el catálogo está vacío y Inicio está a la vista.
  - El tutorial se marca como visto con `markTutorialSeen` (también tras restaurar una copia).
- **Datos:** `tutorial_seen`, `menu_hint_shown`.
- **Flujo:** primera ejecución → tutorial → dashboard → menú se abre solo.
- **Casos límite y errores:** el hint espera hasta ~2 min (240×500 ms) a que Inicio esté visible.
- **Código:** `lib/core/shared_widgets/app_drawer.dart`, `lib/core/shared_widgets/main_scaffold.dart`, `lib/features/tutorial/presentation/tutorial_screen.dart`, `lib/features/dashboard/presentation/dashboard_screen.dart` (`_checkFirstSteps`).
- **Tests:** `test/app_drawer_test.dart`.
