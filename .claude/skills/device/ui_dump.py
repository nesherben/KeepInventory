"""Resume el volcado de uiautomator: un elemento por línea con su centro.

Uso: python ui_dump.py <window_dump.xml>
Salida: "x,y  [tap]  texto | descripción"  (solo elementos con texto o
descripción, o pulsables). Flutter expone sus textos en content-desc.
"""
import re
import sys
import xml.etree.ElementTree as ET

path = sys.argv[1]
try:
    root = ET.parse(path).getroot()
except Exception as e:  # volcado vacío o roto
    print(f'ERROR: no se pudo leer el volcado ({e})')
    sys.exit(1)

rows = []
for node in root.iter('node'):
    text = (node.get('text') or '').strip()
    desc = (node.get('content-desc') or '').strip()
    clickable = node.get('clickable') == 'true'
    if not (text or desc or clickable):
        continue
    m = re.match(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', node.get('bounds', ''))
    if not m:
        continue
    x1, y1, x2, y2 = map(int, m.groups())
    if x2 <= x1 or y2 <= y1:
        continue
    cx, cy = (x1 + x2) // 2, (y1 + y2) // 2
    label = ' | '.join(p for p in (text, desc.replace('\n', ' / ')) if p)
    rows.append((cy, cx, f'{cx},{cy}  {"[tap] " if clickable else "      "}{label}'))

for _, _, line in sorted(rows):
    print(line)
