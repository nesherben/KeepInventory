---
name: device
description: Install and check KeepInventory on the user's real Android phone via adb - build + install over the existing app (keeps data), launch, take screenshots to look at the UI, read Flutter errors from logcat. Use when the user asks to try/test/see a change on the phone, or to visually check a UI change.
---

# device

```bash
bash .claude/skills/device/device.sh status        # connected phones
bash .claude/skills/device/device.sh install       # release build + adb install -r (keeps data)
bash .claude/skills/device/device.sh launch        # open the app
bash .claude/skills/device/device.sh shot tutorial # -> build/screenshots/tutorial.png
bash .claude/skills/device/device.sh log           # recent Flutter errors
```

Flow: `status` → `install` → `launch` → `shot <name>` → **Read the PNG** to look at it.

- If no device: ask the user to plug the phone in with USB debugging on (or, over Wi‑Fi, `adb pair IP:port` then `adb connect IP:port`, from Developer options → Wireless debugging).
- To reach a screen, ask the user to navigate there on the phone; don't script taps (fragile).
- This is the user's real phone with real sales data: only `install -r` (never uninstall / `pm clear`), and don't create or delete data in the app without asking.
- Screenshots go to `build/` (gitignored); never commit them.
