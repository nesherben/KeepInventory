#!/usr/bin/env bash
# Probar la app en un móvil Android vía adb.
# Uso:
#   device.sh status                 # móviles conectados
#   device.sh install                # compila release e instala encima (conserva datos)
#   device.sh launch                 # abre la app
#   device.sh reset                  # BORRA los datos de la app y la abre limpia
#   device.sh shot [nombre]          # captura -> build/screenshots/<nombre>.png
#   device.sh ui                     # elementos en pantalla con su centro (x,y)
#   device.sh tap X Y                # tocar en (x,y) (píxeles reales)
#   device.sh longtap X Y            # pulsación larga
#   device.sh text "texto"           # escribir en el campo con foco
#   device.sh key BACK|HOME|ENTER|DEL|TAB
#   device.sh swipe X1 Y1 X2 Y2 [ms] # deslizar (scroll, cerrar paneles…)
#   device.sh log                    # últimos errores de Flutter en logcat
set -euo pipefail
# Git Bash (Windows) convierte "/sdcard/..." en rutas de Windows: desactivado
export MSYS_NO_PATHCONV=1

APP_ID="com.example.keepinventory"
ADB="$(command -v adb || echo "$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe")"
cd "$(git rev-parse --show-toplevel)"

need_device() {
  local n
  n=$("$ADB" devices | awk 'NR>1 && $2=="device"' | wc -l)
  [ "$n" -ge 1 ] || { echo "ERROR: no hay ningún móvil conectado (USB con depuración, o adb connect IP:puerto)" >&2; exit 1; }
}

# Espera breve para que la interfaz se asiente tras una acción
settle() { sleep "${SETTLE:-0.8}"; }

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
  reset)
    need_device
    "$ADB" shell pm clear "$APP_ID" | tail -1
    "$ADB" shell monkey -p "$APP_ID" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
    echo "Datos borrados y app abierta desde cero" ;;
  shot)
    need_device
    mkdir -p build/screenshots
    OUT="build/screenshots/${2:-shot-$(date +%H%M%S)}.png"
    "$ADB" exec-out screencap -p > "$OUT"
    echo "$OUT" ;;
  ui)
    need_device
    mkdir -p build/screenshots
    "$ADB" shell uiautomator dump /sdcard/kv_ui.xml >/dev/null 2>&1 || true
    "$ADB" exec-out cat /sdcard/kv_ui.xml > build/screenshots/ui.xml
    PYTHONIOENCODING=utf-8 python .claude/skills/device/ui_dump.py build/screenshots/ui.xml ;;
  tap)
    need_device
    "$ADB" shell input tap "$2" "$3"; settle ;;
  longtap)
    need_device
    "$ADB" shell input swipe "$2" "$3" "$2" "$3" 700; settle ;;
  text)
    need_device
    # adb input text: los espacios van como %s
    "$ADB" shell input text "$(printf '%s' "$2" | sed 's/ /%s/g')"; settle ;;
  key)
    need_device
    "$ADB" shell input keyevent "KEYCODE_$2"; settle ;;
  swipe)
    need_device
    "$ADB" shell input swipe "$2" "$3" "$4" "$5" "${6:-300}"; settle ;;
  log)
    need_device
    "$ADB" logcat -d -t 300 | grep -E "flutter|AndroidRuntime" | grep -iE "error|exception|E/flutter" | tail -30 || echo "Sin errores recientes" ;;
  *)
    echo "Uso: device.sh status|install|launch|reset|shot [nombre]|ui|tap X Y|longtap X Y|text \"t\"|key NAME|swipe X1 Y1 X2 Y2 [ms]|log" >&2; exit 2 ;;
esac
