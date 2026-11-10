# KeepInventory

Flutter app (Android) for inventory + POS sales/tickets. Local SQLite (`sqflite`), no state-management lib (StatefulWidget + `setState`/`ValueNotifier`). UI strings in Spanish (template) + English.

## Map
- `lib/main.dart` — init DB, image migration, theme, prefs; routes to screens.
- `lib/core/database/` — `database_helper.dart` (singleton, schema version), `database_schema_creator.dart` (fresh install), `database_migration_runner.dart` (upgrades). Schema change ⇒ bump version + add migration + update creator + tests.
- `lib/core/services/` — prefs, backup, DB import/install, GitHub update check, image compression/migration, sync (`sync_service.dart` shelf server with one-time token **and mandatory sender approval** via `sync_approval.dart` — never serve data without it; `sync_invite.dart` QR format; `hotspot_service.dart` ↔ native `android/.../HotspotChannel.kt` creates/joins a LocalOnlyHotspot so no shared Wi‑Fi is needed — only testable on two real phones).
- `lib/core/shared_widgets/`, `lib/core/theme/`.
- `lib/features/<feature>/` (dashboard, inventory, packs, promotions, sales, sync) — clean layers:
  `domain/` (entities, pure logic, `repositories/` abstract) → `data/` (`*_model.dart`, `datasources/*_local_datasource.dart`, `repositories/*_impl.dart`) → `presentation/` (screens, `widgets/`).
- Dashboard balance UI is in `lib/features/dashboard/presentation/widgets/dashboard_chart.dart`; its private scale and `CustomPainter` implementations live in the sibling `dashboard_chart_painters.dart` part file.
- Inventory filter, category, summary, and mobile sort controls are isolated in `lib/features/inventory/presentation/widgets/inventory_filters_bar.dart`; `inventory_screen.dart` owns their state.
- Inventory product mutations and dialogs are handled by `lib/features/inventory/presentation/inventory_product_editor.dart`; `inventory_screen.dart` owns loading, filters, stock debounce, and view state.
- Sales checkout composition is in `lib/features/sales/presentation/sales_screen.dart`; cart total controls, catalog search/categories, landscape cart panel, and mobile draggable cart are isolated in `presentation/widgets/`.
- Sales pricing/refund logic lives in pure classes in `lib/features/sales/domain/` (`sale_cart_pricing_calculator`, `sale_refund_calculator`, …) — keep logic there, unit-test it in `test/`.
- `lib/l10n/*.arb` → generated `lib/l10n/generated/` (never edit generated).
- Tests: flat `test/<subject>_test.dart`.

## Token-saving rules
- Locate code with the `code-map` skill (outline + line numbers) before reading; read only line ranges.
- Run checks with the `verify` skill, never raw `flutter analyze` / `flutter test`.
- New UI text → `l10n-add` skill (don't read the ARB files).
- Big features → only when the user runs `/feature` (agents in `.claude/agents/`: feature-analyst, product-designer, code-reviewer). User testing → only when the user runs `/user-test` (agent `user-tester`, drives the test phone via the `device` skill). Don't spawn agents otherwise.
- Version bump → `bump-version` skill. Pushing to `main` triggers the APK build in CI.
- Releases are built **locally** (local keystore signature; in-app updater reads GitHub Releases) — never in CI. Claude may build, tag and publish them via the `bump-version` skill (`release.sh`), but only after the user OKs version + notes.

## Conventions
- Commits: `feat: ...` style; version bumps: `feat: update version to X.Y.Z in pubspec.yaml`.
- After any big user-visible change (new feature, new screen/flow, behaviour change), update `README.md` (features table + "Guía de uso", in Spanish) in the same batch of commits.
- Code comments are in Spanish.
- Money/numbers: never `toStringAsFixed` + "€" or `double.parse`. Display with `context.money(x)` ("1.234,50 €") or `context.amount(x)` inside l10n strings that already contain "€"; prefill fields with `context.amountInput(x)`; read with `AppNumbers.parseDecimal/parseInt` + `AppNumbers.decimalInputFormatters` (`lib/core/utils/app_numbers.dart`).
- UI: reuse `lib/core/shared_widgets/app_ui.dart` (AppCard, StatTile, SectionLabel, IconBadge, QuantityStepper, EmptyState, AppRadius/AppSpacing). Flat cards with 1px border, no shadows; text in ink colours, identity colour only on icons/marks.
