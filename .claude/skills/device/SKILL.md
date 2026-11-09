---
name: device
description: Install, drive and check KeepInventory on the Android phone via adb - build + install over the existing app, launch, wipe app data, read the on-screen elements, tap/type/swipe, take screenshots to look at the UI, read Flutter errors from logcat. Use when the user asks to try/test/see a change on the phone, to visually check a UI change, or to exercise a flow on the device.
---

# device

```bash
bash .claude/skills/device/device.sh status          # connected phones
bash .claude/skills/device/device.sh install         # release build + adb install -r (keeps data)
bash .claude/skills/device/device.sh launch          # open the app
bash .claude/skills/device/device.sh reset           # WIPE app data + open fresh (announce first)
bash .claude/skills/device/device.sh shot inventory  # -> build/screenshots/inventory.png (then Read it)
bash .claude/skills/device/device.sh ui              # on-screen elements: "x,y [tap] text | description"
bash .claude/skills/device/device.sh tap 540 1800    # tap at real pixels (from `ui`)
bash .claude/skills/device/device.sh longtap 540 900
bash .claude/skills/device/device.sh text "Camiseta roja"   # type into the focused field
bash .claude/skills/device/device.sh key BACK        # BACK | HOME | ENTER | DEL | TAB
bash .claude/skills/device/device.sh swipe 540 1800 540 600  # scroll / drag sheets
bash .claude/skills/device/device.sh log             # recent Flutter errors
```

Driving the app: `ui` → pick the element's `x,y` → `tap` → `ui` / `shot` to check the result. Flutter exposes texts as descriptions, so most buttons and labels appear in `ui`; icon-only buttons appear by their tooltip. Prefer `ui` (cheap text) and take a `shot` only when you need to *see* layout/visuals. Coordinates are real pixels (the phone is 1080×2400); screenshots shown to you may be scaled.

Device: the connected Xiaomi M2101K6G (serial 3130c4d) is a **test device with fake data** — creating sales, editing stock and `reset` are fine there (announce a `reset` before running it). Any other device: treat as a real phone with real data (only `install -r`, no `reset`, no data changes) unless the user says otherwise.

- No device: ask the user to plug it in with USB debugging (or `adb pair` / `adb connect IP:port` for Wireless debugging).
- Screenshots and dumps go to `build/screenshots/` (gitignored); never commit them.
