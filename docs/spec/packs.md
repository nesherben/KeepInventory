# Packs

Un pack es un conjunto de productos que se monta de antemano y se vende a un precio propio. Tiene **stock propio** (unidades montadas) que se descuenta de los componentes. Para la venta de packs ver [sales.md](sales.md) (SALES-001, SALES-003, SALES-008).

---

### PACK-001 · Modelo de pack y contabilidad de stock
- **Propósito:** representar un lote prefabricado con precio propio.
- **Reglas de negocio:**
  - Un pack = nombre, precio, foto, `units` (unidades montadas, por defecto 1) y lista de componentes (`producto`, `cantidad por 1 pack`).
  - **Montar un pack consume stock de sus componentes**: por cada componente se descuenta `cantidad × units` del producto. El stock de los productos que ya están dentro de packs montados deja de contar como producto suelto.
  - Igualdad de packs por `id` (se usan como clave del carrito).
  - Coste en el dashboard: lo invertido en packs montados = Σ (coste × cantidad × unidades del pack) (DASH-004).
- **Datos:** `packs(id, name, price, units, image_path, image_bytes)`, `pack_items(pack_id, product_id, quantity)`, `products.units`.
- **Flujo:** ver PACK-002…PACK-005.
- **Casos límite y errores:** `pack_items.product_id` es `RESTRICT`: un producto no se puede eliminar físicamente mientras esté en un pack (el borrado de producto es lógico, ver INV-004); al listar packs se hace `JOIN` con `products`, por lo que un componente cuyo producto ya no exista no aparece.
- **Código:** `lib/features/packs/domain/pack.dart` (`Pack`, `PackItem`), `lib/features/packs/data/datasources/pack_local_datasource.dart`, `lib/features/packs/data/pack_model.dart`, `lib/features/packs/data/repositories/pack_repository_impl.dart`.
- **Tests:** `test/pack_form_dialog_test.dart` (formulario), `test/sale_cart_pricing_calculator_test.dart` (precio de packs en el carrito).

### PACK-002 · Crear pack
- **Propósito:** definir un pack nuevo y montar sus unidades iniciales.
- **Reglas de negocio:**
  - Requiere productos disponibles: si el catálogo está vacío se avisa ("necesitas productos") y no se abre el formulario.
  - Validaciones: nombre obligatorio (`trim`); precio obligatorio, número válido y ≥ 0; "stock inicial" (unidades) obligatorio y entero válido; **al menos un componente** (si no, aviso).
  - **Stock suficiente:** para cada componente con cantidad > 0, `cantidad × unidades del pack` debe ser ≤ stock actual del producto; si no, error indicando el producto y las unidades.
  - Solo se guardan componentes con cantidad > 0.
  - Al guardar (transacción): inserta el pack, inserta sus componentes y descuenta `cantidad × units` de cada producto.
  - El selector de productos excluye los ya añadidos al pack.
- **Datos:** `packs`, `pack_items`, `products.units`.
- **Flujo:** pantalla de packs → botón de crear → formulario (nombre, precio, stock inicial, foto, componentes) → guardar → recarga y aviso "pack creado".
- **Casos límite y errores:** unidades de pack 0 es válido (pack sin montar). Un fallo de stock bloquea el guardado entero.
- **Código:** `lib/features/packs/presentation/widgets/pack_form_dialog.dart` (`_savePack`), `lib/features/packs/presentation/packs_screen.dart` (`_showPackDialog`), `lib/features/packs/data/datasources/pack_local_datasource.dart` (`createPack`).
- **Tests:** `test/pack_form_dialog_test.dart`.

### PACK-003 · Editar pack
- **Propósito:** cambiar datos, componentes o unidades de un pack.
- **Reglas de negocio:**
  - Mismas validaciones que PACK-002, pero el stock disponible de un componente es `stock actual + (cantidad anterior × unidades anteriores del pack)` (lo que ya estaba reservado vuelve a estar disponible).
  - Al guardar (transacción): **devuelve** al inventario todo el stock antiguo del pack (`cantidad antigua × units antiguas`), borra los componentes antiguos, actualiza `name/price/units/foto`, inserta los nuevos componentes y **descuenta** `cantidad nueva × units nuevas`.
  - Componentes antiguos cuyo producto ya no está disponible en el catálogo activo se omiten al abrir el formulario (no se precargan).
- **Datos:** `packs`, `pack_items`, `products.units`.
- **Flujo:** acción editar en la tarjeta → formulario precargado → guardar → aviso "pack modificado".
- **Casos límite y errores:** si falta stock tras recomputar, error y no se guarda.
- **Código:** `lib/features/packs/data/datasources/pack_local_datasource.dart` (`updatePack`), `lib/features/packs/presentation/widgets/pack_form_dialog.dart`.
- **Tests:** `test/pack_form_dialog_test.dart` (solo UI del formulario; la transacción de `updatePack` no tiene test).

### PACK-004 · Montar / desmontar rápido (+1 / −1)
- **Propósito:** ajustar las unidades montadas desde la tarjeta.
- **Reglas de negocio:**
  - **Desmontar (−1):** solo si `units > 0`; implementa `updatePack` con `units − 1` (devuelve al inventario los componentes de 1 pack). Aviso "pack desmontado".
  - **Montar (+1):** comprueba que cada componente tenga stock ≥ su cantidad por pack; si falta alguno, error con el nombre y la cantidad que falta (`cantidad − stock`; componentes sin stock/borrados → "desconocido/eliminado"). Si todo está bien, `updatePack` con `units + 1`. Aviso "pack montado".
- **Datos:** `packs.units`, `products.units`.
- **Flujo:** botones +/− en la tarjeta del pack.
- **Casos límite y errores:** no hay debounce (cada toque es una operación).
- **Código:** `lib/features/packs/presentation/packs_screen.dart` (`_quickAdjustStock`), `lib/features/packs/presentation/widgets/pack_list_item.dart`.
- **Tests:** sin tests.

### PACK-005 · Borrar pack
- **Propósito:** eliminar un pack devolviendo los componentes no vendidos.
- **Reglas de negocio:** confirmación con el nombre y las unidades montadas; en transacción devuelve `cantidad × units` de cada componente al inventario y **oculta** el pack (borrado lógico: `is_active = 0`, `units = 0`). La fila de `packs`, sus `pack_items` y las líneas `sale_packs` se conservan, así que los tickets antiguos mantienen su línea y el beneficio no cambia.
- **Datos:** `packs` (`is_active`, desde v19), `pack_items`, `products.units`.
- **Flujo:** acción borrar (rojo) → confirmación → aviso "pack eliminado".
- **Casos límite y errores:** `getPacks` solo lista `is_active = 1`. Si se devuelve una venta que incluía un pack oculto, sus componentes vuelven al inventario (`SaleLocalDatasource._restockPack`) en vez de acumular unidades en un pack invisible. Los tickets cuyo pack se borró antes de la v19 (con cascada) siguen sin su línea.
- **Código:** `lib/features/packs/data/datasources/pack_local_datasource.dart` (`deletePack`), `lib/features/packs/presentation/packs_screen.dart` (`_confirmDelete`).
- **Tests:** sin tests.
- **Resuelto en v19:** antes el borrado físico con `ON DELETE CASCADE` eliminaba las líneas de `sale_packs` de tickets históricos y alteraba el beneficio (DASH-004). El FK sigue en el esquema pero ya no se borran packs.

### PACK-006 · Búsqueda y listado de packs
- **Propósito:** localizar packs.
- **Reglas de negocio:** búsqueda por subcadena (sin mayúsculas) del **nombre del pack o del nombre de cualquiera de sus componentes**. Mismo criterio en el catálogo de ventas (`SaleCatalogFilter.filterPacks`).
- **Datos:** lectura de `packs` y `pack_items`.
- **Flujo:** barra de búsqueda con botón de limpiar; estado vacío si no hay resultados.
- **Casos límite y errores:** consulta vacía → todos.
- **Código:** `lib/features/packs/presentation/packs_screen.dart`, `lib/features/sales/domain/sale_catalog_filter.dart` (`filterPacks`), `lib/features/packs/presentation/widgets/pack_list_item.dart`.
- **Tests:** `test/sale_catalog_filter_test.dart`.
