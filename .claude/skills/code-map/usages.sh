#!/usr/bin/env bash
# Dónde se define y se usa un símbolo (palabra completa) en lib/ y test/.
# Uso: usages.sh <Simbolo> [--lines]
#   Sin --lines: recuento por archivo. Con --lines: file:line: código (máx. 60).
set -u
cd "$(git rev-parse --show-toplevel)" || exit 2
sym="${1:?Uso: usages.sh <Simbolo> [--lines]}"
echo "DEF:"
grep -rnE --include='*.dart' "(class|mixin|enum|extension|typedef) +$sym\b|^\s*[A-Za-z<>?, ]+ +$sym *\(.*\) *(async *)?(\{|=>)" lib test 2>/dev/null | grep -v /generated/ | cut -c1-160
echo "USES:"
if [[ ${2:-} == --lines ]]; then
  grep -rnw --include='*.dart' "$sym" lib test | grep -v /generated/ | sed -E 's/:\s+/: /' | cut -c1-160 | head -60
else
  grep -rcw --include='*.dart' "$sym" lib test | grep -v /generated/ | grep -v ':0$' | sort -t: -k2 -nr
fi
