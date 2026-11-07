---
name: code-map
description: Token-cheap code navigation for this Flutter project — outline of classes/methods with line numbers, and where a symbol is defined/used. Use BEFORE reading Dart files to locate code, understand a feature, estimate impact of a change, or answer "where is X / who uses X".
---

# code-map

Goal: read outlines and line numbers first, then open only the exact line ranges needed (Read with `offset`/`limit`). Avoid reading whole files or broad exploration agents.

## Outline (classes, enums, functions, methods + line numbers)

```bash
bash .claude/skills/code-map/code_map.sh lib/features/sales            # one feature
bash .claude/skills/code-map/code_map.sh lib/features/sales/domain --public
bash .claude/skills/code-map/code_map.sh lib/core/database/database_migration_runner.dart
```

Each file prints `## path (total_lines)` then `  <line> <signature>`. Don't run it on all of `lib` unless you really need the global picture; scope to a feature/layer.

## Definition + usages of a symbol

```bash
bash .claude/skills/code-map/usages.sh SaleRefundCalculator           # count per file
bash .claude/skills/code-map/usages.sh calculateRefund --lines        # file:line: code
```

## Workflow
1. Check `CLAUDE.md` for the architecture map (feature → layer → file).
2. `code_map.sh` on the feature folder → pick the method/line.
3. `Read` with `offset`/`limit` around that line (≈40–80 lines).
4. Before changing a public API, `usages.sh` to see impact; edit all call sites.
