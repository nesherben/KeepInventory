# Copias de seguridad

Copias automáticas locales, subida manual a Google Drive, restauración (móvil, Drive o archivo) y borrado total. Una copia es **un único archivo** `.db` (las fotos viajan dentro como BLOB). Todas las copias van a la misma carpeta; el rojo se reserva a borrar (los avisos de copia pendiente usan `AppColors.warning`). UI en `lib/features/sync/presentation/` (pantalla de Datos `/data-management`).

Reglas transversales:
- Las prefs de copias van en `AppPreferences`, **nunca en `app_meta`** (se copiarían dentro del propio backup).
- **No escribir en la BD al abrirla**: la "firma de cambios" es `tamaño:mtime` del archivo `keepinventory.db`.

---

### BKP-001 · Copia local (crear)
- **Propósito:** guardar una copia consistente de la BD en el móvil.
- **Reglas de negocio (`LocalBackupService.createBackup`):**
  - Estados de resultado: `created`, `unchanged` (sin cambios desde la última), `empty` (BD sin datos de usuario) y `failed`.
  - Firma actual = `"<tamaño>:<mtime ms>"` del archivo de la BD. Sin `force`, si ya hubo una copia y la firma coincide con la guardada (`last_local_backup_signature`) → `unchanged`. Con `force: true` siempre copia.
  - Nombre: `keepinventory_AAAA-MM-DD_HHMM.db`.
  - La copia se hace con `snapshot`: abre la BD y copia el archivo dentro de una transacción **exclusiva** (bloquea escrituras mientras se copia) a un `.tmp` y lo renombra al final; si falla, no deja restos.
  - Tras copiar se valida con `BackupValidator.inspect` (BKP-004): si es inválida → se borra y `failed`; si está vacía (sin productos, ventas ni otros datos) → se borra y `empty` (una copia vacía no debe desplazar a las buenas).
  - Si va bien: aplica la rotación (BKP-002) y anota `last_local_backup_at` + firma y pone `backup_failures = 0`.
  - Si no existe el archivo de BD → `failed`.
- **Datos:** `last_local_backup_at`, `last_local_backup_signature`, `backup_failures` (prefs).
- **Flujo:** "Copiar ahora", copia automática (BKP-007/BKP-008), banner del dashboard (DASH-006) o "hacer una copia antes" de borrar todo (BKP-012).
- **Casos límite y errores:** `backup_failures` se incrementa en copias automáticas con resultado `failed`; desde 2 seguidos hay aviso.
- **Código:** `lib/core/services/local_backup_service.dart` (`createBackup`, `snapshot`, `signatureOf`, `currentSignature`, `hasUnsavedChanges`), `lib/core/services/app_preferences.dart`.
- **Tests:** `test/local_backup_service_test.dart` (nombres, firma), `test/app_preferences_test.dart`.

### BKP-002 · Rotación y nombres de copias
- **Propósito:** limitar el espacio sin perder copias útiles.
- **Reglas de negocio:**
  - Copias automáticas (`keepinventory_*.db`): se conserva **solo la última de cada día** y los **7 días** más recientes (`keepDays = 7`); el resto se borra. Ordenar por nombre = ordenar por fecha.
  - Copias "antes de restaurar" (`antes_de_restaurar_*.db`): se conservan las **3 últimas** (`keepBeforeRestore = 3`).
  - No se tocan archivos con otros nombres.
  - La rotación se aplica tras cada copia nueva o copia previa a restaurar; los borrados fallidos se ignoran.
  - Listado (`listBackups`): archivos de las dos carpetas (compartida si hay permiso, y privada), solo nombres válidos, de más nueva a más antigua por fecha de modificación.
- **Datos:** archivos en la carpeta de copias.
- **Flujo:** automático.
- **Casos límite y errores:** pocas copias → no se borra nada.
- **Código:** `lib/core/services/local_backup_service.dart` (`autoBackupsToDelete`, `beforeRestoreToDelete`, `_applyRetention`, `listBackups`, `autoFileName`, `beforeRestoreFileName`).
- **Tests:** `test/local_backup_service_test.dart` (grupos de rotación).

### BKP-003 · Carpeta de destino y permiso de archivos
- **Propósito:** que la copia sobreviva a desinstalar la app cuando sea posible.
- **Reglas de negocio:**
  - Carpeta compartida: `/storage/emulated/0/Documents/KeepInventory`; privada (fallback): `<almacenamiento externo de la app o soporte>/backups`.
  - Se usa la compartida solo si hay "Acceso a todos los archivos" (`manageExternalStorage` concedido; en Android 10 o anterior vale el permiso de almacenamiento clásico) **y** una escritura de prueba (`.probe`) funciona (2 intentos, 300 ms entre ellos). La comprobación del permiso se repite tras 400 ms para evitar estados provisionales al volver de Ajustes.
  - Flujo de permiso (`BackupPermissionFlow.ensure`): con permiso → `granted`; sin permiso pero con riesgo aceptado (`backup_risk_accepted`) → `riskAccepted`; si no, explicación → Ajustes → si sigue sin permiso, diálogo con "aceptar riesgo" (guarda la pref, la copia queda dentro de la app y no se vuelve a avisar) o "abrir Ajustes"; cancelar en la explicación → `declined` (no cuenta como aceptar riesgos).
  - La fila de aviso "completa los pasos" aparece si la copia automática está activa, no hay permiso y no se aceptó el riesgo.
- **Datos:** `backup_risk_accepted` (pref).
- **Flujo:** al activar la copia automática o "copiar ahora".
- **Casos límite y errores:** `declined` → no se activa/copia; excepciones al leer el permiso → se asume sin permiso.
- **Código:** `lib/core/services/local_backup_service.dart` (`hasFilesAccess`, `canWriteSharedFolder`, `requestFilesAccess`, `_targetFolder`), `lib/features/sync/presentation/backup_permission_flow.dart`.
- **Tests:** sin tests (depende de Android).

### BKP-004 · Validación de una copia (BackupValidator)
- **Propósito:** decidir si un archivo se puede restaurar y qué contiene, sin modificarlo.
- **Reglas de negocio (`inspect`):** abre en **solo lectura** y comprueba, en orden:
  1. `PRAGMA quick_check` = `ok`, si no (o no abre) → `corrupt`.
  2. Debe tener las tablas `products` y `sales`, si no → `notABackup`.
  3. `user_version` mayor que el esquema actual (21) → `newer` (no se migra hacia atrás).
  - Datos extraídos: versión de la app (`app_meta`, null si no hay: anterior a 1.14.1), `schemaVersion`, nº de productos, de ventas y `otherRows` (suma de filas de `categories, fairs, promotions, packs, combos, sale_refunds` que existan).
  - `isEmpty` = productos = 0, ventas = 0 y otherRows = 0; `needsMigration` = válida y esquema < actual.
  - `currentDatabaseHasData()`: la BD actual tiene algún dato (productos, ventas u otras tablas) → decide "instalación nueva" (CORE-006) y si hay recordatorio (DASH-006).
- **Datos:** solo lectura.
- **Flujo:** antes de restaurar, tras copiar, antes de subir a Drive y al buscar copias en el primer arranque.
- **Casos límite y errores:** cualquier excepción → `corrupt`.
- **Código:** `lib/core/services/backup_validator.dart` (`BackupValidator.inspect`, `BackupInfo`, `BackupProblem`, `currentDatabaseHasData`).
- **Tests:** `test/backup_validator_test.dart`.

### BKP-005 · Restaurar una copia (móvil o Drive)
- **Propósito:** sustituir la BD por una copia con red de seguridad.
- **Reglas de negocio (`BackupRestoreService.restoreFrom`):**
  1. Valida (BKP-004): `newer` → estado `newer`; cualquier otro problema → `invalid`.
  2. Detiene el servidor de sincronización y cierra la conexión de BD.
  3. **Siempre guarda una copia previa persistente** de los datos actuales (`saveBeforeRestore` → `antes_de_restaurar_*.db`; no se guarda si estaba vacía o dañada).
  4. Copia la fuente a `keepinventory.db.restore`. Si la copia es de un esquema antiguo, la **migra ahora sobre ese temporal** (CORE-002): si la migración falla, borra el temporal, devuelve los datos previos y responde `invalid` sin tocar la BD actual.
  5. Borra restos `-journal/-wal/-shm`, borra la BD actual y renombra el temporal.
  6. Cualquier excepción → devuelve los datos previos (`_putBack`) y `failed`.
  - Resultado `restored` → hay que **reiniciar** la app.
  - UI (`confirmAndRestore`): valida, pide confirmación (con icono y botón en rojo; muestra nº de productos, de ventas y fecha; si necesita migración, aviso de versión anterior), ejecuta con diálogo de progreso bloqueante, marca el tutorial como visto y anota la restauración como copia local (`recordLocalBackup`) o de Drive (`recordDriveBackup`) con la firma nueva y la fecha mostrada; luego muestra el diálogo de reinicio no descartable. Si la fuente es una descarga de Drive (`deleteAfter`), el temporal se borra siempre al terminar.
  - Mensajes de error distintos para `invalid`, `newer` y `failed`.
- **Datos:** `keepinventory.db`, `antes_de_restaurar_*.db`.
- **Flujo:** Datos → "Restaurar copia" (hoja con copias del móvil, Drive y "otro archivo") → confirmar → reiniciar.
- **Casos límite y errores:** el desplegable de copias del móvil distingue las "antes de restaurar".
- **Código:** `lib/core/services/backup_restore_service.dart` (`restoreFrom`, `_migrates`, `_putBack`), `lib/features/sync/presentation/backup_restore_flow.dart` (`confirmAndRestore`, `runWithBlockingProgress`, `showRestoredDialog`, `restoreFromDrive`), `lib/features/sync/presentation/widgets/auto_backup_section.dart` (`_openRestoreSheet`, `_RestoreSheet`).
- **Tests:** `test/database_migration_runner_test.dart`, `test/backup_validator_test.dart` (no hay test de `restoreFrom` completo — POR CONFIRMAR).

### BKP-006 · Restaurar desde un archivo elegido (`DatabaseBackupService`)
- **Propósito:** importar un `.db` externo mediante el selector de Android.
- **Reglas de negocio:**
  1. Cierra la BD; guarda un `keepinventory_restore_failsafe.db` y (si hay datos) una copia persistente previa; el canal nativo `restoreDatabase` sustituye el archivo (si devuelve false → `failed`, se descarta el failsafe).
  2. Comprueba la versión de la copia con `app_meta`:
     - Igual a la de la app → `restored`.
     - **Distinta** → se acepta si es **válida** (una copia más antigua se migra al abrirla); si es inválida se deshace (`rollbackPendingImport`) con `versionMismatch` (si es `newer`) o `failed`.
     - **Sin versión** (anterior a 1.14.1) → si es válida queda `unknownVersion` pendiente (el failsafe se conserva) hasta que el usuario confirme (`confirmPendingImport`, descarta el failsafe) o cancele (`rollbackPendingImport`, restaura lo anterior; si no había BD original, borra el archivo).
  - Pantalla de Datos: `restored` con versión distinta muestra aviso de copia más antigua y diálogo de reinicio; `unknownVersion` pregunta ("restaurar de todos modos"); `versionMismatch` informa; si se cierra la pantalla a mitad con `unknownVersion` se deshace.
  - Primer arranque: `restored` y `unknownVersion` se aceptan sin preguntar (no hay datos que perder), se marca el tutorial como visto y se pide reinicio.
- **Datos:** `keepinventory_restore_failsafe.db`.
- **Flujo:** hoja "Restaurar copia" → "Elegir archivo" (o botón equivalente del primer arranque).
- **Casos límite y errores:** cualquier excepción → rollback + `failed`.
- **Código:** `lib/core/services/database_backup_service.dart` (`importDatabase`, `confirmPendingImport`, `rollbackPendingImport`), `lib/features/sync/presentation/data_management_screen.dart` (`_handleImport`), `lib/features/sync/presentation/first_run_restore_screen.dart` (`_chooseFile`).
- **Tests:** sin tests propios (lógica de versiones en `test/app_version_test.dart`).
- **POR CONFIRMAR:** `DatabaseBackupService.exportDatabase` (exportar vía canal nativo `saveDatabase`) existe pero ninguna pantalla lo llama; no se revisó el código nativo (`com.example.keepinventory/database`).

### BKP-007 · Programador diario (WorkManager, 00:00)
- **Propósito:** copia automática hacia medianoche.
- **Reglas de negocio:**
  - `BackupScheduler.schedule()` registra una tarea de una sola ejecución con retardo hasta la **siguiente 00:00 local** (`nextMidnight = día siguiente a las 00:00`; a las 00:00 en punto programa la del día siguiente), con política `replace`.
  - Nombre único alterna entre `…dailyLocalBackup.0` y `.1` según el día (días desde 1970 módulo 2) para que la tarea que corre hoy no se cancele a sí misma al programar la de mañana.
  - La tarea (`backupCallbackDispatcher`): carga prefs; si la copia automática está desactivada no hace nada; si no, `createBackup()` (sin `force`); `failed` o excepción → `recordBackupFailure`; **siempre reprograma** la siguiente y devuelve éxito (sin reintentos en cadena).
  - Desactivar la copia automática cancela ambos nombres.
  - Android no garantiza la hora exacta; por eso existe también BKP-008.
- **Datos:** `auto_backup_enabled` (pref).
- **Flujo:** se programa al activar y al abrir la app; `initialize` en el arranque.
- **Casos límite y errores:** fallos al programar/cancelar solo se registran en log.
- **Código:** `lib/core/services/backup_scheduler.dart` (`BackupScheduler`, `backupCallbackDispatcher`, `backupTaskNameFor`), `lib/core/services/local_backup_service.dart` (`nextMidnight`).
- **Tests:** `test/local_backup_service_test.dart` (grupos "próxima medianoche" y "nombre de la tarea programada").

### BKP-008 · Coordinador: copia al abrir, al pasar a segundo plano y aviso
- **Propósito:** cubrir los huecos que deja el programador.
- **Reglas de negocio:**
  - **Al abrir / volver a la app** (`onAppStarted`): recarga prefs; si la copia automática está activa: reprograma y, si hay aviso pendiente (`reminderDue`), hace una copia silenciosa (fallo → `recordBackupFailure`); después refresca estados.
  - **Al pasar a segundo plano** (`onAppPaused`): si está activa, copia silenciosa (sin `force`, así que solo si hay cambios) con límite de **una cada 2 minutos**.
  - `reminderDue`: hay cambios sin copiar **y** (no hay copia previa o la última tiene ≥ 1 día). Con BD vacía no hay aviso.
  - `refresh()` actualiza `reminderNeeded`, `failures` (aviso desde 2) y sube `revision` (las pantallas la escuchan para refrescarse). El recordatorio se puede descartar en la sesión (`dismissReminder`).
- **Datos:** prefs de copias, firma de la BD.
- **Flujo:** ciclo de vida de la app (`main.dart`).
- **Casos límite y errores:** todas las excepciones se capturan y registran.
- **Código:** `lib/core/services/backup_coordinator.dart` (`BackupCoordinator`), `lib/core/services/local_backup_service.dart` (`reminderDue`).
- **Tests:** `test/local_backup_service_test.dart` (grupo "aviso de copia pendiente").

### BKP-009 · Primer arranque: ¿tienes una copia?
- **Propósito:** reinstalaciones sin perder datos.
- **Reglas de negocio:** se muestra cuando el tutorial no se ha visto y la BD está vacía (CORE-006). Busca la copia local **más reciente que sea válida y no vacía** (recorre `listBackups` en orden); ofrece: restaurar esa copia, pedir el permiso de archivos (si falta, para ver las copias de la carpeta compartida), restaurar de Drive (inicia sesión si hace falta; sin copias → aviso), elegir un archivo (BKP-006) o continuar sin restaurar. Los errores de Drive cancelado/offline/otros se traducen a avisos.
- **Datos:** carpeta de copias, Drive.
- **Flujo:** `/first-run` → opciones → restauración → reinicio; o continuar al tutorial.
- **Casos límite y errores:** si la búsqueda falla se siguen mostrando las demás opciones.
- **Código:** `lib/features/sync/presentation/first_run_restore_screen.dart`.
- **Tests:** sin tests.

### BKP-010 · Copia en Google Drive
- **Propósito:** copia remota manual en una carpeta oculta y privada de la cuenta del usuario.
- **Reglas de negocio:**
  - Alcance `drive.appdata` (carpeta `appDataFolder`, sin acceso al resto del Drive); **un único archivo** `keepinventory_backup.db` que se sobrescribe con la última copia.
  - Configuración: `driveServerClientId` en `drive_config.dart`; **vacío ⇒ Drive "pendiente de configurar"** (`DriveFailure.notConfigured`). Actualmente tiene un ID configurado.
  - Sesión: `signIn` (autentica, autoriza el alcance, guarda el correo en `drive_account_email`), `signOut` (borra sesión y correo).
  - Subida (`upload`): toma un `snapshot` temporal, lo **valida** (copia vacía o dañada → error y nunca sobrescribe la buena de Drive), busca el archivo existente (`findBackup`), crea (POST multipart con `parents: [appDataFolder]`) o actualiza (PATCH media), con progreso; al terminar anota `last_drive_backup_at` (= modificado en Drive) y firma; siempre borra el temporal.
  - Descarga (`download`): GET `alt=media` con timeouts de 2 min, a `.part` renombrado al terminar; borra el parcial si falla.
  - Errores: cancelado/interrumpido → `cancelled`; sin red, timeout, handshake → `offline`; HTTP no 2xx → `failed`.
  - Estado en la tarjeta de Datos: consulta silenciosa (`promptIfNecessary: false`) al abrir/reanudar; muestra "no conectado", "comprobando", "no disponible", "sin copia" o la fecha; caché de estado válida solo si la cuenta coincide (`drive_status_*`).
  - "Copiar ahora" con Drive: primero copia local (forzada); solo si resultó `created` y hay sesión sube a Drive; mensajes distintos para: local+Drive correcto, Drive no conectado, sin conexión, fallo de Drive.
- **Datos:** `drive_account_email`, `last_drive_backup_at`, `last_drive_backup_signature`, `drive_status_known`, `drive_status_account`, `drive_status_backup_at`.
- **Flujo:** Datos → conectar cuenta (`DriveBackupSection`) → "Copiar ahora" sube; restaurar desde la hoja (BKP-005).
- **Casos límite y errores:** la subida es **manual** (no hay subida automática); la restauración de Drive pide sesión si no la hay.
- **Código:** `lib/core/services/drive_backup_service.dart` (`DriveBackupService`, `DriveFailure`), `lib/core/services/drive_config.dart`, `lib/features/sync/presentation/widgets/drive_backup_section.dart`, `lib/features/sync/presentation/widgets/auto_backup_section.dart` (`_backupNow`, `_refreshDrive`), `lib/features/sync/presentation/backup_restore_flow.dart` (`restoreFromDrive`, `showDriveError`).
- **Tests:** `test/drive_backup_service_test.dart`.

### BKP-011 · Pantalla de Datos: estado y ajustes de copia
- **Propósito:** centralizar copias y restauración.
- **Reglas de negocio:**
  - Tarjeta de estado: copia pendiente (hay cambios sin copiar), fecha de la copia de Drive/estado, botón "Copiar ahora" (local + Drive).
  - Interruptor de copia automática: activar → `BackupPermissionFlow.ensure` (si `declined`, no se activa) → activa, programa y hace una copia silenciosa; desactivar → apaga y cancela la tarea.
  - Fila "completa los pasos" (permiso) y fila de aviso con fallos ≥ 2 (color de aviso).
  - Hoja "Restaurar copia": copias del móvil (con las "antes de restaurar" marcadas), Drive (solo si está configurado y hay sesión) y "otro archivo".
  - Se refresca al volver a la app (permiso concedido en Ajustes), al escuchar `BackupCoordinator.revision` y al cambiar el correo de Drive.
  - Layout: ≥ 840 px dos columnas para copias; sincronización y borrado a ancho completo. Mientras hay una operación (restaurar/borrar) los controles se desactivan.
- **Datos:** prefs de copias.
- **Flujo:** menú → Datos.
- **Casos límite y errores:** `LocalBackupStatus.unchanged/empty` muestran información (no error); `failed` muestra error.
- **Código:** `lib/features/sync/presentation/widgets/auto_backup_section.dart`, `lib/features/sync/presentation/widgets/settings_group.dart`, `lib/features/sync/presentation/data_management_screen.dart`.
- **Tests:** `test/data_management_layout_test.dart`.

### BKP-012 · Borrar todos los datos
- **Propósito:** reiniciar la app a cero con protecciones contra errores.
- **Reglas de negocio:** tres pasos: (1) diálogo de advertencia (indica que las copias existentes se conservan) con opción "hacer una copia antes" (copia forzada y **no se borra nada**) o continuar; (2) confirmación final; (3) **arrastrar la base de datos a la papelera** (hoja deslizante; solo continúa si se suelta dentro). Entonces `deleteDatabaseFile()` y diálogo para reiniciar; fallo → error. Mientras se importa o borra, la acción está bloqueada.
- **Datos:** archivo `keepinventory.db` (las copias en carpeta no se tocan).
- **Flujo:** Datos → "Zona de peligro" → pasos → reinicio.
- **Casos límite y errores:** cancelar en cualquier paso no borra nada; los estilos usan el rojo de error (única acción destructiva).
- **Código:** `lib/features/sync/presentation/data_management_screen.dart` (`_confirmDatabaseDeletion`, `_copyBeforeDelete`), `lib/features/sync/presentation/widgets/slide_to_trash_sheet.dart`, `lib/core/database/database_helper.dart` (`deleteDatabaseFile`).
- **Tests:** `test/data_management_delete_test.dart`, `test/slide_to_trash_test.dart`.
