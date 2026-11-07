---
name: l10n-add
description: Add or update UI translation strings (Spanish template + English) in lib/l10n/*.arb and regenerate AppLocalizations, without reading the ARB files. Use whenever new user-visible text is added to a widget, or to check for missing translations.
---

# l10n-add

Never hardcode user-visible strings in widgets, and never read the full `.arb` files (they're large). Spanish (`app_es.arb`) is the template.

1. Check whether a similar key already exists (cheap):
   `grep -n '"<palabra>' lib/l10n/app_es.arb | head`
2. Add the key to both languages (camelCase, prefixed by screen/feature, e.g. `salesRefundConfirm`):
   ```bash
   dart run .claude/skills/l10n-add/l10n_add.dart salesItemsCount "{count} artículos" "{count} items" --ph count:int
   ```
   `{x}` placeholders are auto-detected as `String`; use `--ph name:Type` for `int`/`double`/`DateTime`. `--force` overwrites.
3. Regenerate: `flutter gen-l10n` (output goes to `lib/l10n/generated/`, never edit it by hand).
4. Use it in code: `AppLocalizations.of(context)!.<key>` or the extension in `lib/l10n/app_localizations_ext.dart` (check it with `code_map.sh lib/l10n/app_localizations_ext.dart`).
5. `git diff --stat lib/l10n` should only show the new lines.

Check missing translations: `dart run .claude/skills/l10n-add/l10n_add.dart --check`
