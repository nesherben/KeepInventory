# Ventas

Catálogo de cobro (TPV), carrito, precios, tickets, historial, ferias y devoluciones. Las promociones y combos están en [promotions.md](promotions.md); el stock en [inventory.md](inventory.md) y [packs.md](packs.md).

Pantallas: `SalesScreen` (`/sales`) y `HistoryScreen` (`/history`).

---

### SALES-001 · Catálogo de venta
- **Propósito:** elegir qué se vende (productos y packs) y añadirlo al carrito.
- **Reglas de negocio:**
  - Dos pestañas: Productos y Packs, cada una con buscador.
  - Productos: filtro por nombre (subcadena, sin mayúsculas) y por categoría (chips; solo categorías con algún producto activo; `null` = todas). Si la categoría filtrada deja de existir, el filtro se quita.
  - Packs: filtro por nombre del pack **o** de sus componentes.
  - Solo se cargan productos activos; **solo combos completos** (`isComplete`).
  - Tile agotado (`stock <= 0`): en gris y atenuado, pero sigue permitiendo la vista previa (pulsación larga).
  - Toque sobre el tile = añadir 1; botón de quitar en el tile cuando ya está en el carrito.
  - Layout: móvil = carrito arrastrable inferior (se recoge tras vender o al localizar un producto); horizontal/tablet = panel de carrito lateral.
- **Datos:** lectura de `products` (activos), `packs`, `promotions`, `combos`, `categories`.
- **Flujo:** abrir `/sales` → catálogo → toque añade → ver carrito → cobrar (SALES-006).
- **Casos límite y errores:** la recarga de datos tras vender no muestra indicador (conserva el scroll).
- **Código:** `lib/features/sales/presentation/sales_screen.dart` (`_loadData`), `lib/features/sales/presentation/widgets/` (`product_grid_widget.dart`, `packs_grid_widget.dart`, `catalog_tile.dart`, `sales_catalog_header.dart`, `item_preview_info.dart`), `lib/features/sales/domain/sale_catalog_filter.dart` (`SaleCatalogFilter`).
- **Tests:** `test/sale_catalog_filter_test.dart`, `test/item_preview_info_test.dart`, `test/sale_discount_price_widget_test.dart`.

### SALES-002 · Carrito: añadir, quitar y límite de stock
- **Propósito:** componer la venta respetando el stock.
- **Reglas de negocio:**
  - Productos y packs viven en dos mapas (`_cart`, `_cartPacks`) con cantidades.
  - Añadir un producto cuando `cantidad en carrito >= product.units` → error "no queda más stock" y no se añade. Mismo control para packs con `pack.units`.
  - Al meter la **última unidad disponible** de un producto se muestra un aviso de "última unidad" (2 s).
  - Quitar 1: si queda > 1 resta, si no elimina la línea. Quitar todo (pulsación larga) elimina la línea y avisa.
  - Cuando el carrito queda vacío (sin productos ni packs) el ajuste de total se reinicia a 1.0.
  - `countItems` = suma de unidades de productos + packs.
  - Una pista de combo a medias se muestra en el carrito (PROMO-007).
- **Datos:** estado en memoria; no se persiste.
- **Flujo:** ver SALES-001.
- **Casos límite y errores:** el carrito vive en memoria (`CartSession`: ids y cantidades, descuentos, factor y método de pago) y se recupera al volver a la caja desde el menú, recortando cantidades al stock actual y descartando lo que ya no exista; se pierde al cerrar la app. "Atrás" solo pide confirmación ("¿Salir sin cobrar?") si cierra la app (única pantalla); con pantalla debajo, el carrito se conserva.
- **Código:** `lib/features/sales/presentation/sales_screen.dart` (`_addToCart`, `_removeFromCart`, `_removeAllFromCart`, `_addPackToCart`, `_removePackFromCart`, `_removeAllPackFromCart`), `lib/features/sales/presentation/widgets/cart_items_list_widget.dart`, `sales_cart_sheet.dart`, `sales_landscape_cart_panel.dart`.
- **Tests:** sin tests de la pantalla (lógica de conteo en `test/sale_cart_pricing_calculator_test.dart`).

### SALES-003 · Precio del carrito
- **Propósito:** calcular el total de un carrito de productos y packs.
- **Reglas de negocio (`SaleCartPricingCalculator.price`):**
  1. Se detectan los **combos** con `ComboMatcher` (PROMO-005) usando los precios actuales; sus unidades van a precio de combo (con el reparto en céntimos de PROMO-006).
  2. Las unidades que **no** forman combo (`loose`) se precian con su promoción propia (PROMO-002), agrupadas por promoción.
  3. Total de productos = Σ totales por producto (parte de combo + parte suelta).
  4. Packs: `precio del pack × cantidad` (los packs no participan en combos ni promociones).
  5. `total = productos + packs`. Ahorro por combos = Σ `saving` de cada aplicación.
  - Un producto sin `id` se ignora para combos.
  - `SaleFromCartFactory` redondea `totalAmount` a céntimos (`pricing.total × adjustmentFactor`); el reparto de combos va en céntimos exactos.
- **Datos:** `products.price`, `promotions`, `packs.price`, `combos`.
- **Flujo:** recalculado en cada cambio del carrito; el resumen muestra total y nº de artículos.
- **Casos límite y errores:** carrito vacío → 0.
- **Código:** `lib/features/sales/domain/sale_cart_pricing_calculator.dart` (`SaleCartPricingCalculator`, `CartPricing`).
- **Tests:** `test/sale_cart_pricing_calculator_test.dart`, `test/combo_test.dart`.

### SALES-004 · Ajuste del total acordado
- **Propósito:** cobrar un precio pactado distinto del calculado (redondeo, descuento puntual).
- **Reglas de negocio:**
  - Menú del total del carrito → "Ajustar total": el usuario escribe el total acordado (`parseDecimal`); debe ser número finito **≥ 0**, si no error "total acordado no válido".
  - `adjustmentFactor = totalAcordado / totalCalculado`. Si el total calculado es ≤ 0 no se permite ajustar.
  - Total del carrito mostrado = `total calculado × factor`; si hay ajuste (|factor − 1| > 1e‑7) se muestra el total original tachado y una opción "Restablecer".
  - Se reinicia a 1.0 al vaciar el carrito o vender.
  - La venta guarda `total_amount = total calculado × factor` y `adjustment_factor = factor` en `sales`.
  - La opción está deshabilitada con carrito vacío.
  - El factor se conserva en devoluciones: los importes por línea (`historical_price`) siguen **sin** factor; el factor se aplica al calcular lo pagado y lo que queda (SALES-008).
- **Datos:** `sales.adjustment_factor` (v18), `sales.total_amount`.
- **Exclusión con SALES-013:** el total acordado y los descuentos manuales de línea no conviven. Al fijar un total acordado con descuentos de línea se pide confirmación y se quitan (el factor se calcula sobre el total SIN descuentos); al aplicar un descuento de línea con un total acordado activo se pide confirmación y el factor vuelve a 1.
- **Flujo:** carrito → menú del total → diálogo → guardar.
- **Casos límite y errores:** total acordado 0 válido (venta gratis).
- **Código:** `lib/features/sales/presentation/widgets/sales_cart_total_summary.dart`, `lib/features/sales/presentation/sales_screen.dart` (`_cartAdjustmentFactor`, `_cartTotal`), `lib/features/sales/domain/sale_from_cart_factory.dart`.
- **Tests:** `test/sale_refund_calculator_test.dart` (casos con ajuste global).

### SALES-005 · Método de pago
- **Propósito:** registrar cómo pagó el cliente (solo informativo; no procesa cobros).
- **Reglas de negocio:**
  - Valores: `cash` (por defecto), `paypal`, `bizum` y `unspecified` (NULL en BD; solo ventas anteriores a la v12; **no seleccionable**).
  - `fromDb`: NULL o valor desconocido → `unspecified`.
  - Tras cada venta el método vuelve a efectivo.
  - La devolución se hace siempre por el método original (se muestra; si es `unspecified` se indica que se desconoce).
  - `PaymentMethod.totalsOf(ventas)`: suma por método incluyendo todos (0 si no hay), en el orden del enum; se usa para cuadrar la caja por día/feria.
- **Datos:** `sales.payment_method`.
- **Flujo:** selector de método en el carrito antes de cobrar.
- **Casos límite y errores:** los totales por método de las ventas ya incluyen las devoluciones parciales (reducen `total_amount`).
- **Código:** `lib/features/sales/domain/payment_method.dart`, `lib/features/sales/presentation/widgets/payment_method_widgets.dart`.
- **Tests:** `test/payment_method_test.dart`.

### SALES-006 · Cobrar: registrar la venta
- **Propósito:** persistir la venta y descontar stock.
- **Reglas de negocio:**
  - No hace nada con carrito vacío.
  - `SaleFromCartFactory.create` construye la venta con fecha `DateTime.now()`, `totalAmount = pricing.total × factor`, líneas, packs, combos aplicados, método de pago y factor.
  - `processSale` (una transacción): inserta `sales`; inserta `sale_combos` (traduciendo ids provisionales por los reales) ; por cada línea inserta `sale_items` y hace `products.units -= cantidad`; por cada pack inserta `sale_packs` y `packs.units -= cantidad`. Todo-o-nada.
  - Tras vender: se vacían carrito, packs y ajuste, el método vuelve a efectivo, se recargan datos, aviso de éxito con nº de ticket, importe y método, y el carrito se pliega.
  - `fair_name` queda NULL al vender (la feria se asigna después desde el historial, SALES-011).
  - El stock se valida TAMBIÉN en la BD: `processSale` descuenta con `WHERE units >= cantidad` y, si una línea ya no alcanza, lanza `InsufficientStockException` y la transacción se deshace entera (ni venta ni stock cambian). La pantalla avisa ("El stock de «X» ha cambiado…") y recarga el catálogo, ajustando el carrito a las existencias reales.
- **Datos:** `sales`, `sale_items`, `sale_packs`, `sale_combos`, `products.units`, `packs.units`.
- **Flujo:** botón de cobro (grande en horizontal) → registro → aviso.
- **Casos límite y errores:** el botón se bloquea mientras se registra (evita el doble toque) y, si la transacción falla, se muestra "No se pudo registrar la venta" y el carrito se conserva.
- **Código:** `lib/features/sales/presentation/sales_screen.dart` (`_processSale`), `lib/features/sales/domain/sale_from_cart_factory.dart`, `lib/features/sales/data/datasources/sale_local_datasource.dart` (`processSale`), `lib/features/sales/data/repositories/sale_repository_imp.dart`.
- **Tests:** `test/sale_cart_pricing_calculator_test.dart` (factory), `test/combo_test.dart` ("Sale with combos").

### SALES-007 · Congelado de precios y reglas en el ticket
- **Propósito:** que el ticket y las devoluciones no cambien aunque se editen productos, promociones o combos.
- **Reglas de negocio:**
  - Cada `sale_items` guarda: `historical_price` (precio unitario cobrado = subtotal de la línea ÷ cantidad, sin factor de ajuste), `original_price` (precio de lista en el momento), y la promoción propia **congelada** (`promotion_id`, `promo_type`, `promo_threshold`, `promo_discount`) incluso en líneas de combo (si una devolución rompe el combo, las unidades restantes vuelven a su promoción).
  - Las líneas de combo llevan `sale_combo_id`; `sale_combos` guarda nombre, precio, cantidad y la definición de huecos en JSON.
  - Una línea suelta y una de combo del mismo producto son líneas distintas.
  - `refundUnitPrice` = `original_price`, o `historical_price` si `original_price == 0` y `historical_price > 0` (ventas antiguas sin precio original); el datasource aplica la misma normalización al leer.
  - Los packs guardan `historical_price` = precio del pack.
  - El nombre del producto se lee con `LEFT JOIN`.
- **Datos:** `sale_items`, `sale_packs`, `sale_combos`.
- **Flujo:** transparente al usuario; visible en el ticket (precio original tachado, ahorro de combo).
- **Casos límite y errores:** producto borrado lógicamente → el nombre sigue disponible vía JOIN (la fila no se elimina).
- **Código:** `lib/features/sales/domain/sale.dart` (`SaleItem`, `SaleCombo`, `Sale`), `lib/features/sales/domain/sale_from_cart_factory.dart`, `lib/features/sales/data/datasources/sale_local_datasource.dart` (`getSales`, `_originalPrice`).
- **Tests:** `test/combo_test.dart`, `test/sale_cart_pricing_calculator_test.dart`.

### SALES-008 · Devolución parcial: cálculo del importe
- **Propósito:** calcular cuánto reembolsar cuando se devuelven unidades, respetando que una promoción o combo roto cambia el precio de lo que se queda.
- **Reglas de negocio (`SaleRefundCalculator`):**
  - `pagado = (Σ historical_price × cantidad original, líneas + packs) × adjustmentFactor`.
  - `reembolso = pagado − valor de lo que se queda × adjustmentFactor`, mínimo 0.
  - Valor de lo que se queda (`calculateKeptValue`):
    1. **Combos**: un combo intacto (ninguna de sus líneas devuelta) vale lo cobrado. Un combo afectado se **re-empareja** con `ComboMatcher` usando las unidades conservadas de sus líneas **más las unidades sueltas del mismo producto** de la misma venta (así da igual qué línea de "Teclado" se marque), con precios `refundUnitPrice`. Cada combo rehecho conserva su parte; las unidades que sobran quedan sueltas y valen su precio normal; las unidades sueltas absorbidas por el combo pasan a una línea del combo.
    2. **Sueltas por grupo de promoción**: grupos sin tocar valen lo cobrado; grupos afectados se recalculan con `calculateGroupValue`: sin promoción → lo cobrado (las sobrantes de combo, a precio normal); con promoción → si unidades conservadas < umbral → precio completo; `percentage` → `refundUnitPrice × (1 − dto/100)` por unidad; `bundle_fixed_price` → `FixedPriceBundleCalculator` con `refundUnitPrice`; el valor del grupo se reparte entre sus líneas **proporcionalmente al precio completo** (o por unidades si el precio completo es 0).
    3. **Packs**: `historical_price × unidades conservadas`.
  - `brokenPromotions`: avisa de promociones (no combos) que deja de cumplir lo que queda: en `bundle_fixed_price`, si `conservadas ÷ N < antes ÷ N` (divisiones enteras); en `percentage`, si antes ≥ umbral y después < umbral. Se muestra un aviso por promoción rota ("devolver 1 de 3 por 12 € deshace la oferta"), porque lo que queda vuelve a precio normal y por eso se reembolsa menos.
  - El importe calculado es **editable** por el usuario antes de confirmar.
- **Datos:** líneas, combos y factor de la venta.
- **Flujo:** ver SALES-009.
- **Casos límite y errores:** devolver 0 unidades → reembolso 0; reembolso nunca negativo.
- **Código:** `lib/features/sales/domain/sale_refund_calculator.dart` (`calculateRefundAmount`, `calculateRemainingCartValue`, `calculateKeptValue`, `calculateGroupValue`, `brokenPromotions`, `remainingAfterRefund`).
- **Tests:** `test/sale_refund_calculator_test.dart`, `test/combo_test.dart` ("Sale with combos", "Partial refunds in several steps").

### SALES-009 · Devolución parcial: flujo y aplicación en BD
- **Propósito:** devolver parte de un ticket reponiendo stock y dejando constancia.
- **Reglas de negocio:**
  - Diálogo desde el ticket: por cada línea (agrupadas por combo cuando aplica; opción de devolver un combo entero) y por cada pack, un selector 0..cantidad. Al cambiar cualquiera se recalcula el reembolso sugerido: `max(0, total_amount − valor restante × factor)`.
  - Botón «Devolver todo» (`_selectAll`): marca de una vez todas las líneas devolvibles y todos los packs (las líneas con descuento manual no entran) y recalcula el reembolso.
  - Campo del reembolso editable; se formatea al perder el foco. Si el importe > `total_amount` de la venta → error "no puede superar" y no se confirma.
  - Interruptor "reponer packs abiertos como componentes" (`restockAsComponents`): si está activo, los packs devueltos reponen sus **componentes** (`cantidad × unidades devueltas`) al inventario de productos; si no, suman a `packs.units`.
  - `processPartialRefund` (transacción):
    1. Si hay algo devuelto, inserta `sale_refunds(date = ahora, amount, summary)` con resumen "`N× Nombre, …`".
    2. Repone `products.units += devuelto` para líneas sueltas y de combo.
    3. Repone packs según el interruptor.
    4. Reescribe `sale_items` y `sale_combos` con lo que queda (`remainingAfterRefund`): precios recalculados de modo que la suma de líneas = valor de lo conservado; combos con cantidad 0 desaparecen y sus líneas pasan a sueltas.
    5. Packs devueltos por completo se borran de `sale_packs`; parciales restan cantidad.
    6. Si no queda ninguna línea ni pack → la venta se CONSERVA con `total_amount = 0` (sin combos) y con su historial de devoluciones (el ticket aparece como "Reembolsado", sin botón de devolver y sin contar en ingresos ni beneficio); si no, `total_amount = max(0, total − reembolso)` y `adjustment_factor = nuevo total ÷ Σ(historical_price × cantidad restantes)` (si esa suma es 0 se conserva el factor).
  - Una devolución parcial **no** reactiva productos borrados lógicamente.
  - Existen `SaleRepository.refundSale` / `SaleLocalDatasource.refundSale` (devolución total antigua: repone todo el stock, reactiva productos `is_active = 1`, borra venta y líneas; a diferencia de `processPartialRefund`, no conserva el ticket) pero **ninguna pantalla los llama** (POR CONFIRMAR si es código en desuso o se usará).
  - Las devoluciones pueden encadenarse en varios pasos; el ticket muestra el historial de devoluciones.
- **Datos:** `sales`, `sale_items`, `sale_packs`, `sale_combos`, `sale_refunds`, `products.units`, `packs.units`, `pack_items`.
- **Flujo:** historial → ticket → botón "Devolver" → diálogo → confirmar → recarga y aviso de éxito.
- **Casos límite y errores:** la devolución se hace siempre por el método de pago original; en un ticket antiguo sin método se indica que se desconoce.
- **Código:** `lib/features/sales/presentation/widgets/partial_refund_dialog.dart`, `lib/features/sales/presentation/history_screen.dart` (`_showPartialRefundDialog`), `lib/features/sales/data/datasources/sale_local_datasource.dart` (`processPartialRefund`, `refundSale`).
- **Tests:** `test/partial_refund_dialog_test.dart`, `test/sale_refund_calculator_test.dart`, `test/combo_test.dart`.

### SALES-010 · Historial de tickets: agrupación, búsqueda y totales
- **Propósito:** consultar ventas pasadas agrupadas por feria o por día.
- **Reglas de negocio:**
  - Orden: más recientes primero.
  - Búsqueda (subcadena sin mayúsculas) por **nombre de feria**, **nº de ticket** (id como texto), **nombre de algún producto** o **nombre de algún pack**.
  - Agrupación: si la venta tiene `fair_name` no vacío → grupo `fair:<nombre>` (todos los días de la feria juntos); si no → grupo `day:dd/mm/aaaa`. Cada grupo guarda el prefijo de fecha `aaaa-mm-dd` de su última venta procesada.
  - Total de grupo = Σ `total_amount`; recuento de tickets; desglose por método de pago (SALES-005).
  - Grupos expandidos al abrir; estado vacío distinto si no hay ventas o si no hay resultados.
- **Datos:** `sales`, `sale_items`, `sale_packs`, `sale_combos`, `sale_refunds`.
- **Flujo:** `/history` → buscador → grupos → tickets desplegables.
- **Casos límite y errores:** tickets sin nombre de producto (producto borrado) se buscan con cadena vacía.
- **Código:** `lib/features/sales/presentation/history_screen.dart`, `lib/features/sales/presentation/sale_history_group.dart` (`filterAndGroupSales`, `SaleHistoryGroup`), `lib/features/sales/presentation/widgets/sale_history_group_card.dart`.
- **Tests:** `test/sale_history_group_test.dart`, `test/sale_history_group_card_test.dart`.

### SALES-011 · Ferias (asignar, cambiar, quitar, borrar)
- **Propósito:** agrupar tickets por feria/evento.
- **Reglas de negocio:**
  - Catálogo `fairs(name)` (único sin distinguir mayúsculas); permite ferias sin tickets.
  - Asignar a un **grupo de día**: actualiza `sales.fair_name` de todas las ventas cuya `date` empiece por el prefijo `aaaa-mm-dd` de ese día. Asignar/cambiar en un **grupo de feria**: afecta a **todos** los tickets de esa feria, de cualquier día (`reassignFair`).
  - Elegir "quitar feria" (cadena vacía) pone `fair_name = NULL`.
  - Se crea en el catálogo (`_ensureFair`, nombre con `trim`, ignorando duplicados) al asignar.
  - Panel con buscador: tocar una feria la asigna; si lo escrito no existe aparece "Crear «X»".
  - Borrar feria del catálogo: confirmación (indica nº de tickets afectados); sus tickets **quedan sin feria** (no se borran).
  - Elegir la misma feria actual no hace nada.
- **Datos:** `fairs`, `sales.fair_name`.
- **Flujo:** chip "Agrupar en feria / Cambiar feria" en la cabecera del grupo → panel → asignación inmediata y aviso.
- **Casos límite y errores:** si solo se borra una feria desde el panel y no se elige otra, se recarga la lista igualmente.
- **Código:** `lib/features/sales/presentation/history_screen.dart` (`_showAssignFairDialog`, `_deleteFair`), `lib/core/shared_widgets/name_picker_sheet.dart`, `lib/features/sales/data/datasources/sale_local_datasource.dart` (`updateFairNameForDate`, `reassignFair`, `getAvailableFairs`, `countSalesForFair`, `deleteFair`).
- **Tests:** `test/sale_history_group_test.dart` (agrupación); sin tests de la capa de datos de ferias.

### SALES-012 · Ticket: contenido mostrado
- **Propósito:** ver el detalle de una venta.
- **Reglas de negocio:** cada ticket muestra nº, fecha/hora, método de pago, total (`total_amount`), líneas (agrupadas por combo con su precio y ahorro si lo hay, `ahorro = Σ precios de lista − Σ cobrado`, mostrado si > 0,005), packs, historial de devoluciones (fecha, importe, resumen) y botón de devolver. Importes con `context.money`.
- **Datos:** `sales` y tablas hijas.
- **Flujo:** expandir el ticket.
- **Casos límite y errores:** ninguno.
- **Código:** `lib/features/sales/presentation/widgets/sale_history_group_card.dart` (`_SaleTicketCard`), `lib/features/sales/presentation/widgets/sales_ui_utils.dart`.
- **Tests:** `test/sale_history_group_card_test.dart`.

### SALES-013 · Descuento manual por línea del carrito
- **Propósito:** rebajar puntualmente el precio de una línea del carrito sin tocar el producto ("lo dejo en 8 €").
- **Reglas de negocio:**
  - Se puede poner **siempre, salvo que ya mande otra oferta sobre TODAS las unidades**: van dentro de un combo, o su promoción activa las cubre todas. Una promoción asignada que aún no cumple su condición NO lo impide. Con una promoción de **lote de precio fijo** ("3 por 15 €") que deja unidades fuera (la 4.ª), esas unidades sueltas SÍ admiten descuento manual: actúa solo sobre ellas (`SaleCartPricingCalculator.uncoveredUnits` / `discountBase`; los lotes cogen las unidades más caras, `FixedPriceBundleCalculator.uncoveredUnits`) y la hoja lo indica ("Se aplica a la unidad fuera de la promoción"). Con una promoción de porcentaje todas las unidades entran: no hay sobrante. Si el lote pasa a cubrirlas todas (al añadir o quitar unidades), el descuento manual se cancela (`canDiscount`, `lineDiscountsToDrop`, que también se comprueba al quitar unidades).
  - Tipos (`ManualLineDiscount`): porcentaje (0 < x ≤ 100), importe (0 < x ≤ total de línea) y precio final (0 ≤ x < total de línea; se convierte a importe con `fromFinalPrice`). Se aplica al TOTAL de la línea, no por unidad; el resultado nunca baja de 0 y se redondea a céntimos (`roundToCents`) en la lógica pura. Un porcentaje tan pequeño que no descuenta ni un céntimo no cuenta.
  - Al cambiar la cantidad: el % se mantiene; el importe (y el precio final, ya convertido a importe) se mantiene como importe de línea. Al quitar la línea del carrito, el descuento se borra.
  - Si una línea con descuento pasa a tener una promoción activa o a ir en un combo (p. ej. al añadir unidades hasta el mínimo, o otro producto del combo), se quita el descuento y se avisa (`SaleCartPricingCalculator.lineDiscountsToDrop`). Bajar de nuevo las unidades no lo restaura.
  - Exclusión con el total acordado (SALES-004), con confirmación en ambos sentidos.
  - Al cobrar, `SaleFromCartFactory` congela en la línea `historicalPrice = total de línea descontado / unidades`, `originalPrice = precio de catálogo` y `manual_discount_type/value` (para el importe se guarda lo realmente descontado). `totalAmount` = suma de líneas.
  - **Las líneas con descuento manual no se devuelven**: el diálogo de devolución (SALES-008/009) las separa en un bloque propio, "Con descuento manual · no se pueden devolver", solo lectura (nombre, comprado, abonado, etiqueta roja y candado, sin selector), aparte de "Productos sueltos" donde sí se marcan las demás líneas del ticket. Es una decisión deliberada para no tener que recalcular promociones con descuentos a mano. `remainingAfterRefund` sigue conservando los campos del descuento (proporcional a las unidades) para tickets antiguos.
  - Dashboard: usa `historical_price`, así que el beneficio refleja el descuento sin cambios.
- **Datos:** `sale_items.manual_discount_type` (`percent`/`amount`), `sale_items.manual_discount_value` (v20); estado del carrito `_lineDiscounts` (por id de producto) en `SalesScreen`.
- **Flujo:** botón de etiqueta junto al "−" de la línea → hoja/diálogo `LineDiscountSheet` (segmentos %, €, Precio final; chips 5/10/20 % en modo %; vista previa "antes → ahora"; "Quitar descuento" si ya hay uno) → "Aplicar". La línea muestra el precio original tachado, la etiqueta "Descuento −10 %" **en rojo** (señala que el precio se tocó a mano y que no se podrá devolver; tocarla reabre la hoja) y el carrito muestra "Ahorro −X €" bajo el total. Con una promoción activa o en un combo el botón sale atenuado y al tocarlo explica el motivo. El historial muestra la misma etiqueta y el precio original tachado.
- **Casos límite y errores:** línea a 0 € permitida con aviso en la vista previa; doble toque en Aplicar/Quitar protegido (un solo pop); cambiar de modo en la hoja convierte el valor en vez de borrarlo.
- **Código:** `lib/features/sales/domain/manual_line_discount.dart`, `sale_cart_pricing_calculator.dart` (`price(lineDiscounts)`, `canDiscount`, `lineDiscountsToDrop`), `sale_from_cart_factory.dart`, `sale.dart` (`SaleItem.manualDiscount*`), `sale_refund_calculator.dart` (`remainingAfterRefund`), `lib/features/sales/data/datasources/sale_local_datasource.dart`, `lib/features/sales/presentation/sales_screen.dart` (`_setLineDiscount`, `_applyAgreedTotal`, `_pruneLineDiscounts`), `widgets/line_discount_sheet.dart`, `widgets/cart_items_list_widget.dart`, `widgets/sales_cart_total_summary.dart` (ahorro), `widgets/sale_history_group_card.dart`, `widgets/sales_ui_utils.dart` (`lineDiscountLabel`).
- **Tests:** `test/manual_line_discount_test.dart`, `test/sale_cart_pricing_calculator_test.dart` (grupo "manual line discounts"), `test/sale_refund_calculator_test.dart`, `test/database_migration_runner_test.dart`, `test/sale_history_group_card_test.dart`. Sin tests de widget de `LineDiscountSheet` ni de la capa de datos (insertar/leer `manual_discount_*`).

### SALES-015 · Catálogo de la caja en pantallas anchas
- **Propósito:** aprovechar el ancho de una tablet.
- **Reglas de negocio:** las columnas del catálogo salen del ancho disponible (`SalesScreen._catalogColumns`: tarjetas de ~150 dp, entre un mínimo de 3 en vertical / 4 en horizontal y 8). En una tablet caben muchas más que en un móvil. El encabezado de la hoja del carrito reserva más alto (`hasExtraLine`) cuando hay "Ahorro" o total tachado, para no pisar el aviso de combo.
- **Código:** `lib/features/sales/presentation/sales_screen.dart`, `widgets/sales_cart_sheet.dart`, `widgets/product_grid_widget.dart`, `widgets/packs_grid_widget.dart`.
- **Tests:** probado en emulador de tablet (sin tests de widget).

### SALES-014 · Total acordado y cambios en el carrito
- **Propósito:** que un total pactado no se aplique por error a un carrito distinto.
- **Reglas de negocio:** si cambia el CONTENIDO del carrito (añadir o quitar unidades de un producto o pack) con un total acordado activo (SALES-004), el total acordado se quita (factor 1) y se avisa ("Se quitó el total acordado porque cambió el carrito"). Si el carrito queda vacío se quita en silencio. También se quita si al recuperar el carrito (CartSession) las cantidades se recortan por el stock. Esto sustituye al comportamiento anterior (el factor proporcional se conservaba al cambiar el carrito).
- **Código:** `lib/features/sales/presentation/sales_screen.dart` (`_dropAgreedTotal`, `_notifyAgreedTotalDropped`, `_remapCart`), `lib/features/sales/presentation/cart_session.dart`.
- **Tests:** sin tests de widget (probado en el emulador).

### SALES-016 · Calculadora de vueltas en efectivo
- **Propósito:** saber cuánto devolver al cliente antes de cobrar, sin hacer la cuenta de cabeza.
- **Reglas de negocio:** con el método **Efectivo** y algo en el carrito, junto al botón COBRAR aparece un botón con icono de calculadora (se oculta con Bizum y PayPal). Abre un modal (`AdaptiveForm`: panel inferior en móvil, lateral/diálogo en tablet) con dos columnas arriba: a la izquierda el **Total** y lo **Entregado**, a la derecha las **Vueltas** (o **Faltan X €** si no llega) con los **billetes y monedas a devolver** (`CashChange.breakdown`: menor número de piezas, incluye 1 y 2 céntimos, p. ej. `1 × 5,00 €`, `2 × 0,20 €`). Abajo, solo botones, sin campos de texto: **billetes** (5, 10, 20, 50, 100, 200 €) y **monedas** (0,05, 0,10, 0,20, 0,50, 1, 2 €): cada toque suma lo que entrega el cliente. Lo marcado sale agrupado en chips bajo *Entregado* (`2 × 20,00 €`) y **cada chip se puede quitar de uno en uno** con su ✕ por si se marcó una pieza equivocada. **Justo** marca el total exacto, **Deshacer** quita el último y **Borrar** vacía. El modal tiene **Cerrar** y **COBRAR** (cierra y cobra directamente). Es solo una ayuda: no se guarda en la venta ni en el ticket. El cálculo va en céntimos enteros (`CashChange`) para evitar errores de coma flotante.
- **Código:** `lib/features/sales/domain/cash_change.dart`, `lib/features/sales/presentation/widgets/cash_change_sheet.dart`, `sales_screen.dart` (`_buildCheckoutButton`, `_openCashChange`).
- **Tests:** `test/cash_change_test.dart`.
