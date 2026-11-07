#!/usr/bin/env bash
# Esquema compacto de archivos Dart: clases, enums, funciones y métodos con nº de línea.
# Uso: code_map.sh [ruta ...] [--public]
#   ruta: carpeta o archivo (por defecto lib). --public oculta miembros privados (_x).
set -u
cd "$(git rev-parse --show-toplevel)" || exit 2
public=0; paths=()
for a in "$@"; do [[ $a == --public ]] && public=1 || paths+=("$a"); done
[[ ${#paths[@]} -eq 0 ]] && paths=(lib)

decl='^(abstract |sealed |final |base |interface )*(class|mixin|enum|extension|typedef) '
# miembros con indentación de 2 espacios o funciones top-level
member='^(  )?(@override )?(static |external |factory )?([A-Z][][A-Za-z0-9_<>?, ]*|void|int|double|bool|num|String|dynamic|Future<.*>|Stream<.*>|List<.*>|Map<.*>|Set<.*>) +(get +)?[a-zA-Z_][A-Za-z0-9_]*(\(|( =>| \{))'
skip='^\s*(return|if|for|while|switch|final|const|var|await|throw|else|case) '

find "${paths[@]}" -name '*.dart' -not -path '*/generated/*' -not -name '*.g.dart' 2>/dev/null | sort | while read -r f; do
  n=$(wc -l <"$f")
  echo "## $f ($n)"
  grep -nE "$decl|$member" "$f" | grep -vE ":$skip" \
    | { [[ $public == 1 ]] && grep -vE '[ .]_[A-Za-z0-9]+(\(| =>| \{)|class _' || cat; } \
    | sed -E 's/\s*\{\s*$//; s/ async$//; s/^([0-9]+):/  \1 /' | cut -c1-140
done
