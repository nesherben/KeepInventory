# Especificación funcional de KeepInventory

Especificación en español, **bidireccional**: describe lo que hace hoy el código (código → spec) y sirve para pedir cambios (spec → código). Generada a partir del código de la versión 1.18.2 y actualizada con los arreglos posteriores (esquema de BD 21 tras el borrado lógico de packs, el descuento manual por línea y el historial de cambios).

## Índice

| Módulo | Archivo | Prefijo de IDs |
|---|---|---|
| Inventario (productos, categorías, stock) | [inventory.md](inventory.md) | `INV-` |
| Ventas (carrito, cobro, tickets, devoluciones, precios, ferias) | [sales.md](sales.md) | `SALES-` |
| Packs (productos montados) | [packs.md](packs.md) | `PACK-` |
| Promociones y combos | [promotions.md](promotions.md) | `PROMO-` |
| Dashboard (métricas, gráfico, avisos) | [dashboard.md](dashboard.md) | `DASH-` |
| Sincronización entre móviles (servidor, aprobación, QR, hotspot) | [sync.md](sync.md) | `SYNC-` |
| Copias de seguridad (local, Drive, restauración, programador) | [backups.md](backups.md) | `BKP-` |
| Historial de cambios (registro de configuración, deshacer/rehacer) | [history.md](history.md) | `HIST-` |
| Núcleo (BD, esquema, migraciones, preferencias, números, tema, l10n, arranque) | [core.md](core.md) | `CORE-` |

## Cómo usar la spec

### 1. Cambiar la app: editar la spec y pedir "aplica la spec al código"
1. Edita la sección (por su ID, p. ej. `SALES-004`) en el `.md` correspondiente: cambia reglas de negocio, flujo o casos límite.
2. Pide: **"aplica la spec al código"** (opcionalmente indicando IDs: "aplica SALES-004 y PACK-002").
3. El agente compara la sección con el código de su apartado **Código**, implementa la diferencia, actualiza los **Tests** listados (o crea nuevos) y, si procede, l10n (skill `l10n-add`), README y migración de BD (subir versión + migración + creador + tests).
4. Al terminar, la sección queda como verdad; si el agente detecta que algo no encaja lo anota como **POR CONFIRMAR** en vez de suponer.

### 2. Detectar deriva: pedir "sincroniza la spec"
Compara spec y código en ambos sentidos y devuelve una lista de diferencias (código que ya no cumple la spec, o spec desactualizada). No cambia nada sin tu OK; tú decides en cada diferencia si se corrige el código o la spec.

### 3. Reglas de mantenimiento
- Los **IDs son estables**: no se renumeran ni se reutilizan. Una funcionalidad eliminada se marca `**ELIMINADA**` pero conserva su ID.
- Las rutas de **Código** no llevan números de línea (se desactualizan); se identifican por archivo + clase/método.
- Todo lo que no se pudo confirmar leyendo el código figura como **POR CONFIRMAR** (búsquelo con `grep -rn "POR CONFIRMAR" docs/spec`).
- Cambios de esquema de BD: ver CORE-001 / CORE-002 (subir `schemaVersion`, migración, creador, tests).
- El texto de UI nunca se copia aquí; se referencia por comportamiento (las cadenas viven en `lib/l10n/*.arb`).

## Plantilla de sección

```markdown
### MOD-000 · Nombre de la funcionalidad
- **Propósito:** una o dos líneas.
- **Reglas de negocio:**
  - Fórmulas, redondeos, validaciones, estados y límites concretos.
- **Datos:** tablas/columnas, preferencias (`AppPreferences`), `app_meta`.
- **Flujo:** pasos de pantalla/usuario.
- **Casos límite y errores:** qué pasa cuando falla o hay datos raros.
- **Código:** `ruta/archivo.dart` (`Clase.método`), …
- **Tests:** `test/archivo_test.dart`, … (o "sin tests").
- **POR CONFIRMAR:** (opcional) dudas no resueltas leyendo el código.
```

## Convenciones transversales (resumen; detalle en core.md)
- Dinero: se muestra con `context.money(x)` / `context.amount(x)`, se lee con `AppNumbers.parseDecimal/parseInt` (CORE-005).
- Persistencia: SQLite local (`sqflite`), sin gestor de estado; `StatefulWidget` + `setState`/`ValueNotifier`.
- Capas por feature: `domain/` (lógica pura) → `data/` (modelos, datasources, repos) → `presentation/`.
- Idiomas: español (plantilla) + inglés (CORE-008).
