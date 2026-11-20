# Dashboard (Inicio)

Pantalla `/` (`DashboardScreen`): caja acumulada, métricas del inventario, gráfico de balance, aviso de copias y comprobación de actualizaciones. Todas las cifras de este módulo son consultas SQL directas (sin lógica de dominio aparte).

---

### DASH-001 · Métricas principales
- **Propósito:** resumen del negocio de un vistazo.
- **Reglas de negocio:**
  - **Caja** (tarjeta principal, "balance acumulado"): `SUM(sales.total_amount)` de todas las ventas (ya netas de devoluciones, que reducen o eliminan la venta); 0 si no hay ventas.
  - **Coste del inventario**: `SUM(products.cost × products.units)` + coste invertido en packs montados `SUM(products.cost × pack_items.quantity × packs.units)`. Incluye productos con `units` > 0 (los borrados lógicamente tienen `units = 0`).
  - **Valor de venta esperado**: `SUM(products.price × products.units)` + `SUM(packs.price × packs.units)`.
  - **Beneficio neto real**: ver DASH-004.
  - Tarjetas: coste (icono `warning`), valor de venta (`info`), beneficio neto (`success`).
  - Layout: ancho ≥ 600 px → dos columnas (caja y gráfico a la izquierda, tres métricas a la derecha); menos → apiladas (2 + 1).
  - Se recarga al abrir y con "tirar para refrescar".
- **Datos:** `sales`, `sale_items`, `sale_packs`, `products`, `packs`, `pack_items`.
- **Flujo:** abrir Inicio → indicador de carga → tarjetas.
- **Casos límite y errores:** cualquier excepción en la carga solo quita el indicador (las cifras quedan como estaban, sin mensaje).
- **Código:** `lib/features/dashboard/data/datasources/dashboard_local_datasource.dart` (`getTotalRevenue`, `getInventoryCost`, `getExpectedRevenue`), `lib/features/dashboard/presentation/dashboard_screen.dart` (`_loadMetrics`, `_buildMainCard`, `_buildMetricCard`), `lib/features/dashboard/data/repositories/dashboard_repository_impl.dart`.
- **Tests:** sin tests.

### DASH-002 · Desglose de ingresos por método de pago
- **Propósito:** cuadrar la caja por efectivo / PayPal / Bizum.
- **Reglas de negocio:** al tocar la tarjeta principal se despliega (con animación) el desglose: `SUM(total_amount)` agrupado por `payment_method`, mapeado con `PaymentMethod.fromDb` (todos los métodos presentes, aunque sean 0). La fila "Sin especificar" **solo aparece si su importe absoluto ≥ 0,005**.
- **Datos:** `sales.payment_method`, `sales.total_amount`.
- **Flujo:** toque en la tarjeta → panel → toque de nuevo lo pliega.
- **Casos límite y errores:** importes ocultos si el modo privacidad está activo (DASH-005).
- **Código:** `lib/features/dashboard/data/datasources/dashboard_local_datasource.dart` (`getRevenueByPaymentMethod`), `lib/features/dashboard/presentation/dashboard_screen.dart` (`_buildPaymentBreakdownPanel`).
- **Tests:** `test/payment_method_test.dart` (lógica de métodos).

### DASH-003 · Gráfico de balance (pantalla completa)
- **Propósito:** ver ingresos y beneficio por feria o por día.
- **Reglas de negocio:**
  - Clave de grupo SQL: `COALESCE(fair_name, date(date))`; una feria agrupa todos sus días; un día sin feria usa `aaaa-mm-dd`. Se considera **feria** toda clave que no case con `^\d{4}-\d{2}-\d{2}$`.
  - Cada grupo: ingresos (`SUM total_amount`), beneficio neto (DASH-004 por grupo), desglose por método y margen = `neto ÷ ingresos × 100` (0 si ingresos ≤ 0).
  - Los grupos son la unión de las claves de ventas y de beneficios, en el orden del mapa de ventas (cronológico: `ORDER BY date ASC`).
  - Filtro: Todos / Ferias / Días.
  - Barras de 60 px de ancho con scroll horizontal, que arranca desplazado al final (lo más reciente); eje con marcas "redondas" (`_niceTicks`: paso = 1, 2, 5 o 10 × 10ⁿ tal que haya ~4 marcas, desde `floor(min/paso)·paso` hasta `ceil(max/paso)·paso`).
  - Etiqueta corta: nombre de feria o `dd/mm`.
  - Por defecto está seleccionada la última barra; la tarjeta de detalle muestra ingresos, beneficio, margen y el desglose por método (solo métodos con |importe| > 0,005). El historial completo sirve también de vista tabla (más reciente primero).
  - El modo privacidad se puede conmutar dentro del gráfico.
- **Datos:** `sales`, `sale_items`, `sale_packs`, `pack_items`, `products`.
- **Flujo:** botón "gráfico" del dashboard → `FullScreenChartScreen`.
- **Casos límite y errores:** sin datos → estado vacío (POR CONFIRMAR el detalle visual).
- **Código:** `lib/features/dashboard/presentation/widgets/dashboard_chart.dart` (`FullScreenChartScreen`, `_Group`, `_niceTicks`), `lib/features/dashboard/presentation/widgets/dashboard_chart_painters.dart`, `lib/features/dashboard/data/datasources/dashboard_local_datasource.dart` (`getDailySales`, `getDailyNetProfits`, `getRevenueByPaymentMethodPerGroup`).
- **Tests:** sin tests.
- **Nota:** `getDailySales` ordena por `MIN(date)` de cada grupo, así que el orden cronológico es estable también en ferias de varios días.

### DASH-004 · Beneficio neto
- **Propósito:** beneficio real de lo vendido.
- **Reglas de negocio:**
  - Productos: `SUM((sale_items.historical_price × sales.adjustment_factor − COALESCE(products.cost, 0)) × quantity)`; el coste usado es el **coste actual** del producto (no el del momento de la venta).
  - Packs: `SUM(sale_packs.quantity × (historical_price × sales.adjustment_factor − COALESCE(coste del pack, 0)))`, con coste del pack = `SUM(products.cost × pack_items.quantity)` actual.
  - Total = productos + packs. Por grupo (feria/día) con la misma fórmula (`UNION ALL` de líneas y packs).
  - Las líneas se reescriben tras devoluciones parciales (SALES-009), así que el beneficio las refleja.
  - **Aplica `sales.adjustment_factor`** (total acordado, SALES-004): el beneficio cuadra con la caja. Sigue usando el coste actual, no el del momento de la venta (pendiente: columna de coste en `sale_items`).
- **Datos:** `sale_items`, `sale_packs`, `pack_items`, `products.cost`.
- **Flujo:** valor mostrado en la tarjeta "beneficio neto" y en el gráfico.
- **Casos límite y errores:** producto/pack sin coste → coste 0; un pack borrado (lógico, PACK-005) conserva sus líneas de venta y su beneficio.
- **Código:** `lib/features/dashboard/data/datasources/dashboard_local_datasource.dart` (`getActualNetProfit`, `getDailyNetProfits`).
- **Tests:** sin tests.

### DASH-005 · Modo privacidad
- **Propósito:** ocultar importes ante terceros.
- **Reglas de negocio:** botón ojo en la barra; activo → todos los importes del dashboard se muestran como `•••••• €`; el estado persiste (`privacy_mode_enabled`) y se refleja en el gráfico a pantalla completa (mismo notifier).
- **Datos:** pref `privacy_mode_enabled`.
- **Flujo:** toque en el ojo.
- **Casos límite y errores:** solo afecta al dashboard y al gráfico (no a ventas ni historial).
- **Código:** `lib/features/dashboard/presentation/dashboard_screen.dart` (`_togglePrivacyMode`, `_formatCurrency`), `lib/core/services/app_preferences.dart`.
- **Tests:** `test/app_preferences_test.dart`.

### DASH-006 · Aviso de copia de seguridad en el dashboard
- **Propósito:** recordar hacer copia o avisar de fallos.
- **Reglas de negocio:**
  - Si hay **≥ 2 fallos seguidos** de copia automática **y** la copia automática está activada → banner de error con botón a Datos (`/data-management`).
  - Si no, y `BackupCoordinator.reminderNeeded` (hay datos, cambios sin copiar y última copia con ≥ 1 día o inexistente; no descartado en la sesión) → banner con la fecha de la última copia (o "nunca"), botón "Copiar ahora" y cerrar (descarta hasta la próxima sesión).
  - "Copiar ahora": pide el permiso de archivos si hace falta (`BackupPermissionFlow`; si lo pospone no copia) y luego `createBackup(force: true)`; éxito/fallo con aviso.
- **Datos:** `AppPreferences` (`backup_failures`, `last_local_backup_at`, firma), BD.
- **Flujo:** banner arriba de la lista del dashboard.
- **Casos límite y errores:** resultado `empty/unchanged` no muestra aviso.
- **Código:** `lib/features/dashboard/presentation/widgets/backup_reminder_banner.dart`, `lib/core/services/backup_coordinator.dart`.
- **Tests:** `test/local_backup_service_test.dart` (regla `reminderDue`).

### DASH-007 · Actualizaciones y primeros pasos
- **Propósito:** comprobación de versión y guía al primer uso.
- **Reglas de negocio:** comprobación de actualización automática silenciosa una vez por sesión y botón manual (reglas en CORE-011); menú lateral que se abre solo la primera vez con catálogo vacío (CORE-012).
- **Datos:** pref `menu_hint_shown`.
- **Flujo:** ver CORE-011 y CORE-012.
- **Casos límite y errores:** ver CORE-011.
- **Código:** `lib/features/dashboard/presentation/dashboard_screen.dart` (`_checkForAppUpdates`, `_checkFirstSteps`), `lib/features/dashboard/presentation/widgets/update_available_dialog.dart`.
- **Tests:** `test/update_available_dialog_test.dart`.
