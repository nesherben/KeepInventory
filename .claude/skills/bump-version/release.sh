#!/usr/bin/env bash
# Publica una release de GitHub con el APK compilado en local.
# Uso: bash .claude/skills/bump-version/release.sh <notas.md> [--build] [--dry-run]
#  - La versión sale de pubspec.yaml (tag X.Y.Z, sin "v").
#  - --build  : ejecuta antes `flutter build apk --release`.
#  - --dry-run: solo comprueba y muestra lo que haría.
# Solo se lanza DESPUÉS de que el usuario confirme notas y versión.
set -euo pipefail

NOTES="${1:?Uso: release.sh <notas.md> [--build] [--dry-run]}"
shift || true
BUILD=0; DRY=0
for a in "$@"; do
  case "$a" in
    --build) BUILD=1 ;;
    --dry-run) DRY=1 ;;
    *) echo "Argumento desconocido: $a" >&2; exit 2 ;;
  esac
done

cd "$(git rev-parse --show-toplevel)"

# gh puede no estar en el PATH de Git Bash recién instalado
GH="$(command -v gh || true)"
[ -z "$GH" ] && [ -x "/c/Program Files/GitHub CLI/gh.exe" ] && GH="/c/Program Files/GitHub CLI/gh.exe"
[ -z "$GH" ] && { echo "ERROR: GitHub CLI (gh) no instalado: winget install GitHub.cli" >&2; exit 1; }
"$GH" auth status >/dev/null 2>&1 || { echo "ERROR: gh sin sesión. El usuario debe ejecutar: ! gh auth login" >&2; exit 1; }

[ -f "$NOTES" ] || { echo "ERROR: no existe el fichero de notas $NOTES" >&2; exit 1; }

VERSION="$(sed -n 's/^version:[[:space:]]*\([0-9.]*\).*/\1/p' pubspec.yaml)"
TAG="$VERSION"
APK="build/app/outputs/apk/release/KeepInventory-v${VERSION}-release.apk"

[ -z "$(git status --porcelain)" ] || { echo "ERROR: hay cambios sin commit" >&2; exit 1; }
git fetch -q origin main
[ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] || { echo "ERROR: HEAD no coincide con origin/main (haz push primero)" >&2; exit 1; }
if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null || git ls-remote --exit-code --tags origin "$TAG" >/dev/null 2>&1; then
  echo "ERROR: el tag $TAG ya existe" >&2; exit 1
fi

if [ "$BUILD" = 1 ]; then
  flutter build apk --release 2>&1 | tail -2
fi
[ -f "$APK" ] || { echo "ERROR: no existe $APK (usa --build)" >&2; exit 1; }
# El APK debe ser posterior al último commit (no publicar uno viejo)
APK_TIME=$(stat -c %Y "$APK"); COMMIT_TIME=$(git log -1 --format=%ct)
[ "$APK_TIME" -ge "$COMMIT_TIME" ] || { echo "ERROR: el APK es anterior al último commit; recompila con --build" >&2; exit 1; }

SIZE=$(du -h "$APK" | cut -f1)
echo "Versión : $VERSION (tag $TAG)"
echo "APK     : $APK ($SIZE)"
echo "Commit  : $(git log -1 --oneline)"
if [ "$DRY" = 1 ]; then echo "DRY-RUN: no se crea nada."; exit 0; fi

git tag -a "$TAG" -m "$TAG"
git push -q origin "$TAG"
# Un único asset: el actualizador de la app descarga assets[0]
"$GH" release create "$TAG" "$APK" --title "$TAG" --notes-file "$NOTES" --verify-tag
echo "OK: release $TAG publicada"
