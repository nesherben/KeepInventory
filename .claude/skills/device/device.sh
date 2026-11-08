#!/usr/bin/env bash
# Probar la app en el móvil real del usuario vía adb.
# Uso:
#   device.sh status            # móviles conectados
#   device.sh install           # compila release e instala encima (conserva datos)
#   device.sh launch            # abre la app
#   device.sh shot [nombre]     # captura -> build/screenshots/<nombre>.png
#   device.sh log               # últimos errores de Flutter en logcat
set -euo pipefail

APP_ID="com.example.keepinventory"
ADB="$(command -v adb || echo "$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe")"
cd "$(git rev-parse --show-toplevel)"

need_device() {
  local n
  n=$("$ADB" devices | awk 'NR>1 && $2=="device"' | wc -l)
  [ "$n" -ge 1 ] || { echo "ERROR: no hay ningún móvil conectado (USB con depuración, o adb connect IP:puerto)" >&2; exit 1; }
}

case "${1:-status}" in
  status)
    "$ADB" devices -l | tail -n +2 | sed '/^$/d' ;;
  install)
    need_device
    flutter build apk --release 2>&1 | tail -1
    APK=$(ls -t build/app/outputs/apk/release/*.apk | head -1)
    # -r: reinstala encima sin borrar datos
    "$ADB" install -r "$APK" | tail -1 ;;
  launch)
    need_device
    "$ADB" shell monkey -p "$APP_ID" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
    echo "Abierta $APP_ID" ;;
  shot)
    need_device
    mkdir -p build/screenshots
    OUT="build/screenshots/${2:-shot-$(date +%H%M%S)}.png"
    "$ADB" exec-out screencap -p > "$OUT"
    echo "$OUT" ;;
  log)
    need_device
    "$ADB" logcat -d -t 300 | grep -E "flutter|AndroidRuntime" | grep -iE "error|exception|E/flutter" | tail -30 || echo "Sin errores recientes" ;;
  *)
    echo "Uso: device.sh status|install|launch|shot [nombre]|log" >&2; exit 2 ;;
esac
