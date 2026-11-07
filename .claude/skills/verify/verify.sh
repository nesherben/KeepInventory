#!/usr/bin/env bash
# Ejecuta flutter analyze y/o flutter test con salida compacta.
# Uso: verify.sh [all|analyze|test] [rutas_de_test...]
#   VERBOSE=1 muestra también los "info" del analyzer.
set -u
cd "$(git rev-parse --show-toplevel)" || exit 2
mode="${1:-all}"; [ $# -gt 0 ] && shift
rc=0

if [[ $mode == all || $mode == analyze ]]; then
  out=$(flutter analyze --no-pub 2>&1); arc=$?
  e=$(grep -cE '^\s*error •' <<<"$out"); w=$(grep -cE '^\s*warning •' <<<"$out"); i=$(grep -cE '^\s*info •' <<<"$out")
  echo "ANALYZE: errors=$e warnings=$w infos=$i"
  pat='^\s*(error|warning) •'; [[ ${VERBOSE:-0} == 1 ]] && pat='^\s*(error|warning|info) •'
  grep -E "$pat" <<<"$out" | sed -E 's/^\s+//' | head -40
  if [[ $arc -ne 0 && $e -eq 0 && $w -eq 0 && $i -eq 0 ]]; then tail -15 <<<"$out"; fi
  [[ $e -gt 0 ]] && rc=1
fi

if [[ $mode == all || $mode == test ]]; then
  out=$(flutter test --no-pub -r failures-only "$@" 2>&1); trc=$?
  if [[ $trc -eq 0 ]]; then
    echo "TEST: OK — $(grep -oE '[0-9]+ tests? passed|All tests passed!' <<<"$out" | tail -1)"
  else
    echo "TEST: FAILED"
    # Quita líneas de stack de paquetes del SDK para reducir ruido
    grep -vE 'package:(flutter|flutter_test|test_api|matcher|stack_trace)/|dart:async|^\s*$' <<<"$out" | head -120
    rc=1
  fi
fi
exit $rc
