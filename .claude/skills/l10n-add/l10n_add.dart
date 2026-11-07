// Añade (o actualiza con --force) una clave de traducción en app_es.arb y app_en.arb.
// Uso:
//   dart run .claude/skills/l10n-add/l10n_add.dart <key> "<texto es>" "<texto en>" [--ph nombre:Tipo ...] [--force]
//   dart run .claude/skills/l10n-add/l10n_add.dart --check     (claves que faltan en algún idioma)
import 'dart:convert';
import 'dart:io';

const files = {'es': 'lib/l10n/app_es.arb', 'en': 'lib/l10n/app_en.arb'};

Map<String, dynamic> load(String p) =>
    jsonDecode(File(p).readAsStringSync()) as Map<String, dynamic>;

/// Inserta/actualiza la clave editando el texto (no re-serializa el archivo),
/// para conservar formato, CRLF y orden y que el diff sea mínimo.
void upsert(String path, String key, String value, Map<String, String> ph,
    bool withMeta) {
  var src = File(path).readAsStringSync();
  final nl = src.contains('\r\n') ? '\r\n' : '\n';
  final v = jsonEncode(value);
  final existing = RegExp('^(\\s*)${RegExp.escape(jsonEncode(key))}: ".*?"(,?)\\s*\$',
      multiLine: true);
  if (existing.hasMatch(src)) {
    src = src.replaceFirstMapped(existing,
        (m) => '${m[1]}${jsonEncode(key)}: $v${m[2]}');
    File(path).writeAsStringSync(src);
    return;
  }
  var entry = '  ${jsonEncode(key)}: $v';
  if (withMeta && ph.isNotEmpty) {
    final phs = ph.entries
        .map((e) => '      "${e.key}": {$nl        "type": "${e.value}"$nl      }')
        .join(',$nl');
    entry += ',$nl  "@$key": {$nl    "placeholders": {$nl$phs$nl    }$nl  }';
  }
  final end = src.lastIndexOf('}');
  final before = src.substring(0, end).trimRight();
  src = '$before,$nl$entry$nl}${src.substring(end + 1)}';
  File(path).writeAsStringSync(src);
}

Set<String> keys(Map<String, dynamic> m) =>
    m.keys.where((k) => !k.startsWith('@')).toSet();

void main(List<String> args) {
  if (args.contains('--check')) {
    final es = keys(load(files['es']!)), en = keys(load(files['en']!));
    print('es=${es.length} en=${en.length}');
    print('Faltan en en: ${es.difference(en).join(', ')}');
    print('Faltan en es: ${en.difference(es).join(', ')}');
    return;
  }
  final pos = <String>[], ph = <String, String>{};
  var force = false;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--force') {
      force = true;
    } else if (args[i] == '--ph') {
      final parts = args[++i].split(':');
      ph[parts[0]] = parts.length > 1 ? parts[1] : 'String';
    } else {
      pos.add(args[i]);
    }
  }
  if (pos.length != 3) {
    stderr.writeln('Uso: l10n_add.dart <key> "<es>" "<en>" [--ph name:Type] [--force]');
    exit(1);
  }
  final key = pos[0], texts = {'es': pos[1], 'en': pos[2]};
  // Detecta placeholders {x} no declarados como String por defecto
  for (final t in texts.values) {
    for (final m in RegExp(r'\{(\w+)\}').allMatches(t)) {
      ph.putIfAbsent(m.group(1)!, () => 'String');
    }
  }
  files.forEach((lang, path) {
    final m = load(path);
    if (m.containsKey(key) && !force) {
      stderr.writeln('La clave "$key" ya existe en $path (usa --force).');
      exit(1);
    }
    // Los metadatos @key solo en la plantilla (es)
    upsert(path, key, texts[lang]!, ph, lang == 'es');
    jsonDecode(File(path).readAsStringSync()); // valida que sigue siendo JSON
  });
  print('OK $key ${ph.isEmpty ? '' : 'placeholders=$ph'}');
}
