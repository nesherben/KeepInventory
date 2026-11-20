# Promociones y combos

Descuentos por cantidad (promociones, asignadas a productos) y combos (precio fijo por completar huecos). Cómo se aplican en el carrito: [sales.md](sales.md) (SALES-003). Cómo se recalculan al devolver: SALES-008.

---

### PROMO-001 · Promoción: definición y validación
- **Propósito:** crear/editar descuentos por cantidad reutilizables.
- **Reglas de negocio:**
  - Dos tipos: `bundle_fixed_price` ("N por X €") y `percentage` ("N o más → X % de descuento").
  - Campos: `threshold` (entero ≥ 1; por defecto 3 en lote y 2 en porcentaje al crear), `discount_value` (en lote: precio total del lote > 0; en porcentaje: 0 < valor ≤ 100) y nombre obligatorio.
  - Nombre sugerido automáticamente ("3 por 12 €" / "2 o más: 10 %") mientras el usuario no escriba uno propio (si el nombre está vacío o sigue siendo el automático anterior se actualiza al cambiar valores).
  - Vista previa en vivo de la regla; no se muestra si valor ≤ 0, cantidad < 1 o porcentaje > 100.
  - Errores de campo: cantidad no válida → "número válido requerido"; valor ≤ 0 o (porcentaje y > 100) → "valor válido requerido".
- **Datos:** tabla `promotions(id, name, type, threshold, discount_value)`; `products.promotion_id`.
- **Flujo:** pantalla de promociones → nueva/editar → formulario → guardar; al crear una nueva se ofrece asignarla (categoría / productos / más tarde, ver PROMO-003).
- **Casos límite y errores:** doble guardado evitado (`_saving`).
- **Código:** `lib/features/promotions/domain/promotion.dart`, `lib/features/promotions/presentation/promotion_form_dialog.dart`, `lib/features/promotions/presentation/promotions_screen.dart`, `lib/features/promotions/data/datasources/promotion_local_datasource.dart`, `.../data/promotion_model.dart`.
- **Tests:** sin tests del formulario.

### PROMO-002 · Cálculo del precio con promoción propia (sin combos)
- **Propósito:** total de un producto del carrito según su promoción.
- **Reglas de negocio (`SaleCartPricingCalculator.calculateItemTotal`):**
  - Sin promoción (o su id no existe): `precio × cantidad`.
  - Se agrupan **todas las líneas del carrito con la misma promoción**; `combinedQuantity` = suma de sus unidades. Si `combinedQuantity < threshold` → precio normal.
  - `percentage` (cumplido el umbral): `precio × (1 − descuento/100) × cantidad` — aplica a **todas** las unidades, no solo a múltiplos.
  - `bundle_fixed_price` (cumplido el umbral): `FixedPriceBundleCalculator`:
    - Se expanden las unidades y se ordenan por precio **descendente**.
    - `discountedUnitCount = (nº unidades ÷ N) × N` (división entera); las unidades que sobran de formar lotes completos van a precio normal.
    - Precio unitario del lote = `precioLote / N`.
    - **Un lote solo se aplica si es más barato que la suma de sus unidades sueltas** (`precioLote < suma`): una oferta nunca encarece la compra.
    - Los lotes se forman con las unidades más caras primero (bloques consecutivos de N en el orden descendente).
    - `bundleSize ≤ 0` → `ArgumentError`.
  - Tipo desconocido → precio normal.
- **Datos:** `promotions`, `products.promotion_id`, precio del producto.
- **Flujo:** automático al cambiar el carrito; el ticket congela la promoción (SALES-004).
- **Casos límite y errores:** productos distintos con la misma promoción suman cantidad conjunta.
- **Código:** `lib/features/sales/domain/sale_cart_pricing_calculator.dart` (`calculateItemTotal`), `lib/features/promotions/domain/fixed_price_bundle_calculator.dart`.
- **Tests:** `test/sale_cart_pricing_calculator_test.dart`, `test/fixed_price_bundle_calculator_test.dart`, `test/combo_test.dart` (grupo "a fixed bundle never charges more than the loose units").

### PROMO-003 · Asignar una promoción a productos
- **Propósito:** aplicar la promoción a varios productos de una vez.
- **Reglas de negocio:**
  - Opciones al asignar: por **categoría** (todos los productos **activos** de la categoría, con diálogo de confirmación que muestra cuántos; es una acción de una vez, después cada producto puede cambiarse por separado), por **productos** (selector con casillas: los marcados la reciben, los desmarcados que la tenían la pierden) o más tarde.
  - Aviso de éxito con el nº de productos afectados.
  - El recuento del diálogo de categoría usa los productos cargados (`_products`), el resultado real viene de `setPromotionForCategory` (solo `is_active = 1`).
- **Datos:** `products.promotion_id`.
- **Flujo:** tras crear una promoción o desde su menú de acciones.
- **Casos límite y errores:** categoría sin productos → cambia 0.
- **Código:** `lib/features/promotions/presentation/promotions_screen.dart` (`_applyToCategory`, `_chooseProducts`), `lib/features/inventory/data/datasources/product_local_datasource.dart` (`setPromotionForCategory`, `updateFields`).
- **Tests:** sin tests.

### PROMO-004 · Combo: definición y validación
- **Propósito:** precio fijo por completar todos los huecos de un conjunto de productos (p. ej. camiseta + gorra = 20 €). No tiene stock propio.
- **Reglas de negocio:**
  - Un combo = nombre + precio + lista ordenada de huecos. Cada hueco: cantidad (≥ 1) y **un producto concreto** o **una categoría** ("cualquier producto de la categoría X"; los productos son los activos de esa categoría, resueltos al cargar).
  - Validaciones al guardar (por orden): nombre vacío → error; **menos de 2 huecos** → error; algún hueco vacío → error; precio nulo o negativo → "número no válido".
  - Aviso (confirmable) si `precio ≥ suma por separado` (sin ahorro). `separatePrice` = por hueco, el precio del producto **más caro** del hueco × cantidad (en el formulario, para huecos de categoría, el más caro de la categoría).
  - Aviso (confirmable) si algún producto del combo tiene promoción propia: **el combo gana** (ver PROMO-008).
  - "Completo" (`isComplete`): tiene huecos y todos con ≥ 1 producto; un combo incompleto (p. ej. se borró el único producto de un hueco) está **en pausa** y no se usa en el carrito hasta editarlo.
  - Guardar reescribe todos los huecos del combo; los huecos de categoría no guardan filas en `combo_slot_products`.
- **Datos:** `combos`, `combo_slots(quantity, position, category_id)`, `combo_slot_products`; los productos borrados lógicamente no cuentan.
- **Flujo:** pantalla de promociones → combo nuevo/editar (pantalla completa) → huecos (producto o categoría) → precio → guardar.
- **Casos límite y errores:** un mismo producto en varios huecos lo usa el primero que lo pida (PROMO-005).
- **Código:** `lib/features/promotions/domain/combo.dart` (`Combo`, `ComboSlot`), `lib/features/promotions/presentation/combo_form_screen.dart` (`_save`), `lib/features/promotions/data/datasources/combo_local_datasource.dart` (`getCombos`, `saveCombo`).
- **Tests:** `test/combo_test.dart` (grupos "Category slots", serialización).

### PROMO-005 · Detección de combos en el carrito (ComboMatcher)
- **Propósito:** decidir qué combos se forman con las unidades del carrito.
- **Reglas de negocio:**
  - Se procesan los combos en orden; cada combo se aplica **tantas veces como permita su hueco más escaso**: `count = min por hueco de (unidades disponibles ÷ cantidad del hueco)` (cantidad < 1 se trata como 1). Si `count ≤ 0` no se aplica.
  - Un producto solo cuenta para un hueco (si está en varios, el primero que lo reclama).
  - En cada hueco se consumen primero las unidades **más caras** (empate por id menor).
  - Las unidades usadas se restan: un combo posterior solo ve lo que queda.
  - Resultado por aplicación: unidades usadas por producto, total asignado por producto, `fullPrice` (precio suelto de lo usado) y `saving = fullPrice − precio del combo × count`.
- **Datos:** definiciones de combo; precios de producto.
- **Flujo:** automático al cambiar el carrito.
- **Casos límite y errores:** combo sin huecos se ignora; unidades de precio 0 → reparto por unidades (PROMO-006).
- **Código:** `lib/features/promotions/domain/combo_matcher.dart` (`ComboMatcher.match`, `ComboApplication`).
- **Tests:** `test/combo_test.dart` (grupo "ComboMatcher").

### PROMO-006 · Reparto del precio del combo entre sus productos
- **Propósito:** asignar a cada línea una parte exacta del precio del combo (para tickets y devoluciones).
- **Reglas de negocio (`_allocate`):**
  - Total en céntimos = `round(precioCombo × count × 100)`.
  - Peso de cada producto = `precio normal × unidades usadas` (si la suma de pesos es 0 → peso por unidades).
  - Cada parte = `floor(totalCéntimos × peso / sumaPesos)`; los céntimos sobrantes se reparten **de uno en uno por mayor resto** (empate por id menor) → **la suma coincide exactamente con el precio del combo**.
  - Valores devueltos como `céntimos / 100`.
- **Datos:** ninguno (cálculo).
- **Flujo:** interno.
- **Casos límite y errores:** combo gratis (precio 0) reparte 0 y suma 0.
- **Código:** `lib/features/promotions/domain/combo_matcher.dart` (`_allocate`).
- **Tests:** `test/combo_test.dart` ("splits the price in exact cents", "free combo splits 0 and adds up").

### PROMO-007 · Pistas de combo a medio completar
- **Propósito:** sugerir en el carrito qué falta para completar un combo.
- **Reglas de negocio:** tras el emparejamiento, para cada combo se mira lo **sobrante** (`remaining`); un hueco "falta" si las unidades sobrantes de sus productos < su cantidad. Se muestra pista si faltan algunos huecos pero **no todos** (`0 < faltan < total`). `filled = total − faltan`.
- **Datos:** ninguno.
- **Flujo:** tarjeta de pista en el carrito con nombre del combo y lo que falta; botón "completar": añade al carrito lo que falta de cada hueco pendiente (cantidad del hueco − sobrantes), recorriendo los productos del hueco en orden y respetando el stock libre (`unidades − ya en carrito`); tocar la tarjeta lleva al catálogo (`onLocateProduct`: primer producto faltante con stock libre, o el primero; pestaña Productos, quita búsqueda/categoría que lo oculten, recoge el carrito, desplaza y resalta 3 s).
- **Casos límite y errores:** si no hay stock suficiente para completar algún hueco, el botón de completar no se ofrece (acción nula).
- **Código:** `lib/features/promotions/domain/combo_matcher.dart` (`ComboHint`, `_hints`), `lib/features/sales/presentation/widgets/cart_items_list_widget.dart` (`_ComboHintCard`, `_completeComboAction`), `lib/features/sales/presentation/sales_screen.dart` (`_locateProduct`).
- **Tests:** `test/combo_test.dart` ("hint lists the missing slot…").

### PROMO-008 · Prioridad: el combo gana sobre la promoción propia
- **Propósito:** definir cómo conviven combos y promociones.
- **Reglas de negocio:** primero se detectan los combos; sus unidades van a precio de combo; **solo las unidades sobrantes** cuentan para la promoción propia del producto (cantidad conjunta con las demás sobrantes de la misma promoción). Las unidades sueltas que no forman nada van a precio normal.
- **Datos:** `products.promotion_id`.
- **Flujo:** automático.
- **Casos límite y errores:** el formulario de combo avisa al crear si hay productos con promoción propia.
- **Código:** `lib/features/sales/domain/sale_cart_pricing_calculator.dart` (`SaleCartPricingCalculator.price`).
- **Tests:** `test/combo_test.dart` ("combo wins over own promotion; leftovers keep the promotion", "leftover units go at their normal price").

### PROMO-009 · Borrado de promociones y combos
- **Propósito:** eliminarlos sin alterar el historial.
- **Reglas de negocio:**
  - Borrar promoción: confirmación; `promotions` se borra y los productos quedan con `promotion_id = NULL` (FK `SET NULL`). Los tickets ya hechos conservan la promoción **congelada** en cada línea (`promo_type/threshold/discount`).
  - Borrar combo: confirmación; borra `combos` (cascada a sus huecos). Los tickets conservan su propia copia (`sale_combos.definition`).
- **Datos:** `promotions`, `combos`, `combo_slots`, `combo_slot_products`, `sale_combos`.
- **Flujo:** acción de borrar (deslizar/menú) → diálogo → aviso.
- **Casos límite y errores:** ninguno adicional.
- **Código:** `lib/features/promotions/presentation/promotions_screen.dart` (`_confirmDelete`, `_confirmDeleteCombo`), `lib/features/promotions/data/datasources/promotion_local_datasource.dart`, `.../combo_local_datasource.dart` (`deleteCombo`).
- **Tests:** sin tests.
