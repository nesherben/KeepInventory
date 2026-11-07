---
name: verify
description: Run flutter analyze and/or flutter test with compact, token-cheap output (only errors, warnings and failing tests). Use after any code change, before committing, or when the user asks to "verify", "check", "run tests" or "analyze".
---

# verify

Never run `flutter analyze` or `flutter test` directly — their raw output is long. Use the script:

```bash
bash .claude/skills/verify/verify.sh            # analyze + all tests
bash .claude/skills/verify/verify.sh analyze    # only analyzer
bash .claude/skills/verify/verify.sh test test/sale_refund_calculator_test.dart   # specific tests
VERBOSE=1 bash .claude/skills/verify/verify.sh analyze   # include "info" lints
```

Output: one summary line per phase, then only the problems (capped). Exit code 0 = OK.

Guidelines:
- After editing, run only the relevant test files first (`test/<name>_test.dart`); run the full suite once at the end.
- Only `error`s block; report warnings but don't fix unrelated pre-existing ones unless asked.
- If a failure is unclear, read just the referenced test lines (`file:line`), not the whole file.
