# KeepInventory

Flutter app (Android) for inventory + POS sales/tickets. Local SQLite (`sqflite`), no state-management lib (StatefulWidget + `setState`/`ValueNotifier`). UI strings in Spanish (template) + English.

## Map
- `lib/main.dart` — init DB, image migration, theme, prefs; routes to screens.
- `lib/core/database/` — `database_helper.dart` (singleton, schema version), `database_schema_creator.dart` (fresh install), `database_migration_runner.dart` (upgrades). Schema change ⇒ bump version + add migration + update creator + tests.
- `lib/core/services/` — prefs, backup, DB import/install, GitHub update check, image compression/migration, LAN sync (`sync_service.dart`, shelf server + QR).
- `lib/core/shared_widgets/`, `lib/core/theme/`.
- `lib/features/<feature>/` (dashboard, inventory, packs, promotions, sales, sync) — clean layers:
  `domain/` (entities, pure logic, `repositories/` abstract) → `data/` (`*_model.dart`, `datasources/*_local_datasource.dart`, `repositories/*_impl.dart`) → `presentation/` (screens, `widgets/`).
- Sales pricing/refund logic lives in pure classes in `lib/features/sales/domain/` (`sale_cart_pricing_calculator`, `sale_refund_calculator`, …) — keep logic there, unit-test it in `test/`.
- `lib/l10n/*.arb` → generated `lib/l10n/generated/` (never edit generated).
- Tests: flat `test/<subject>_test.dart`.

## Token-saving rules
- Locate code with the `code-map` skill (outline + line numbers) before reading; read only line ranges.
- Run checks with the `verify` skill, never raw `flutter analyze` / `flutter test`.
- New UI text → `l10n-add` skill (don't read the ARB files).
- Big features → only when the user runs `/feature` (agents in `.claude/agents/`: feature-analyst, product-designer, code-reviewer). Don't spawn agents otherwise.
- Version bump → `bump-version` skill. Pushing to `main` triggers the APK build in CI.
- Releases are built and published **manually** by the user (local keystore signature; in-app updater reads GitHub Releases). Don't automate releases in CI.

## Conventions
- Commits: `feat: ...` style; version bumps: `feat: update version to X.Y.Z in pubspec.yaml`.
- Code comments are in Spanish.
- Money/numbers: never `toStringAsFixed` + "€" or `double.parse`. Display with `context.money(x)` ("1.234,50 €") or `context.amount(x)` inside l10n strings that already contain "€"; prefill fields with `context.amountInput(x)`; read with `AppNumbers.parseDecimal/parseInt` + `AppNumbers.decimalInputFormatters` (`lib/core/utils/app_numbers.dart`).
- UI: reuse `lib/core/shared_widgets/app_ui.dart` (AppCard, StatTile, SectionLabel, IconBadge, QuantityStepper, EmptyState, AppRadius/AppSpacing). Flat cards with 1px border, no shadows; text in ink colours, identity colour only on icons/marks.
