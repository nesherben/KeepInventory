#!/usr/bin/env bash
# Incrementa la versión en pubspec.yaml.
# Uso: bump.sh [patch|minor|major|X.Y.Z]   (por defecto patch). Conserva +build si existe.
set -eu
cd "$(git rev-parse --show-toplevel)"
line=$(grep -E '^version: ' pubspec.yaml)
cur=${line#version: }; base=${cur%%+*}; build=""; [[ $cur == *+* ]] && build="+${cur#*+}"
IFS=. read -r M m p <<<"$base"
case "${1:-patch}" in
  patch) p=$((p+1));;
  minor) m=$((m+1)); p=0;;
  major) M=$((M+1)); m=0; p=0;;
  [0-9]*.[0-9]*.[0-9]*) IFS=. read -r M m p <<<"$1";;
  *) echo "Argumento inválido: $1" >&2; exit 1;;
esac
new="$M.$m.$p"
[[ -n $build ]] && build="+$(( ${build#+} + 1 ))"
sed -i -E "s/^version: .*/version: $new$build/" pubspec.yaml
echo "$cur -> $new$build"
