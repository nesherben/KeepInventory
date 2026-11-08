<div align="center">

<img src="assets/icon/app_icon.png" alt="KeepInventory" width="120" />

# keepinventory

**Sales manager with customizable options powered by flutter and AI.**

Inventario + punto de venta (TPV) para Android, pensado para ferias, mercadillos y pequeños negocios.
Funciona 100 % sin conexión: tus datos viven en tu móvil.

[![Release](https://img.shields.io/github/v/release/nesherben/KeepInventory?label=descargar%20APK&logo=android&color=3DDC84)](https://github.com/nesherben/KeepInventory/releases/latest)
[![Build](https://img.shields.io/github/actions/workflow/status/nesherben/KeepInventory/build.yml?branch=main&label=build)](https://github.com/nesherben/KeepInventory/actions/workflows/build.yml)
![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![Platform](https://img.shields.io/badge/plataforma-Android-3DDC84?logo=android&logoColor=white)
[![License: MIT](https://img.shields.io/badge/licencia-MIT-blue.svg)](LICENSE)
[![PayPal](https://img.shields.io/badge/donar-PayPal-00457C?logo=paypal&logoColor=white)](https://www.paypal.me/nestor8299)

</div>

---

## 📑 Índice

- [Funcionalidades](#-funcionalidades)
- [Instalación](#-instalación)
- [Guía de uso](#-guía-de-uso)
- [Sincronizar entre móviles](#-sincronizar-entre-móviles)
- [Copias de seguridad](#-copias-de-seguridad)
- [Desarrollo](#-desarrollo)
- [Localization](#localization)
- [Donaciones](#donations-if-you-like-the-project)

---

## ✨ Funcionalidades

| | |
|---|---|
| 📦 **Inventario** | Productos con foto, unidades, precio de venta y coste. Margen calculado, alertas de stock bajo / agotado, filtros y ordenación (nombre, unidades, precio, coste, margen). Vista en tarjetas en el móvil y tabla en pantallas grandes. |
| 🎁 **Packs** | Agrupa varios productos en un pack con su propio precio y stock de unidades montadas. |
| 🏷️ **Promociones** | Descuento por porcentaje (p. ej. 10 % a partir de 2 uds.) o precio fijo por lote (p. ej. *3 por 12 €*), con soporte Mix & Match entre productos de la misma promoción. |
| 🛒 **Ventas** | Catálogo con buscador, carrito con las promociones aplicadas automáticamente y cobro indicando el método de pago (efectivo, PayPal, Bizum). |
| 🧾 **Tickets e historial** | Historial de ventas agrupado, ticket de cada venta y devoluciones parciales o totales (los packs pueden devolverse enteros o por componentes) calculadas correctamente aunque hubiera promociones. |
| 📊 **Panel** | Ingresos, beneficio y desglose por método de pago, con gráfica de ventas a pantalla completa. |
| 🔄 **Sincronización** | Pasa toda la base de datos a otro móvil con un QR. **No hace falta Wi‑Fi compartida**: la app crea su propio punto de acceso. |
| 💾 **Backups** | Exporta / comparte la base de datos y restáurala cuando quieras. |
| 🎨 **Personalización** | Tema claro / oscuro, colores dinámicos (Material You), español e inglés. |
| ⬆️ **Actualizaciones** | La app avisa cuando hay una nueva versión publicada en GitHub Releases. |

---

## 📲 Instalación

1. Ve a [**Releases**](https://github.com/nesherben/KeepInventory/releases/latest) y descarga el `.apk` más reciente.
2. Ábrelo en tu móvil Android. Si te lo pide, permite *instalar apps de origen desconocido* para tu navegador / gestor de archivos.
3. ¡Listo! Las siguientes versiones te las ofrecerá la propia app desde el aviso de actualización.

> Los APK de Releases están firmados siempre con la misma clave, así que puedes actualizar encima sin perder datos.
> Los APK que genera CI en cada push son solo para pruebas.

---

## 🧭 Guía de uso

El menú lateral (desliza desde el borde izquierdo o pulsa ☰) da acceso a todas las secciones.

> 🎓 La primera vez que abres la app aparece un **tutorial** rápido. Puedes volver a verlo cuando quieras desde **menú → Tutorial**.

### 1. Da de alta tu inventario
1. Abre **Inventario** y pulsa **＋**.
2. Rellena nombre, unidades, precio de venta y coste (el coste se usa para calcular margen y beneficio). Añade una foto si quieres; se comprime automáticamente.
3. Usa los filtros para ver rápidamente qué está **bajo de stock**, **agotado** o **con promoción**, y ordena por la columna que te interese.

### 2. Crea packs (opcional)
1. En **Packs**, pulsa **＋**, ponle nombre, precio y foto.
2. Añade los productos que lo forman y cuántas unidades de cada uno lleva.
3. Indica cuántos packs tienes montados: es el stock que se descuenta al venderlos.

### 3. Configura promociones (opcional)
1. En **Promociones**, crea una promoción:
   - **Porcentaje** → descuento del X % a partir de N unidades.
   - **Precio fijo por lote** → N unidades por X € (p. ej. *3 por 12 €*).
2. Asigna la promoción a los productos desde su ficha de inventario. Los productos que comparten promoción se combinan entre sí (Mix & Match).

### 4. Vende
1. Abre **Ventas**, busca o toca los productos / packs para añadirlos al carrito.
2. Ajusta cantidades: el total ya incluye las promociones.
3. Pulsa **COBRAR**, elige el método de pago y confirma. El stock se descuenta solo.

### 5. Consulta el historial y haz devoluciones
1. En **Historial** verás las ventas agrupadas con su ticket.
2. Para devolver, abre la venta y elige qué y cuántas unidades devolver. El importe se recalcula teniendo en cuenta las promociones aplicadas y el stock vuelve al inventario.

### 6. Revisa el panel
El **Panel** resume ingresos, beneficio y cuánto se ha cobrado por cada método de pago: perfecto para cuadrar la caja al final del día. Toca la gráfica para verla a pantalla completa.

---

## 🔄 Sincronizar entre móviles

Ideal para pasar el inventario a otro móvil del puesto. Ve a **Gestión de Datos → Sincronización por QR**:

1. **Emisor** (el que tiene los datos): elige *enviar*. La app crea un punto de acceso propio y muestra un **QR**.
2. **Receptor**: elige *recibir* y escanea el QR. Se conecta solo, sin necesidad de Wi‑Fi común.
3. El emisor recibe una **solicitud de aprobación** y debe aceptarla; sin esa aprobación no se envía nada.
4. El receptor descarga la base de datos y la app se reinicia con los datos nuevos.

> ⚠️ La sincronización **sustituye** los datos del receptor por los del emisor. Haz un backup antes si lo necesitas.
> 🔐 Cada QR lleva un token de un solo uso.

---

## 💾 Copias de seguridad

En **Gestión de Datos** puedes:

- **Exportar / compartir** la base de datos (por correo, Drive, Telegram…).
- **Importar** un backup anterior para restaurarlo.

Como la app no usa la nube, haz backups de vez en cuando para no perder nada si cambias de móvil.

---

## 🛠️ Desarrollo

**Stack:** Flutter · Dart · SQLite (`sqflite`) · `shelf` (servidor de sincronización local) · Kotlin (canal nativo del hotspot).

```bash
git clone https://github.com/nesherben/KeepInventory.git
cd KeepInventory
flutter pub get
flutter run            # con un móvil Android conectado o un emulador
flutter test           # tests unitarios
flutter build apk --release
```

**Estructura** (capas limpias por feature):

```
lib/
├── core/            # base de datos, servicios, tema, widgets compartidos
├── features/
│   ├── dashboard/
│   ├── inventory/
│   ├── packs/
│   ├── promotions/
│   ├── sales/       # lógica de precios y devoluciones en domain/
│   └── sync/
└── l10n/            # traducciones (.arb)
```

Cada feature se divide en `domain/` (entidades y lógica pura) → `data/` (modelos, datasources, repositorios) → `presentation/` (pantallas y widgets).

- **Cambios de esquema:** sube la versión en `database_helper.dart`, añade la migración en `database_migration_runner.dart` y actualiza `database_schema_creator.dart`.
- **CI:** cada push a `main` compila un APK de prueba (GitHub Actions). Las releases se publican a mano.

---

## Localization

The app follows the device language for Spanish (`lib/l10n/app_es.arb`) and English (`lib/l10n/app_en.arb`). Unsupported languages fall back to Spanish. Add translations to the matching ARB catalog and run `flutter gen-l10n` to regenerate the localization API.

---

## Donations if you like the project:

Si la app te resulta útil, puedes invitarme a un café ☕

www.paypal.me/nestor8299

---

<div align="center">

Hecho con ❤️ por **Néstor Hernández** · [Licencia MIT](LICENSE)

</div>
