# Sincronización entre móviles

Copia de **todos los datos** de un móvil (emisor) a otro (receptor) por red local, sin cuentas ni nube. El emisor muestra un QR; el receptor lo escanea; **el emisor debe aprobar cada solicitud** y ambos deben tener la **misma versión de la app**. Pantalla: `SyncScreen` (se abre desde la pantalla de Datos, `/data-management`).

> Regla de seguridad del proyecto: **nunca servir datos sin la aprobación del emisor** (SYNC-002).

---

### SYNC-001 · Servidor HTTP del emisor
- **Propósito:** exponer el archivo de la BD al receptor autorizado.
- **Reglas de negocio:**
  - Servidor `shelf` en `0.0.0.0:8080` (`SyncService.port`). Al arrancar: calcula las IPv4 locales (si no hay ninguna → error "sin IP"), cierra la conexión de BD (`resetDatabase`) para que el archivo esté completo en disco, comprueba que existe `keepinventory.db` (si no → error), detiene cualquier servidor previo y arranca. Cualquier excepción → error genérico de arranque; devuelve null.
  - **Todas** las rutas exigen `?token=<token del QR>`; si no coincide → 403.
  - Rutas: `GET /ping` → `keepinventory`; `GET /request?id&device&app` → registra solicitud; `GET /status?id` → `pending|approved|denied|unknown`; `GET /download-db?id` → el archivo (`application/octet-stream`, con `Content-Length`) solo si está aprobada y quedan descargas.
  - `/request`: `id` ausente o de menos de **8** caracteres → 400. Si el servidor tiene `appVersion` y `app` de la solicitud no coincide (o falta: receptores antiguos) → **409** con `version:<versión>`. Si hay demasiadas pendientes → **429** `busy`. `device` vacío → `?`. Es idempotente para el mismo id (notifica una sola vez).
  - Detener servidor: `stopServer()` (cierre forzado); se detiene también al salir de la pantalla, al parar la emisión y antes de restaurar una copia (BKP-005).
  - El token es aleatorio, de 24 caracteres sin ambiguos (`SyncInvite.newToken`) y **se genera en cada arranque del servidor**.
- **Datos:** archivo `keepinventory.db`.
- **Flujo:** emisor pulsa emitir (misma Wi‑Fi o con punto de acceso) → servidor activo + QR.
- **Casos límite y errores:** si el hotspot arrancó pero el servidor falla, se detiene el hotspot.
- **Código:** `lib/core/services/sync_service.dart` (`SyncService.startServer`, `buildSyncHandler`, `stopServer`, `localIPv4Addresses`), `lib/features/sync/presentation/sync_screen.dart` (`_startHosting`, `_stopHosting`).
- **Tests:** `test/sync_server_test.dart`.
- **POR CONFIRMAR:** CLAUDE.md habla de token "de un solo uso", pero en el código el token vale durante toda la sesión del servidor (no se invalida tras una descarga); la protección de un solo uso real viene del id de solicitud aprobado y el límite de descargas (SYNC-002).

### SYNC-002 · Aprobación obligatoria del emisor (SyncApprovalGate)
- **Propósito:** que ningún dispositivo reciba datos sin que el dueño lo acepte en pantalla.
- **Reglas de negocio:**
  - Estados: `pending`, `approved`, `denied`, `unknown` (id desconocido), `versionMismatch` (solo lado receptor).
  - Una solicitud pendiente sin respuesta pasa a `denied` tras **2 min** (`pendingTimeout`).
  - Una aprobación **caduca a los 10 min** (`approvalValidity`) → `denied`.
  - `maxDownloads = 3` descargas por aprobación (reintentos si se corta la red); la 4ª → 403.
  - `maxPending = 5` solicitudes pendientes simultáneas; la 6ª → 429.
  - `approve/deny` solo tienen efecto si la solicitud sigue pendiente.
  - Un id distinto no puede reutilizar la aprobación de otro.
  - `dispose()` cancela temporizadores y limpia.
- **Datos:** estado en memoria del emisor.
- **Flujo:** al llegar una solicitud, el emisor ve un diálogo no descartable con el nombre del dispositivo y el **código de verificación** (SYNC-003) → "Permitir" o "Denegar" → aviso de aprobado/denegado.
- **Casos límite y errores:** si el emisor cierra la pantalla, el `gate` se destruye y todo pasa a `unknown`.
- **Código:** `lib/core/services/sync_approval.dart` (`SyncApprovalGate`, `SyncRequest`, `SyncRequestStatus`), `lib/features/sync/presentation/sync_screen.dart` (`_onSyncRequest`, `_ApprovalDialog`).
- **Tests:** `test/sync_server_test.dart` (grupo `SyncApprovalGate`).

### SYNC-003 · Código de verificación
- **Propósito:** que ambos móviles muestren el mismo número de 4 cifras para confirmar que se aprueba al dispositivo correcto.
- **Reglas de negocio:** `verificationCode(id)` = hash FNV‑1a de 32 bits del id (offset `0x811c9dc5`, primo `0x01000193`, máscara 32 bits) módulo 10000, con ceros a la izquierda; estable y distinto por id. El receptor genera el id (token de 16 caracteres) y muestra el código mientras espera.
- **Datos:** id de solicitud.
- **Flujo:** receptor: "esperando aprobación (código NNNN)"; emisor: diálogo con el mismo código.
- **Casos límite y errores:** colisiones posibles (4 cifras); es una ayuda visual, no autenticación.
- **Código:** `lib/core/services/sync_approval.dart` (`verificationCode`, `SyncRequest.code`).
- **Tests:** `test/sync_server_test.dart` ("verification code is stable, 4 digits and differs by id").

### SYNC-004 · Contenido y formato del QR (SyncInvite)
- **Propósito:** pasar al receptor cómo conectar.
- **Reglas de negocio:**
  - Formato v2 (URI): `keepinventory://sync?v=2&port=8080&token=…&hosts=ip1,ip2&app=<versión>`; en modo punto de acceso añade `&ssid=…&pw=…&sec=wpa2|wpa3|open`.
  - `parse`: acepta el formato antiguo `http(s)://ip:puerto/download-db` (hosts = [ip], sin token/aprobación: `legacyUrl`; puerto por defecto 80); si no es de la app (esquema distinto o host ≠ `sync`) o el puerto no está en 1..65535 → null. `hosts` se separa por comas, recortando vacíos; `sec` por defecto `wpa2`; `ssid` vacío = sin hotspot (`usesHotspot` = ssid no vacío).
  - `app` es la versión del emisor (null en QR de antes de la 1.14.1).
  - URIs derivadas: `/ping`, `/request`, `/status`, `/download-db` contra un host concreto, con el token como `query`.
  - `hosts` ordena primero las IPs típicas de punto de acceso/Wi‑Fi Direct (`192.168.43.*`, `192.168.49.*`).
- **Datos:** ninguno (efímero).
- **Flujo:** emisor genera el QR; receptor lo escanea con `mobile_scanner`; QR inválido → error "QR no válido".
- **Casos límite y errores:** un QR antiguo se interpreta pero no tiene `app`, así que `importDatabase` lo rechaza por "versión desconocida" antes de conectar (SYNC-005, paso 1); las ramas de "sin aprobación" para `legacyUrl` quedan como código muerto en la práctica (POR CONFIRMAR si se quiere mantener la compatibilidad).
- **Código:** `lib/core/services/sync_invite.dart` (`SyncInvite`, `parse`, `toQrData`, `newToken`), `lib/features/sync/presentation/sync_screen.dart` (escáner y QR).
- **Tests:** `test/sync_invite_test.dart`.

### SYNC-005 · Receptor: importar los datos
- **Propósito:** descargar e instalar la BD del emisor de forma segura.
- **Reglas de negocio (`SyncService.importDatabase`), en orden:**
  1. **Misma versión de la app obligatoria**: compara la del QR con la propia: distinta → error "versión distinta (X vs Y)"; sin versión en el QR → error "versión desconocida"; ambas abortan sin tocar nada.
  2. Localizar al emisor: prueba cada host del QR (+ pasarela del hotspot primero) con `/ping` (timeout 3 s), hasta 3 rondas con 2 s entre ellas; si ninguno responde → "emisor no encontrado".
  3. Aprobación (no aplica al QR antiguo): genera id de 16 caracteres, `GET /request` (timeout 5 s); 409 → versión distinta; otro código ≠ 200 → denegado; luego consulta `/status` cada 1 s hasta **2 min** o hasta `approved`/`denied`; `denied` → "denegado por el emisor"; agotado el tiempo → "sin respuesta".
  4. Descarga con **hasta 3 intentos** (2 s entre ellos, timeout de conexión 15 s): escribe en `keepinventory_temp.db` con progreso (% si hay `Content-Length`, MB si no).
  5. **Integridad:** si hubo error de stream o `recibidos < esperados` → borra el temporal y reintenta; tras el 3º → "descarga inestable".
  6. **Validación y copia previa** (ver nota abajo) y **instalación segura:** cierra la BD, copia la actual a `keepinventory_failsafe.db`, copia el temporal sobre `keepinventory.db`, borra temporal y failsafe y devuelve éxito; si falla, restaura desde el failsafe y devuelve error.
  - Siempre al final: `HotspotService.disconnect()` (vuelve a la red normal).
  - Éxito → diálogo para **reiniciar** la app (`restart_app`).
- **Datos:** `keepinventory.db`, `keepinventory_temp.db`, `keepinventory_failsafe.db`.
- **Flujo:** receptor → "Recibir datos" → escanear QR → (conectar al hotspot si procede) → esperar aprobación → descarga → reinicio.
- **Casos límite y errores:** respuesta HTTP ≠ 200 en la descarga → reintenta y, al fallar, "servidor rechazó".
- **Código:** `lib/core/services/sync_service.dart` (`importDatabase`, `requestApproval`, `findReachableHost`), `lib/core/services/database_file_installer.dart` (`DatabaseFileInstaller.installDownloadedFile`), `lib/features/sync/presentation/sync_screen.dart`.
- **Tests:** `test/sync_server_test.dart` (end-to-end con servidor real), `test/database_file_installer_test.dart`.
- **Nota:** la BD descargada se valida con `BackupValidator.inspect` antes de instalarla (dañada o de una versión más nueva → "no se pudo aplicar", sin tocar la BD actual) y, tras cerrar la BD, se guarda una copia persistente previa con `LocalBackupService.saveBeforeRestore` (igual que la restauración de copias, BKP-005); si esa copia falla, se aborta. No se ha podido probar con dos móviles reales.

### SYNC-006 · Punto de acceso local (hotspot) y conexión automática
- **Propósito:** sincronizar sin Wi‑Fi compartida: el emisor crea una red local y el receptor se une.
- **Reglas de negocio (contrato Flutter ↔ Android):**
  - Canal `MethodChannel('com.example.keepinventory/hotspot')`: `startHotspot` → `{ssid, password, security}` (si falta ssid → error), `stopHotspot`, `connect({ssid, password, security})` → `{gateway}` (Android 10+), `disconnect`, `deviceName` (marca y modelo, por defecto "Android"), `canConnectAutomatically`, `openLocationSettings`.
  - Errores nativos traducidos a `HotspotError`: `permission_denied`, `location_off` (se ofrece abrir ajustes de ubicación), `incompatible_mode`/`busy`, `unsupported` (también si no hay plugin), `unavailable`/`failed` → mensaje genérico.
  - Emisor con hotspot: tras arrancar espera 1,5 s a que la interfaz tenga IP; el QR incluye `ssid/pw/sec`.
  - Receptor: si no puede conectar automáticamente (Android 9 o anterior) → diálogo de conexión manual guiada; si el usuario no completa o la conexión falla → se aborta con error.
  - La pasarela devuelta por `connect` se prueba primero al localizar al emisor.
- **Datos:** ninguno persistente.
- **Flujo:** emisor elige "emitir con punto de acceso" → QR con credenciales; receptor escanea → se une a la red → continúa en SYNC-005.
- **Casos límite y errores:** `stop`/`disconnect` ignoran errores; al salir de la pantalla se detienen servidor, hotspot y conexión.
- **Código:** `lib/core/services/hotspot_service.dart` (`HotspotService`, `HotspotException`), `android/…/HotspotChannel.kt` (no revisado en esta spec), `lib/features/sync/presentation/sync_screen.dart` (`_showHotspotError`, `_joinSenderNetwork`).
- **Tests:** sin tests (solo comprobable en dos móviles reales).
- **POR CONFIRMAR:** comportamiento exacto nativo (permisos pedidos, `LocalOnlyHotspot`, seguridad de la red) no verificado leyendo `HotspotChannel.kt`.

### SYNC-007 · Pantalla de sincronización
- **Propósito:** interfaz de emisor y receptor.
- **Reglas de negocio:** botones para emitir con punto de acceso, emitir en la misma Wi‑Fi y recibir datos (escáner); con el servidor activo se muestra el QR, la IP activa, las credenciales del hotspot si aplica y "detener emisión"; durante la recepción se muestra progreso y mensaje de estado; mensajes de error con prefijo del estado; tras éxito, diálogo de reinicio. Al salir de la pantalla se destruye todo (gate, servidor, hotspot, conexión).
- **Datos:** estado en memoria.
- **Flujo:** Datos → tarjeta de sincronización → `SyncScreen`.
- **Casos límite y errores:** doble inicio evitado con banderas `_isStarting`/`_isReceiving`.
- **Código:** `lib/features/sync/presentation/sync_screen.dart`, `lib/features/sync/presentation/data_management_screen.dart` (`_SyncCard`).
- **Tests:** `test/data_management_layout_test.dart` (layout de la pantalla de datos).
