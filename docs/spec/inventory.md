# Inventario

Productos, stock, categorías y su pantalla. Los precios por promoción están en [promotions.md](promotions.md); los packs en [packs.md](packs.md).

---

### INV-001 · Modelo de producto y validación del formulario
- **Propósito:** definir qué es un producto y qué datos son válidos.
- **Reglas de negocio:**
  - Campos: nombre, unidades (stock), precio de venta, coste de adquisición, foto, promoción (opcional), categoría (opcional), activo.
  - Formulario (alta/edición): nombre obligatorio (no vacío tras `trim`); precio, coste y unidades obligatorios; deben ser números válidos y **no negativos** (0 permitido); las unidades son enteros (`parseInt`); mensajes "Requerido" / "número no válido".
  - Pista de margen en vivo (solo si precio > 0): margen = precio − coste y % = margen / precio × 100; en rojo con icono de bajada si hay pérdida (margen < 0).
- **Datos:** tabla `products` (`name`, `units`, `price`, `cost`, `image_path`, `image_bytes`, `promotion_id`, `is_active`, `category_id`).
- **Flujo:** botón de añadir o editar → formulario adaptativo (panel en móvil, lateral/diálogo en tablet) → guardar → recarga y aviso de "creado/actualizado".
- **Casos límite y errores:** número vacío o con coma/punto inconsistente → error de campo; guardar con doble toque se evita con bandera `_saving`.
- **Código:** `lib/features/inventory/domain/product.dart` (`Product`), `lib/features/inventory/presentation/widgets/product_form_dialog.dart` (`_validateNumber`, `_buildMarginHint`), `lib/features/inventory/data/product_model.dart`.
- **Tests:** `test/inventory_products_table_test.dart` (tabla); sin tests específicos del formulario.

### INV-002 · Búsqueda, filtros, orden y resumen
- **Propósito:** localizar productos y ver el estado del almacén.
- **Reglas de negocio (lógica pura `InventoryView.apply`):**
  - Búsqueda: subcadena del nombre sin distinguir mayúsculas (`trim` de la consulta).
  - Filtro por categoría (`categoryId`; null = todas) combinable con la búsqueda.
  - Filtros rápidos: `all`, `lowStock` (nivel bajo), `outOfStock` (agotado), `withPromotion` (producto con `promotion_id` que además exista entre las promociones válidas).
  - Orden (un solo criterio activo, ascendente/descendente): `name`, `units`, `price`, `cost`, `margin`. Empates siempre por nombre A→Z y luego por id. En `margin` se ordena por el % mostrado y los productos **sin %** (precio 0, se muestran "—") van siempre al final.
  - Comparación de nombres "humana" (`compareNames`): sin mayúsculas ni tildes, la Ñ va entre la N y la O, y los números por valor ("Pendiente 2" < "Pendiente 10").
  - Pulsar de nuevo el mismo criterio invierte el sentido; un criterio nuevo empieza ascendente; hay "quitar orden".
  - Resumen (`InventorySummary.of`): nº de productos, unidades totales (las negativas cuentan 0), nº en stock bajo y nº agotados.
- **Datos:** solo lectura de `products` activos.
- **Flujo:** barra de filtros arriba (búsqueda, chips de filtro, categoría, orden en móvil, resumen).
- **Casos límite y errores:** si se borra la categoría filtrada, el filtro se quita solo al recargar.
- **Código:** `lib/features/inventory/domain/inventory_view.dart` (`InventoryView`, `InventoryFilter`, `InventorySort`, `InventorySummary`), `lib/features/inventory/presentation/widgets/inventory_filters_bar.dart`, `lib/features/inventory/presentation/inventory_screen.dart`.
- **Tests:** `test/inventory_view_test.dart`.

### INV-003 · Nivel de stock y margen por unidad
- **Propósito:** avisos visuales de stock y rentabilidad.
- **Reglas de negocio:**
  - `StockLevel.of(units)`: `units <= 0` → `out`; `units <= 3` (`lowThreshold = 3`) → `low`; si no `ok`.
  - Margen: `marginAmount = price − cost`; `marginPercent = (price − cost) / price × 100`, **null si price ≤ 0**.
  - El nivel se usa también en ventas (tile en gris si agotado, aviso de "última unidad") y en packs.
- **Datos:** `products.units/price/cost`.
- **Flujo:** colores/etiquetas en tarjetas, tabla y catálogo de ventas.
- **Casos límite y errores:** stock negativo se trata como agotado.
- **Código:** `lib/features/inventory/domain/inventory_view.dart` (`StockLevel`, extensión `ProductMargin`), `lib/features/inventory/presentation/widgets/inventory_product_widgets.dart`.
- **Tests:** `test/inventory_view_test.dart`.

### INV-004 · Borrado lógico de producto
- **Propósito:** quitar un producto del catálogo sin romper tickets antiguos.
- **Reglas de negocio:**
  - Borrar = `is_active = 0` **y** `units = 0` (no se elimina la fila: `sale_items.product_id` es `RESTRICT`).
  - `getProducts()` solo devuelve activos; `getProductById` devuelve también inactivos.
  - Los productos inactivos no cuentan para huecos de combo (se excluyen al cargar) ni para el resumen del inventario.
  - Si el producto forma parte de algún combo o pack, el diálogo lo avisa en rojo con sus nombres (el producto se quita de ahí y esos combos/packs pueden quedar incompletos).
  - Confirmación con diálogo (acción destructiva en rojo) y aviso al terminar; se descartan los +/− de stock pendientes del producto.
  - Una devolución **completa** de ticket (`refundSale`) reactiva el producto (`is_active = 1`); las devoluciones parciales **no** lo reactivan (ver SALES-009).
- **Datos:** `products.is_active`, `products.units`.
- **Flujo:** acción borrar en tarjeta/fila → confirmación → recarga.
- **Casos límite y errores:** un combo con un hueco cuyo único producto se borró queda "en pausa" (ver PROMO-004).
- **Código:** `lib/features/inventory/data/datasources/product_local_datasource.dart` (`deleteProduct`, `getProducts`), `lib/features/inventory/presentation/inventory_product_editor.dart` (`showDeleteConfirmation`, `deleteProduct`).
- **Tests:** sin tests.

### INV-005 · Edición rápida de campos y ajuste de stock +/−
- **Propósito:** cambiar nombre, unidades, precio o coste sin abrir el formulario completo, y ajustar stock con toques.
- **Reglas de negocio:**
  - Edición de un campo: nombre (ignora si queda vacío); unidades (`parseInt`, ≥ 0); precio y coste (`parseDecimal`, ≥ 0); número inválido → error "número no válido" y el diálogo no se cierra. Se actualiza solo la columna editada (`updateFields`).
  - `+`/`−` de stock: no baja de 0 en pantalla (`newUnits < 0` se ignora). Los toques se **agrupan con un debounce de 600 ms por producto** y se guardan como una única suma atómica (`UPDATE ... units = MAX(0, units + ?)`).
  - Al salir de la pantalla se guardan los cambios pendientes (no se pierden). Al recargar, los pendientes se aplican sobre los datos leídos.
  - Antes de escribir un stock exacto (campo o formulario) se descartan los +/− pendientes de ese producto.
  - Cada recarga lleva un número de secuencia: una carga antigua que termina después de otra nueva se descarta.
- **Datos:** `products.units` y demás columnas editadas.
- **Flujo:** toque sobre el valor → diálogo con valor seleccionado → guardar; botones +/− en la tarjeta.
- **Casos límite y errores:** guardado doble evitado con bandera; `addUnits` con delta 0 no hace nada.
- **Código:** `lib/features/inventory/presentation/inventory_product_editor.dart` (`saveProductField`, `showProductFieldDialog`), `lib/features/inventory/presentation/inventory_screen.dart` (`_updateStockQuickly`, `_flushStock`, `_discardPendingStock`), `lib/features/inventory/data/datasources/product_local_datasource.dart` (`updateFields`, `addUnits`).
- **Tests:** sin tests.

### INV-006 · Categorías de producto
- **Propósito:** agrupar productos (opcional) para filtrar, aplicar promociones y definir huecos de combo.
- **Reglas de negocio:**
  - Nombre único sin distinguir mayúsculas (`COLLATE NOCASE`); se recorta con `trim`. `getOrCreate(name)` inserta ignorando duplicados y devuelve la existente.
  - Renombrar a un nombre ya usado por **otra** categoría → falla (devuelve false, aviso "nombre en uso").
  - Borrar: confirmación (distinta si tiene productos); los productos pasan a sin categoría; se borran los huecos de combo que usaban esa categoría (`combo_slots.category_id`).
  - `countAll` cuenta solo productos **activos**.
  - `setProducts(id, add, remove)`: asigna productos a la categoría; al quitar solo afecta a los que estén en esa categoría.
  - Un producto tiene como mucho una categoría; el selector indica si un producto ya está en otra.
- **Datos:** `categories(id, name)`, `products.category_id`, `combo_slots.category_id`.
- **Flujo:** pantalla de categorías (crear, renombrar, borrar, elegir productos); selector de categoría al editar un producto; chips de categoría en inventario y ventas.
- **Casos límite y errores:** en ventas solo aparecen chips de categorías con algún producto a la venta.
- **Código:** `lib/features/inventory/presentation/categories_screen.dart`, `lib/features/inventory/presentation/widgets/category_picker.dart`, `lib/features/inventory/data/datasources/category_local_datasource.dart`, `lib/features/inventory/domain/product_category.dart`.
- **Tests:** sin tests propios (los huecos por categoría se prueban en `test/combo_test.dart`).

### INV-007 · Fotos del producto
- **Propósito:** asociar una imagen al producto.
- **Reglas de negocio:** cámara o galería (`image_picker`); se comprime (CORE-010) y se guarda en `products.image_bytes` (BLOB); aviso "foto actualizada".
- **Datos:** `products.image_bytes`, `image_path` (heredado, solo para migración).
- **Flujo:** acción de foto en la tarjeta → hoja con cámara/galería.
- **Casos límite y errores:** si el usuario cancela el selector no se cambia nada.
- **Código:** `lib/features/inventory/presentation/inventory_product_editor.dart` (`processAndSaveNewImage`, `editSingleImage`), `lib/core/services/image_compression_service.dart`.
- **Tests:** sin tests.

### INV-008 · Asignar promoción a un producto
- **Propósito:** elegir qué promoción de precio por cantidad aplica a un producto.
- **Reglas de negocio:** selector de promociones; elegir "sin promoción" la quita (`clearPromotion`); una promoción borrada no cuenta como actual; si no cambia, no se escribe. La lógica de la promoción vive en PROMO-001/PROMO-002.
- **Datos:** `products.promotion_id`.
- **Flujo:** acción de promoción en la tarjeta → hoja → aplicar → aviso.
- **Casos límite y errores:** `promotion_id` se pone a NULL por FK si se borra la promoción.
- **Código:** `lib/features/inventory/presentation/inventory_product_editor.dart` (`showPromotionSelectDialog`), `lib/features/inventory/presentation/widgets/promotion_picker.dart`.
- **Tests:** sin tests.

### INV-009 · Presentación: tabla en pantallas anchas y tarjetas en móvil
- **Propósito:** adaptar el listado al ancho.
- **Reglas de negocio:** ancho ≥ 700 px → tabla con cabeceras ordenables; menos → tarjetas con control de orden propio; unidades "encerradas" en packs montados = Σ (cantidad por pack × unidades del pack) por producto, y el nombre del combo al que pertenece un producto es informativo.
- **Datos:** lectura de `products`, `packs`/`pack_items`, `combos`.
- **Flujo:** misma pantalla, distinto layout.
- **Casos límite y errores:** catálogo vacío → estado vacío y `AppDrawer.catalogEmpty = true`.
- **Código:** `lib/features/inventory/presentation/inventory_screen.dart`, `widgets/inventory_products_table.dart`, `widgets/inventory_table_cell.dart`, `widgets/inventory_product_widgets.dart`.
- **Tests:** `test/inventory_products_table_test.dart`.

### INV-010 · Edición múltiple
- **Propósito:** cambiar o borrar varios productos de una vez.
- **Reglas de negocio:**
  - Se entra con el botón "Seleccionar varios" de la barra o con pulsación larga en una tarjeta; en la tabla (tablet) aparecen casillas. En selección, tocar una tarjeta la marca (no abre las ediciones de campo), "atrás" sale de la selección y se oculta el botón ＋. La barra muestra el nº de seleccionados, "Seleccionar todo" (lo filtrado), "Editar" y "Eliminar" (rojo).
  - La hoja de edición (`BulkEditSheet`) cambia, a elección y sin tocar lo demás: categoría, promoción, precio y coste. Precio y coste admiten "Igual", "Fijar" (mismo valor), "± %" (sube o baja un porcentaje) o "± €" (suma o resta); nunca bajan de 0 y van a céntimos (`BulkNumberEdit.apply`). El stock NO se toca.
  - `updateMany` y `deleteMany` (datasource) lo aplican en UNA transacción (todo o nada); cada producto genera su entrada de historial (HIST-001) y todas comparten `group_id`. Si no cambia nada, no se registra nada. Borrar es lógico, igual que INV-004.
- **Datos:** `products` (`category_id`, `promotion_id`, `price`, `cost`, `is_active`); `change_log`.
- **Flujo:** seleccionar → editar → elegir cambios → Aplicar → aviso "N productos actualizados" y se sale de la selección. Eliminar pide confirmación con el nº.
- **Casos límite y errores:** los marcados que desaparecen al recargar se desmarcan; con la selección activa, los +/− de stock siguen funcionando por separado.
- **Código:** `lib/features/inventory/domain/bulk_product_edit.dart`, `lib/features/inventory/presentation/widgets/bulk_edit_sheet.dart`, `lib/features/inventory/presentation/inventory_screen.dart`, `widgets/inventory_product_widgets.dart` (`InventoryProductCard`), `widgets/inventory_products_table.dart`, `product_local_datasource.dart` / `product_repository_impl.dart` (`updateMany`, `deleteMany`).
- **Tests:** `test/bulk_product_edit_test.dart`, `test/product_bulk_datasource_test.dart`.
