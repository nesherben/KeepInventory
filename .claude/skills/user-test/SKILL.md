---
name: user-test
description: Launch the user-tester agent to use KeepInventory like a real stallholder on the test phone (and read the code) and report bugs, friction and missing features. Invoke only with /user-test [scenario or persona].
disable-model-invocation: true
---

# user-test — probar como un usuario

Input: optional scenario or persona in the arguments (e.g. "cerrar la caja de una feria", "primera vez", "combos y devoluciones"). Without arguments: a general pass over the main flows.

1. Check the device: `bash .claude/skills/device/device.sh status`. If the app on the phone is older than HEAD and the brief needs the latest features, install it first with `device.sh install` (tell the user). Only run `device.sh reset` if the user asked for a clean start.
2. Launch the `user-tester` agent with: the scenario/persona (or "pasada general: alta de productos, venta con promociones y combos, devolución parcial, ferias, cierre de caja, copias y sincronización"), whether the app was just reset, and the current app version (`grep '^version' pubspec.yaml`). Ask it to report in Spanish.
3. When it returns, show the user its findings grouped 🔴 / 🟠 / 🟢 (short, keep its `path:line` and repro steps) and ask which ones to fix. Do not fix anything before the user chooses. Fixes follow the normal rules (verify, l10n-add, README for big changes, commits in parts).
