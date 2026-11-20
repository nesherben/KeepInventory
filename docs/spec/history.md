# Historial de cambios

Registro de los cambios de **configuración** (no de stock ni de ventas) para poder consultarlos y, en fases posteriores, deshacerlos.

> Estado: **fase 1** (solo registro, sin pantalla). Pantalla de consulta y deshacer/rehacer: pendientes.

### HIST-001 · Registro de cambios de configuración
- **Propósito:** anotar qué cambia el usuario en productos, categorías, packs, promociones y combos, con su antes y después, para entenderlo y poder revertirlo.
- **Reglas de negocio:**
  - Se registra DENTRO de la misma transacción que el cambio (`HistoryRecorder.recordCreated/recordUpdated/recordDeleted`): se guardan los dos o ninguno. No se usan triggers ni decoradores.
  - Campos de configuración vigilados (`ChangeTracking.trackedFields`): producto `name, price, cost, category_id, promotion_id, imagen`; categoría `name`; promoción `name, type, threshold, discount_value`; pack `name, price, componentes, imagen`; combo `name, price, huecos`. **Las cantidades (stock) y las ventas NO se registran**: si una edición solo cambia el stock, no se anota nada.
  - Una edición guarda solo los campos que cambian (`before_json`/`after_json`); una creación solo `after`; un borrado solo `before`. Los ids de categoría y promoción llevan además su nombre legible (`category`, `promotion`) para que la entrada se entienda aunque se borren después.
  - Imágenes: se anota solo "tenía / no tenía imagen" (`image`: true/false); nunca se guardan los bytes.
  - Operaciones que afectan a varios elementos (asignar una promoción a toda una categoría, borrar una categoría o promoción en uso, cambiar los productos de una categoría) crean una entrada por elemento con el mismo `group_id`.
  - Un cambio nuevo borra las entradas `undone = 1` (lo que se podía rehacer).
  - Límite de 500 entradas (`HistoryRecorder.maxEntries`): al pasarlo se podan las más antiguas (por `created_at`, `id`).
  - No se escribe nada al abrir la BD ni en migraciones; restaurar una copia o importar por sync no genera entradas (el historial es el de la copia).
- **Datos:** tabla `change_log(id, created_at, entity, entity_id, entity_name, action, changed_fields, before_json, after_json, undone, group_id)` con índices por `created_at` y por `(entity, entity_id)`. Viaja con las copias de seguridad y la sincronización (BD entera).
- **Flujo:** transparente: se activa al guardar cualquier cambio de configuración desde Inventario, Categorías, Packs, Promociones y combos.
- **Casos límite y errores:** borrar un producto es lógico (`is_active = 0`): se anota como borrado y deshacerlo NO devolverá el stock. Los borrados de categoría/promoción anotan también los productos y combos afectados.
- **Código:** `lib/features/history/domain/{change_entry,change_diff}.dart`, `lib/features/history/data/history_recorder.dart`, y su uso en `product_local_datasource.dart`, `category_local_datasource.dart`, `promotion_local_datasource.dart`, `combo_local_datasource.dart`, `pack_local_datasource.dart`.
- **Tests:** `test/change_diff_test.dart`, `test/history_recorder_test.dart`, `test/database_migration_runner_test.dart`, `test/database_schema_creator_test.dart`.
